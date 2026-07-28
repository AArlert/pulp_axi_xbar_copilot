// tb/sva/axi_xbar_atop_sva.sv — M2 ATOP paired-response / ID-uniqueness SVA
// (design-prompt sva_bind.md §3 C3.5, spec §6.3/§6.4). One instance per
// crossbar *slave* port interface (6 instances — C3.5 "适用端口：仅 slave
// 端口"), direct-instantiated from tb/sva_bind.sv (VCS-2018.09-SP2 rejects
// `bind <interface>`, REV-003 — same attachment mechanism as
// axi_xbar_stall_sva.sv). Generic `interface axi` port + manual field
// copies, same known-working pattern.
//
// C3.5 property 1 (spec §6.3, delay-insensitive red line): an AW handshake
// whose aw.atop requests a read response (aw.atop[ATOP_R_RESP],
// vendor/axi/src/axi_pkg.sv — the DV parameter-definition source) opens a
// "pending B" and a "pending R" record for its ID; each clears on the
// matching B / R(last) handshake. Nothing here asserts the B-vs-R arrival
// order or any inter-arrival cycle count (spec §7.4) — the only judgement
// is "both eventually appear". Its end-of-test form (an open record when
// the test ends) is judged by the scoreboard's SB_ATOP_DANGLING inside the
// UVM report gate (scoreboard_refmodel.md C6.3 — the UVM-counted anchor);
// the `final` check below is a redundant, log-visible trace of the same
// condition from this module's own independent observation path.
//
// C3.5 property 2 (spec §6.4): at an ATOP AW handshake (aw.atop != '0), the
// ID must differ from every currently in-flight (read or write direction)
// transaction ID on this port. This is an *environment* discipline
// (uvm_env.md C2.4/C5.5); a violation points at the env breaking its own
// constraint (TB_BUG) first, never straight at the DUT.
//
// Range boundary (spec §6.5/§5.2.5, BUG-0012): only external AW/AR/B/R
// handshakes are modelled; the atomic-load "shadow AR" counter injection is
// invisible here by design, so the cross-direction read stall it may cause
// cannot trigger anything in this module.
import uvm_pkg::*;
`include "uvm_macros.svh"

module axi_xbar_atop_sva
  import xbar_types_pkg::*;
(
  interface axi
);

  logic clk_i, rst_ni;
  assign clk_i  = axi.clk_i;
  assign rst_ni = axi.rst_ni;

  id_slv_t        aw_id, ar_id, b_id, r_id;
  axi_pkg::atop_t aw_atop;
  logic           aw_valid, aw_ready, ar_valid, ar_ready;
  logic           b_valid, b_ready, r_valid, r_ready, r_last;
  assign aw_id    = axi.aw_id;
  assign aw_atop  = axi.aw_atop;
  assign aw_valid = axi.aw_valid;
  assign aw_ready = axi.aw_ready;
  assign ar_id    = axi.ar_id;
  assign ar_valid = axi.ar_valid;
  assign ar_ready = axi.ar_ready;
  assign b_id     = axi.b_id;
  assign b_valid  = axi.b_valid;
  assign b_ready  = axi.b_ready;
  assign r_id     = axi.r_id;
  assign r_last   = axi.r_last;
  assign r_valid  = axi.r_valid;
  assign r_ready  = axi.r_ready;

  localparam int unsigned NUM_IDS = 2**ID_W_SLV;

  // ---- per-full-ID in-flight tracking, both directions (spec §6.4 "所有
  // （读+写）在飞事务"). Counters (not single bits) so that two legally
  // overlapping same-ID/same-target transactions (spec §5.2.4) stay counted.
  // An atomic load contributes to w_cnt like any write (its B closes it);
  // its extra R leg is tracked by the dedicated pair flags below, never in
  // r_cnt (no AR is ever issued for it — spec §6.3/§6.5 background).
  int unsigned w_cnt[NUM_IDS];
  int unsigned r_cnt[NUM_IDS];
  bit          atop_b_pend[NUM_IDS];
  bit          atop_r_pend[NUM_IDS];

  // Same-edge accept+complete on one ID would clobber via two NBAs to the
  // same element, so each side resolves its net update explicitly.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned i = 0; i < NUM_IDS; i++) begin
        w_cnt[i]       <= '0;
        r_cnt[i]       <= '0;
        atop_b_pend[i] <= 1'b0;
        atop_r_pend[i] <= 1'b0;
      end
    end else begin
      // write side: AW accept (+1) / B complete (-1)
      if (aw_valid && aw_ready && b_valid && b_ready && (aw_id == b_id)) begin
        // net 0 on w_cnt[aw_id]
      end else begin
        if (aw_valid && aw_ready)
          w_cnt[aw_id] <= w_cnt[aw_id] + 1;
        if (b_valid && b_ready && (w_cnt[b_id] > 0))
          w_cnt[b_id] <= w_cnt[b_id] - 1;
      end
      // read side: AR accept (+1) / non-ATOP R(last) complete (-1); an
      // atomic load's R(last) clears its pair flag instead (below).
      if (ar_valid && ar_ready && r_valid && r_ready && r_last
          && (ar_id == r_id) && !atop_r_pend[r_id]) begin
        // net 0 on r_cnt[ar_id]
      end else begin
        if (ar_valid && ar_ready)
          r_cnt[ar_id] <= r_cnt[ar_id] + 1;
        if (r_valid && r_ready && r_last && !atop_r_pend[r_id]
            && (r_cnt[r_id] > 0))
          r_cnt[r_id] <= r_cnt[r_id] - 1;
      end
      // C3.5 property-1 pair records (spec §6.3)
      if (aw_valid && aw_ready && aw_atop[axi_pkg::ATOP_R_RESP]) begin
        atop_b_pend[aw_id] <= 1'b1;
        atop_r_pend[aw_id] <= 1'b1;
      end
      if (b_valid && b_ready && atop_b_pend[b_id]
          && !(aw_valid && aw_ready && aw_atop[axi_pkg::ATOP_R_RESP]
               && (aw_id == b_id)))
        atop_b_pend[b_id] <= 1'b0;
      if (r_valid && r_ready && r_last && atop_r_pend[r_id]
          && !(aw_valid && aw_ready && aw_atop[axi_pkg::ATOP_R_RESP]
               && (aw_id == r_id)))
        atop_r_pend[r_id] <= 1'b0;
    end
  end

  // True if `id` has any in-flight transaction, either direction, including
  // a still-open atomic-load response pair.
  function automatic bit id_busy(input logic [ID_W_SLV-1:0] id);
    return (w_cnt[id] != 0) || (r_cnt[id] != 0)
           || atop_b_pend[id] || atop_r_pend[id];
  endfunction

  function automatic bit any_inflight();
    any_inflight = 1'b0;
    for (int unsigned i = 0; i < NUM_IDS; i++)
      if (id_busy(id_slv_t'(i))) any_inflight = 1'b1;
  endfunction

  // Busy predicates are folded into combinational *signals* referenced
  // directly by the properties below, so they get preponed (pre-clock-edge)
  // sampling. Calling the functions inside the property expression instead
  // would evaluate them in the observed region — *after* this same edge's
  // NBA updates — making an ATOP AW handshake see its own registration in
  // w_cnt/atop_*_pend and self-trigger (exactly what the first bring-up run
  // of this module did on an otherwise idle port).
  logic aw_id_busy_now;
  logic any_inflight_now;
  always_comb aw_id_busy_now   = id_busy(aw_id);
  always_comb any_inflight_now = any_inflight();

  // ---- C3.5 property 2 (spec §6.4): ATOP AW handshake with an ID that is
  // already in flight (either direction) on this port, as the in-flight set
  // stood *before* this handshake registers.
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (aw_valid && aw_ready && (aw_atop != '0)) |-> !aw_id_busy_now)
    else `uvm_error("SVA_ATOP_ID_UNIQ",
      $sformatf("ATOP AW id 'h%0h accepted while the same id is in flight (read or write) on this slave port — env violated its own spec §6.4 discipline (TB_BUG suspect first, sva_bind.md C3.5)",
                 $sampled(aw_id)))
  ;

  // ---- cover: property-1 premise — an atomic read initiated at least once
  // (激励来源 M2-AT01, sva_bind.md C3.5).
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_ready && aw_atop[axi_pkg::ATOP_R_RESP]);

  // ---- cover: property-2 premise non-vacuous — an ATOP accepted while the
  // port genuinely had other transactions in flight (the §6.4 uniqueness
  // guarantee exercised against a non-empty in-flight set, pre-sampled like
  // the assert above so the ATOP's own registration cannot fake it).
  cover property (@(posedge clk_i) disable iff (!rst_ni)
    aw_valid && aw_ready && (aw_atop != '0) && any_inflight_now);

  // Redundant, log-visible end-of-test trace of property 1 (the UVM-counted
  // judgement is the scoreboard's SB_ATOP_DANGLING — see header).
  final begin
    for (int unsigned i = 0; i < NUM_IDS; i++) begin
      if (atop_b_pend[i] || atop_r_pend[i])
        `uvm_error("SVA_ATOP_DANGLING",
          $sformatf("atomic load id 'h%0h still awaiting %s%s at end of test — spec §6.3 pair incomplete",
                     i, atop_b_pend[i] ? "B" : "",
                     atop_r_pend[i] ? "R" : ""))
    end
  end

endmodule
