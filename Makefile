# Mechanical layer, single entry point. See CLAUDE.md for the target table
# and the invariants each target backs.

.DEFAULT_GOAL := help

.PHONY: help handoff next run evidence regress check guards bump commit \
        archive docs-archive selftest

# Bare `make` (no target) lands here. Keep in sync with the target comments
# below — this is a manual list, not comment-scraped, so a new target needs
# a line here too.
help:
	@echo "pulp_axi_xbar_copilot — mechanical layer targets"
	@echo ""
	@echo "  handoff                    print current status/testplan/bugs summary (session start)"
	@echo "  next                       mechanically derived next-action list"
	@echo "  run TEST= SEED=            forward to sim/Makefile: run one simulation"
	@echo "  evidence ...               register evidence (scenario pass or bug closure) — see below"
	@echo "  regress                    forward to sim/Makefile: run the regression suite"
	@echo "  check [SCEN=] [MILESTONE=] docs-check + chain audit; narrow to one scenario or a milestone"
	@echo "  guards FILES=\"...\"         print registered regression_guards binding the given files"
	@echo "  bump [minor=1]             VERSION + CHANGELOG skeleton bump (patch by default)"
	@echo "  commit                     git add -A + commit with a handoff summary (never pushes)"
	@echo "  archive                    archive old log/testplan entries"
	@echo "  selftest                   run scripts/tests unit tests"
	@echo "  smoke / cov / lint / verdi / clean   forward to sim/Makefile"
	@echo ""
	@echo "evidence usage:"
	@echo "  make evidence SCEN=<id> TEST=<t> SEED=<n> [SPEC_REF=SPEC-x.y] [LOG=<path>]"
	@echo "  make evidence BUG=<id> TEST=<t> SEED=<n>            bug closure (closer != fixer)"
	@echo "  make evidence BUG=<id> CMD='<cmd>' EXPECT='<regex>' non-sim re-verification"
	@echo "    CMD/EXPECT may contain literal \$$(...) / \$$VAR shell syntax"
	@echo "    (e.g. CMD='echo \$$(pwd)') — passed through to the shell"
	@echo "    unexpanded by make; no \$$\$$-escaping needed (BUG-0069)"

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
# BUG-0069: CMD/EXPECT use $(value ...), not a plain $(CMD)/$(EXPECT)
# reference. A command-line-set variable is stored unexpanded and
# re-expanded on every reference — a CMD containing its own $(...)/$VAR
# (e.g. `echo $(pwd)`) would otherwise be silently re-evaluated by make
# itself before reaching the shell, swallowing anything that isn't a
# defined make variable. $(value ...) takes the raw text once and skips
# that second pass, so $(pwd)/$VAR now reach the shell exactly as typed.
# 见 doc/fw-feedback.md FB-34.
evidence:
	@python3 scripts/evidence.py $(if $(SCEN),--scen $(SCEN)) \
		$(if $(BUG),--bug $(BUG)) \
		$(if $(value CMD),--cmd '$(value CMD)' --expect '$(value EXPECT)', \
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
	@python3 scripts/docsx.py --check
# docsx.py is project-owned (F1/F2/F7/F10 batch 1; doc/design-prompt/
# doc_mechanization.md §13 C13.1) — no SCEN/MILESTONE narrowing yet.
# 见 doc/fw-feedback.md FB-36.

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

# `archive` is the real target; `docs-archive` is a compat alias because
# scripts/docs.py (upstream file, not touched) hardcodes the string
# `make docs-archive` in four remediation hints (BUG-0065).
docs-archive: archive

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
