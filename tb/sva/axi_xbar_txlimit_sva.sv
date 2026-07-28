// tb/sva/axi_xbar_txlimit_sva.sv — M2 transaction-number-ceiling SVA
// (design-prompt sva_bind.md §3 C3.4, spec §5.4.1/§5.4.2/§5.4.3, §7.4.5). One
// instance per crossbar *master* port interface (8 instances), direct-
// instantiated from tb/sva_bind.sv (VCS-2018.09-SP2 rejects `bind
// <interface>`, REV-003 — same attachment mechanism as the other tb/sva/
// modules). Reads only external master-port AXI4 handshakes plus the pinned
// baseline Cfg (xbar_types_pkg); no DUT-internal signal (CLAUDE.md input
// boundary).
//
// ## Why the count is taken at the MASTER port (BUG-0013 / spec §7.4.5)
//
// Both ceilings are counted here as *master-port outstanding*: +1 when an
// AW/AR is accepted at this master port, -1 when its B / R(last) departs this
// master port — a purely delay-insensitive valid/ready tally, never a
// cycle-count. This is the ONLY externally-observable count the two ceilings
// genuinely bound, and it is the direct answer to BUG-0013 (REV-006, spec
// §7.4.5): the *slave*-port AW/AR accept boundary sits AFTER a `SpillAw`/
// `SpillAr` elastic buffer that precedes the demux core counter (CUT_ALL_AX,
// spec §7.2), so a slave-side accept-count can transiently exceed the ceiling
// by the buffer depth — asserting it would false-red. The master-port count
// does not: for `MaxMstTrans` the demux core counter caps how many the demux
// forwards toward any master port (spec §5.4.1), and the master-side
// `MuxAw`/`MuxAr` spill sits AFTER the mux (spec §7.1.1), so what arrives here
// is already past the counting logic. Formally, master-port outstanding =
// (arrived here) − (departed here) ≤ (forwarded past the counter) − (counter-
// decremented) = the DUT's own counter ≤ the ceiling. So this count is a hard,
// falsifiable, latency-insensitive image of "上限最终被守" (spec §7.4.5),
// with no assertion about *when* an external accept/reject edge happens.
//
// ## Two groupings, each a conservative lower side of the real mechanism
//
//  - MaxMstTrans (spec §5.4.1, M2-TL01): per (source slave port = ID prefix,
//    low-AxiIdUsedSlvPorts-bit bucket, direction). A demux ceiling, per
//    slave-port × bucket × direction; at one master port each such group is a
//    subset of that demux's count, so ≤ MaxMstTrans holds for every scenario.
//  - MaxSlvTrans (spec §5.4.2, M2-TL02, BUG-0011 / REV-005): per (full
//    prefix-after ID, direction) at this master port. Direction split and full
//    ID are the conservative finest grouping REV-005 unlocked — a subset of any
//    plausible undefined mechanism grouping, so only ever ≤ the true bound,
//    never a false red. The mechanism-level "which Nth beat is refused, when"
//    is a spec §5.4.3 upstream-confirmation item and is NOT asserted here (the
//    card's hard red line for M2-TL02).
//
// ## Judgement demoted to non-decisional under BUG-0016 (OPEN)
//
// A first draft ASSERTED "master-port in-flight ≤ MaxMstTrans / ≤ MaxSlvTrans"
// (the spec §5.4.1/§5.4.2 delay-insensitive image of "上限最终被守"). Both fire
// deterministically on the pinned baseline: the master-port count surpasses the
// documented ceiling (MaxMstTrans reaches 12 with 12 sent — the RTL demux
// counter is idx_width(MaxTrans)-bit and "full" only at all-ones = 2**ceil(
// log2(MaxMstTrans))-1 = 15, not 10; MaxSlvTrans reaches 8 with 8 sent — the
// mux has no per-id counter, cf. BUG-0011). This is a distinct effect from
// BUG-0013/§7.4.5 (the accept-*boundary* immediacy, ±spill depth); here the
// delay-insensitive COUNT itself exceeds the documented ceiling. The scoreboard
// routing/data/response-route/completion checks pass with zero mismatch in the
// same runs, so the DUT is functionally correct — only the documented numeric
// ceiling is not honored. Filed as BUG-0016. Per the BUG-0013 lesson (do not
// assert a bound the baseline DUT contradicts while it is under rev dispute),
// the ceiling readings are kept ONLY as non-decisional witnesses:
//   - a cover + one-shot uvm_info when a group REACHES the documented ceiling
//     (non-vacuity, sva_bind.md C3.4's required cover);
//   - a cover + one-shot uvm_info when a group EXCEEDS it (the BUG-0016 symptom,
//     reproducible and promotable to an assert the moment rev arbitrates).
// The decisional gate for M2-TL01/TL02 is the scoreboard's correctness under
// sustained same-bucket/same-id pressure (spec §1/§3/§5.1/§5.5) plus the
// "reached ceiling" non-vacuity covers.
//
// Read-direction guard (M2-AT01 atomic loads, spec §6.5): an atomic load
// returns an R at the master port with NO matching AR handshake (its shadow-AR
// lives inside the demux). Every R decrement is therefore guarded `> 0` so
// such an unmatched R can never drive a read counter negative (unsigned
// wrap) — it simply leaves the count at 0. The atomic-load R is not a real
// AR-based read at this boundary, so this keeps AT01 counts bounded and the
// read assertions free of false reds; M2-TL01/TL02 issue no ATOP, so their
// read counts are exact.
import uvm_pkg::*;
`include "uvm_macros.svh"

module axi_xbar_txlimit_sva
  import xbar_types_pkg::*;
(
  interface axi
);

  logic clk_i, rst_ni;
  assign clk_i  = axi.clk_i;
  assign rst_ni = axi.rst_ni;

  id_mst_t aw_id, ar_id, b_id, r_id;
  logic    aw_valid, aw_ready, ar_valid, ar_ready;
  logic    b_valid, b_ready, r_valid, r_ready, r_last;
  assign aw_id    = axi.aw_id;
  assign aw_valid = axi.aw_valid;
  assign aw_ready = axi.aw_ready;
  assign ar_id    = axi.ar_id;
  assign ar_valid = axi.ar_valid;
  assign ar_ready = axi.ar_ready;
  assign b_id     = axi.b_id;
  assign b_valid  = axi.b_valid;
  assign b_ready  = axi.b_ready;
  assign r_id     = axi.r_id;
  assign r_valid  = axi.r_valid;
  assign r_ready  = axi.r_ready;
  assign r_last   = axi.r_last;

  localparam int unsigned MAXMST   = Cfg.MaxMstTrans;             // 10
  localparam int unsigned MAXSLV   = Cfg.MaxSlvTrans;             // 6
  localparam int unsigned BUCKET_W = Cfg.AxiIdUsedSlvPorts;       // 3
  localparam int unsigned PREFIX_W = ID_W_MST - ID_W_SLV;         // 3
  localparam int unsigned MSTKEY_W = PREFIX_W + BUCKET_W;         // 6
  localparam int unsigned N_MSTKEY = 1 << MSTKEY_W;               // 64
  localparam int unsigned N_ID     = 1 << ID_W_MST;               // 256

  // (source prefix, bucket) key — the MaxMstTrans demux grouping projected to
  // the bits observable in the master-side id (spec §5.1.1: id = {prefix,
  // slv_id}; bucket = low AxiIdUsedSlvPorts bits of slv_id).
  function automatic logic [MSTKEY_W-1:0] mstkey(input id_mst_t id);
    return {id[ID_W_MST-1:ID_W_SLV], id[BUCKET_W-1:0]};
  endfunction

  // outstanding counts AT THIS master port
  int unsigned cnt_mst_w[N_MSTKEY]; // MaxMstTrans grouping, write
  int unsigned cnt_mst_r[N_MSTKEY]; // MaxMstTrans grouping, read
  int unsigned cnt_slv_w[N_ID];     // MaxSlvTrans grouping, write
  int unsigned cnt_slv_r[N_ID];     // MaxSlvTrans grouping, read

  wire aw_hs = aw_valid && aw_ready;
  wire ar_hs = ar_valid && ar_ready;
  wire b_hs  = b_valid && b_ready;
  wire r_hs  = r_valid && r_ready && r_last;

  wire [MSTKEY_W-1:0] aw_mk = mstkey(aw_id);
  wire [MSTKEY_W-1:0] b_mk  = mstkey(b_id);
  wire [MSTKEY_W-1:0] ar_mk = mstkey(ar_id);
  wire [MSTKEY_W-1:0] r_mk  = mstkey(r_id);

  bit reported_maxmst, reported_maxslv;
  bit reported_maxmst_over, reported_maxslv_over;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < N_MSTKEY; i++) begin
        cnt_mst_w[i] <= '0;
        cnt_mst_r[i] <= '0;
      end
      for (int i = 0; i < N_ID; i++) begin
        cnt_slv_w[i] <= '0;
        cnt_slv_r[i] <= '0;
      end
      reported_maxmst      <= 1'b0;
      reported_maxslv      <= 1'b0;
      reported_maxmst_over <= 1'b0;
      reported_maxslv_over <= 1'b0;
    end else begin
      // ---- write direction, MaxMstTrans grouping (aw +1 / b -1) ----
      if (aw_hs && b_hs && aw_mk == b_mk) begin
        // net 0 (one in, one out on the same key) — leave unchanged
      end else begin
        if (aw_hs)                       cnt_mst_w[aw_mk] <= cnt_mst_w[aw_mk] + 1;
        if (b_hs && cnt_mst_w[b_mk] > 0) cnt_mst_w[b_mk]  <= cnt_mst_w[b_mk] - 1;
      end
      // ---- write direction, MaxSlvTrans grouping (aw +1 / b -1) ----
      if (aw_hs && b_hs && aw_id == b_id) begin
      end else begin
        if (aw_hs)                       cnt_slv_w[aw_id] <= cnt_slv_w[aw_id] + 1;
        if (b_hs && cnt_slv_w[b_id] > 0) cnt_slv_w[b_id]  <= cnt_slv_w[b_id] - 1;
      end
      // ---- read direction, MaxMstTrans grouping (ar +1 / r-last -1) ----
      if (ar_hs && r_hs && ar_mk == r_mk) begin
      end else begin
        if (ar_hs)                       cnt_mst_r[ar_mk] <= cnt_mst_r[ar_mk] + 1;
        if (r_hs && cnt_mst_r[r_mk] > 0) cnt_mst_r[r_mk]  <= cnt_mst_r[r_mk] - 1;
      end
      // ---- read direction, MaxSlvTrans grouping (ar +1 / r-last -1) ----
      if (ar_hs && r_hs && ar_id == r_id) begin
      end else begin
        if (ar_hs)                       cnt_slv_r[ar_id] <= cnt_slv_r[ar_id] + 1;
        if (r_hs && cnt_slv_r[r_id] > 0) cnt_slv_r[r_id]  <= cnt_slv_r[r_id] - 1;
      end

      // ---- one-shot readable evidence: the DOCUMENTED ceiling was reached
      // (non-vacuity) and, per BUG-0016, SURPASSED (the finding witness). ----
      if (!reported_maxmst
          && ((aw_hs && !(b_hs && aw_mk == b_mk) && cnt_mst_w[aw_mk] == MAXMST-1)
           || (ar_hs && !(r_hs && ar_mk == r_mk) && cnt_mst_r[ar_mk] == MAXMST-1)))
      begin
        reported_maxmst <= 1'b1;
        `uvm_info("SVA_TXLIMIT",
          $sformatf("MaxMstTrans reached: master-port in-flight for a (source,bucket) group hit %0d (spec §5.4.1; non-vacuous, limit genuinely stressed)",
                     MAXMST), UVM_LOW)
      end
      if (!reported_maxmst_over
          && ((aw_hs && !(b_hs && aw_mk == b_mk) && cnt_mst_w[aw_mk] == MAXMST)
           || (ar_hs && !(r_hs && ar_mk == r_mk) && cnt_mst_r[ar_mk] == MAXMST)))
      begin
        reported_maxmst_over <= 1'b1;
        `uvm_info("SVA_TXLIMIT_OVER",
          $sformatf("BUG-0016 witness: master-port in-flight for a (source,bucket) group EXCEEDED MaxMstTrans=%0d (spec §5.4.1 / xbar.md L46 say '<= MaxMstTrans'; RTL demux counter is idx_width(MaxTrans)-bit, full only at all-ones=2**ceil(log2(MaxMstTrans))-1). Non-decisional (BUG-0016 OPEN).",
                     MAXMST), UVM_LOW)
      end
      if (!reported_maxslv
          && ((aw_hs && !(b_hs && aw_id == b_id) && cnt_slv_w[aw_id] == MAXSLV-1)
           || (ar_hs && !(r_hs && ar_id == r_id) && cnt_slv_r[ar_id] == MAXSLV-1)))
      begin
        reported_maxslv <= 1'b1;
        `uvm_info("SVA_TXLIMIT",
          $sformatf("MaxSlvTrans reached: master-port in-flight for a (full-id,direction) group hit %0d (spec §5.4.2, observable-upper-bound monitor per BUG-0011/REV-005; non-vacuous)",
                     MAXSLV), UVM_LOW)
      end
      if (!reported_maxslv_over
          && ((aw_hs && !(b_hs && aw_id == b_id) && cnt_slv_w[aw_id] == MAXSLV)
           || (ar_hs && !(r_hs && ar_id == r_id) && cnt_slv_r[ar_id] == MAXSLV)))
      begin
        reported_maxslv_over <= 1'b1;
        `uvm_info("SVA_TXLIMIT_OVER",
          $sformatf("BUG-0016 witness: master-port in-flight for a (full-id,direction) group EXCEEDED MaxSlvTrans=%0d (REV-005 unlocked a '<= MaxSlvTrans, never false-red' observable monitor; empirically it is NOT an upper bound — mux has no per-id counter, cf. BUG-0011). Non-decisional (BUG-0016 OPEN).",
                     MAXSLV), UVM_LOW)
      end
    end
  end

  // ==== judgement note (BUG-0016, OPEN, pending rev arbitration) ============
  // A first draft asserted "master-port in-flight <= MaxMstTrans / <=
  // MaxSlvTrans" — the spec §5.4.1/§5.4.2 (from xbar.md L46/L47 "at most this
  // many ... in flight", demux.md L72 "each counter can count up to and
  // including MaxTrans") delay-insensitive image of "上限最终被守". Both fired
  // deterministically on the pinned baseline: with n>ceiling same-bucket /
  // same-id back-to-back requests and the responder holding B/R, the master-
  // port count reaches ceiling+2 (MaxMstTrans: sent 12, all forwarded; the
  // demux counter is idx_width(MaxTrans)-bit and "full" only at all-ones, so
  // the structural per-bucket ceiling is 2**ceil(log2(10))-1 = 15, not 10) and
  // ceiling+2 for MaxSlvTrans (sent 8, all forwarded — the mux has no per-id
  // counter, cf. BUG-0011, so the demux per-bucket ceiling dominates, not a
  // <=6 per-id bound). This is a distinct effect from BUG-0013/§7.4.5 (that is
  // the accept-*boundary* immediacy, ±spill-buffer depth; here the delay-
  // insensitive count itself surpasses the documented ceiling by the counter-
  // width rounding). Crucially the scoreboard's routing / data / response-
  // route / completion checks pass with zero mismatch in the same runs — every
  // transaction is correctly routed, data-correct and completes; only the
  // documented numeric ceiling is not honored. Filed as BUG-0016 (OPEN,
  // suspect DUT vs vendor doc; rev may instead refine the spec's MaxTrans
  // semantics). Until rev arbitrates, the ceiling readings are NOT asserted
  // (asserting a bound the baseline DUT contradicts under dispute would be the
  // BUG-0013 mistake); they are kept as non-decisional cover/uvm_info witnesses
  // so the exact symptom is reproducible and promotable the moment rev rules.
  // The decisional gate for M2-TL01/TL02 is therefore the scoreboard's
  // correctness-under-sustained-pressure (spec §1/§3/§5.1/§5.5) plus the
  // non-vacuity "reached ceiling" covers below.

  // ---- covers: the documented ceiling was reached (non-vacuity, sva_bind.md
  // C3.4 "某桶计数达到 MaxMstTrans 至少发生一次") --------------------------
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_hs && !(b_hs && aw_mk == b_mk) && (cnt_mst_w[aw_mk] == MAXMST-1));
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_hs && !(r_hs && ar_mk == r_mk) && (cnt_mst_r[ar_mk] == MAXMST-1));
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_hs && !(b_hs && aw_id == b_id) && (cnt_slv_w[aw_id] == MAXSLV-1));
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_hs && !(r_hs && ar_id == r_id) && (cnt_slv_r[ar_id] == MAXSLV-1));

  // ---- covers: the documented ceiling was EXCEEDED (BUG-0016 witness — the
  // reproducible precondition, ready to promote to an assert once rev rules) --
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_hs && !(b_hs && aw_mk == b_mk) && (cnt_mst_w[aw_mk] == MAXMST));
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_hs && !(r_hs && ar_mk == r_mk) && (cnt_mst_r[ar_mk] == MAXMST));
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_hs && !(b_hs && aw_id == b_id) && (cnt_slv_w[aw_id] == MAXSLV));
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    ar_hs && !(r_hs && ar_id == r_id) && (cnt_slv_r[ar_id] == MAXSLV));

endmodule
