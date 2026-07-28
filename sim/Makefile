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
else
FLISTS := -f flist/vendor.f -f flist/dut.f -f flist/tb.f
TOP    := tb_top
IS_UVM := 1
endif

.PHONY: compile run sanity smoke regress cov lint verdi clean

compile:
	@mkdir -p $(OUT)
	$(VCS) $(VCS_FLAGS_2018) $(if $(filter 1,$(COV)),$(CM)) $(FLISTS) \
	  -top $(TOP) -o $(OUT)/simv -l $(OUT)/comp.log

# 上游 tb 以 $stop 结束 → ucli 脚本驱动批处理；UVM tb_top 以 run_test()
# 内部 $finish 自然结束，不需要 ucli。SIM_OPTS_2018（-assert verbose）
# 不可省：sva_enforce 下 evidence.py/regress.py 依赖其原生 "Summary: N
# assertions" 行，缺行即 fail-closed（拒收证据）。+ntb_random_seed 为 SV
# RNG 种子（M0/M1 通用）。
run: compile
ifeq ($(IS_UVM),1)
	$(OUT)/simv $(SIM_OPTS_2018) +UVM_TESTNAME=$(TEST) \
	  +ntb_random_seed=$(SEED) \
	  $(if $(filter 1,$(COV)),$(CM) -cm_name $(TEST)_$(SEED)) \
	  -l $(OUT)/$(TEST)_$(SEED).log
else
	echo "run; exit" > $(OUT)/run.ucli
	$(OUT)/simv $(SIM_OPTS_2018) +ntb_random_seed=$(SEED) \
	  $(if $(filter 1,$(COV)),$(CM) -cm_name $(TEST)_$(SEED)) \
	  -ucli -i $(OUT)/run.ucli -l $(OUT)/$(TEST)_$(SEED).log
endif

sanity: run
smoke: run

regress:
	@python3 ../scripts/regress.py $(if $(filter 1,$(COV)),COV=1)

cov:
	urg -full64 -dir $(OUT)/cov.vdb -report $(OUT)/urgReport

# lint 判定范围 = ../tb/（本仓库交付物；vendor 与 UVM 库告警不计入）。
# 复用 VCS_FLAGS_2018（含 -assert svaext，vendor 侧 elaboration system task
# 需要，见 BUG-0014）而非手写第二份旗标列表，避免与 compile/run 目标失配。
# -top $(TOP)（同 compile:/run:）：缺省时 VCS 对全量 flist 做多顶层枚举，
# 撞上 vendor 测试专用 wrapper 模块的未约束参数（见 BUG-0019）。
lint:
	@mkdir -p $(OUT)
	$(VCS) $(VCS_FLAGS_2018) +lint=all,noVCDE $(FLISTS) -top $(TOP) \
	  -o $(OUT)/simv_lint -l $(OUT)/lint.log
	@if grep -A1 '^Lint-\[' $(OUT)/lint.log | grep -qE '^\.\./tb/'; then \
	  grep -A1 '^Lint-\[' $(OUT)/lint.log | grep -B1 -E '^\.\./tb/'; exit 1; \
	else echo "lint clean within ../tb/ scope"; fi

verdi:
	verdi -ssf $(OUT)/wave.fsdb &

clean:
	rm -rf $(OUT) csrc simv* *.daidir ucli.key vc_hdrs.h novas.* verdiLog \
	  nWaveLog DVEfiles axi_log
