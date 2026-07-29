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
