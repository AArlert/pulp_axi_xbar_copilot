// tb/report_seed_catcher.sv — M5 failure-traceability (milestone.md M5 exit
// criterion 1, first task): a failing log must be self-contained without
// needing to scroll back to line 1's `Command:` banner for the seed. This
// uvm_report_catcher appends "[seed=N]" to every UVM_ERROR/UVM_FATAL message
// tb-wide (scoreboard `uvm_error AND every tb/sva/*.sv `uvm_error, both of
// which report through the same uvm_root-rooted callback pool) — one
// registration point (test_lib.sv base_test), zero touch to existing call
// sites. Registered exactly once per sim (one test per simv invocation, one
// base_test::build_phase call); the static guard below only memoizes the
// plusarg lookup, it is not multi-registration protection (a second
// registered instance would still append its own "[seed=N]").
class xbar_seed_catcher extends uvm_report_catcher;

  local static int seed;
  local static bit  have_seed;

  function new(string name = "xbar_seed_catcher");
    super.new(name);
  endfunction

  function action_e catch();
    if (get_severity() inside {UVM_ERROR, UVM_FATAL}) begin
      if (!have_seed) begin
        // Read back the exact plusarg sim/Makefile's `run:` target passes
        // (+ntb_random_seed=$(SEED)) rather than trusting a VCS-internal
        // "initial seed" notion to agree with it.
        if (!$value$plusargs("ntb_random_seed=%d", seed)) seed = -1;
        have_seed = 1'b1;
      end
      set_message($sformatf("%s [seed=%0d]", get_message(), seed));
    end
    return THROW;
  endfunction

endclass
