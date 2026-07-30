# VCS/Verdi O-2018 environment + known-workaround fragment.
# Pinned into scripts/make/vcs-2018.mk; include near the top of sim/Makefile,
# after defining OUT (default provided). Everything uses ?=/:= so the
# environment or the including Makefile can override.
#
# Collected workarounds (each cost a real debugging session once):
#   LD_FIX    - Ubuntu 22.04 g++ defaults to -Wl,--as-needed, which drops
#               snps*/vfs_* libraries that libvcsnew.so needs (2018-era VCS
#               predates this default) => explicit --no-as-needed.
#   covreset  - VCS O-2018 drops async-reset FSM arcs when merging into a
#               shared coverage DB; run reset tests with their own OUT= and
#               merge the extra .vdb in the cov report (pattern below).
#   clean-before-regress - stale .daidir/csrc from a different option set
#               (e.g. lint) corrupts incremental builds (VFS_SDB_ERROR class);
#               a project-owned regress loop must clean first (pattern below).
#   ld-colon  - ':$(LD_LIBRARY_PATH)' with the parent var empty leaves a
#               trailing empty element; NPI-based tools (xdebug) refuse
#               to initialize on it (pulp BUG-0030) => conditional append.
#   SIM_OPTS_2018 (-assert verbose) - SVA failures do NOT increment
#               UVM_ERROR and do not change the simv exit code; the native
#               "Summary: N assertions, ..." line this option prints is the
#               only structured proof of assertion cleanliness, and
#               evidence.py / svacheck.py --judge fail-closed without it
#               (ppa BUG-014). Never drop it from the run rule.
#   cov-dir-lazy - CM's `-cm_dir` used to be bound with `:=` (immediate
#               expansion) at include time, freezing whatever OUT held
#               *then* (the default) before the including Makefile's
#               per-config `override OUT` blocks ever ran, so every COV=1
#               `make run` wrote into the same shared cov.vdb regardless of
#               which design/topology it was (pulp BUG-0037) => CM/COV_DIR
#               are now recursive (`=`), resolved at recipe-execution time
#               instead. 见 doc/fw-feedback.md FB-30.

# ---- EDA environment fallback (non-interactive shells skip ~/.bashrc) ----
export VCS_HOME        ?= /home/synopsys/vcs-mx/O-2018.09-SP2
export VCS_MX_HOME     ?= $(VCS_HOME)
export VERDI_HOME      ?= /home/synopsys/verdi/Verdi_O-2018.09-SP2
export SCL_HOME        ?= /home/synopsys/scl/2018.06
# LM_LICENSE_FILE: this default is a PLACEHOLDER, not a guess at a "usually
# right" value — license servers are per-environment and this repo cannot
# know yours. It exists only so the variable is always set to *something*
# (silent-unset is worse than a loud wrong value). Export the real
# host:port for your VM/farm before this file is included, or every VCS
# invocation will fail against a server that doesn't exist.
export LM_LICENSE_FILE ?= 27000@localhost
export VCS_ARCH_OVERRIDE ?= linux
export LD_LIBRARY_PATH := $(VERDI_HOME)/share/PLI/VCS/LINUX64$(if $(LD_LIBRARY_PATH),:$(LD_LIBRARY_PATH))
export PATH := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(SCL_HOME)/linux64/bin:$(PATH)

# xverif toolkit (VM instruments; NOT on PATH — call via full path).
# Probe with `test -x $(XVERIF_ROOT)/tools/xdebug`, never `command -v`;
# xdebug/xcov need VERDI_HOME exported first (both handled above).
# Its tested Verdi baseline (V-2023.12) is newer than this VM's Verdi 2018 —
# if a tool misbehaves, record it as a TOOL_ENV failure record rather than
# debugging blind.
export XVERIF_ROOT ?= /home/open_tools/xverif

OUT  ?= out
COV  ?= 0
FSDB ?= 0
# Coverage DB location, kept as its own indirection (not inlined into CM)
# so the including Makefile can redirect a single TEST's database (e.g.
# M0's upstream_sanity, a structurally different top-level design from
# every M1+ UVM test — see BUG-0037) without touching OUT itself, which
# would also move that TEST's build product and narrow `make clean`'s
# scope. Recursive (`=`, not `:=`): must resolve OUT/its own override at
# CM's point of use, not at this include. 见 doc/fw-feedback.md FB-30.
COV_DIR = $(OUT)/cov.vdb

VCS    := vcs
LD_FIX := -LDFLAGS "-Wl,--no-as-needed"
# Verdi PLI (novas.tab + pli.a): registers $fsdbDump* system tasks.
NOVAS  := -P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab \
          $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a

# Common 2018-era flags: -assert svaext is required for elaboration system
# tasks ($error/$fatal inside generate) used heavily by vendored IP libraries.
VCS_FLAGS_2018 := -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 \
                  -assert svaext -debug_access+all -kdb +vcs+lic+wait \
                  $(LD_FIX) $(NOVAS)

# Runtime (simv) options — pinned, see SIM_OPTS_2018 note in the header.
SIM_OPTS_2018 := -assert verbose

# ---- coverage: the six-type yardstick ----
ifeq ($(COV),1)
# `=` (recursive), not `:=`: must re-resolve COV_DIR at the point compile:/
# run: actually reference $(CM) (recipe-execution time), by which point the
# including Makefile's per-config `override OUT` / per-TEST `COV_DIR`
# overrides have already run (BUG-0037). 见 doc/fw-feedback.md FB-30.
CM = -cm line+cond+fsm+tgl+branch+assert -cm_dir $(COV_DIR)
# Optional measurement-domain filter: CMHIER=<cfg> passes -cm_hier to both
# compile and sim (restrict to the tb subtree / exclude UVM library
# scaffolding). Default: full-domain collection.
ifneq ($(CMHIER),)
CM += -cm_hier $(CMHIER)
endif
endif

# Reference patterns for the including sim/Makefile:
#
#   compile:  $(VCS) $(VCS_FLAGS_2018) $(if $(filter 1,$(COV)),$(CM)) \
#                 $(FLISTS) -top $(TOP) -o $(OUT)/simv -l $(OUT)/comp.log
#   run:      $(OUT)/simv $(SIM_OPTS_2018) +UVM_TESTNAME=$(TEST) \
#                 +ntb_random_seed=$(SEED) \
#                 $(if $(filter 1,$(COV)),$(CM) -cm_name $(TEST)_$(SEED)) \
#                 -l $(OUT)/$(TEST)_$(SEED).log
#   covreset: $(MAKE) run TEST=<reset_test> SEED=1 COV=1 OUT=cov_reset
#   cov:      urg -full64 -dir $(COV_DIR) \
#                 $(wildcard cov_reset*/cov.vdb:%=-dir %) -report $(OUT)/urgReport
#
# Upstream TBs ending in $stop hang batch runs at the interactive prompt —
# drive them with a ucli script:  echo "run; exit" > $(OUT)/x.ucli ;
# $(OUT)/simv -ucli -i $(OUT)/x.ucli -l $(OUT)/<test>_<seed>.log
#
# regress (project-owned; canon only owns the one-log verdict primitive —
# svacheck.py --judge, invoked below — everything else here is yours to
# customize: parallelism, COV=1 policy, summary format):
#
#   regress:
#       $(MAKE) clean                                    # avoid VFS_SDB_ERROR
#       @rc=0; \
#       while read -r test seed; do \
#         [ -z "$$test" ] && continue; \
#         case "$$test" in \#*) continue;; esac; \
#         $(MAKE) run TEST=$$test SEED=$$seed COV=$(COV) \
#           OUT=out/$$test_$$seed || true; \
#         python3 ../scripts/svacheck.py --judge out/$$test_$$seed/*.log \
#           || rc=1; \
#       done < regress/regress.list; \
#       exit $$rc
#
# A nonzero `make run` exit should force FAIL even if the log looks clean —
# an abnormal process exit is never evidence of a clean run.
