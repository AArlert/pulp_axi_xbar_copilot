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
