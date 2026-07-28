// tb/xbar_types_pkg.sv — M1 UVM env: baseline Cfg, channel typedefs, address
// map and the shared read-data prediction function.
//
// Split out of tb_pkg.sv (which holds the UVM classes) purely to break a
// compile-order cycle: tb/axi_if.sv needs these typedefs, and tb_pkg.sv's
// classes need virtual handles to the interfaces declared in axi_if.sv.
// Compile order (sim/flist/tb.f): xbar_types_pkg.sv -> axi_if.sv -> tb_pkg.sv.
//
// Every numeric value below is the baseline Cfg pin from doc/spec.md §0
// (row 2) / design-prompt tb_top.md C1.2 — DV's sole parameter-definition
// source is vendor/axi/src/axi_pkg.sv (CLAUDE.md §6); the *values* are the
// project-wide baseline pin, not read from RTL.
package xbar_types_pkg;

  `include "axi/typedef.svh"
  import axi_pkg::*;

  // ---- port counts / widths (spec §0 row 2, §2.1, §5.1.1) --------------
  localparam int unsigned NO_SLV_PORTS   = 6;
  localparam int unsigned NO_MST_PORTS   = 8;
  localparam int unsigned ID_W_SLV       = 5;
  localparam int unsigned ID_W_MST       = ID_W_SLV + $clog2(NO_SLV_PORTS); // = 8, spec §5.1.1
  localparam int unsigned ADDR_W         = 32;
  localparam int unsigned DATA_W         = 64;
  localparam int unsigned STRB_W         = DATA_W / 8;
  localparam int unsigned USER_W         = 1;
  localparam int unsigned NO_ADDR_RULES  = 8;
  localparam int unsigned MST_PORT_IDX_W = (NO_MST_PORTS == 1) ? 1 : $clog2(NO_MST_PORTS);

  // full-width beats only (no narrow-transfer exercised in M1-01)
  localparam axi_pkg::size_t BEAT_SIZE = axi_pkg::size_t'($clog2(STRB_W));

  typedef logic [ID_W_MST-1:0] id_mst_t;
  typedef logic [ID_W_SLV-1:0] id_slv_t;
  typedef logic [ADDR_W-1:0]   addr_t;
  typedef logic [DATA_W-1:0]   data_t;
  typedef logic [STRB_W-1:0]   strb_t;
  typedef logic [USER_W-1:0]   user_t;
  typedef axi_pkg::xbar_rule_32_t rule_t; // AxiAddrWidth=32 => xbar_rule_32_t (spec §0/§2.2)

  // ---- channel / req-resp struct types (mirrors vendor/axi test/tb_axi_xbar.sv
  // pattern: one shared w_chan_t for both port classes, per-side id width for
  // the rest — axi_xbar.sv requires exactly one `w_chan_t` type parameter) --
  `AXI_TYPEDEF_AW_CHAN_T(slv_aw_chan_t, addr_t, id_slv_t, user_t)
  `AXI_TYPEDEF_AW_CHAN_T(mst_aw_chan_t, addr_t, id_mst_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(slv_b_chan_t, id_slv_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(mst_b_chan_t, id_mst_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(slv_ar_chan_t, addr_t, id_slv_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(mst_ar_chan_t, addr_t, id_mst_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(slv_r_chan_t, data_t, id_slv_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(mst_r_chan_t, data_t, id_mst_t, user_t)
  `AXI_TYPEDEF_REQ_T(slv_req_t, slv_aw_chan_t, w_chan_t, slv_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(slv_resp_t, slv_b_chan_t, slv_r_chan_t)
  `AXI_TYPEDEF_REQ_T(mst_req_t, mst_aw_chan_t, w_chan_t, mst_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(mst_resp_t, mst_b_chan_t, mst_r_chan_t)

  // ---- Cfg (axi_pkg::xbar_cfg_t), all 13 fields pinned (spec §0 row 2) --
  localparam axi_pkg::xbar_cfg_t Cfg = '{
    NoSlvPorts:         NO_SLV_PORTS,
    NoMstPorts:         NO_MST_PORTS,
    MaxMstTrans:        10,
    MaxSlvTrans:        6,
    FallThrough:        1'b0,
    LatencyMode:        axi_pkg::CUT_ALL_AX,
    PipelineStages:     1,
    AxiIdWidthSlvPorts: ID_W_SLV,
    AxiIdUsedSlvPorts:  3,
    UniqueIds:          1'b0,
    AxiAddrWidth:       ADDR_W,
    AxiDataWidth:       DATA_W,
    NoAddrRules:        NO_ADDR_RULES
  };
  localparam bit ATOPS = 1'b1; // spec §0 row 2 / §2.2 — M1-01 issues no ATOP (uvm_env.md C2.4 note)
  localparam bit [Cfg.NoSlvPorts-1:0][Cfg.NoMstPorts-1:0] CONNECTIVITY = '1;

  // ---- address map: one non-overlapping rule per master port (spec §3.1) -
  // Region size 0x1000_0000 (256 MiB) keeps every rule inside the 32-bit
  // address space with no wraparound; idx == rule index == target mst port.
  localparam addr_t REGION_SIZE = 32'h1000_0000;

  function automatic rule_t [NO_ADDR_RULES-1:0] gen_addr_map();
    for (int unsigned i = 0; i < NO_ADDR_RULES; i++) begin
      gen_addr_map[i] = rule_t'{
        idx:        i,
        start_addr: addr_t'(i)   * REGION_SIZE,
        end_addr:   addr_t'(i+1) * REGION_SIZE,
        default:    '0
      };
    end
  endfunction
  localparam rule_t [NO_ADDR_RULES-1:0] ADDR_MAP = gen_addr_map();

  // ---- M2-CFG01 runtime-reconfiguration target table (spec §3.4) ---------
  // A single alternate table version the env switches to at runtime (only in
  // an all-ports-AW/AR-idle window). Two independent kinds of routing change
  // so batch 2 exercises both spec §3.1/§3.2 (rule move) and §3.3 (default
  // master port):
  //   (1) rule CFG01_MOVED_RULE's target idx is moved to CFG01_MOVED_IDX, so
  //       the SAME region-CFG01_MOVED_RULE address routes to a *different*
  //       master port before vs after the change (rule move, §3.1/§3.2);
  //   (2) every slave port's default master port is enabled (EN_DEFAULT_V1)
  //       with a per-port index (DEFAULT_MST_V1), so an address matching NO
  //       rule is routed to that default port instead of a decode error
  //       (default master port, §3.3). Baseline (V0) has default disabled, so
  //       the same unmapped address would be a decode error under V0 — batch 1
  //       never sends it (stays entirely on rule hits).
  localparam int unsigned CFG01_MOVED_RULE = 0;
  localparam int unsigned CFG01_MOVED_IDX  = 5;

  function automatic rule_t [NO_ADDR_RULES-1:0] gen_addr_map_v1();
    gen_addr_map_v1 = gen_addr_map();
    gen_addr_map_v1[CFG01_MOVED_RULE].idx = CFG01_MOVED_IDX;
  endfunction
  localparam rule_t [NO_ADDR_RULES-1:0] ADDR_MAP_V1 = gen_addr_map_v1();

  localparam logic [NO_SLV_PORTS-1:0] EN_DEFAULT_V1 = '1;

  function automatic logic [NO_SLV_PORTS-1:0][MST_PORT_IDX_W-1:0]
      gen_default_mst_v1();
    for (int unsigned i = 0; i < NO_SLV_PORTS; i++)
      gen_default_mst_v1[i] = i[MST_PORT_IDX_W-1:0];
  endfunction
  localparam logic [NO_SLV_PORTS-1:0][MST_PORT_IDX_W-1:0] DEFAULT_MST_V1 =
      gen_default_mst_v1();

  // Reference-model decode function shared with the scoreboard and the
  // protocol SVA (doc/design-prompt/scoreboard_refmodel.md C1.2/C1.3/C1.5,
  // sva_bind.md §3 "译码复用", spec §3.2/§3.1.3/§3.3/§3.4). The address table
  // and this slave port's default-master-port configuration are *inputs*
  // (not a compile-time localparam) so the one decode implementation serves
  // both the fixed-baseline scenarios and M2-CFG01's runtime-variable table
  // (single source of truth — no second decode logic, no second snapshot).
  // Returns 1 when the address routes to a real master port (a rule hit, or
  // the enabled default master port), 0 on decode error (no rule + no
  // default — spec §4, only reached in M3 error-path scenarios).
  // Rules are constructed non-overlapping (see REGION_SIZE above), so
  // "highest-position rule wins on overlap" (§3.1.3) is never exercised —
  // first (only) match found wins, scanned low-index-first.
  function automatic bit decode_mst_port(input addr_t addr,
                                          input rule_t [NO_ADDR_RULES-1:0] amap,
                                          input bit en_def,
                                          input logic [MST_PORT_IDX_W-1:0] def_port,
                                          output int unsigned mst_port);
    for (int unsigned r = 0; r < NO_ADDR_RULES; r++) begin
      if (addr >= amap[r].start_addr && addr < amap[r].end_addr) begin
        mst_port = amap[r].idx;
        return 1'b1;
      end
    end
    if (en_def) begin
      mst_port = int'(def_port); // §3.3 default master port
      return 1'b1;
    end
    mst_port = '0;
    return 1'b0; // decode error — never reached before batch2 uses default (§4, M3)
  endfunction

  // Deterministic predictable read-data generator shared by the mst-port
  // responder (drives it) and the scoreboard (predicts it) — single source
  // avoids drift between "what was sent" and "what is expected"
  // (design-prompt uvm_env.md C3.1, scoreboard_refmodel.md C4.2).
  // Per-beat address computed via axi_pkg::beat_addr (AXI4 baseline math,
  // spec §1), not a DUT-specific formula.
  function automatic data_t predict_beat_data(input addr_t axaddr,
                                               input axi_pkg::size_t axsize,
                                               input axi_pkg::len_t axlen,
                                               input axi_pkg::burst_t axburst,
                                               input int unsigned i_beat);
    addr_t beat_a;
    shortint unsigned i_beat_su;
    i_beat_su = i_beat[15:0];
    beat_a = addr_t'(axi_pkg::beat_addr(axaddr, axsize, axlen, axburst,
                                         i_beat_su));
    return {beat_a, beat_a};
  endfunction

endpackage
