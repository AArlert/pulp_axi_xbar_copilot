// tb/sva/axi_chan_sva.sv — M1 protocol/timing-contract SVA (design-prompt
// sva_bind.md §2, M1 AXI4 protocol-baseline assertion set). Independent
// module, attached from tb/sva_bind.sv (`include`-d into tb_top.sv) — never
// inlined into tb_top's own body, never references DUT-internal signals
// (CLAUDE.md input-boundary rule): every field read here is an externally
// observable AXI4 channel signal at a crossbar port interface.
//
// Attachment mechanism note: the design prompt's default expectation is a
// `bind` attachment (CLAUDE.md §6). VCS-2018.09-SP2 rejects `bind <iface>
// axi_chan_sva (...)` for both slvport_if and mstport_if with
// "Error-[IIM] ... Interface has a module instantiation which is not
// allowed" (a tool-side restriction on binding a module directly into an
// interface scope, observed empirically when this card compiled it).
// tb/sva_bind.sv works around this by *directly instantiating* this module
// from tb_top.sv's own generate loops instead of `bind`-ing it — tb_top.sv
// is DV-owned code (unlike the DUT), so non-invasive attachment via `bind`
// buys nothing there; the module stays standalone/reusable and out of
// tb_top's body either way, which is the substance of C1.1. This is a
// structural/implementation deviation only — no behavior asserted here or
// elsewhere changed by it; flagged for orch/rev awareness in the delivery
// report, not silently taken.
//
// Generic interface port: `axi` is bound to whichever interface instance is
// connected (slvport_if or mstport_if — both share identical field names,
// differing only in ID width, passed via ID_WIDTH); this is what lets one
// module instance serve both port classes.
//
// Every assertion below cites doc/spec.md; none assumes a fixed
// pipeline-stage count (spec §7.4 / C2.4) and none asserts a specific
// round-robin grant order (spec §5.5.4 / C2.5).
//
// C2.3's beat-count bookkeeping (aw/ar-len FIFO paired to the following
// W/R burst) assumes bursts on this interface are not interleaved across
// sources, which holds for every port this env drives/responds on (each
// slvport_driver/mstport_responder instance processes one burst per
// direction/queue slot at a time — see tb/slvport_agent.sv,
// tb/mstport_agent.sv); a future M2 env that allows genuine interleaving
// would need this reworked to track per-ID state.
import uvm_pkg::*;
`include "uvm_macros.svh"

module axi_chan_sva #(
  parameter int unsigned ID_WIDTH = 1
) (
  interface axi
);

  logic clk_i;
  logic rst_ni;
  assign clk_i  = axi.clk_i;
  assign rst_ni = axi.rst_ni;

  logic [ID_WIDTH-1:0] aw_id;
  logic [31:0]         aw_addr;
  axi_pkg::len_t       aw_len;
  axi_pkg::size_t      aw_size;
  axi_pkg::burst_t     aw_burst;
  logic                aw_lock;
  axi_pkg::cache_t     aw_cache;
  axi_pkg::prot_t      aw_prot;
  axi_pkg::qos_t       aw_qos;
  axi_pkg::region_t    aw_region;
  axi_pkg::atop_t      aw_atop;
  logic                aw_valid;
  logic                aw_ready;
  assign aw_id     = axi.aw_id;
  assign aw_addr   = axi.aw_addr;
  assign aw_len    = axi.aw_len;
  assign aw_size   = axi.aw_size;
  assign aw_burst  = axi.aw_burst;
  assign aw_lock   = axi.aw_lock;
  assign aw_cache  = axi.aw_cache;
  assign aw_prot   = axi.aw_prot;
  assign aw_qos    = axi.aw_qos;
  assign aw_region = axi.aw_region;
  assign aw_atop   = axi.aw_atop;
  assign aw_valid  = axi.aw_valid;
  assign aw_ready  = axi.aw_ready;

  logic [63:0] w_data;
  logic [7:0]  w_strb;
  logic        w_last;
  logic        w_valid;
  logic        w_ready;
  assign w_data  = axi.w_data;
  assign w_strb  = axi.w_strb;
  assign w_last  = axi.w_last;
  assign w_valid = axi.w_valid;
  assign w_ready = axi.w_ready;

  logic [ID_WIDTH-1:0] b_id;
  axi_pkg::resp_t      b_resp;
  logic                b_valid;
  logic                b_ready;
  assign b_id    = axi.b_id;
  assign b_resp  = axi.b_resp;
  assign b_valid = axi.b_valid;
  assign b_ready = axi.b_ready;

  logic [ID_WIDTH-1:0] ar_id;
  logic [31:0]         ar_addr;
  axi_pkg::len_t       ar_len;
  axi_pkg::size_t      ar_size;
  axi_pkg::burst_t     ar_burst;
  logic                ar_lock;
  axi_pkg::cache_t     ar_cache;
  axi_pkg::prot_t      ar_prot;
  axi_pkg::qos_t       ar_qos;
  axi_pkg::region_t    ar_region;
  logic                ar_valid;
  logic                ar_ready;
  assign ar_id     = axi.ar_id;
  assign ar_addr   = axi.ar_addr;
  assign ar_len    = axi.ar_len;
  assign ar_size   = axi.ar_size;
  assign ar_burst  = axi.ar_burst;
  assign ar_lock   = axi.ar_lock;
  assign ar_cache  = axi.ar_cache;
  assign ar_prot   = axi.ar_prot;
  assign ar_qos    = axi.ar_qos;
  assign ar_region = axi.ar_region;
  assign ar_valid  = axi.ar_valid;
  assign ar_ready  = axi.ar_ready;

  logic [ID_WIDTH-1:0] r_id;
  logic [63:0]         r_data;
  axi_pkg::resp_t      r_resp;
  logic                r_last;
  logic                r_valid;
  logic                r_ready;
  assign r_id    = axi.r_id;
  assign r_data  = axi.r_data;
  assign r_resp  = axi.r_resp;
  assign r_last  = axi.r_last;
  assign r_valid = axi.r_valid;
  assign r_ready = axi.r_ready;

  // ---- C2.1: handshake stability (spec §1 — full AXI4 handshake
  // baseline). valid held until ready; payload stable while valid && !ready.
  // Widths derived via $bits() on the concatenation itself (not hand
  // counted) to avoid drift if a field's width ever changes.
  localparam int unsigned AW_PAYLOAD_W = ID_WIDTH + 32 + $bits(aw_len)
      + $bits(aw_size) + $bits(aw_burst) + 1 + $bits(aw_cache)
      + $bits(aw_prot) + $bits(aw_qos) + $bits(aw_region) + $bits(aw_atop);
  localparam int unsigned W_PAYLOAD_W  = 64 + 8 + 1;
  localparam int unsigned B_PAYLOAD_W  = ID_WIDTH + $bits(b_resp);
  localparam int unsigned AR_PAYLOAD_W = ID_WIDTH + 32 + $bits(ar_len)
      + $bits(ar_size) + $bits(ar_burst) + 1 + $bits(ar_cache)
      + $bits(ar_prot) + $bits(ar_qos) + $bits(ar_region);
  localparam int unsigned R_PAYLOAD_W  = ID_WIDTH + 64 + $bits(r_resp) + 1;

  logic [AW_PAYLOAD_W-1:0] aw_payload;
  assign aw_payload = {aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock,
                        aw_cache, aw_prot, aw_qos, aw_region, aw_atop};
  logic [W_PAYLOAD_W-1:0] w_payload;
  assign w_payload = {w_data, w_strb, w_last};
  logic [B_PAYLOAD_W-1:0] b_payload;
  assign b_payload = {b_id, b_resp};
  logic [AR_PAYLOAD_W-1:0] ar_payload;
  assign ar_payload = {ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock,
                        ar_cache, ar_prot, ar_qos, ar_region};
  logic [R_PAYLOAD_W-1:0] r_payload;
  assign r_payload = {r_id, r_data, r_resp, r_last};

  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (aw_valid && !aw_ready) |=> aw_valid && $stable(aw_payload))
    else `uvm_error("SVA_AW_STABLE", "AW valid/payload not held stable until ready (spec §1)")
  ;
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (w_valid && !w_ready) |=> w_valid && $stable(w_payload))
    else `uvm_error("SVA_W_STABLE", "W valid/payload not held stable until ready (spec §1)")
  ;
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (b_valid && !b_ready) |=> b_valid && $stable(b_payload))
    else `uvm_error("SVA_B_STABLE", "B valid/payload not held stable until ready (spec §1)")
  ;
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (ar_valid && !ar_ready) |=> ar_valid && $stable(ar_payload))
    else `uvm_error("SVA_AR_STABLE", "AR valid/payload not held stable until ready (spec §1)")
  ;
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (r_valid && !r_ready) |=> r_valid && $stable(r_payload))
    else `uvm_error("SVA_R_STABLE", "R valid/payload not held stable until ready (spec §1)")
  ;

  // ---- C2.2: reset-idle (spec §2.3 clk_i/rst_ni + §1 AXI4 reset baseline;
  // N1 fix — no longer cites §3.1, which is address-map structure, not
  // reset semantics, per REV-002 §3.4 N1). While rst_ni is low, and on the
  // cycle it is released, every *valid must read 0.
  assert property (@(posedge clk_i) (!rst_ni) |->
    !(aw_valid || w_valid || b_valid || ar_valid || r_valid))
    else `uvm_error("SVA_RST_IDLE", "channel *valid asserted while rst_ni low (spec §2.3/§1)")
  ;
  assert property (@(posedge clk_i) ($rose(rst_ni)) |->
    !(aw_valid || w_valid || b_valid || ar_valid || r_valid))
    else `uvm_error("SVA_RST_RELEASE_IDLE", "channel *valid asserted on the rst_ni release edge (spec §2.3/§1)")
  ;

  // ---- C2.3: WLAST/RLAST vs burst length (spec §1 primary anchor — full
  // AXI4 handshake baseline; N2 fix — §4.3 demoted to a secondary
  // reference since it is decode-error-slave-specific, per REV-002 §3.4
  // N2). AW/AR len is FIFO-paired to the following (non-interleaved) W/R
  // burst on this same interface.
  // Queues are a dynamic type — VCS rejects them in a continuous `assign`/
  // always_comb context (and always_comb over a queue silently drops it
  // from the sensitivity list, which would make the checker miss updates).
  // So the whole beat-count bookkeeping + check is procedural, inside the
  // same always_ff that owns the queues, using an immediate assertion at
  // the exact cycle WLAST/RLAST fires (still counted by the native
  // "-assert verbose" Summary line — svacheck.py layer 2).
  axi_pkg::len_t aw_len_q[$];
  axi_pkg::len_t ar_len_q[$];

  logic [7:0] w_beat_idx_r, r_beat_idx_r; // registered index of the last beat seen
  logic       w_active, r_active;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      aw_len_q.delete();
      ar_len_q.delete();
      w_beat_idx_r <= '0; w_active <= 1'b0;
      r_beat_idx_r <= '0; r_active <= 1'b0;
    end else begin
      if (aw_valid && aw_ready) aw_len_q.push_back(aw_len);
      if (ar_valid && ar_ready) ar_len_q.push_back(ar_len);

      if (w_valid && w_ready) begin
        logic [7:0] this_idx;
        this_idx     = w_active ? (w_beat_idx_r + 8'd1) : 8'd0;
        w_beat_idx_r <= this_idx;
        w_active     <= !w_last;
        if (w_last) begin
          axi_pkg::len_t exp_len;
          exp_len = (aw_len_q.size() > 0) ? aw_len_q.pop_front() : 8'd0;
          assert (this_idx == exp_len) else
            `uvm_error("SVA_WLAST_LEN",
              $sformatf("WLAST beat index %0d != AxLEN %0d (spec §1; §4.3 decode-error beat-count as secondary reference)",
                         this_idx, exp_len))
          ;
        end
      end

      if (r_valid && r_ready) begin
        logic [7:0] this_idx;
        this_idx     = r_active ? (r_beat_idx_r + 8'd1) : 8'd0;
        r_beat_idx_r <= this_idx;
        r_active     <= !r_last;
        if (r_last) begin
          axi_pkg::len_t exp_len;
          exp_len = (ar_len_q.size() > 0) ? ar_len_q.pop_front() : 8'd0;
          assert (this_idx == exp_len) else
            `uvm_error("SVA_RLAST_LEN",
              $sformatf("RLAST beat index %0d != AxLEN %0d (spec §1; §4.3 decode-error beat-count as secondary reference)",
                         this_idx, exp_len))
          ;
        end
      end
    end
  end

  // C2.4 (no fixed-cycle assertions) / C2.5 (no arbitration-order
  // assertions) are structural non-additions — nothing to code here by
  // design (spec §7.4, §5.5.4).

endmodule
