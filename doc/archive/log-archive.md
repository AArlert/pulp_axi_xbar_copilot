# Log archive (newest first)

## [0.5.6] 2026-08-03 M5 第一张活：失败可追溯机制落地

**Done**
- 摸清现状：scoreboard ~22 处 `uvm_error 中约 15 处已是"实际/期望/spec§"
  三段式，真正缺口是 (1) seed 不在报错附近（只在 log 第 1 行 Command:
  banner）(2) `report_phase` 五处"悬挂"类报错三处是纯聚合计数，连是哪个
  id/port 都不报。据此收窄范围，未动已经写得好的比对类报错，未动 6 个
  SVA 文件。
- 新增 `tb/report_seed_catcher.sv`：全局 `uvm_report_catcher`，给每条
  UVM_ERROR/FATAL 追加 `[seed=N]`（`$value$plusargs("ntb_random_seed=%d")`
  回读 sim/Makefile 传的同一 plusarg），`test_lib.sv` base_test 注册一处，
  零改动既有调用点，SVA 的 `uvm_error 一并覆盖（同一 uvm_root 回调池）。
- `pend_rec_t`/`atop_pend_t` 补 `time accept_time` 字段并在创建点回填；
  SB_ROUTE/SB_WDATA_LEN/SB_WDATA/SB_ATOP_DANGLING 带上 accept_time，
  SB_RESP_DANGLING 补 slv-id。
- `report_phase` 三处纯聚合计数改造：SB_DANGLING（pending_by_id）/
  SB_OR_DANGLING（or_open_q）/SB_WORDER_DANGLING（worder_pend）从
  "%0d 条记录未匹配"改为逐记录 `uvm_error`（port/dir/bucket/id/
  accept_time，从 key 位运算还原，与各自 key-builder 函数对齐），计数用的
  原 foreach 循环不动（SB_SUMMARY 数字来源不变），只换 `if (total!=0)` 里
  的单条聚合改成逐记录 foreach——触发条件（非空⟺有错）不变。
- rev 评审（checker/oracle 设计评审）verdict PASS：无 silent-pass、无
  RTL 值泄漏为期望值、无 latency-bake、`accept_time` 无未初始化读取路径；
  1 处措辞类 nit（seed catcher 注释误导，已改）。
- 现场验证（故意破坏后复原，非纸面评审）：破坏 `build_exp_id` 强制全部
  `pending_by_id` 查找落空——SB_DANGLING 精确触发 333 次，与 SB_SUMMARY
  `pending=333` 完全对齐（UVM 自带 per-id 计数交叉核对）；破坏
  `rec.addr` 触发 SB_ROUTE，消息含 seed+accept_time+got/expected/spec§，
  自包含可读。两处破坏均已还原（grep TEMP-DELIBERATE-BREAK 为空）。
- milestone.md M5 exit criteria 第一条打勾。

**Not done**
- M5 其余四条 exit criteria：约束随机层、多种子回归、soak、BUG-0044 裁决。

**Next**
- M5 第二张活：约束随机激励层（`xbar_random_vseq`，milestone.md 已有约束
  设计蒸馏），先注册 M5-RN01..03/SK01..03 六行 testplan 骨架。

**How verified**
- `make regress` 30/30（改动前后各跑一次，改动后现场注入两类失败观察新
  报错格式后还原复绿）；rev 独立评审 PASS；`make check` 绿。

## [0.5.5] 2026-08-03 M5 步 0：VM 内 make regress 确认接手基线绿

**Done**
- VM 内（icarray-virtual-machine，VCS O-2018.09-SP2 + xverif 均在）跑
  `make regress`：30/30 PASS（M0 1 + M1 2 + M2 8 + M3 11 + M4 8），无
  `--wipe`，复用既有 `sim/out/` 增量构建；summary 见
  `sim/result_summary.txt`。确认前任留下的基线在接手环境下活着，M5 步 0
  完成，可以开始写 M5 代码。
- 顺手修 `milestone.md` 步 0 一处笔误："24 场景"→"30 场景"（与 testplan
  实际行数对齐，无独立登记）。

**Not done**
- M5 五条 exit criteria 均未动：失败可追溯机制（第一张活）、约束随机层、
  多种子回归、soak、BUG-0044 裁决。

**Next**
- M5 第一张活：失败可追溯机制——评估现 scoreboard/SVA 报错形态，改造为
  失败自包含（seed+轨迹+DUT/期望/spec 三方文本），见 `milestone.md` M5
  exit criteria 第一条。

**How verified**
- `make regress` 退出码 0，`sim/result_summary.txt` 30 行全 PASS。

## [0.5.4] 2026-08-03 大重置：拆除仪式层，以接手者姿态进入 M5

**Done**
- 用户裁决执行：文档/流程仪式整体拆除（doc 从 3.6MB/234 文件砍到核心集）。
  删：`workflow/` 四细则、`doc/review`（1.1M）、`doc/evidence` 存档（828K）、
  `doc/archive` 旧内容、终态 bug 单页（仅留 BUG-0044）、`doc/design-prompt`
  （干货已蒸馏进 `doc/uvm.md`/`doc/milestone.md`）、guards/fw-feedback/
  code-suggestion、arch/de/dv 三个 agent、全部 skills、`scripts/tests` 60 单测。
  现场先锁 `git tag v0.5.3-pre-reset`。
- 机械层收编为单脚本：`scripts/docs.py`（handoff/next/check/archive/evidence/
  bump，evidence.py 与 bump.py 并入，无 cmd_ 前缀）；Makefile 同步收缩；
  `iverif_config.py` 瘦身（svacheck/regress 仍依赖）。
- spec 就地裁决（原 BUG-0074）：§4 clause 7 与 §8 clause 3 两条环境约束由
  "M3/M4"逐字作用域改为**里程碑无关**写法（随机层须编码进 constraint），
  Change record 表与 sha256 pin 机制删除（git 即历史）。
- CLAUDE.md 重写（接手叙事 + 两条红线）；bugs.md 重建（五类速查 + 总表，
  仅存 BUG-0044）；milestone.md M5/M6 重写（含约束设计蒸馏、6 行场景骨架、
  反稀释四条）；uvm.md/axi.md/README 清死链；记忆文件清零重开。

**Not done**
- M5 步 0（VM 内 `make regress` 确认接手基线全绿）——本机无 VCS，未跑。
- testplan 的 M5 六行场景尚未注册（等基线确认后落）。

**Next**
- VM 内 `make regress` 跑一遍确认基线绿；然后 M5 第一张活：失败可追溯机制
  （失败报告自包含 seed+轨迹+DUT/期望/spec 三方文本），见 milestone.md M5。

**How verified**
- `make check` 绿（瘦身版门禁）；`make handoff`/`make next` 输出正常；
  `python3 -m py_compile scripts/*.py` 全过；旧产物引用统一注记脚本跑过
  （testplan/axi.md/coverage-waivers/BUG-0044 四文件加注）；仿真未跑（见上）。
