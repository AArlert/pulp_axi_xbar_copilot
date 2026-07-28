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
  `include "slvport_agent.sv"
  `include "mstport_agent.sv"
  `include "functional_coverage.sv"
  `include "scoreboard_refmodel.sv"
  `include "xbar_env.sv"
  `include "seq_lib.sv"
  `include "test_lib.sv"

endpackage
