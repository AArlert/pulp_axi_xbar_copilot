# pulp_axi_xbar_copilot root Makefile — doc mechanical layer + sim forwarding.
# The mechanical targets come from the vendored framework snapshot.
include scripts/make/core.mk
include scripts/make/evidence.mk

# ---- simulation (local VM with VCS/Verdi; see sim/Makefile) ----
.PHONY: smoke run regress cov lint verdi clean
smoke run regress cov lint verdi clean:
	@$(MAKE) -C sim $@
