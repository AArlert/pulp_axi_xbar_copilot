// tb/sva/axi_xbar_route_sva.sv — M2 address-table / default-port runtime
// stability SVA (design-prompt sva_bind.md §3 C3.1, spec §3.4). One instance
// per crossbar *slave* port interface (6 instances — C3.1 "适用端口：仅 slave
// 端口"), direct-instantiated from tb/sva_bind.sv (VCS-2018.09-SP2 rejects
// `bind <interface>`, REV-003 — same attachment mechanism as
// axi_xbar_stall_sva.sv / axi_xbar_atop_sva.sv). Generic `interface axi`
// port for this slave port's AW/AR valids plus explicit config ports for the
// three signals whose stability spec §3.4 governs: the shared `addr_map`, and
// this port's own `en_default` / `default_mst`.
//
// Reads only the slvport_if AW/AR valids and the config signals wired in from
// tb_top's cfg_if — no DUT-internal signal (CLAUDE.md input-boundary rule).
//
// C3.1 property (spec §3.4): "任一 slave 端口的 AW 或 AR 通道 valid 期间不得
// 更改" address table / default master port. Encoded per §3.4's "during valid"
// wording: whenever this port holds AW or AR valid across two adjacent cycles,
// addr_map / en_default / default_mst must be $stable between them. Asserting
// this independently for each of the 6 slave ports covers the global §3.4
// constraint (its per-port disjunction is the original constraint). A change
// concurrent with the rising or falling edge of a valid — where the config is
// still constant for the whole span the valid is actually held — is benign and
// intentionally not flagged (it is not a change *during* a held valid).
import uvm_pkg::*;
`include "uvm_macros.svh"

module axi_xbar_route_sva
  import xbar_types_pkg::*;
(
  interface axi,
  input rule_t [NO_ADDR_RULES-1:0]    addr_map,
  input logic                         en_default,
  input logic [MST_PORT_IDX_W-1:0]    default_mst
);

  logic clk_i, rst_ni;
  assign clk_i  = axi.clk_i;
  assign rst_ni = axi.rst_ni;

  logic aw_valid, ar_valid;
  assign aw_valid = axi.aw_valid;
  assign ar_valid = axi.ar_valid;

  wire ax_active = aw_valid || ar_valid;

  // ---- main judgement (spec §3.4): config stable while this port's AW/AR
  // is held valid across adjacent cycles.
  a_cfg_stable_during_ax: assert property (@(posedge clk_i) disable iff (!rst_ni)
    (ax_active && $past(ax_active)) |->
      ($stable(addr_map) && $stable(en_default) && $stable(default_mst)))
    else `uvm_error("SVA_CFG_UNSTABLE",
      "addr_map/en_default_mst_port/default_mst_port changed while this slave port's AW/AR was valid (spec §3.4)")
  ;

  // ---- cover (sva_bind.md C3.1, 激励来源 M2-CFG01): the config actually
  // changed at least once in the run — proof the assert above is not a
  // "never changes, never violates" vacuous pass. M1 / other-M2 scenarios keep
  // a constant table, so only M2-CFG01's runtime reconfiguration excites it.
  c_cfg_changed: cover property (@(posedge clk_i) disable iff (!rst_ni)
    (!$stable(addr_map) || !$stable(en_default) || !$stable(default_mst)));

endmodule
