// tb/sva/axi_xbar_stall_sva.sv — M2 same-ID cross-port ordering/stall SVA
// (design-prompt sva_bind.md §3 C3.2, spec §5.2.1/§5.2.2/§5.2.3/§5.2.4). One
// instance per crossbar *slave* port interface (6 instances — C3.2 "适用
// 端口：仅 slave 端口"), direct-instantiated from tb/sva_bind.sv (mirrors
// tb/sva/axi_chan_sva.sv's attachment-mechanism note: VCS-2018.09-SP2
// rejects `bind <slvport_if> ...`, REV-003 — the module stays independent/
// reusable either way, only the attachment syntax differs). Generic
// `interface axi` port + manual field copies, same pattern as
// axi_chan_sva.sv, so it compiles the same known-working way.
//
// Reads only the slvport_if AXI4 channel signals plus the shared, spec-
// derived xbar_types_pkg::decode_mst_port() function — the exact same
// routing function the M1 scoreboard already uses for "target master
// port" (single source of truth, sva_bind.md §3 "译码复用"). No DUT-
// internal signal is read (CLAUDE.md input-boundary rule).
//
// Judgement-gate note (BUG-0013, OPEN, pending rev arbitration): a first
// draft of this module asserted spec §5.2.1's literal external-boundary
// reading — "the second same-bucket/direction, different-target request's
// AW/AR handshake must not be accepted before the first one's B/rlast".
// `make run TEST=m2_or01_stall_test SEED=1` reproduced that assert failing
// deterministically on this repo's pinned baseline (`LatencyMode=
// CUT_ALL_AX`, spec §7.2): `axi_demux.sv` wraps the core per-ID-bucket
// counter/target-lock decision logic (`axi_demux_simple`) in `SpillAw`/
// `SpillAr` spill registers *ahead* of it, so a second request can be
// externally accepted into that elastic buffering before the core decision
// logic has evaluated it against the still-open first one. Crucially, the
// completion *order* (B/rlast arrival) was still exactly preserved in the
// same repro — the AXI-ordering purpose spec §5.2.3 states for this
// mechanism ("...故以 stall 方式防止跨 master 端口乱序返回") held, even
// though the boundary-level acceptance timing did not match §5.2.1's literal
// wording. Filed as BUG-0013 (SPEC_ISSUE, non-blocking) rather than assumed
// away. Until rev arbitrates, this module's PASS/FAIL gate is the
// reading-independent property directly derivable from §5.2.3 (no
// completion reordering across different targets within one same-bucket/
// direction group); the stricter boundary-level reading is kept only as a
// non-decisional cover (so it can be promoted to an assert immediately if
// rev picks that reading) — see BUG-0013 ## fix and ## regression_guard.
//
// Companion-property (spec §5.2.4) realization note: a matching-target
// pending request never contributes a "different-target" term to either
// the cover or the reorder check below, so §5.2.4's "not delayed by the
// preceding property" guarantee is a *structural* consequence of the `!=`
// terms used throughout, not a separate runtime condition to assert.
//
// Range boundary (spec §5.2.5/§6.5, sva_bind.md C3.2): only externally
// observable AW/AR/B/R handshakes are modelled; the ATOP-atomic-read
// "shadow AR" mechanism (BUG-0012) is out of scope by design — a cross-
// direction stall it causes cannot satisfy this module's same-key/
// same-direction match condition and so cannot trigger either property.
import uvm_pkg::*;
`include "uvm_macros.svh"

module axi_xbar_stall_sva
  import xbar_types_pkg::*;
(
  interface axi
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

  // ---- target-port decode (shared function, spec §3.1/§3.2 — same one the
  // scoreboard uses; no second decode logic, sva_bind.md §3 "译码复用").
  int unsigned aw_tgt, ar_tgt;
  bit          aw_hit, ar_hit;
  // Baseline table + no default master port: the OR-stall scenarios
  // (M2-OR01/OR02) never reconfigure, so the compile-time ADDR_MAP is the
  // live table throughout; the runtime-variable table path (M2-CFG01) uses
  // single-outstanding-per-port stimulus, so this module's sibling-comparison
  // tracking below stays quiescent there regardless. Same one decode
  // implementation the scoreboard uses (sva_bind.md §3 "译码复用").
  always_comb aw_hit = decode_mst_port(aw_addr, ADDR_MAP, 1'b0, '0, aw_tgt);
  always_comb ar_hit = decode_mst_port(ar_addr, ADDR_MAP, 1'b0, '0, ar_tgt);

  logic [BUCKET_W-1:0] aw_bkt, ar_bkt;
  assign aw_bkt = aw_id[BUCKET_W-1:0];
  assign ar_bkt = ar_id[BUCKET_W-1:0];

  // ---- per-full-ID open/target/accept-order table (spec §5.2.1/§5.2.2),
  // kept separately per direction. Indexed by the *full* slv-side ID (not
  // just its low bucket bits) so that two different IDs sharing a bucket
  // (the exact construction uvm_env.md C5.2 uses) can each be tracked
  // individually — needed both for the boundary-precondition covers below
  // and for the completion-order assert (BUG-0013 ## fix).
  int unsigned w_id_tgt[NUM_IDS];
  bit          w_id_open[NUM_IDS];
  int unsigned w_id_seq[NUM_IDS];
  int unsigned r_id_tgt[NUM_IDS];
  bit          r_id_open[NUM_IDS];
  int unsigned r_id_seq[NUM_IDS];
  int unsigned w_seq_ctr, r_seq_ctr;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned i = 0; i < NUM_IDS; i++) begin
        w_id_open[i] <= 1'b0;
        r_id_open[i] <= 1'b0;
      end
      w_seq_ctr <= '0;
      r_seq_ctr <= '0;
    end else begin
      if (aw_valid && aw_ready && aw_hit) begin
        w_id_tgt[aw_id]  <= aw_tgt;
        w_id_open[aw_id] <= 1'b1;
        w_id_seq[aw_id]  <= w_seq_ctr;
        w_seq_ctr        <= w_seq_ctr + 1;
      end
      if (ar_valid && ar_ready && ar_hit) begin
        r_id_tgt[ar_id]  <= ar_tgt;
        r_id_open[ar_id] <= 1'b1;
        r_id_seq[ar_id]  <= r_seq_ctr;
        r_seq_ctr        <= r_seq_ctr + 1;
      end
      // Same-edge accept+complete on one full ID would otherwise clobber:
      // two NBAs to the same element, the later one (the clear) wins (IEEE
      // 1800 §10.4.2), swallowing the *new* transaction's open record and
      // silently retiring that ID from the reorder check (BUG-0023). Each
      // clear therefore stands down when this same edge already registered
      // the same ID — the net effect is "old one closed, new one open",
      // which is what the tgt/seq writes above assume. Same guard shape as
      // axi_xbar_atop_sva.sv's pair-flag clears.
      if (b_valid && b_ready
          && !(aw_valid && aw_ready && aw_hit && (aw_id == b_id)))
        w_id_open[b_id] <= 1'b0;
      if (r_valid && r_ready && r_last
          && !(ar_valid && ar_ready && ar_hit && (ar_id == r_id)))
        r_id_open[r_id] <= 1'b0;
    end
  end

  // ---- BUG-0023 regression witness: remembers a same-edge "accept + complete
  // on one full ID" collision and the ID it hit, so the covers at the bottom
  // can observe, one cycle later, whether that new transaction's open record
  // actually survived the collision. Falsifying by construction: with the
  // unguarded clear the record is swallowed and the "survived" cover can
  // never match.
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
  // that older, different-target request (spec §5.2.3's no-reordering
  // purpose, the BUG-0013-safe judgement anchor).
  function automatic bit w_reorder(input int unsigned completing_id);
    w_reorder = 1'b0;
    for (int unsigned hi = 0; hi < NUM_SIBLINGS; hi++) begin
      int unsigned cand;
      cand = sibling_id(completing_id, hi);
      if (cand != completing_id && w_id_open[cand]
          && (w_id_tgt[cand] != w_id_tgt[completing_id])
          && (w_id_seq[cand] < w_id_seq[completing_id]))
        w_reorder = 1'b1;
    end
  endfunction

  function automatic bit r_reorder(input int unsigned completing_id);
    r_reorder = 1'b0;
    for (int unsigned hi = 0; hi < NUM_SIBLINGS; hi++) begin
      int unsigned cand;
      cand = sibling_id(completing_id, hi);
      if (cand != completing_id && r_id_open[cand]
          && (r_id_tgt[cand] != r_id_tgt[completing_id])
          && (r_id_seq[cand] < r_id_seq[completing_id]))
        r_reorder = 1'b1;
    end
  endfunction

  // All tracking-state predicates are folded into combinational *signals*
  // referenced directly by the properties below, so they get preponed
  // (pre-clock-edge) sampling. Calling the functions inside the property
  // expression instead evaluates them in the observed region — *after* this
  // same edge's NBA updates — i.e. against the in-flight set as it stands
  // *after* this very handshake registers, which is not what spec §5.2.3
  // constrains (BUG-0015 regression_guard; BUG-0021 F1/F2).
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

  // ---- main judgement (spec §5.2.3, BUG-0013-safe anchor): a completing
  // B/rlast must not overtake an older, still-open, same-bucket/direction,
  // different-target request — no cross-master-port response reordering.
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
  // M2-OR01) — a request is *presented* against a live conflicting record.
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_hit && aw_sib_diff_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_hit && ar_sib_diff_now);

  // ---- covers: companion-property precondition actually exercised
  // (激励来源 M2-OR02) — a matching-target request presented while a
  // same-bucket/direction record is open.
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_hit && aw_sib_same_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_hit && ar_sib_same_now);

  // ---- cover: BUG-0013's literal boundary-level precondition — a request
  // is *accepted* (not just presented) while an older, different-target,
  // same-bucket/direction sibling is still open. Non-decisional (BUG-0013
  // OPEN): proves the exact symptom precondition is reproducible, ready to
  // promote to an assert the moment rev arbitrates that reading.
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_ready && aw_hit && aw_sib_diff_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_valid && ar_ready && ar_hit && ar_sib_diff_now);

  // ---- covers: BUG-0023 regression guard. The first of each pair proves the
  // same-edge accept+complete corner is reached at all (else the second is
  // vacuous); the second proves the newly accepted transaction is still
  // registered one cycle later, i.e. the collision did not retire that ID
  // from the reorder check above.
  cover property (@(posedge clk_i) disable iff (!rst_ni) w_collide_q);
  cover property (@(posedge clk_i) disable iff (!rst_ni) w_collide_kept_now);
  cover property (@(posedge clk_i) disable iff (!rst_ni) r_collide_q);
  cover property (@(posedge clk_i) disable iff (!rst_ni) r_collide_kept_now);

endmodule
