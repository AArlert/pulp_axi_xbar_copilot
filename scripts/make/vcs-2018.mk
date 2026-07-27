# VCS/Verdi O-2018 environment + known-workaround fragment.
# Vendored to scripts/make/vcs-2018.mk; include near the top of sim/Makefile,
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
#               regress.py already cleans first.
#   SIM_OPTS_2018 (-assert verbose) - SVA failures do NOT increment
#               UVM_ERROR and do not change the simv exit code; the native
#               "Summary: N assertions, ..." line this option prints is the
#               only structured proof of assertion cleanliness, and
#               evidence.py/regress.py fail-closed without it (ppa BUG-014).
#               Never drop it from the run rule.

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
export LD_LIBRARY_PATH := $(VERDI_HOME)/share/PLI/VCS/LINUX64:$(LD_LIBRARY_PATH)
export PATH := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(SCL_HOME)/linux64/bin:$(PATH)

# xverif toolkit (VM instruments; NOT on PATH — call via full path).
# Probe with `test -x $(XVERIF_ROOT)/tools/xdebug`, never `command -v`;
# xdebug/xcov need VERDI_HOME exported first (both handled above).
export XVERIF_ROOT ?= /home/open_tools/xverif

OUT  ?= out
COV  ?= 0
FSDB ?= 0

VCS    := vcs
LD_FIX := -LDFLAGS "-Wl,--no-as-needed"
# Verdi PLI (novas.tab + pli.a): registers $fsdbDump* system tasks.
NOVAS  := -P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab \
          $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a

# Common 2018-era flags: -assert svaext is required for elaboration system
# tasks ($error/$fatal inside generate) used heavily by pulp libraries.
VCS_FLAGS_2018 := -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 \
                  -assert svaext -debug_access+all -kdb +vcs+lic+wait \
                  $(LD_FIX) $(NOVAS)

# Runtime (simv) options — pinned, see SIM_OPTS_2018 note in the header.
SIM_OPTS_2018 := -assert verbose

# ---- coverage: the six-type yardstick ----
ifeq ($(COV),1)
CM := -cm line+cond+fsm+tgl+branch+assert -cm_dir $(OUT)/cov.vdb
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
#   cov:      urg -full64 -dir $(OUT)/cov.vdb \
#                 $(wildcard cov_reset*/cov.vdb:%=-dir %) -report $(OUT)/urgReport
#
# Upstream TBs ending in $stop hang batch runs at the interactive prompt —
# drive them with a ucli script:  echo "run; exit" > $(OUT)/x.ucli ;
# $(OUT)/simv -ucli -i $(OUT)/x.ucli -l $(OUT)/<test>_<seed>.log
