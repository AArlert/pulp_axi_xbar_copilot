# Work log

滚动工作日志（最新在前，块数超限经 `make archive` 滚入 `doc/archive/`）。
每块回答四问：done / not done / next / how verified。0.5.4 之前的历史
见 `git show v0.5.3-pre-reset:doc/log.md` 及其归档。

## [0.5.9] 2026-08-03 M5 全 6 行翻绿（Slice 2-4 交付）

**Done**
- Slice 2（M5-SK02/SK03/RN03）：纯复用 `xbar_soak_vseq`，各 config point
  新增 test class + Makefile `TEST` 前缀→`+define` 映射。SK02 cfgB（6×1）
  `resp_hold=20`（6 端口汇聚到 1 个 responder，100 会顶 watchdog）；
  SK03 cfgA（1×8）/RN03 cfgE `resp_hold=100`。rev 发现 SK03 仅 1 个 slave
  端口 + `num_rounds=4` 最多只访问 4/8 个 master 端口——追加 target sweep
  （`fire_round` 遍历每个 round 0 未命中的 master 端口）；cfgA 下+7 sweep
  项，cfgB/baseline 下+0/~7 项，watchdog 余量充足。全回归 35/35。
- Slice 3（M5-RN02 cfgD）：新建 `xbar_soak_cfgd_seq`（继承 `xbar_soak_seq`，
  override `body()`）+ `xbar_soak_cfgd_vseq`。`cfgd_region()` 将逻辑目标
  映射到地址区域（mst0/mst1 走 rule region，default port 走 unmapped
  region `NO_ADDR_RULES*REGION_SIZE`=0x8000_0000）；target 限定于
  `CONNECTIVITY[slv_port_idx]`；default-port config 沿用 m3_cf04 同一
  `set_cfgd_default()` 模式。rev PASS + 清理 dead `def_port` 变量。36/36。
- Slice 4（M5-RN01 cfgC UniqueIds=1）：`drive_burst()` 逐 burst 全排空
  响应（`wait(done_cnt>=total)` + `item_done()`），故 `fire_round()` 间
  无跨 burst 在飞重叠——SPEC-5.3.1 结构性保证，无需运行时 ID 分配器。
  peak burst 15 项同桶 ID 循环（{0,8,16,24} 各 3-4 次）在 resp_hold=100
  下同时在飞同目标，覆盖"合法堆积"分支。`SB_UNIQUEIDS_SUMMARY:
  violations=0`。rev PASS；testplan M5-RN01 行描述更新为结构性方案
  （原文描述"集中 ID 分配器"与实现不符）。36/36。
- 每片 rev 独立评审 PASS（Slice 2/3/4 各一轮，共 3 次 rev 调用）。

**Not done**
- BUG-0044 仍 OPEN（ATOP store/swap/compare 无 oracle）。
- M5 多种子回归未跑（当前每行仅 SEED=1）。
- M6（覆盖率收敛）未启动。

**Next**
- BUG-0044 裁决（补 spec §6 条款 or 书面标范围外）。
- M5 多种子回归（`make regress` 扩充 SEED 列表，验证随机层稳定性）。
- M6 覆盖率收敛（`doc/milestone.md`）。

**How verified**
- `make regress` 36/36（含 M5 全 6 行：SK01/SK02/SK03/RN01/RN02/RN03）。
- 每 Slice 独立 rev 评审 PASS（3 轮）。
- 关键覆盖：cg_xbucket_total 每行 100%；RN02 cg_default_port_tracked
  100%（13 samples）；RN01 SB_UNIQUEIDS_SUMMARY violations=0。
- `make check` 绿；`make evidence` 逐行收集。

## [0.5.8] 2026-08-03 M5-SK01 落地（Slice 1/4）；新流程：每闭环强制 rev 门禁

**Done**
- 用户确立新标准流程（此后默认适用）：任务切成可闭环小片；每片做完必须
  派 rev 独立评审；rev prompt 不带我的推理叙事（只给改了什么/在哪 + 客观
  要求原文 + charter 维度，不塞"我验证过 X"）；rev 过了才 git push。
- 把"M5 第二张活"切成 4 片（TaskCreate #7-10）：Slice1=核心机制+M5-SK01
  (baseline)、Slice2=纯复用 SK02/SK03/RN03、Slice3=cfgD+RN02、
  Slice4=cfgC ID 分配器+RN01。
- 摸清驱动模型：`axi_seq_item`/`drive_write`/`drive_read` 单笔阻塞（等
  B/R 才 item_done），建不了同桶在飞深度；`axi_burst_item`/`drive_burst`
  才能背靠背下发多笔（M2-TL01/M3-TL01 先例），且必须配 `resp_hold`（否则
  响应即时回收、深度"空转"——现场验证过：不设 resp_hold 时
  `cg_xbucket_total` samples=0）。
- 落地 `tb/seq_lib.sv`：`xbar_soak_seq`/`xbar_soak_vseq`（复用
  `build_txlimit_burst`+`fanout_per_slv`，未新增底层机制）；round 0 是
  确定性"peak"轮（bucket0 压到 SPEC-5.4.1 结构有效上限 15、bucket1=3 同时
  非空，每颗种子必中，不靠随机撞）；其余 3 轮小幅随机（桶/深度/方向/
  目标端口）。`tb/test_lib.sv` 新增 `m5_sk01_soak_test`（resp_hold=100）。
- rev 独立评审 verdict PASS（现场读 raw log/coverage feeder 交叉核对，非
  信任 testplan 行文字）：确认 cg_tx_limit `at_effective_ceiling`（15）与
  cg_xbucket_total 均真实命中、无 RTL 值泄漏为期望值、无 silent-pass。
  2 处非阻塞发现已处理：①（中）我自己写的"worst case 72000ns 安全"注释
  算漏了跨端口叠加到同一 responder 的情形（真实最坏~234000ns 可能顶到
  watchdog）——收窄随机轮深度上限 6→3，重算最坏情形 144000ns 留足余量；
  ②（低）`xbar_random_vseq` 这个名字是 milestone.md 留给未来真正
  rand/constraint 求解通用层的，本实现无 rand/constraint 块，占用会话
  RN0x 实现时的语义——更名 `xbar_soak_vseq`，同步改 testplan M5-SK01 行。
- `make evidence SCEN=M5-SK01`；`sim/regress/regress.list` 新增一行。

**Not done**
- Slice 2/3/4（M5-SK02/SK03/RN01/RN02/RN03）未动。

**Next**
- Slice 2：M5-SK02（cfgB）/SK03（cfgA）/RN03（cfgE）——纯复用
  `xbar_soak_vseq`，各自新 test class + sim/Makefile 加 TEST 名前缀→
  `+define` 映射（当前只有 m3_cf01../m3_cf04../m4_ft01_ 前缀，M5 测试名
  需要新增对应行）。

**How verified**
- `make regress` 31/31（改前 30/31 基线 + 改后两次，rename/收窄后重跑
  确认 corner 仍命中：cg_tx_limit cp_inflight=100%、cg_xbucket_total
  samples=36/100%，Time=57925000ps < watchdog 200000000ps）；rev 独立
  评审 PASS；`make check` 绿。

## [0.5.7] 2026-08-03 文档漂移修复：M5 六行注册进 testplan.md（真值表归位）

**Done**
- 用户指出潜在文档漂移：milestone.md 的"场景骨架（6 行）"表（id/config/
  内容）号称"注册进 testplan 时逐行落判据"，但一直未真正注册——
  testplan.md 才是 CLAUDE.md 定义的场景真值表，milestone.md 只是进度表，
  两处并存同形表格是真实漂移风险（而非已经漂移，因为内容还没来得及分岔，
  但下一次任一处被单独改动就会分岔）。核实：`testplan.md` 自己的表头就写
  明"Register rows BEFORE coding"；`scripts/docs.py` 的 `update_row`/
  `row_exists` 只改已存在行，不建行——注册新行必须是人工步骤，机械脚本
  不代劳。历史沿用的"未开始"状态符号是 `🔲`（评审/证据列留 `-`），git log
  证实（重置前 59 处 `🔲`、55 处 `-`）。
- 补齐 6 行 M5-RN01/RN02/RN03/SK01/SK02/SK03 到 testplan.md（status 🔲，
  evidence/repro 留 `-`），每行落判据（oracle 复用现有 scoreboard/SVA、
  spec 锚点、反稀释"必须真正到达"角落、适用红线），而非照抄 milestone.md
  的一句话摘要——testplan 行本身要自包含。
- milestone.md 的"场景骨架"表整块移除，改一段指回 testplan.md 的指针
  （"场景真值表以 testplan.md 为准，本页不重复维护该表"），只保留仍然
  正确归属 milestone.md 的共享设计依据（约束设计要点、反稀释四条）。
- `make check`/`make next` 验证：`make next` 现在正确列出 6 个 M5 open
  scenarios（此前一直是"M5 has no testplan rows yet"），确认机械推导层
  与真实状态对齐。

**Not done**
- 6 行仍是 🔲（判据已落但代码未写）——M5 第二张活：约束随机层
  `xbar_random_vseq` 待实现，实现后逐行 `make evidence` 转绿。

**Next**
- 写 `xbar_random_vseq`（milestone.md 约束设计要点：len/addr/id/atop 四
  类硬软约束），先落 cfgC 一行（M5-RN01，集中 ID 分配器）跑通，再横向铺
  其余 5 行。

**How verified**
- `make check` 绿；`make next` 输出从"M5 has no testplan rows yet"变为
  列出 6 个具体 open scenario id，确认真值表与机械推导层对齐；6 行列数
  逐行核对（7 列/8 个竖线，与表头一致）。

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
