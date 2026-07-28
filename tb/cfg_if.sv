// tb/cfg_if.sv — M2-CFG01 runtime-reconfiguration config interface
// (design-prompt tb_top.md C4.2 / sva_bind.md §3 preamble, spec §2.3/§3.4).
//
// Carries the crossbar's global address-routing configuration inputs —
// `addr_map` (shared across all slave ports), and the per-slave-port
// `en_default_mst_port` / `default_mst_port` — as runtime-drivable TB signals
// so the env can perform the one M2-CFG01 reconfiguration while the DUT is
// running (spec §3.4: these inputs are runtime-variable). tb_top wires these
// members straight to the DUT's `addr_map_i` / `en_default_mst_port_i` /
// `default_mst_port_i` ports and, for stability checking, into the new
// per-slave-port axi_xbar_route_sva instances (sva_bind.md §3 C3.1). It is
// NOT an AXI channel interface — it only holds these broadcast config inputs
// plus one TB-internal synchronisation aid (`all_ax_idle`).
//
// `all_ax_idle` is a TB-only monitor signal (driven by tb_top from the DUT
// slave-port request array): high on a cycle where NO slave port has AW or AR
// valid — the "all-ports-silent" window the env waits for before applying the
// reconfiguration (uvm_env.md C5.1, so the change never overlaps any port's
// AW/AR valid, spec §3.4). It is not a DUT port.
interface xbar_cfg_if
  import xbar_types_pkg::*;
(
  input logic clk_i,
  input logic rst_ni
);
  rule_t [NO_ADDR_RULES-1:0]                    addr_map;
  logic  [NO_SLV_PORTS-1:0]                      en_default_mst_port;
  logic  [NO_SLV_PORTS-1:0][MST_PORT_IDX_W-1:0]  default_mst_port;

  logic                                          all_ax_idle;
endinterface
