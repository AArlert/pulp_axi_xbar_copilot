// tb/sva/axi_xbar_worder_sva.sv — M2 W-channel-order non-vacuity cover
// (design-prompt sva_bind.md §3 C3.3, spec §5.5.1/§5.5.2). One instance per
// crossbar *master* port interface (8 instances — C3.3 "适用端口：master
// 端口"), direct-instantiated from tb/sva_bind.sv (VCS-2018.09-SP2 rejects
// `bind <interface>`, REV-003 — same attachment mechanism as
// axi_xbar_stall_sva.sv / axi_xbar_atop_sva.sv).
//
// C3.3 adds NO new assert: "W burst stays in AW order, non-interleaved"
// (spec §5.5.1/§5.5.2) is already enforced by the existing per-interface
// beat-count bookkeeping in axi_chan_sva C2.3 (SVA_WLAST_LEN) plus the
// mstport_monitor aw_q FIFO pairing and the scoreboard's per-burst
// attribution — an interleave/reorder there manifests as a length or
// data/id mismatch. What was missing is *non-vacuity evidence*: proof that
// those existing checks were exercised under genuine multi-source
// convergence rather than passing only because sources never actually
// competed at one master port.
//
// This module contributes exactly ONE cover property (sva_bind.md C3.3
// "本卡只加一条非空转 cover property"): fired when a W burst STARTS at this
// master port while ≥2 *distinct source slave ports* have an AW pending
// here (accepted, its W burst not yet completed). "Source slave port" = the
// master-side AW id's high $clog2(NoSlvPorts) prefix bits (spec §5.1.1).
//
// Nothing here asserts any round-robin grant order or which source is served
// next (spec §5.5.4 / C6.2 hard red line) — a cover only records that a
// condition occurred, it constrains nothing.
import uvm_pkg::*;
`include "uvm_macros.svh"

module axi_xbar_worder_sva
  import xbar_types_pkg::*;
(
  interface axi
);

  logic clk_i, rst_ni;
  assign clk_i  = axi.clk_i;
  assign rst_ni = axi.rst_ni;

  id_mst_t aw_id;
  logic    aw_valid, aw_ready;
  logic    w_valid, w_ready, w_last;
  assign aw_id    = axi.aw_id;
  assign aw_valid = axi.aw_valid;
  assign aw_ready = axi.aw_ready;
  assign w_valid  = axi.w_valid;
  assign w_ready  = axi.w_ready;
  assign w_last   = axi.w_last;

  localparam int unsigned PREFIX_W = ID_W_MST - ID_W_SLV; // = $clog2(NoSlvPorts)

  // Source-prefix of each AW accepted here but whose W burst has not yet
  // completed, in AW-acceptance order (mirrors mstport_monitor.aw_q). The
  // front is the burst currently draining; later entries are AWs waiting
  // behind it. A W burst completing (w_last) pops the front.
  logic [PREFIX_W-1:0] pend_pref[$];
  bit                  w_busy;
  // One-cycle pulse: a W burst started this cycle with ≥2 distinct sources
  // pending. Registered (not combinational over a queue — VCS drops queues
  // from always_comb sensitivity, axi_chan_sva C2.3 note), then covered.
  bit                  compete_start;

  // Distinct source-prefixes currently pending (includes the burst whose W is
  // now starting, whose AW was accepted on an earlier cycle and is still at
  // the queue front). ≥2 => this master port has genuine cross-source W
  // convergence at this instant.
  function automatic int unsigned distinct_pending();
    bit [(1<<PREFIX_W)-1:0] seen;
    seen = '0;
    distinct_pending = 0;
    foreach (pend_pref[i]) begin
      if (!seen[pend_pref[i]]) begin
        seen[pend_pref[i]] = 1'b1;
        distinct_pending++;
      end
    end
  endfunction

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pend_pref.delete();
      w_busy        <= 1'b0;
      compete_start <= 1'b0;
    end else begin
      compete_start <= 1'b0; // default: no pulse
      // W burst start — evaluate the pending set as it stood coming into this
      // cycle (before this cycle's own AW push below), so a same-cycle AW is
      // conservatively excluded rather than faking the condition.
      if (w_valid && w_ready && !w_busy) begin
        if (distinct_pending() >= 2) compete_start <= 1'b1;
        w_busy <= 1'b1;
      end
      // AW accept — record its source prefix.
      if (aw_valid && aw_ready)
        pend_pref.push_back(aw_id[ID_W_MST-1:ID_W_SLV]);
      // W burst end — the front AW's burst just completed.
      if (w_valid && w_ready && w_last) begin
        if (pend_pref.size() > 0) pend_pref.pop_front();
        w_busy <= 1'b0;
      end
    end
  end

  // ---- cover (sva_bind.md C3.3, spec §5.5.2, 激励来源 M2-WO01): a W burst
  // started here under genuine ≥2-source AW convergence — the non-vacuity
  // witness for the existing §5.5.1/§5.5.2 order/interleave checks.
  cover property (@(posedge clk_i) disable iff (!rst_ni) compete_start);

endmodule
