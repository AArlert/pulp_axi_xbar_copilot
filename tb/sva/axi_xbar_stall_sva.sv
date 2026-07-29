// tb/sva/axi_xbar_stall_sva.sv — M2/M3 same-ID cross-port ordering/stall SVA
// (design-prompt sva_bind.md §3 C3.2, spec §5.2.1/§5.2.2/§5.2.3/§5.2.4/§5.2.6).
// One instance per crossbar *slave* port interface (6 instances — C3.2 "适用
// 端口：仅 slave 端口"), direct-instantiated from tb/sva_bind.sv (mirrors
// tb/sva/axi_chan_sva.sv's attachment-mechanism note: VCS-2018.09-SP2
// rejects `bind <slvport_if> ...`, REV-003 — the module stays independent/
// reusable either way, only the attachment syntax differs). Generic
// `interface axi` port + manual field copies, same pattern as
// axi_chan_sva.sv, so it compiles the same known-working way.
//
// Reads only the slvport_if AXI4 channel signals plus the *live* config the
// crossbar itself is driven by — the shared addr_map and this slave port's own
// en_default / default_mst are wired in from tb_top's cfg_if exactly like
// axi_xbar_route_sva.sv (sva_bind.sv:41-47). Decoding the target master port
// uses the shared, spec-derived xbar_types_pkg::decode_mst_port() function
// against that *runtime* table — the exact same routing function/table version
// the M1 scoreboard uses (single source of truth, sva_bind.md §3 "译码复用").
// No DUT-internal signal is read (CLAUDE.md input-boundary rule).
//
// Runtime-live decode (BUG-0031): before, this call passed the compile-time
// localparam ADDR_MAP and hard-coded en_default=1'b0, so after an M2-CFG01-style
// runtime reconfiguration the module decoded against a stale table (target
// mis-recorded, error double-sided) AND dropped every default-master-port /
// err_slv transaction from tracking. Both are fixed by decoding against the live
// addr_map/en_default/default_mst wired in below. See doc/bugs.md BUG-0031.
//
// Decode-miss (err_slv) tracking (BUG-0025, spec §5.2.6): the per-full-ID table
// now registers EVERY accepted AW/AR (not only rule/default hits) and marks the
// decode-miss ones with an explicit is_err bit, so:
//   - spec §5.2.6 clause 1 (default master port is a real master port): default-
//     routed transactions enter the table and the §5.2.1-4 checks apply to them
//     unchanged;
//   - spec §5.2.6 clause 2.a (same FULL ID ordering, assertable regardless of
//     routing): judged by the scoreboard's per-(port,dir,full-id) completion FIFO
//     (scoreboard_refmodel.sv), not here — this module's single-bit-per-full-ID
//     table cannot represent two same-full-ID transactions in flight (BUG-0024);
//   - spec §5.2.6 clause 2.b/3 (low-ID-BUCKET dimension, DIFFERENT full IDs, one
//     via err_slv: UNDEFINED): the bucket-level reorder assertion below EXPLICITLY
//     excludes any transaction marked is_err (see w_reorder/r_reorder), and a
//     non-judgemental cover records the excluded corner being reached. The
//     exclusion is by the is_err marker, NOT by "unregistered ⇒ stale/default
//     value ⇒ comparison happens to be false" (spec §5.2.6 clause 3 red line).
// See doc/bugs.md BUG-0025.
//
// Judgement-gate note (BUG-0013, arbitrated by REV-006, spec §5.2.1 收窄):
// this module's PASS/FAIL gate is the reading-independent property directly
// derivable from §5.2.3 (no completion reordering across different targets
// within one same-bucket/direction group). The stricter boundary-level reading
// (§5.2.1 literal accept-time) is kept only as a non-decisional cover.
//
// Companion-property (spec §5.2.4) realization note: a matching-target
// pending request never contributes a "different-target" term to either
// the cover or the reorder check below, so §5.2.4's "not delayed by the
// preceding property" guarantee is a *structural* consequence of the `!=`
// terms used throughout, not a separate runtime condition to assert.
//
// Range boundary (spec §5.2.5/§6.5, sva_bind.md C3.2): only externally
// observable AW/AR/B/R handshakes are modelled; the ATOP-atomic-read
// "shadow AR" mechanism (BUG-0012) is out of scope by design.
import uvm_pkg::*;
`include "uvm_macros.svh"

module axi_xbar_stall_sva
  import xbar_types_pkg::*;
(
  interface axi,
  // Live crossbar config (wired from tb_top's cfg_if, sva_bind.sv gen_slv_stall_sva):
  // the shared runtime address table + this slave port's own default-master-port
  // config. BUG-0031: decode against these, never the compile-time ADDR_MAP.
  input rule_t [NO_ADDR_RULES-1:0] addr_map,
  input logic                      en_default,
  input logic [MST_PORT_IDX_W-1:0] default_mst
);

  logic clk_i, rst_ni;
  assign clk_i  = axi.clk_i;
  assign rst_ni = axi.rst_ni;

  id_slv_t aw_id, ar_id, b_id, r_id;
  addr_t   aw_addr, ar_addr;
  logic    aw_valid, aw_ready, ar_valid, ar_ready;
  logic    b_valid, b_ready, r_valid, r_ready, r_last;
  assign aw_id    = axi.aw_id;
  assign aw_addr  = axi.aw_addr;
  assign aw_valid = axi.aw_valid;
  assign aw_ready = axi.aw_ready;
  assign ar_id    = axi.ar_id;
  assign ar_addr  = axi.ar_addr;
  assign ar_valid = axi.ar_valid;
  assign ar_ready = axi.ar_ready;
  assign b_id     = axi.b_id;
  assign b_valid  = axi.b_valid;
  assign b_ready  = axi.b_ready;
  assign r_id     = axi.r_id;
  assign r_last   = axi.r_last;
  assign r_valid  = axi.r_valid;
  assign r_ready  = axi.r_ready;

  localparam int unsigned BUCKET_W     = Cfg.AxiIdUsedSlvPorts;
  localparam int unsigned NUM_IDS      = 2**ID_W_SLV;
  localparam int unsigned HI_W         = ID_W_SLV - BUCKET_W;
  localparam int unsigned NUM_SIBLINGS = 2**HI_W;

  // Bounds of the M2-CFG01/M3-CFG02 "moved rule" region (spec §3.1/§3.4). Only
  // its idx changes V0->V1 (0 -> CFG01_MOVED_IDX), start/end are stable, so the
  // baseline ADDR_MAP gives the correct region window for the BUG-0031 live-table
  // positive cover below.
  localparam addr_t MOVED_LO = ADDR_MAP[CFG01_MOVED_RULE].start_addr;
  localparam addr_t MOVED_HI = ADDR_MAP[CFG01_MOVED_RULE].end_addr;

  // ---- target-port decode against the LIVE table (BUG-0031). aw_hit/ar_hit is
  // 1 for a rule hit OR the enabled default master port (both real master ports,
  // spec §5.2.6 clause 1), 0 only on a genuine decode error (err_slv, spec §4).
  // aw_rule_hit re-decodes with default forced off, so aw_via_default marks a
  // transaction that matched NO rule but was routed to the default master port —
  // the BUG-0025 clause-1 witness that default traffic now enters the table.
  int unsigned aw_tgt, ar_tgt, aw_rule_tgt, ar_rule_tgt;
  bit          aw_hit, ar_hit, aw_rule_hit, ar_rule_hit;
  always_comb aw_hit      = decode_mst_port(aw_addr, addr_map, en_default, default_mst, aw_tgt);
  always_comb ar_hit      = decode_mst_port(ar_addr, addr_map, en_default, default_mst, ar_tgt);
  always_comb aw_rule_hit = decode_mst_port(aw_addr, addr_map, 1'b0, '0, aw_rule_tgt);
  always_comb ar_rule_hit = decode_mst_port(ar_addr, addr_map, 1'b0, '0, ar_rule_tgt);
  wire aw_via_default = aw_hit && !aw_rule_hit; // spec §5.2.6 clause 1
  wire ar_via_default = ar_hit && !ar_rule_hit;
  // BUG-0031 live-table positive witness: a transaction into the moved-rule
  // region whose LIVE-table target equals the V1 idx (CFG01_MOVED_IDX) — can only
  // be true if the module decoded the *runtime* table (V1), never the compile-time
  // V0 (which routes this region to idx 0). Structurally 0 before the fix.
  wire aw_moved_live_v1 = aw_hit && (aw_addr >= MOVED_LO) && (aw_addr < MOVED_HI)
                          && (aw_tgt == CFG01_MOVED_IDX);
  wire ar_moved_live_v1 = ar_hit && (ar_addr >= MOVED_LO) && (ar_addr < MOVED_HI)
                          && (ar_tgt == CFG01_MOVED_IDX);

  logic [BUCKET_W-1:0] aw_bkt, ar_bkt;
  assign aw_bkt = aw_id[BUCKET_W-1:0];
  assign ar_bkt = ar_id[BUCKET_W-1:0];

  // ---- per-full-ID open/target/accept-order/err table (spec §5.2.1/§5.2.2/
  // §5.2.6). Indexed by the *full* slv-side ID. is_err marks a decode-miss
  // (err_slv) transaction so the bucket-level reorder check can EXCLUDE it
  // (spec §5.2.6 clause 2.b) by an explicit marker, not a stale value.
  int unsigned w_id_tgt[NUM_IDS];
  bit          w_id_open[NUM_IDS];
  bit          w_id_is_err[NUM_IDS];
  int unsigned w_id_seq[NUM_IDS];
  int unsigned r_id_tgt[NUM_IDS];
  bit          r_id_open[NUM_IDS];
  bit          r_id_is_err[NUM_IDS];
  int unsigned r_id_seq[NUM_IDS];
  int unsigned w_seq_ctr, r_seq_ctr;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned i = 0; i < NUM_IDS; i++) begin
        w_id_open[i]   <= 1'b0;
        r_id_open[i]   <= 1'b0;
        w_id_is_err[i] <= 1'b0;
        r_id_is_err[i] <= 1'b0;
      end
      w_seq_ctr <= '0;
      r_seq_ctr <= '0;
    end else begin
      // BUG-0025: registration now covers EVERY accepted AW/AR, not only
      // rule/default hits. The old `aw_hit`-gated registration silently dropped
      // decode-miss err_slv transactions (making their completion invisible) and
      // left a stale target/seq behind (spec §5.2.6 clause 3 red line). Decode-miss
      // transactions register WITH an is_err marker so the reorder check excludes
      // them explicitly rather than by an unregistered/default value.
      if (aw_valid && aw_ready) begin
        w_id_tgt[aw_id]    <= aw_tgt;
        w_id_open[aw_id]   <= 1'b1;
        w_id_is_err[aw_id] <= !aw_hit;
        w_id_seq[aw_id]    <= w_seq_ctr;
        w_seq_ctr          <= w_seq_ctr + 1;
      end
      if (ar_valid && ar_ready) begin
        r_id_tgt[ar_id]    <= ar_tgt;
        r_id_open[ar_id]   <= 1'b1;
        r_id_is_err[ar_id] <= !ar_hit;
        r_id_seq[ar_id]    <= r_seq_ctr;
        r_seq_ctr          <= r_seq_ctr + 1;
      end
      // Symmetric deregistration (BUG-0025 rca): registration no longer requires a
      // hit, so the same-edge re-registration guard no longer tests aw_hit/ar_hit
      // either (otherwise a same-edge accept+complete on one full ID with a
      // decode-miss accept would clobber, BUG-0023 shape). Same guard rationale as
      // axi_xbar_atop_sva.sv's pair-flag clears.
      if (b_valid && b_ready && !(aw_valid && aw_ready && (aw_id == b_id)))
        w_id_open[b_id] <= 1'b0;
      if (r_valid && r_ready && r_last && !(ar_valid && ar_ready && (ar_id == r_id)))
        r_id_open[r_id] <= 1'b0;
    end
  end

  // ---- BUG-0023 regression witness (UNCHANGED, gated on aw_hit — M2-OR03 is an
  // all-rule-hit scenario; see doc/bugs.md BUG-0023). Remembers a same-edge
  // "accept + complete on one full ID" collision so the covers below can observe,
  // one cycle later, whether that new transaction's open record survived.
  bit      w_collide_q, r_collide_q;
  id_slv_t w_collide_id_q, r_collide_id_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      w_collide_q <= 1'b0;
      r_collide_q <= 1'b0;
    end else begin
      w_collide_q    <= aw_valid && aw_ready && aw_hit
                        && b_valid && b_ready && (aw_id == b_id);
      w_collide_id_q <= aw_id;
      r_collide_q    <= ar_valid && ar_ready && ar_hit
                        && r_valid && r_ready && r_last && (ar_id == r_id);
      r_collide_id_q <= ar_id;
    end
  end

  // ---- BUG-0024 corner witness (UNCHANGED, gated on aw_hit — see doc/bugs.md
  // BUG-0024, a separate ACCEPTED@M3 debt). Per-full-ID in-flight count + uniform
  // target; feeds covers only, never the judgement table above.
  int unsigned w_n[NUM_IDS],    r_n[NUM_IDS];
  int unsigned w_utgt[NUM_IDS], r_utgt[NUM_IDS];
  bit          w_uni[NUM_IDS],  r_uni[NUM_IDS];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned i = 0; i < NUM_IDS; i++) begin
        w_n[i]   <= 0;    r_n[i]   <= 0;
        w_uni[i] <= 1'b1; r_uni[i] <= 1'b1;
      end
    end else begin
      if (aw_valid && aw_ready && aw_hit) begin
        int unsigned n_now; // count after this same edge's own completion, if any
        n_now = w_n[aw_id]
                - ((b_valid && b_ready && (b_id == aw_id) && w_n[aw_id] > 0) ? 1 : 0);
        w_n[aw_id]    <= n_now + 1;
        w_uni[aw_id]  <= (n_now == 0) ? 1'b1
                                      : (w_uni[aw_id] && (w_utgt[aw_id] == aw_tgt));
        w_utgt[aw_id] <= (n_now == 0) ? aw_tgt : w_utgt[aw_id];
      end
      if (b_valid && b_ready && w_n[b_id] > 0
          && !(aw_valid && aw_ready && aw_hit && (aw_id == b_id))) begin
        w_n[b_id] <= w_n[b_id] - 1;
        if (w_n[b_id] == 1) w_uni[b_id] <= 1'b1;
      end
      if (ar_valid && ar_ready && ar_hit) begin
        int unsigned n_now;
        n_now = r_n[ar_id]
                - ((r_valid && r_ready && r_last && (r_id == ar_id) && r_n[ar_id] > 0)
                     ? 1 : 0);
        r_n[ar_id]    <= n_now + 1;
        r_uni[ar_id]  <= (n_now == 0) ? 1'b1
                                      : (r_uni[ar_id] && (r_utgt[ar_id] == ar_tgt));
        r_utgt[ar_id] <= (n_now == 0) ? ar_tgt : r_utgt[ar_id];
      end
      if (r_valid && r_ready && r_last && r_n[r_id] > 0
          && !(ar_valid && ar_ready && ar_hit && (ar_id == r_id))) begin
        r_n[r_id] <= r_n[r_id] - 1;
        if (r_n[r_id] == 1) r_uni[r_id] <= 1'b1;
      end
    end
  end

  // Enumerate the NUM_SIBLINGS full IDs sharing `id`'s low BUCKET_W bits
  // (spec §5.2.2's own "same ID" bucket comparison) other than `id` itself.
  function automatic int unsigned sibling_id(input int unsigned id,
                                              input int unsigned hi);
    return {hi[HI_W-1:0], id[BUCKET_W-1:0]};
  endfunction

  // True if some *other* same-bucket ID currently open on the write side
  // has a target that mismatches `tgt` (`match=0`) or matches it (`match=1`).
  function automatic bit w_sibling_open(input int unsigned id,
                                        input int unsigned tgt,
                                        input bit          match);
    w_sibling_open = 1'b0;
    for (int unsigned hi = 0; hi < NUM_SIBLINGS; hi++) begin
      int unsigned cand;
      cand = sibling_id(id, hi);
      if (cand != id && w_id_open[cand] && ((w_id_tgt[cand] == tgt) == match))
        w_sibling_open = 1'b1;
    end
  endfunction

  function automatic bit r_sibling_open(input int unsigned id,
                                        input int unsigned tgt,
                                        input bit          match);
    r_sibling_open = 1'b0;
    for (int unsigned hi = 0; hi < NUM_SIBLINGS; hi++) begin
      int unsigned cand;
      cand = sibling_id(id, hi);
      if (cand != id && r_id_open[cand] && ((r_id_tgt[cand] == tgt) == match))
        r_sibling_open = 1'b1;
    end
  endfunction

  // True if some *other*, *earlier-accepted* (lower seq), same-bucket,
  // different-target ID is still open on the write/read side when
  // `completing_id` completes — i.e. `completing_id`'s response overtook
  // that older, different-target request (spec §5.2.3's no-reordering purpose,
  // the BUG-0013-safe judgement anchor).
  //
  // spec §5.2.6 clause 2.b/3 EXCLUSION (BUG-0025): the low-ID-bucket ordering
  // relationship between a decode-miss (err_slv) transaction and a DIFFERENT
  // full ID sharing its bucket is UNDEFINED in the permitted sources (err_slv is
  // an internal per-slave-port module, not a master port — spec §4.1/§5.2.6). So
  // this check must not judge any pair where EITHER side is is_err. The exclusion
  // is by the explicit is_err marker (registered above), never by a stale/default
  // target value making the `!=` term happen to be false (spec §5.2.6 clause 3).
  function automatic bit w_reorder(input int unsigned completing_id);
    w_reorder = 1'b0;
    if (w_id_is_err[completing_id]) return w_reorder; // §5.2.6 2.b: completing side excluded
    for (int unsigned hi = 0; hi < NUM_SIBLINGS; hi++) begin
      int unsigned cand;
      cand = sibling_id(completing_id, hi);
      if (cand != completing_id && w_id_open[cand] && !w_id_is_err[cand] // §5.2.6 2.b
          && (w_id_tgt[cand] != w_id_tgt[completing_id])
          && (w_id_seq[cand] < w_id_seq[completing_id]))
        w_reorder = 1'b1;
    end
  endfunction

  function automatic bit r_reorder(input int unsigned completing_id);
    r_reorder = 1'b0;
    if (r_id_is_err[completing_id]) return r_reorder; // §5.2.6 2.b: completing side excluded
    for (int unsigned hi = 0; hi < NUM_SIBLINGS; hi++) begin
      int unsigned cand;
      cand = sibling_id(completing_id, hi);
      if (cand != completing_id && r_id_open[cand] && !r_id_is_err[cand] // §5.2.6 2.b
          && (r_id_tgt[cand] != r_id_tgt[completing_id])
          && (r_id_seq[cand] < r_id_seq[completing_id]))
        r_reorder = 1'b1;
    end
  endfunction

  // §5.2.6 clause 2.b excluded-corner witness (non-judgemental): at an AW/AR
  // accept, is there a same-bucket, DIFFERENT full ID sibling open whose err
  // status differs from this transaction's (exactly one of the pair via err_slv)?
  // That is precisely the combination the reorder check above must NOT judge — this
  // cover only proves the excluded corner is reached (spec §5.2.6 clause 2.b), never
  // a verdict.
  function automatic bit w_err_bucket(input int unsigned id, input bit this_is_err);
    w_err_bucket = 1'b0;
    for (int unsigned hi = 0; hi < NUM_SIBLINGS; hi++) begin
      int unsigned cand;
      cand = sibling_id(id, hi);
      if (cand != id && w_id_open[cand] && (w_id_is_err[cand] ^ this_is_err))
        w_err_bucket = 1'b1;
    end
  endfunction

  function automatic bit r_err_bucket(input int unsigned id, input bit this_is_err);
    r_err_bucket = 1'b0;
    for (int unsigned hi = 0; hi < NUM_SIBLINGS; hi++) begin
      int unsigned cand;
      cand = sibling_id(id, hi);
      if (cand != id && r_id_open[cand] && (r_id_is_err[cand] ^ this_is_err))
        r_err_bucket = 1'b1;
    end
  endfunction

  // All tracking-state predicates are folded into combinational *signals*
  // referenced directly by the properties below, so they get preponed
  // (pre-clock-edge) sampling — calling the functions inside the property
  // expression instead evaluates them in the observed region, after this same
  // edge's NBA updates, which is not what spec §5.2.3 constrains (BUG-0015).
  logic w_reorder_now, r_reorder_now;
  always_comb w_reorder_now = w_reorder(b_id);
  always_comb r_reorder_now = r_reorder(r_id);
  logic aw_sib_diff_now, ar_sib_diff_now, aw_sib_same_now, ar_sib_same_now;
  always_comb aw_sib_diff_now = w_sibling_open(aw_id, aw_tgt, 1'b0);
  always_comb ar_sib_diff_now = r_sibling_open(ar_id, ar_tgt, 1'b0);
  always_comb aw_sib_same_now = w_sibling_open(aw_id, aw_tgt, 1'b1);
  always_comb ar_sib_same_now = r_sibling_open(ar_id, ar_tgt, 1'b1);
  logic w_collide_kept_now, r_collide_kept_now;
  always_comb w_collide_kept_now = w_collide_q && w_id_open[w_collide_id_q];
  always_comb r_collide_kept_now = r_collide_q && r_id_open[r_collide_id_q];
  // §5.2.6 2.b excluded corner, evaluated at this AW/AR accept.
  logic aw_err_bucket_now, ar_err_bucket_now;
  always_comb aw_err_bucket_now = w_err_bucket(aw_id, !aw_hit);
  always_comb ar_err_bucket_now = r_err_bucket(ar_id, !ar_hit);
  // BUG-0024 corner (M2-OR03): this full ID already has >= 2 transactions in
  // flight, all at one target, and the AW/AR being accepted now carries the same
  // full ID for a *different* target.
  logic aw_stack_diff_now, ar_stack_diff_now;
  always_comb aw_stack_diff_now = (w_n[aw_id] >= 2) && w_uni[aw_id]
                                  && (w_utgt[aw_id] != aw_tgt);
  always_comb ar_stack_diff_now = (r_n[ar_id] >= 2) && r_uni[ar_id]
                                  && (r_utgt[ar_id] != ar_tgt);
  // BUG-0024 defect witness (UNCHANGED). NOT reused for BUG-0025/0031 (its
  // regression_guard proved it insensitive to those, REV-010 §2.2).
  logic w_lost_now, r_lost_now;
  always_comb begin
    w_lost_now = 1'b0;
    r_lost_now = 1'b0;
    for (int unsigned i = 0; i < NUM_IDS; i++) begin
      if (w_n[i] > 0 && !w_id_open[i]) w_lost_now = 1'b1;
      if (r_n[i] > 0 && !r_id_open[i]) r_lost_now = 1'b1;
    end
  end

  // ---- main judgement (spec §5.2.3, BUG-0013-safe anchor; spec §5.2.6 clause
  // 2.b exclusion built into w_reorder/r_reorder): a completing B/rlast must not
  // overtake an older, still-open, same-bucket/direction, different-target,
  // NON-err_slv request — no cross-master-port response reordering.
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (b_valid && b_ready) |-> !w_reorder_now)
    else `uvm_error("SVA_OR_W_REORDER",
      $sformatf("B id 'h%0h completed ahead of an older, still-open, same-bucket different-target write — spec §5.2.1/§5.2.3 response reordering",
                 $sampled(b_id)))
  ;
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (r_valid && r_ready && r_last) |-> !r_reorder_now)
    else `uvm_error("SVA_OR_R_REORDER",
      $sformatf("R(last) id 'h%0h completed ahead of an older, still-open, same-bucket different-target read — spec §5.2.1/§5.2.3 response reordering",
                 $sampled(r_id)))
  ;

  // ---- covers: main-property precondition actually exercised (激励来源
  // M2-OR01, and post-reconfig M3-CFG02) — a request is *presented* against a
  // live conflicting record. Under M3-CFG02 (BUG-0031 crit 4) these fire only
  // *after* the runtime reconfiguration created cross-target siblings; today's
  // M2-CFG01 baseline leaves this whole file at 0 match (single-outstanding).
  c_sib_diff_aw: cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_hit && aw_sib_diff_now);
  c_sib_diff_ar: cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_hit && ar_sib_diff_now);

  // ---- covers: companion-property precondition actually exercised (M2-OR02).
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_hit && aw_sib_same_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_hit && ar_sib_same_now);

  // ---- cover: BUG-0013's literal boundary-level precondition (non-decisional).
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_ready && aw_hit && aw_sib_diff_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_ready && ar_hit && ar_sib_diff_now);

  // ---- covers: BUG-0023 regression guard.
  cover property (@(posedge clk_i) disable iff (!rst_ni) w_collide_q);
  cover property (@(posedge clk_i) disable iff (!rst_ni) w_collide_kept_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni) r_collide_q);
  cover property (@(posedge clk_i) disable iff (!rst_ni) r_collide_kept_now);

  // ---- covers: BUG-0024 regression guard (testplan M2-OR03 criterion (2)).
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_ready && aw_hit && aw_stack_diff_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_ready && ar_hit && ar_stack_diff_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni) w_lost_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni) r_lost_now);

  // ---- cover: BUG-0025 clause-1 guard (spec §5.2.6 clause 1; testplan M3-DE02
  // criterion (4)). A transaction routed via the default master port has ENTERED
  // this tracking table — structurally 0 before the fix (the old call hard-coded
  // en_default=1'b0 so default traffic was dropped). >0 once M3-DE02 enables a
  // default master port and sends unmapped-address traffic to it.
  c_bug25_default_aw: cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_ready && aw_via_default);
  c_bug25_default_ar: cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_ready && ar_via_default);

  // ---- cover: BUG-0025 clause-2.b guard (spec §5.2.6; testplan M3-OR04
  // criterion (2)). The excluded low-ID-bucket corner is reached: an AW/AR is
  // accepted while a same-bucket, DIFFERENT full ID sibling of the OPPOSITE err
  // status is open (exactly one of the pair via err_slv). Non-judgemental — the
  // reorder assert above deliberately renders no verdict on this pair.
  c_bug25_errbucket_aw: cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_ready && aw_err_bucket_now);
  c_bug25_errbucket_ar: cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_ready && ar_err_bucket_now);

  // ---- cover: BUG-0031 live-table positive witness (testplan M3-CFG02
  // criterion (3)). Fires iff the module decoded the *runtime* V1 table for a
  // moved-rule-region transaction (target == CFG01_MOVED_IDX). Structurally 0
  // before the fix (compile-time V0 routes this region to idx 0). Non-decisional.
  c_bug31_livev1_aw: cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_ready && aw_moved_live_v1);
  c_bug31_livev1_ar: cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_ready && ar_moved_live_v1);

endmodule
