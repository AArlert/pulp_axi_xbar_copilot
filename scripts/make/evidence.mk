# iverif evidence-chain targets.
# Vendored to scripts/make/evidence.mk; include from the project root
# Makefile after core.mk.
.PHONY: evidence replay chain signoff-check

# After a sim run in the VM:
#   make evidence SCEN=M1-01 TEST=<t> SEED=<n> [SPEC_REF=SPEC-x.y] [LOG=<p>]
# Bug closure re-verification (closer != fixer):
#   make evidence BUG=BUG-003 TEST=<t> SEED=<n>
evidence:
	@python3 scripts/evidence.py $(if $(SCEN),--scen $(SCEN)) \
		$(if $(BUG),--bug $(BUG)) --test $(TEST) --seed $(SEED) \
		$(if $(LOG),--log $(LOG)) $(if $(SPEC_REF),--spec-ref $(SPEC_REF))

# Re-run exactly what an evidence record claims: make replay SCEN=M1-01
replay:
	@cmd=$$(python3 scripts/docs.py --repro $(SCEN)) && \
		echo "replaying: $$cmd" && $$cmd

# Full traceability for one scenario (spec -> evidence -> bugs -> reviews):
#   make chain SCEN=M1-01
chain:
	@python3 scripts/docs.py --chain $(SCEN)

# Milestone signoff pre-check (machine conditions + human checklist).
signoff-check:
	@python3 scripts/docs.py --signoff
