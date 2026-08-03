# Mechanical layer, single entry point (0.5.4 reset). All doc bookkeeping
# forwards to scripts/docs.py; simulation targets forward to sim/Makefile.

.DEFAULT_GOAL := help

.PHONY: help handoff next run evidence regress check archive bump commit

help:
	@echo "pulp_axi_xbar_copilot — targets"
	@echo ""
	@echo "  handoff                    session-start status snapshot"
	@echo "  next                       mechanically derived next-action list"
	@echo "  run TEST= SEED=            run one simulation (sim/Makefile)"
	@echo "  evidence SCEN= TEST= SEED= [SPEC_REF=] [LOG=]   turn a scenario green"
	@echo "  evidence BUG= TEST= SEED=                       close a bug (sim)"
	@echo "  evidence BUG= CMD='<cmd>' EXPECT='<regex>'      close a bug (non-sim)"
	@echo "  regress                    run the regression suite (sim/Makefile)"
	@echo "  check                      doc sanity gate (pre-commit runs this)"
	@echo "  archive                    roll old log/status/bug entries"
	@echo "  bump [minor=1]             version bump + log/status skeletons"
	@echo "  commit                     git add -A + commit (never pushes)"
	@echo "  smoke / cov / lint / verdi / clean   forward to sim/Makefile"

handoff:
	@python3 scripts/docs.py --handoff

next:
	@python3 scripts/docs.py --next

run:
	@$(MAKE) -C sim run TEST=$(TEST) SEED=$(SEED)

# CMD/EXPECT use $(value ...): a command-line variable is stored unexpanded
# and re-expanded on every reference — a CMD containing its own $(...)/$VAR
# (e.g. `echo $(pwd)`) would otherwise be re-evaluated by make itself before
# reaching the shell. $(value ...) takes the raw text once.
evidence:
	@python3 scripts/docs.py $(if $(SCEN),--scen $(SCEN)) \
		$(if $(BUG),--bug $(BUG)) \
		$(if $(value CMD),--cmd '$(value CMD)' --expect '$(value EXPECT)', \
		--test $(TEST) --seed $(SEED)) \
		$(if $(LOG),--log $(LOG)) $(if $(SPEC_REF),--spec-ref $(SPEC_REF))

regress:
	@$(MAKE) -C sim regress

check:
	@python3 scripts/docs.py --check

archive:
	@python3 scripts/docs.py --archive

bump:
	@python3 scripts/docs.py --bump $(if $(minor),minor,patch)

# add+commit only — never push; push is a separate, human decision.
commit:
	@git add -A && git commit -m "$$(python3 scripts/docs.py --handoff | head -3)"

# ---- simulation forwarding (VM: VCS/Verdi O-2018) ----
.PHONY: smoke cov lint verdi clean
smoke cov lint verdi clean:
	@$(MAKE) -C sim $@
