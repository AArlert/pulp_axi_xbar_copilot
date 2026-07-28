# iverif evidence-chain targets.
# Pinned into scripts/make/evidence.mk; include from the project root
# Makefile after core.mk.
.PHONY: evidence replay chain chain-audit signoff-check

# After a sim run in the VM:
#   make evidence SCEN=M1-01 TEST=<t> SEED=<n> [SPEC_REF=SPEC-x.y] [LOG=<p>]
# Bug closure re-verification (closer != fixer):
#   make evidence BUG=BUG-003 TEST=<t> SEED=<n>
# Non-sim re-verification (lint/compile/tool criteria — runs CMD now,
# exit 0 + EXPECT signature required, fail-closed):
#   make evidence BUG=BUG-003 CMD='make -C sim lint' EXPECT='lint clean'
evidence:
	@python3 scripts/evidence.py $(if $(SCEN),--scen $(SCEN)) \
		$(if $(BUG),--bug $(BUG)) \
		$(if $(CMD),--cmd '$(CMD)' --expect '$(EXPECT)', \
		--test $(TEST) --seed $(SEED)) \
		$(if $(LOG),--log $(LOG)) $(if $(SPEC_REF),--spec-ref $(SPEC_REF))

# Re-run exactly what an evidence record claims: make replay SCEN=M1-01
replay:
	@cmd=$$(python3 scripts/docs.py --repro $(SCEN)) && \
		echo "replaying: $$cmd" && $$cmd

# Full traceability for one scenario (spec -> evidence -> bugs -> reviews):
#   make chain SCEN=M1-01
chain:
	@python3 scripts/docs.py --chain $(SCEN)

# Whole-graph break-link audit (spec <-> testplan <-> matrix <-> evidence);
# fails only on dangling spec refs, reports every other gap class.
chain-audit:
	@python3 scripts/docs.py --chain-audit

# Milestone signoff pre-check (machine conditions + human checklist).
signoff-check:
	@python3 scripts/docs.py --signoff
