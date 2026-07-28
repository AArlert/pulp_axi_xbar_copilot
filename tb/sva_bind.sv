// tb/sva_bind.sv — M1 SVA attachment (design-prompt sva_bind.md C1.1/C1.2,
// tb_top.md C4.1: "tb_top only provides the attachment and signal
// visibility, it does not inline assertions"). `include-d from tb_top.sv,
// after slvport_if/mstport_if instances exist.
//
// One axi_chan_sva instance per port interface instance (spec §2.3
// clk_i/rst_ni observed at every slave/master port, per sva_bind.md C1.2).
// ID_WIDTH is passed explicitly per port class since the two port classes
// carry different AXI ID widths (spec §5.1.1).
//
// Attachment mechanism: direct instantiation, not `bind`. VCS-2018.09-SP2
// rejects `bind <slvport_if|mstport_if> axi_chan_sva (...)` outright
// ("Error-[IIM] ... Interface has a module instantiation which is not
// allowed" — see the note atop tb/sva/axi_chan_sva.sv). Since tb_top.sv is
// DV-owned (unlike the DUT), `bind`'s non-invasive-attachment benefit does
// not apply here; direct instantiation from tb_top's own generate loop
// keeps the checker module standalone/reusable and out of tb_top's main
// body, which is the substance of C1.1.
for (genvar i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin : gen_slv_sva
  axi_chan_sva #(
    .ID_WIDTH(xbar_types_pkg::ID_W_SLV)
  ) u_axi_chan_sva (.axi(slv_if[i]));
end

for (genvar j = 0; j < xbar_types_pkg::NO_MST_PORTS; j++) begin : gen_mst_sva
  axi_chan_sva #(
    .ID_WIDTH(xbar_types_pkg::ID_W_MST)
  ) u_axi_chan_sva (.axi(mst_if[j]));
end

// M2 same-ID cross-port ordering/stall SVA (sva_bind.md §3 C3.2, spec
// §5.2.1/§5.2.2/§5.2.4) — slave ports only (C3.2 "适用端口：仅 slave 端口").
for (genvar k = 0; k < xbar_types_pkg::NO_SLV_PORTS; k++) begin : gen_slv_stall_sva
  axi_xbar_stall_sva u_axi_xbar_stall_sva (.axi(slv_if[k]));
end

// M2 address-table / default-port runtime stability SVA (sva_bind.md §3 C3.1,
// spec §3.4, tb_top.md C4.2) — slave ports only. Beyond the per-port AW/AR
// valids carried by slv_if, each instance reads the shared cfg_if.addr_map and
// this port's own cfg_if.en_default_mst_port[i]/default_mst_port[i].
for (genvar r = 0; r < xbar_types_pkg::NO_SLV_PORTS; r++) begin : gen_slv_route_sva
  axi_xbar_route_sva u_axi_xbar_route_sva (
    .axi        (slv_if[r]),
    .addr_map   (cfg_if.addr_map),
    .en_default (cfg_if.en_default_mst_port[r]),
    .default_mst(cfg_if.default_mst_port[r])
  );
end

// M2 ATOP paired-response / ID-uniqueness SVA (sva_bind.md §3 C3.5, spec
// §6.3/§6.4) — slave ports only (C3.5 "适用端口：仅 slave 端口").
for (genvar m = 0; m < xbar_types_pkg::NO_SLV_PORTS; m++) begin : gen_slv_atop_sva
  axi_xbar_atop_sva u_axi_xbar_atop_sva (.axi(slv_if[m]));
end

// M2 W-channel-order non-vacuity cover (sva_bind.md §3 C3.3, spec
// §5.5.1/§5.5.2) — master ports only (C3.3 "适用端口：master 端口").
for (genvar n = 0; n < xbar_types_pkg::NO_MST_PORTS; n++) begin : gen_mst_worder_sva
  axi_xbar_worder_sva u_axi_xbar_worder_sva (.axi(mst_if[n]));
end

// M2 transaction-number-ceiling SVA (sva_bind.md §3 C3.4, spec §5.4.1/§5.4.2/
// §7.4.5) — master ports (the count is taken master-side; see the module
// header for why that is the only delay-insensitive image of both ceilings).
// Always-on DUT invariants (MaxMstTrans/MaxSlvTrans never exceeded); the
// non-vacuity covers fire under M2-TL01/TL02 stimulus.
for (genvar t = 0; t < xbar_types_pkg::NO_MST_PORTS; t++) begin : gen_mst_txlimit_sva
  axi_xbar_txlimit_sva u_axi_xbar_txlimit_sva (.axi(mst_if[t]));
end
