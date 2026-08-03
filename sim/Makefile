# pulp_axi_xbar_copilot sim entry — VCS-MX O-2018 + Verdi（workaround 见
# ../scripts/make/vcs-2018.mk 头注释）。
# 本 VM 实测 license 端点与 fragment 回退值不同（FB-2），include 前覆盖：
export LM_LICENSE_FILE := 27000@icarray-virtual-machine
include ../scripts/make/vcs-2018.mk

TEST ?= upstream_sanity
SEED ?= 1

# M0：vendor 依赖 + axi 全库 + 上游 sanity tb（非 UVM，以 $stop 结束）。
# M1+：追加 flist/tb.f、切换 TOP 至 UVM tb_top、run 规则加
# +UVM_TESTNAME=$(TEST)。用 TEST 名字挑选：TEST=upstream_sanity 走 M0 上游
# tb（M0-01 repro `make run TEST=upstream_sanity SEED=1` 保持不变），其余
# TEST 名字一律视为 M1+ UVM 测试名。
ifeq ($(TEST),upstream_sanity)
FLISTS := -f flist/vendor.f -f flist/dut.f -f flist/tb_upstream.f
TOP    := tb_axi_xbar
IS_UVM := 0
# BUG-0037 fix: M0 (TOP=tb_axi_xbar) is a structurally different design
# from every M1+ UVM test (TOP=tb_top) and must not share the default
# out/cov.vdb coverage database with them (VCS's urg merge emits
# CMR-VCINF/UCAPI-INSTANCEMISMATCH when asked to merge incompatible
# top-level designs). Redirect only the coverage DB, not OUT itself, so
# the build product (out/simv) and `make clean`'s scope (bare `make
# clean` still wipes the whole $(OUT) tree, unaffected by TEST's default
# value of upstream_sanity) are unchanged. 见 git show v0.5.3-pre-reset:doc/fw-feedback.md FB-30.
COV_DIR := $(OUT)/m0/cov.vdb
else
FLISTS := -f flist/vendor.f -f flist/dut.f -f flist/tb.f
TOP    := tb_top
IS_UVM := 1
endif

# M3 config-point selection (design-prompt tb_top.md §5 C5.1/C5.2): the config
# point is chosen by TEST name and gets its OWN `+define` + build directory, so
# a config never reuses another config's elaborated simv — the silent-pass
# hazard behind BUG-0022 (lint 假绿) / BUG-0028 (分母缩水). C5.2 isolation is on
# the BUILD PRODUCT (simv/daidir in $(OUT)/cfgA), NOT the run log: the run log
# stays at the base out/ standard path ($(BASE_OUT)) so docs.py/regress.py
# default lookups (sim/out/{test}_{seed}.log) find it with no LOG= override and
# no scripts change — the log self-identifies its config via [CFG_REPORT] (C5.3)
# regardless of where the simv lives. Only the matched branch touches OUT;
# baseline TESTs fall through unchanged (no define, default OUT ⇒ build product,
# lint.log & FSDB paths bit-for-bit identical, C5.4 + guards BUG-0014/0020/0022
# untouched). Add a config point = one branch here + one `ifdef in
# tb/xbar_types_pkg.sv (C5.5). `override` so the config dir also holds under any
# outer OUT= (regress.py passes none today, but this keeps it robust).
BASE_OUT   := $(OUT)
CFG_DEFINE :=
ifneq ($(filter m3_cf01_%,$(TEST)),)
CFG_DEFINE := +define+XBAR_CFG_A
override OUT := $(OUT)/cfgA
endif
ifneq ($(filter m3_cf02_%,$(TEST)),)
CFG_DEFINE := +define+XBAR_CFG_B
override OUT := $(OUT)/cfgB
endif
ifneq ($(filter m3_cf03_%,$(TEST)),)
CFG_DEFINE := +define+XBAR_CFG_C
override OUT := $(OUT)/cfgC
endif
ifneq ($(filter m3_cf04_%,$(TEST)),)
CFG_DEFINE := +define+XBAR_CFG_D
override OUT := $(OUT)/cfgD
endif
# M4-FT01 (testplan.md M4-FT01, spec §0 row 3/§2.1): cfgE, same C5.1/C5.2
# pattern as cfgA-D above (own build product dir, run log stays at the base
# out/ path, no other TEST's build touched).
ifneq ($(filter m4_ft01_%,$(TEST)),)
CFG_DEFINE := +define+XBAR_CFG_E
override OUT := $(OUT)/cfgE
endif
RUN_LOG := $(BASE_OUT)/$(TEST)_$(SEED).log

# lint 门禁的判定范围与执行证明范围（BUG-0022）：本仓库交付的全部 tb 源文件。
# `include`-d class 文件也在内——它们同样承载 Lint 告警（见 doc/lint-baseline.md
# 按文件表），VCS 日志里以 "Parsing included file" 出现。
LINT_SRCS := $(shell find ../tb -name '*.sv' | sed 's|^\.\./tb/||' | sort)

.PHONY: compile run sanity smoke regress cov lint lint-run lint-diff verdi clean

# BUG-0037: mkdir also COV_DIR's parent -- for the baseline/cfg cases it
# equals $(OUT) already (no-op), but M0's COV_DIR lives one level under
# $(OUT) (out/m0/) without $(OUT) itself moving there, so it needs its own
# mkdir. 见 git show v0.5.3-pre-reset:doc/fw-feedback.md FB-30.
compile:
	@mkdir -p $(OUT) $(if $(filter 1,$(COV)),$(dir $(COV_DIR)))
	$(VCS) $(VCS_FLAGS_2018) $(if $(filter 1,$(COV)),$(CM)) $(CFG_DEFINE) $(FLISTS) \
	  -top $(TOP) -o $(OUT)/simv -l $(OUT)/comp.log

# 上游 tb 以 $stop 结束 → ucli 脚本驱动批处理；UVM tb_top 以 run_test()
# 内部 $finish 自然结束，不需要 ucli。SIM_OPTS_2018（-assert verbose）
# 不可省：sva_enforce 下 docs.py/regress.py 依赖其原生 "Summary: N
# assertions" 行，缺行即 fail-closed（拒收证据）。+ntb_random_seed 为 SV
# RNG 种子（M0/M1 通用）。
#
# 可选波形（BUG-0020）：FSDB=1 才 dump，产出 $(OUT)/wave.fsdb 供 verdi:/xdebug
# 使用。dump 有仿真时间与磁盘代价，故**不进默认路径**——证据链主链路
# （make run / make regress）的成本不因调试能力抬高。实现上只改 runtime：
# $fsdbDump* 由已常开的 Verdi PLI（$(NOVAS)）注册，-debug_access+all -kdb 本就
# 在 VCS_FLAGS_2018 里，因此 FSDB=1 与否**编译旗标逐字相同**、不触发重编。
ifeq ($(FSDB),1)
UCLI := -ucli -i $(OUT)/wave.ucli
else ifeq ($(IS_UVM),1)
UCLI :=
else
UCLI := -ucli -i $(OUT)/run.ucli
endif

run: compile
ifeq ($(FSDB),1)
	printf 'call {$$fsdbDumpfile("%s")}\ncall {$$fsdbDumpvars(0, "%s")}\nrun\nexit\n' \
	  "$(OUT)/wave.fsdb" "$(TOP)" > $(OUT)/wave.ucli
else ifeq ($(IS_UVM),0)
	echo "run; exit" > $(OUT)/run.ucli
endif
	$(OUT)/simv $(SIM_OPTS_2018) $(if $(filter 1,$(IS_UVM)),+UVM_TESTNAME=$(TEST)) \
	  +ntb_random_seed=$(SEED) \
	  $(if $(filter 1,$(COV)),$(CM) -cm_name $(TEST)_$(SEED)) \
	  $(UCLI) -l $(RUN_LOG)

sanity: run
smoke: run

regress:
	@python3 ../scripts/regress.py $(if $(filter 1,$(COV)),COV=1)

# BUG-0037: -dir now $(COV_DIR), not a hardcoded $(OUT)/cov.vdb, so a query
# for a given TEST/OUT resolves to the SAME db that `make run` for that
# TEST actually wrote into (see the TEST=upstream_sanity/cfgA-D overrides
# above). 见 git show v0.5.3-pre-reset:doc/fw-feedback.md FB-30.
cov:
	urg -full64 -dir $(COV_DIR) -report $(OUT)/urgReport

# lint 判定范围 = ../tb/（本仓库交付物；vendor 与 UVM 库告警不计入）。
# 复用 VCS_FLAGS_2018（含 -assert svaext，vendor 侧 elaboration system task
# 需要，见 BUG-0014）而非手写第二份旗标列表，避免与 compile/run 目标失配。
# -top $(TOP)（同 compile:/run:）：缺省时 VCS 对全量 flist 做多顶层枚举，
# 撞上 vendor 测试专用 wrapper 模块的未约束参数（见 BUG-0019）。
#
# lint-run = 执行 lint 并**自证本次真的执行了**（BUG-0022 的修复所在）。
# 假绿路径：VCS 设计未变时走增量，不重新分析源码、不产生任何 Lint- 行，却
# 仍以 -l 覆写 lint.log ⇒ 「没执行」与「执行且干净」在日志上同形。两道防线：
#   (a) 删 .vcs.timestamp 强制全量重编——从源头消灭增量命中；
#   (b) 校验日志里 ../tb/ 下**每一个**源文件都被本次分析过——执行证明与被
#       检查内容逐文件绑定。(b) 不只是 (a) 的冗余：它同时堵住「摘 flist 文件
#       让 lint 变绿」的分母缩水路径，且在 (a) 失效（VCS 换 timestamp 位置、
#       或有人删掉那行）时仍然报红。判据只增不减，过滤范围未动。
lint-run:
	@mkdir -p $(OUT)
	@rm -f $(OUT)/simv_lint.daidir/.vcs.timestamp
	$(VCS) $(VCS_FLAGS_2018) +lint=all,noVCDE $(CFG_DEFINE) $(FLISTS) -top $(TOP) \
	  -o $(OUT)/simv_lint -l $(OUT)/lint.log
	@fail=0; for f in $(LINT_SRCS); do \
	  grep -q "Parsing .* file '\.\./tb/$$f'" $(OUT)/lint.log || \
	    { echo "[LINT-GATE] 本次未分析: tb/$$f"; fail=1; }; \
	done; \
	if [ $$fail -ne 0 ]; then \
	  echo "[LINT-GATE][FAIL] 本次 lint 未覆盖 ../tb/ 全部 $(words $(LINT_SRCS)) 个源文件"; \
	  echo "  → 常见原因：TEST=$(TEST) 的 flist 不含 ../tb/（upstream_sanity 即如此）、"; \
	  echo "     flist/tb.f 摘了文件、或 VCS 增量编译命中（BUG-0022）。"; \
	  echo "  → 「没看到 Lint 行」不等于「lint 通过」，本次结论作废。"; \
	  exit 1; \
	fi; \
	echo "[LINT-GATE] 执行证明 OK：TEST=$(TEST) 本次分析了 ../tb/ 全部 $(words $(LINT_SRCS)) 个源文件"

lint: lint-run
	@if grep -A1 '^Lint-\[' $(OUT)/lint.log | grep -qE '^\.\./tb/'; then \
	  grep -A1 '^Lint-\[' $(OUT)/lint.log | grep -B1 -E '^\.\./tb/'; exit 1; \
	else echo "lint clean within ../tb/ scope"; fi

# 里程碑守卫（BUG-0021 转 WONTFIX 后的载体，见 doc/lint-baseline.md）：
# 与基线差分，出现新类别或新站点即报红。它不自己跑 VCS，而是复用 lint-run
# ——执行证明因此不可绕过：没真跑 lint 就到不了差分这一步。
lint-diff: lint-run
	@python3 lintdiff.py $(OUT)/lint.log ../doc/lint-baseline.md

# 波形消费者。产波形先 `make run TEST=<t> SEED=<n> FSDB=1`。
# xdebug 另需一份**干净**的 EDA 环境（本卡实测，四项缺一即 npi_init.failed）：
#   VERDI_HOME / VCS_HOME / LM_LICENSE_FILE 三者必须有值，且
#   LD_LIBRARY_PATH 恰为 $$VERDI_HOME/share/PLI/VCS/LINUX64——尾部空元素
#   （形如 "...LINUX64:"）同样会让 NPI 初始化失败。故用 env -i 起干净环境调用
#   $$XVERIF_ROOT/tools/xdebug，不要继承当前 shell 的 LD_LIBRARY_PATH。
verdi:
	verdi -ssf $(OUT)/wave.fsdb &

clean:
	rm -rf $(OUT) csrc simv* *.daidir ucli.key vc_hdrs.h novas.* verdiLog \
	  nWaveLog DVEfiles axi_log
