// tb/test_lib.sv — M1 UVM env: uvm_test classes. `include-d from tb_pkg.sv.

class base_test extends uvm_test;
  `uvm_component_utils(base_test)

  xbar_env env;

  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = xbar_env::type_id::create("env", this);
  endfunction
endclass

// M1-01 happy-path routing smoke (testplan.md M1-01).
class m1_01_smoke_test extends base_test;
  `uvm_component_utils(m1_01_smoke_test)

  function new(string name = "m1_01_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m1_01_smoke_vseq vseq;
    phase.raise_objection(this, "m1_01_smoke_vseq running");
    vseq = m1_01_smoke_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m1_01_smoke_vseq done");
  endtask
endclass

// M1-02 ID-prefix response-routing smoke (testplan.md M1-02).
class m1_02_id_prefix_test extends base_test;
  `uvm_component_utils(m1_02_id_prefix_test)

  function new(string name = "m1_02_id_prefix_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m1_02_id_prefix_vseq vseq;
    phase.raise_objection(this, "m1_02_id_prefix_vseq running");
    vseq = m1_02_id_prefix_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m1_02_id_prefix_vseq done");
  endtask
endclass

// M2-OR01 same-ID cross-port stall trigger (testplan.md M2-OR01).
class m2_or01_stall_test extends base_test;
  `uvm_component_utils(m2_or01_stall_test)

  function new(string name = "m2_or01_stall_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2_or01_stall_vseq vseq;
    phase.raise_objection(this, "m2_or01_stall_vseq running");
    vseq = m2_or01_stall_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m2_or01_stall_vseq done");
  endtask
endclass

// M2-AT01 ATOP atomic read: B+R pair + ID uniqueness (testplan.md M2-AT01).
class m2_at01_atop_test extends base_test;
  `uvm_component_utils(m2_at01_atop_test)

  function new(string name = "m2_at01_atop_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2_at01_atop_vseq vseq;
    phase.raise_objection(this, "m2_at01_atop_vseq running");
    vseq = m2_at01_atop_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m2_at01_atop_vseq done");
  endtask
endclass

// M2-OR02 same-ID non-stall counter-examples (testplan.md M2-OR02).
class m2_or02_nonstall_test extends base_test;
  `uvm_component_utils(m2_or02_nonstall_test)

  function new(string name = "m2_or02_nonstall_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2_or02_nonstall_vseq vseq;
    phase.raise_objection(this, "m2_or02_nonstall_vseq running");
    vseq = m2_or02_nonstall_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m2_or02_nonstall_vseq done");
  endtask
endclass

// M2-CFG01 address-table / default-port runtime reconfiguration (testplan.md
// M2-CFG01). Fetches the runtime config-bus handle and hands it to the vseq,
// which drives the one reconfiguration in the idle window between two batches.
class m2_cfg01_reconfig_test extends base_test;
  `uvm_component_utils(m2_cfg01_reconfig_test)

  virtual xbar_cfg_if cfg_vif;

  function new(string name = "m2_cfg01_reconfig_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual xbar_cfg_if)::get(this, "", "cfg_vif", cfg_vif))
      `uvm_fatal("NOCFGVIF", "m2_cfg01_reconfig_test: cfg_vif not set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2_cfg01_reconfig_vseq vseq;
    phase.raise_objection(this, "m2_cfg01_reconfig_vseq running");
    vseq = m2_cfg01_reconfig_vseq::type_id::create("vseq");
    vseq.cfg_vif = cfg_vif;
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m2_cfg01_reconfig_vseq done");
  endtask
endclass

// M2-TL01 MaxMstTrans transaction-number ceiling (testplan.md M2-TL01). Holds
// the responders' B/R a bounded number of cycles (resp_hold) so the per-
// (bucket,direction) in-flight count is genuinely pushed to MaxMstTrans before
// any response drains it — otherwise the ceiling would never be reached
// ("空转", uvm_env.md C5.3). The judgement is delay-insensitive and lives in
// axi_xbar_txlimit_sva (spec §5.4.1/§7.4.5).
class m2_tl01_txlimit_test extends base_test;
  `uvm_component_utils(m2_tl01_txlimit_test)

  function new(string name = "m2_tl01_txlimit_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    // Set before the responders' build_phase (child components build after
    // this test's build_phase). resp_hold cycles > the time to inject
    // MaxMstTrans requests, so the count is at the ceiling before the first
    // response returns.
    uvm_config_db#(int)::set(this, "env.mst_agent*", "resp_hold", 30);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2_tl01_txlimit_vseq vseq;
    phase.raise_objection(this, "m2_tl01_txlimit_vseq running");
    vseq = m2_tl01_txlimit_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m2_tl01_txlimit_vseq done");
  endtask
endclass

// M2-TL02 MaxSlvTrans observable-upper-bound monitor (testplan.md M2-TL02).
// Same bounded-hold rationale as M2-TL01; the only judgement is the weakened
// observable upper bound (≤ MaxSlvTrans per master port × full id × direction,
// axi_xbar_txlimit_sva) — no mechanism-level reject assertion (spec §5.4.3
// upstream-confirmation item, BUG-0011 / REV-005).
class m2_tl02_slvtrans_test extends base_test;
  `uvm_component_utils(m2_tl02_slvtrans_test)

  function new(string name = "m2_tl02_slvtrans_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    uvm_config_db#(int)::set(this, "env.mst_agent*", "resp_hold", 30);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2_tl02_slvtrans_vseq vseq;
    phase.raise_objection(this, "m2_tl02_slvtrans_vseq running");
    vseq = m2_tl02_slvtrans_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m2_tl02_slvtrans_vseq done");
  endtask
endclass

// M2-OR03 BUG-0023/BUG-0024 joint regression guard (testplan.md M2-OR03).
// Responders keep their default zero hold: the testplan's construction wants
// the stall release and the last same-target completion to coincide (or not)
// under natural run conditions, with no extra response backpressure.
class m2_or03_guard_test extends base_test;
  `uvm_component_utils(m2_or03_guard_test)

  function new(string name = "m2_or03_guard_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2_or03_guard_vseq vseq;
    phase.raise_objection(this, "m2_or03_guard_vseq running");
    vseq = m2_or03_guard_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m2_or03_guard_vseq done");
  endtask
endclass

// M2-WO01 W channel order under multi-source convergence (testplan.md M2-WO01).
class m2_wo01_worder_test extends base_test;
  `uvm_component_utils(m2_wo01_worder_test)

  function new(string name = "m2_wo01_worder_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2_wo01_worder_vseq vseq;
    phase.raise_objection(this, "m2_wo01_worder_vseq running");
    vseq = m2_wo01_worder_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m2_wo01_worder_vseq done");
  endtask
endclass

// M3-DE01 decode-error slave basic response (testplan.md M3-DE01, spec §4).
class m3_de01_decerr_test extends base_test;
  `uvm_component_utils(m3_de01_decerr_test)

  function new(string name = "m3_de01_decerr_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_de01_decerr_vseq vseq;
    phase.raise_objection(this, "m3_de01_decerr_vseq running");
    vseq = m3_de01_decerr_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_de01_decerr_vseq done");
  endtask
endclass

// M3-DE02 default master port vs decode error slave split (testplan.md M3-DE02,
// spec §3.3/§4). Fetches the runtime config bus so the vseq can drive the mixed
// per-port en_default in an all-idle window before traffic.
class m3_de02_default_test extends base_test;
  `uvm_component_utils(m3_de02_default_test)

  virtual xbar_cfg_if cfg_vif;

  function new(string name = "m3_de02_default_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual xbar_cfg_if)::get(this, "", "cfg_vif", cfg_vif))
      `uvm_fatal("NOCFGVIF", "m3_de02_default_test: cfg_vif not set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_de02_default_vseq vseq;
    phase.raise_objection(this, "m3_de02_default_vseq running");
    vseq = m3_de02_default_vseq::type_id::create("vseq");
    vseq.cfg_vif = cfg_vif;
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_de02_default_vseq done");
  endtask
endclass

// M3-OR04 decode-miss ordering position (testplan.md M3-OR04, spec §5.2.6).
class m3_or04_order_test extends base_test;
  `uvm_component_utils(m3_or04_order_test)

  function new(string name = "m3_or04_order_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_or04_order_vseq vseq;
    phase.raise_objection(this, "m3_or04_order_vseq running");
    vseq = m3_or04_order_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_or04_order_vseq done");
  endtask
endclass

// M3-CFG02 runtime address-table live value on the judgement path (testplan.md
// M3-CFG02, BUG-0031). Same cfg_vif plumbing as M2-CFG01.
class m3_cfg02_reconfig_test extends base_test;
  `uvm_component_utils(m3_cfg02_reconfig_test)

  virtual xbar_cfg_if cfg_vif;

  function new(string name = "m3_cfg02_reconfig_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual xbar_cfg_if)::get(this, "", "cfg_vif", cfg_vif))
      `uvm_fatal("NOCFGVIF", "m3_cfg02_reconfig_test: cfg_vif not set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_cfg02_reconfig_vseq vseq;
    phase.raise_objection(this, "m3_cfg02_reconfig_vseq running");
    vseq = m3_cfg02_reconfig_vseq::type_id::create("vseq");
    vseq.cfg_vif = cfg_vif;
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_cfg02_reconfig_vseq done");
  endtask
endclass

// M3-OR05 stall-SVA judgement-range disarm directed falsification (testplan.md
// M3-OR05, BUG-0024, REV-011 §2.3 route (b)). Baseline config (same as M1-01).
class m3_or05_range_test extends base_test;
  `uvm_component_utils(m3_or05_range_test)

  function new(string name = "m3_or05_range_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_or05_range_vseq vseq;
    phase.raise_objection(this, "m3_or05_range_vseq running");
    vseq = m3_or05_range_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_or05_range_vseq done");
  endtask
endclass

// M3-CF01 config point A regression (testplan.md M3-CF01, spec §0 row 3/§7.2).
// TEST name prefix m3_cf01_ selects the XBAR_CFG_A build in sim/Makefile
// (cfgA: 1×8, NO_LATENCY) — see design-prompt tb_top.md C5.1.
class m3_cf01_cfga_test extends base_test;
  `uvm_component_utils(m3_cf01_cfga_test)

  function new(string name = "m3_cf01_cfga_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_cf01_cfga_vseq vseq;
    phase.raise_objection(this, "m3_cf01_cfga_vseq running");
    vseq = m3_cf01_cfga_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_cf01_cfga_vseq done");
  endtask
endclass

// M3-CF02 config point B regression (testplan.md M3-CF02, spec §0 row 3/§7.2).
// TEST name prefix m3_cf02_ selects the XBAR_CFG_B build in sim/Makefile
// (cfgB: 6×1, CUT_ALL_PORTS) — see design-prompt tb_top.md C5.1.
class m3_cf02_cfgb_test extends base_test;
  `uvm_component_utils(m3_cf02_cfgb_test)

  function new(string name = "m3_cf02_cfgb_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_cf02_cfgb_vseq vseq;
    phase.raise_objection(this, "m3_cf02_cfgb_vseq running");
    vseq = m3_cf02_cfgb_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_cf02_cfgb_vseq done");
  endtask
endclass

// M3-CF03 config point C regression (testplan.md M3-CF03, spec §0 row 3/§5.3).
// TEST name prefix m3_cf03_ selects the XBAR_CFG_C build in sim/Makefile
// (cfgC: 4×4, UniqueIds=1) — see design-prompt tb_top.md C5.1.
class m3_cf03_cfgc_test extends base_test;
  `uvm_component_utils(m3_cf03_cfgc_test)

  function new(string name = "m3_cf03_cfgc_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_cf03_cfgc_vseq vseq;
    phase.raise_objection(this, "m3_cf03_cfgc_vseq running");
    vseq = m3_cf03_cfgc_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_cf03_cfgc_vseq done");
  endtask
endclass

// M3-CF04 config point D regression (testplan.md M3-CF04, spec §0 row 3/§8/§6).
// TEST name prefix m3_cf04_ selects the XBAR_CFG_D build in sim/Makefile
// (cfgD: 4×4, sparse Connectivity, ATOPs=0). Fetches the runtime config bus so
// the vseq can apply the per-port default master port config (mst2/mst3) in an
// all-idle window before traffic (spec §3.3/§3.4).
class m3_cf04_cfgd_test extends base_test;
  `uvm_component_utils(m3_cf04_cfgd_test)

  virtual xbar_cfg_if cfg_vif;

  function new(string name = "m3_cf04_cfgd_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual xbar_cfg_if)::get(this, "", "cfg_vif", cfg_vif))
      `uvm_fatal("NOCFGVIF", "m3_cf04_cfgd_test: cfg_vif not set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_cf04_cfgd_vseq vseq;
    phase.raise_objection(this, "m3_cf04_cfgd_vseq running");
    vseq = m3_cf04_cfgd_vseq::type_id::create("vseq");
    vseq.cfg_vif = cfg_vif;
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_cf04_cfgd_vseq done");
  endtask
endclass

// M3-AT02 ATOP atomic read cross-direction false-conflict guard (testplan.md
// M3-AT02, spec §6.5/§5.2.5, BUG-0012). Baseline config (ATOPs=1).
class m3_at02_atop_read_test extends base_test;
  `uvm_component_utils(m3_at02_atop_read_test)

  function new(string name = "m3_at02_atop_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_at02_atop_read_vseq vseq;
    phase.raise_objection(this, "m3_at02_atop_read_vseq running");
    vseq = m3_at02_atop_read_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_at02_atop_read_vseq done");
  endtask
endclass

// M3-TL01 BUG-0010 cross-bucket directed regression guard (testplan.md
// M3-TL01, spec §5.4.1). Same bounded-hold rationale as M2-TL01: resp_hold
// keeps B/R from draining the in-flight count before the whole 2-bucket burst
// is presented, so the combined in-flight count on this one port genuinely
// reaches 20 (> MaxMstTrans=10) with both buckets concurrently non-empty
// rather than draining away as it fills ("空转").
class m3_tl01_xbucket_test extends base_test;
  `uvm_component_utils(m3_tl01_xbucket_test)

  function new(string name = "m3_tl01_xbucket_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    // 20 sub-transactions this time (vs. M2-TL01's 12) — a slightly deeper
    // hold keeps the same "hold outlasts the whole injection" margin.
    uvm_config_db#(int)::set(this, "env.mst_agent*", "resp_hold", 40);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m3_tl01_xbucket_vseq vseq;
    phase.raise_objection(this, "m3_tl01_xbucket_vseq running");
    vseq = m3_tl01_xbucket_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m3_tl01_xbucket_vseq done");
  endtask
endclass

// M4-OV01 overlapping-rule tie-break (testplan.md M4-OV01, spec §3.1.3/
// §3.2.1). Baseline config (same as M1-01); fetches the runtime config-bus
// handle and hands it to the vseq, which applies the ADDR_MAP_OV1 overlap
// table in the post-reset idle window before any traffic (same pattern as
// m2_cfg01_reconfig_test / m3_cfg02_reconfig_test).
class m4_ov01_overlap_test extends base_test;
  `uvm_component_utils(m4_ov01_overlap_test)

  virtual xbar_cfg_if cfg_vif;

  function new(string name = "m4_ov01_overlap_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual xbar_cfg_if)::get(this, "", "cfg_vif", cfg_vif))
      `uvm_fatal("NOCFGVIF", "m4_ov01_overlap_test: cfg_vif not set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    m4_ov01_overlap_vseq vseq;
    phase.raise_objection(this, "m4_ov01_overlap_vseq running");
    vseq = m4_ov01_overlap_vseq::type_id::create("vseq");
    vseq.cfg_vif = cfg_vif;
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m4_ov01_overlap_vseq done");
  endtask
endclass

// M4-FT01 config point E regression (testplan.md M4-FT01, spec §0 row 3/
// §2.1/§7.3.1). TEST name prefix m4_ft01_ selects the XBAR_CFG_E build in
// sim/Makefile (cfgE: 6×8, FallThrough=1'b1) — see design-prompt
// tb_top.md C5.1.
class m4_ft01_cfge_test extends base_test;
  `uvm_component_utils(m4_ft01_cfge_test)

  function new(string name = "m4_ft01_cfge_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m4_ft01_cfge_vseq vseq;
    phase.raise_objection(this, "m4_ft01_cfge_vseq running");
    vseq = m4_ft01_cfge_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m4_ft01_cfge_vseq done");
  endtask
endclass

// M4-RC01 default-master-port enable->close round trip (testplan.md
// M4-RC01, spec §3.4 items 1/2/§3.3/§4.2-4.4). Baseline config (same as
// M1-01); fetches the runtime config-bus handle and hands it to the vseq,
// which drives the two reconfigurations (enable, then close) each in its own
// all-idle window (same cfg_vif plumbing as m2_cfg01_reconfig_test/
// m3_cfg02_reconfig_test/m4_ov01_overlap_test).
class m4_rc01_reclose_test extends base_test;
  `uvm_component_utils(m4_rc01_reclose_test)

  virtual xbar_cfg_if cfg_vif;

  function new(string name = "m4_rc01_reclose_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual xbar_cfg_if)::get(this, "", "cfg_vif", cfg_vif))
      `uvm_fatal("NOCFGVIF", "m4_rc01_reclose_test: cfg_vif not set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    m4_rc01_reclose_vseq vseq;
    phase.raise_objection(this, "m4_rc01_reclose_vseq running");
    vseq = m4_rc01_reclose_vseq::type_id::create("vseq");
    vseq.cfg_vif = cfg_vif;
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m4_rc01_reclose_vseq done");
  endtask
endclass

// M4-AW01 master-port AW arbitration under backpressure (testplan.md
// M4-AW01, spec §5.5.1/§5.5.2/§5.5.3/§5.5.4, §7.4 items 1/5). Baseline
// config (same as M1-01). Enables mstport_responder's off-by-default
// bp_enable backpressure (mstport_agent.sv) on master port 0's responder
// ONLY, before that component's own build_phase runs (same config_db-
// before-super.build_phase ordering as M2-TL01/TL02's resp_hold above),
// then reuses m2_wo01_worder_vseq UNCHANGED — its body already forks all
// NO_SLV_PORTS source slave ports converging their writes on master port 0
// (the exact "≥2 sources contend for one master port's AW" shape this
// scenario needs), so no new vseq class is warranted (simplicity-first).
// The W-burst-order judgement this stimulus feeds already lives in
// scoreboard_refmodel.sv C5.4 (SPEC-5.5.1), unchanged by this card.
class m4_aw01_awbp_test extends base_test;
  `uvm_component_utils(m4_aw01_awbp_test)

  function new(string name = "m4_aw01_awbp_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    uvm_config_db#(bit)::set(this, "env.mst_agent[0].responder", "bp_enable", 1'b1);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m2_wo01_worder_vseq vseq;
    phase.raise_objection(this, "m4_aw01_awbp_vseq running");
    vseq = m2_wo01_worder_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m4_aw01_awbp_vseq done");
  endtask
endclass

// M4-EB01 err_slv decode-error B-channel backpressure (testplan.md M4-EB01,
// spec §4.2/§4.3/§4.5/§5.1/§7.4/§7.4.5). Baseline config (same as M1-01;
// en_default_mst_port='0 by reset default ⇒ unmapped addresses route to each
// port's internal err_slv). No config_db knob: the b_ready backpressure is
// carried on the burst item itself (axi_burst_item.b_backpressure), applied
// per slave port by slvport_driver — so the mstport responders (never involved
// in decode-error traffic) stay at their default zero hold, unlike the TL01/
// TL02 tests. The DECERR judgement is the M3-DE01 SB_DECERR_* family, reused
// verbatim (no new expected values).
class m4_eb01_errbp_test extends base_test;
  `uvm_component_utils(m4_eb01_errbp_test)

  function new(string name = "m4_eb01_errbp_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m4_eb01_errbp_vseq vseq;
    phase.raise_objection(this, "m4_eb01_errbp_vseq running");
    vseq = m4_eb01_errbp_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m4_eb01_errbp_vseq done");
  endtask
endclass

// M4-BP02 demux lock-retry FSM + same-bucket in-flight ceiling under W-open
// stress (testplan.md M4-BP02, spec §5.4.1/§5.4.2/§5.5.1/§5.5.3/§7.4.5).
// Baseline config (same as M1-01). Two off-by-default responder knobs, both
// reused unchanged from earlier scenarios:
//   - bp_enable on master port 0's responder ONLY (the sole target, M4-AW01's
//     mechanism) so the demux's already-selected AW repeatedly sits valid-but-
//     not-ready → lock-retry path;
//   - resp_hold on the responders (M2-TL01/M3-TL01's mechanism) so B responses
//     drain slowly enough that the same-(bucket,direction) in-flight count is
//     genuinely pressed to the §5.4.1 effective ceiling (15) rather than
//     draining away. The vseq's sliding-window driver (drive_burst_wopen)
//     keeps >=3 W channels simultaneously open (w_open high) while W keeps
//     flowing, so the AW ID counter (which pops on B, not W) can still climb to
//     the ceiling under resp_hold — the three-way structural stack.
// The judgement is the scoreboard's (route/data/wstrb/wlast/response/
// completion, spec §1/§3.1/§5.1/§5.2.3), delay-insensitive (spec §7.4.5).
class m4_bp02_demuxlock_test extends base_test;
  `uvm_component_utils(m4_bp02_demuxlock_test)

  function new(string name = "m4_bp02_demuxlock_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    // Set before the responders' build_phase (child components build after this
    // test's build_phase) — byte-identical config path to M4-AW01 / M2-TL01.
    // resp_hold sized to span the whole AW-injection window so no B drains the
    // per-bucket count before it reaches the ceiling.
    uvm_config_db#(bit)::set(this, "env.mst_agent[0].responder", "bp_enable", 1'b1);
    uvm_config_db#(int)::set(this, "env.mst_agent*", "resp_hold", 150);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m4_bp02_demuxlock_vseq vseq;
    phase.raise_objection(this, "m4_bp02_demuxlock_vseq running");
    vseq = m4_bp02_demuxlock_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m4_bp02_demuxlock_vseq done");
  endtask
endclass

// M4-BP03 demux AR lock-retry FSM + same-bucket read in-flight ceiling
// (testplan.md M4-BP03, spec §5.4.1/§5.4.2/§5.2.3/§5.5.3/§7.4.5 — REV-027 §5
// hardening card B, the read-direction dual of M4-BP02). Baseline config
// (same as M1-01). Two off-by-default responder knobs, mirroring M4-BP02's
// write-direction pair:
//   - bp_enable_ar on master port 0's responder ONLY (mstport_agent.sv's
//     AR-direction mirror of M4-AW01's bp_enable) so the demux's
//     already-selected AR repeatedly sits valid-but-not-ready → AR
//     lock-retry path;
//   - resp_hold on the responders (M2-TL01/M3-TL01/M4-BP02's mechanism, here
//     delaying R instead of B) so the same-(bucket,direction) AR in-flight
//     count is genuinely pressed to the §5.4.1 effective ceiling (15) rather
//     than draining away as each burst's R completes.
// The vseq's read-direction burst already keeps every sub-item's AR
// presented back-to-back (drive_burst()'s existing non-write branch, no new
// driver primitive needed — see slvport_bp03_seq's header comment in
// seq_lib.sv). The judgement is the scoreboard's (route/data/response/
// completion, spec §1/§3.1/§5.1/§5.2.3), delay-insensitive (spec §7.4.5).
class m4_bp03_demuxlock_ar_test extends base_test;
  `uvm_component_utils(m4_bp03_demuxlock_ar_test)

  function new(string name = "m4_bp03_demuxlock_ar_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    // Set before the responders' build_phase (child components build after this
    // test's build_phase) — byte-identical config path to M4-BP02/M4-AW01.
    // resp_hold sized to span the whole AR-injection window so no R drains the
    // per-bucket count before it reaches the ceiling.
    uvm_config_db#(bit)::set(this, "env.mst_agent[0].responder", "bp_enable_ar", 1'b1);
    uvm_config_db#(int)::set(this, "env.mst_agent*", "resp_hold", 150);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    m4_bp03_demuxlock_ar_vseq vseq;
    phase.raise_objection(this, "m4_bp03_demuxlock_ar_vseq running");
    vseq = m4_bp03_demuxlock_ar_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this, "m4_bp03_demuxlock_ar_vseq done");
  endtask
endclass
