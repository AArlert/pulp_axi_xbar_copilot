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

  // ---- config-point selection (design-prompt tb_top.md §5, spec §0 row 3) ---
  // A config point is chosen UNIQUELY by a compile-time `+define` (C5.1: the
  // TEST name maps to the macro in sim/Makefile — never env var / file /
  // random). No macro ⇒ baseline, whose every value below is bit-for-bit the
  // spec §0 row-2 pin (C5.4). Adding a config point = one `elsif branch here +
  // one Makefile mapping line (extensible per C5.5). Config points vary ONLY
  // the spec §0 row-3 dimensions; all other Cfg fields and the address-table
  // layout follow baseline (C5.5).
  // Each branch sets the FIVE spec §0 row-3 dimensions (topology NoSlv/NoMst,
  // LatencyMode, UniqueIds, ATOPs, Connectivity-sparse-or-not) plus a stable
  // CFG_POINT_ID (indexes the cg_cfg_point covergroup bin — one bin per
  // registered config point, functional_coverage.md §4). CFG_RULE_MST_MOD is
  // how the address-table idx is derived: idx = rule_index mod CFG_RULE_MST_MOD
  // (C5.5, = NoMstPorts for every point EXCEPT cfgD, where C5.7 pins the 8
  // rules to mst0/mst1 only ⇒ mod 2). Every field NOT listed as a row-3
  // dimension stays baseline (C5.5) — the Cfg struct / address layout below
  // reference these knobs, they are not re-pinned per point.
`ifdef XBAR_CFG_A
  // cfgA (M3-CF01): topology 1×8 + LatencyMode=NO_LATENCY (spec §0 row 3 /
  // §7.2). NoSlvPorts=1 ⇒ $clog2(1)=0 ⇒ 0-bit ID prefix (spec §5.1, C5.6).
  localparam int unsigned            NO_SLV_PORTS    = 1;
  localparam int unsigned            NO_MST_PORTS    = 8;
  localparam axi_pkg::xbar_latency_e CFG_LATENCY     = axi_pkg::NO_LATENCY;
  localparam bit                     CFG_UNIQUE_IDS  = 1'b0;
  localparam bit                     CFG_ATOPS       = 1'b1;
  localparam bit                     CFG_SPARSE_CONN = 1'b0;
  localparam int unsigned            CFG_RULE_MST_MOD= 8;
  localparam int unsigned            CFG_POINT_ID    = 1;
  localparam string                  CFG_NAME        = "cfgA (1x8, NO_LATENCY)";
`elsif XBAR_CFG_B
  // cfgB (M3-CF02): topology 6×1 + LatencyMode=CUT_ALL_PORTS (spec §0 row 3 /
  // §7.2). All 8 rules idx=0 (mod NoMstPorts=1) ⇒ maximal mux-side convergence
  // at the sole master port (spec §3.1: many rules may map to one master port).
  // NoSlvPorts=6 ⇒ PREFIX_W=3, non-degenerate (same as baseline).
  localparam int unsigned            NO_SLV_PORTS    = 6;
  localparam int unsigned            NO_MST_PORTS    = 1;
  localparam axi_pkg::xbar_latency_e CFG_LATENCY     = axi_pkg::CUT_ALL_PORTS;
  localparam bit                     CFG_UNIQUE_IDS  = 1'b0;
  localparam bit                     CFG_ATOPS       = 1'b1;
  localparam bit                     CFG_SPARSE_CONN = 1'b0;
  localparam int unsigned            CFG_RULE_MST_MOD= 1;
  localparam int unsigned            CFG_POINT_ID    = 2;
  localparam string                  CFG_NAME        = "cfgB (6x1, CUT_ALL_PORTS)";
`elsif XBAR_CFG_C
  // cfgC (M3-CF03): topology 4×4 + UniqueIds=1'b1 (spec §0 row 3 / §5.3). 8
  // rules idx = rule_index mod 4 (2 rules per master port). Env constructively
  // guarantees the §5.3.1 precondition (single-outstanding-per-port ⇒ every
  // in-flight ID unique per direction) — enforced by a fallback monitor (CF03).
  localparam int unsigned            NO_SLV_PORTS    = 4;
  localparam int unsigned            NO_MST_PORTS    = 4;
  localparam axi_pkg::xbar_latency_e CFG_LATENCY     = axi_pkg::CUT_ALL_AX;
  localparam bit                     CFG_UNIQUE_IDS  = 1'b1;
  localparam bit                     CFG_ATOPS       = 1'b1;
  localparam bit                     CFG_SPARSE_CONN = 1'b0;
  localparam int unsigned            CFG_RULE_MST_MOD= 4;
  localparam int unsigned            CFG_POINT_ID    = 3;
  localparam string                  CFG_NAME        = "cfgC (4x4, UniqueIds)";
`elsif XBAR_CFG_D
  // cfgD (M3-CF04): topology 4×4 + sparse Connectivity + ATOPs=1'b0 (spec §0
  // row 3 / §8 / §6). 8 rules point ONLY to mst0/mst1 (mod 2); mst2/mst3 are
  // reachable only via each slave port's default master port (slv 0/1 → mst2,
  // slv 2/3 → mst3). Connectivity per C5.7 keeps SPEC-8.3 constructively true.
  localparam int unsigned            NO_SLV_PORTS    = 4;
  localparam int unsigned            NO_MST_PORTS    = 4;
  localparam axi_pkg::xbar_latency_e CFG_LATENCY     = axi_pkg::CUT_ALL_AX;
  localparam bit                     CFG_UNIQUE_IDS  = 1'b0;
  localparam bit                     CFG_ATOPS       = 1'b0;
  localparam bit                     CFG_SPARSE_CONN = 1'b1;
  localparam int unsigned            CFG_RULE_MST_MOD= 2;
  localparam int unsigned            CFG_POINT_ID    = 4;
  localparam string                  CFG_NAME        = "cfgD (4x4, sparse Conn, ATOPs=0)";
`else
  // baseline (M1/M2): spec §0 row 2, values pinned (C5.4 anchor — unchanged).
  localparam int unsigned            NO_SLV_PORTS    = 6;
  localparam int unsigned            NO_MST_PORTS    = 8;
  localparam axi_pkg::xbar_latency_e CFG_LATENCY     = axi_pkg::CUT_ALL_AX;
  localparam bit                     CFG_UNIQUE_IDS  = 1'b0;
  localparam bit                     CFG_ATOPS       = 1'b1;
  localparam bit                     CFG_SPARSE_CONN = 1'b0;
  localparam int unsigned            CFG_RULE_MST_MOD= 8;
  localparam int unsigned            CFG_POINT_ID    = 0;
  localparam string                  CFG_NAME        = "baseline (6x8, CUT_ALL_AX)";
`endif

  // ---- port counts / widths (spec §0 row 2, §2.1, §5.1.1) --------------
  localparam int unsigned ID_W_SLV       = 5;
  localparam int unsigned ID_W_MST       = ID_W_SLV + $clog2(NO_SLV_PORTS); // spec §5.1.1
  // ID-prefix width = $clog2(NoSlvPorts) (spec §5.1); 0 for cfgA's NoSlvPorts=1
  // (tb_top.md C5.6) — consumers must not width-0 part-select it.
  localparam int unsigned PREFIX_W       = ID_W_MST - ID_W_SLV;
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
    LatencyMode:        CFG_LATENCY, // config-point dimension (spec §0 row 3/§7.2)
    PipelineStages:     1,
    AxiIdWidthSlvPorts: ID_W_SLV,
    AxiIdUsedSlvPorts:  3,
    UniqueIds:          CFG_UNIQUE_IDS, // config-point dimension (spec §0 row 3/§5.3)
    AxiAddrWidth:       ADDR_W,
    AxiDataWidth:       DATA_W,
    NoAddrRules:        NO_ADDR_RULES
  };
  // Transaction-number ceiling constants used by the M2 functional-coverage
  // bins (functional_coverage.md §2 cg_tx_limit). Values come from the pinned
  // baseline Cfg above; the *effective* per-(bucket,direction) ceiling is
  // spec §5.4.1's formula 2**ceil(log2(MaxMstTrans))-1 (baseline 15, not the
  // literal 10 — BUG-0016/REV-007), not a value observed in RTL/waveform.
  localparam int unsigned MAX_MST_TRANS     = Cfg.MaxMstTrans;                // 10
  localparam int unsigned MAX_MST_TRANS_EFF = (1 << $clog2(MAX_MST_TRANS)) - 1; // 15

  localparam bit ATOPS = CFG_ATOPS; // spec §0 row 2/row 3 (§2.2/§6) — config-point dim

  // Connectivity (spec §2.2/§8, C5.7): full-mesh for every point except cfgD's
  // sparse construction. cfgD: rule-reachable ports (0..CFG_RULE_MST_MOD-1, i.e.
  // mst0/mst1) are connected to ALL slave ports; the sparse ports (mst2/mst3)
  // are connected only to the slave-port rows that use them as default master
  // port (rows 0..NoSlv/2-1 → mst NoMst-2; rows NoSlv/2..NoSlv-1 → mst NoMst-1).
  // This keeps SPEC-8.3 constructively true (no address decodes to a
  // non-connected port), so SPEC-8.4's undefined case is unreachable.
  localparam int unsigned CFG_DEF_LO = (NO_MST_PORTS >= 2) ? (NO_MST_PORTS - 2) : 0;
  localparam int unsigned CFG_DEF_HI = (NO_MST_PORTS >= 1) ? (NO_MST_PORTS - 1) : 0;

  function automatic bit [NO_SLV_PORTS-1:0][NO_MST_PORTS-1:0] gen_connectivity();
    for (int unsigned s = 0; s < NO_SLV_PORTS; s++) begin
      if (!CFG_SPARSE_CONN) begin
        gen_connectivity[s] = '1;
      end else begin
        gen_connectivity[s] = '0;
        for (int unsigned m = 0; m < CFG_RULE_MST_MOD; m++)
          gen_connectivity[s][m] = 1'b1;                       // mst0/mst1: all rows
        gen_connectivity[s][(s < NO_SLV_PORTS/2) ? CFG_DEF_LO : CFG_DEF_HI] = 1'b1; // this row's default
      end
    end
  endfunction
  localparam bit [NO_SLV_PORTS-1:0][NO_MST_PORTS-1:0] CONNECTIVITY = gen_connectivity();

  // cfgD default-master-port config (spec §3.3, C5.7): slave rows 0..NoSlv/2-1
  // default to mst NoMst-2, rows NoSlv/2..NoSlv-1 to mst NoMst-1 (cfgD: mst2 /
  // mst3). Applied at runtime by m3_cf04's vseq in an all-idle window (spec
  // §3.4); computed for every config but only exercised under cfgD.
  localparam logic [NO_SLV_PORTS-1:0] EN_DEFAULT_CFGD = '1;

  function automatic logic [NO_SLV_PORTS-1:0][MST_PORT_IDX_W-1:0]
      gen_default_mst_cfgd();
    for (int unsigned i = 0; i < NO_SLV_PORTS; i++)
      gen_default_mst_cfgd[i] = (i < NO_SLV_PORTS/2)
          ? MST_PORT_IDX_W'(CFG_DEF_LO) : MST_PORT_IDX_W'(CFG_DEF_HI);
  endfunction
  localparam logic [NO_SLV_PORTS-1:0][MST_PORT_IDX_W-1:0] DEFAULT_MST_CFGD =
      gen_default_mst_cfgd();

  // ---- address map: one non-overlapping rule per region (spec §3.1) ------
  // Region size 0x1000_0000 (256 MiB) keeps every rule inside the 32-bit
  // address space with no wraparound. idx = rule_index mod CFG_RULE_MST_MOD
  // (C5.5): = rule_index for baseline/cfgA/cfgC (mod = NoMstPorts, identity for
  // index < NoMstPorts), all-0 for cfgB (mod 1), and {0,1} alternating for cfgD
  // (mod 2, C5.7 — rules point to mst0/mst1 only). Baseline stays bit-for-bit
  // identical (0..7 mod 8 = 0..7, C5.4).
  localparam addr_t REGION_SIZE = 32'h1000_0000;

  function automatic rule_t [NO_ADDR_RULES-1:0] gen_addr_map();
    for (int unsigned i = 0; i < NO_ADDR_RULES; i++) begin
      gen_addr_map[i] = rule_t'{
        idx:        i % CFG_RULE_MST_MOD,
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
