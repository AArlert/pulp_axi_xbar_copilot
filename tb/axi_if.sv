// tb/axi_if.sv — M1 UVM env: TB-side AXI4 signal interfaces.
//
// Two concrete (non-generic) interfaces, one per crossbar port class, so that
// `bind` targets for tb/sva_bind.sv can pick the right ID width without a
// runtime parameter plumbing exercise:
//   - slvport_if: attaches to a crossbar *slave* port (TB plays the external
//     AXI master). ID width = Cfg.AxiIdWidthSlvPorts (doc/spec.md §2.1/§0).
//   - mstport_if: attaches to a crossbar *master* port (TB plays the
//     external AXI slave). ID width = AxiIdWidthSlvPorts + $clog2(NoSlvPorts)
//     (doc/spec.md §5.1.1).
//
// Field names deliberately mirror vendor/axi/src/axi_intf.sv (AXI_BUS) so
// that `axi/assign.svh` macros (AXI_ASSIGN_TO_REQ / AXI_ASSIGN_FROM_RESP /
// AXI_ASSIGN_FROM_REQ / AXI_ASSIGN_TO_RESP) work unmodified against them.
// Only tb_top.sv instantiates these; they carry no protocol assertions of
// their own — those live in tb/sva/axi_chan_sva.sv, bound in via
// tb/sva_bind.sv (design-prompt tb_top.md C4.1 / sva_bind.md C1.1).

interface slvport_if
  import xbar_types_pkg::*;
(
  input logic clk_i,
  input logic rst_ni
);
  id_slv_t          aw_id;
  addr_t             aw_addr;
  axi_pkg::len_t     aw_len;
  axi_pkg::size_t    aw_size;
  axi_pkg::burst_t   aw_burst;
  logic              aw_lock;
  axi_pkg::cache_t   aw_cache;
  axi_pkg::prot_t    aw_prot;
  axi_pkg::qos_t     aw_qos;
  axi_pkg::region_t  aw_region;
  axi_pkg::atop_t    aw_atop;
  user_t             aw_user;
  logic              aw_valid;
  logic              aw_ready;

  data_t             w_data;
  strb_t             w_strb;
  logic              w_last;
  user_t             w_user;
  logic              w_valid;
  logic              w_ready;

  id_slv_t           b_id;
  axi_pkg::resp_t    b_resp;
  user_t             b_user;
  logic              b_valid;
  logic              b_ready;

  id_slv_t           ar_id;
  addr_t             ar_addr;
  axi_pkg::len_t     ar_len;
  axi_pkg::size_t    ar_size;
  axi_pkg::burst_t   ar_burst;
  logic              ar_lock;
  axi_pkg::cache_t   ar_cache;
  axi_pkg::prot_t    ar_prot;
  axi_pkg::qos_t     ar_qos;
  axi_pkg::region_t  ar_region;
  user_t             ar_user;
  logic              ar_valid;
  logic              ar_ready;

  id_slv_t           r_id;
  data_t             r_data;
  axi_pkg::resp_t    r_resp;
  logic              r_last;
  user_t             r_user;
  logic              r_valid;
  logic              r_ready;

  modport Master (
    output aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache,
           aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid,
    input  aw_ready,
    output w_data, w_strb, w_last, w_user, w_valid,
    input  w_ready,
    input  b_id, b_resp, b_user, b_valid,
    output b_ready,
    output ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache,
           ar_prot, ar_qos, ar_region, ar_user, ar_valid,
    input  ar_ready,
    input  r_id, r_data, r_resp, r_last, r_user, r_valid,
    output r_ready
  );

  modport Monitor (
    input aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache,
          aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, aw_ready,
          w_data, w_strb, w_last, w_user, w_valid, w_ready,
          b_id, b_resp, b_user, b_valid, b_ready,
          ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache,
          ar_prot, ar_qos, ar_region, ar_user, ar_valid, ar_ready,
          r_id, r_data, r_resp, r_last, r_user, r_valid, r_ready
  );
endinterface

interface mstport_if
  import xbar_types_pkg::*;
(
  input logic clk_i,
  input logic rst_ni
);
  id_mst_t           aw_id;
  addr_t             aw_addr;
  axi_pkg::len_t     aw_len;
  axi_pkg::size_t    aw_size;
  axi_pkg::burst_t   aw_burst;
  logic              aw_lock;
  axi_pkg::cache_t   aw_cache;
  axi_pkg::prot_t    aw_prot;
  axi_pkg::qos_t     aw_qos;
  axi_pkg::region_t  aw_region;
  axi_pkg::atop_t    aw_atop;
  user_t             aw_user;
  logic              aw_valid;
  logic              aw_ready;

  data_t             w_data;
  strb_t             w_strb;
  logic              w_last;
  user_t             w_user;
  logic              w_valid;
  logic              w_ready;

  id_mst_t           b_id;
  axi_pkg::resp_t    b_resp;
  user_t             b_user;
  logic              b_valid;
  logic              b_ready;

  id_mst_t           ar_id;
  addr_t             ar_addr;
  axi_pkg::len_t     ar_len;
  axi_pkg::size_t    ar_size;
  axi_pkg::burst_t   ar_burst;
  logic              ar_lock;
  axi_pkg::cache_t   ar_cache;
  axi_pkg::prot_t    ar_prot;
  axi_pkg::qos_t     ar_qos;
  axi_pkg::region_t  ar_region;
  user_t             ar_user;
  logic              ar_valid;
  logic              ar_ready;

  id_mst_t           r_id;
  data_t             r_data;
  axi_pkg::resp_t    r_resp;
  logic              r_last;
  user_t             r_user;
  logic              r_valid;
  logic              r_ready;

  modport Slave (
    input  aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache,
           aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid,
    output aw_ready,
    input  w_data, w_strb, w_last, w_user, w_valid,
    output w_ready,
    output b_id, b_resp, b_user, b_valid,
    input  b_ready,
    input  ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache,
           ar_prot, ar_qos, ar_region, ar_user, ar_valid,
    output ar_ready,
    output r_id, r_data, r_resp, r_last, r_user, r_valid,
    input  r_ready
  );

  modport Monitor (
    input aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache,
          aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, aw_ready,
          w_data, w_strb, w_last, w_user, w_valid, w_ready,
          b_id, b_resp, b_user, b_valid, b_ready,
          ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache,
          ar_prot, ar_qos, ar_region, ar_user, ar_valid, ar_ready,
          r_id, r_data, r_resp, r_last, r_user, r_valid, r_ready
  );
endinterface
