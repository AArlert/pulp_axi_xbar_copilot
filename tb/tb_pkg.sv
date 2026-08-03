// tb/tb_pkg.sv — M1 UVM env: top package. Compiled after xbar_types_pkg.sv
// and axi_if.sv (sim/flist/tb.f order) since the classes below hold virtual
// handles to slvport_if/mstport_if.
//
// `include order mirrors the delivery structure named in the design
// prompts: transaction items, the two port agents (uvm_env.md §2/§3), the
// functional-coverage collector (functional_coverage.md — before the
// scoreboard, which stores its stall_class_e), the scoreboard/reference model
// (scoreboard_refmodel.md — kept as its own top-level
// tb/scoreboard_refmodel.sv file per the feature-matrix module mapping),
// env/virtual-sequencer, sequences, tests.
package xbar_tb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import xbar_types_pkg::*;

  `include "axi_txn.sv"
  // functional_coverage.sv moved ahead of slvport_agent.sv (M4-FT01): the
  // slvport_monitor now samples cg_fallthrough directly via the static
  // xbar_functional_coverage::m_probe bridge (same pattern the stall-SVA
  // module already uses), so the class must be declared before that use
  // site — SV class references, unlike the tb/sva/*.sv modules that import
  // this whole package post-compilation, need the class body already seen
  // within this same package compilation unit. Still "before the
  // scoreboard, which stores its stall_class_e" (original ordering intent
  // above) — only its position relative to the two port-agent files moved.
  `include "functional_coverage.sv"
  `include "slvport_agent.sv"
  `include "mstport_agent.sv"
  `include "scoreboard_refmodel.sv"
  `include "xbar_env.sv"
  `include "seq_lib.sv"
  // report_seed_catcher.sv before test_lib.sv: base_test::build_phase
  // references xbar_seed_catcher (M5 failure-traceability).
  `include "report_seed_catcher.sv"
  `include "test_lib.sv"

endpackage
