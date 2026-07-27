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
