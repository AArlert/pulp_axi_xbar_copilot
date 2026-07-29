# Mechanical layer, single entry point. See CLAUDE.md for the target table
# and the invariants each target backs.

.PHONY: handoff next run evidence regress check guards bump commit archive \
        selftest

handoff:
	@python3 scripts/docs.py --handoff

next:
	@python3 scripts/docs.py --next

# make run TEST=<t> SEED=<n> — forwarded, project-owned (sim/Makefile).
run:
	@$(MAKE) -C sim run TEST=$(TEST) SEED=$(SEED)

# make evidence SCEN=M1-01 TEST=<t> SEED=<n> [SPEC_REF=SPEC-x.y] [LOG=<p>]
# Bug closure re-verification (closer != fixer):
#   make evidence BUG=BUG-003 TEST=<t> SEED=<n>
# Non-sim re-verification (lint/compile/tool criteria — runs CMD, exit 0 +
# EXPECT signature required, fail-closed twice):
#   make evidence BUG=BUG-003 CMD='make -C sim lint' EXPECT='lint clean'
evidence:
	@python3 scripts/evidence.py $(if $(SCEN),--scen $(SCEN)) \
		$(if $(BUG),--bug $(BUG)) \
		$(if $(CMD),--cmd '$(CMD)' --expect '$(EXPECT)', \
		--test $(TEST) --seed $(SEED)) \
		$(if $(LOG),--log $(LOG)) $(if $(SPEC_REF),--spec-ref $(SPEC_REF))

# Pure forward, project-owned — same pattern as run/smoke/cov/lint/verdi/
# clean. canon owns only the one-log verdict primitive: scripts/svacheck.py
# --judge (reference regress loop: scripts/make/vcs-2018.mk tail comment).
regress:
	@$(MAKE) -C sim regress

# Bare: docs-check + whole-graph chain audit (ghost ref / unevidenced ✅ /
# broken chain / this-milestone kill coverage).
# make check SCEN=M1-01      — narrow to one scenario's full evidence chain.
# make check MILESTONE=2     — narrow to milestone-2 signoff precheck.
check:
	@python3 scripts/docs.py --check $(if $(SCEN),--scen $(SCEN)) \
		$(if $(MILESTONE),--milestone $(MILESTONE))

# Registered regression_guards binding the given files (card assembly +
# review.md spot-check 6). Usage: make guards FILES="tb/sva/foo.sv tb/bar.sv"
guards:
	@python3 scripts/docs.py --guards $(FILES)

# VERSION + CHANGELOG skeleton + reminder to tag. make bump minor=1 for a
# milestone bump (0.M+1.0); default is a patch bump (0.M.P+1).
bump:
	@python3 scripts/bump.py $(if $(minor),minor,patch)

# add+commit only — never push. message carries a one-line evidence/status
# summary; push is a separate, manual, human decision (git push).
commit:
	@git add -A && git commit -m "$$(python3 scripts/docs.py --handoff | head -3)"

archive:
	@python3 scripts/docs.py --archive

selftest:
	cd scripts/tests && python3 -m unittest discover -v

# ---- project-owned simulation forwarding (VM: VCS/Verdi O-2018) ----
# `run` and `regress` are already forwarded above by the canon Makefile.
# The regress loop itself is project-owned since 0.8.0 (sim/Makefile calls
# scripts/regress.py, kept here as a project file — canon owns only the
# one-log verdict primitive, scripts/svacheck.py --judge).
.PHONY: smoke cov lint verdi clean
smoke cov lint verdi clean:
	@$(MAKE) -C sim $@
