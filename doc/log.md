# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.4.14] 2026-08-01 M4 完整签核卡：REJECTED——四条机器门禁全绿不等于签核，覆盖率定义性出口条件未满足；新登记 BUG-0047（判据可行性张力）

**背景**：0.4.9-0.4.13 五个周期把 `make check MILESTONE=4` 的四条机器
门禁逐条转绿（场景 ✅、regress evidence、bug 终态、KILL 覆盖）。本周期
派出全套 rev 签核 rubric 卡，本以为是收尾的最后一步，结果卡本身给出了
**REJECTED** 判决——这是本轮 M4 收尾里最重要的一次纠偏：机器门禁全绿
从未等于"可以签核"，签核判的是"证据是否支撑风险已收敛"。

**Done**
- **M4 完整签核卡（L3/opus，fresh instance，与本轮全部 M4 相关卡作者
  均不共享）**产出 `doc/evidence/v0.4.13/signoff-M4.md`。逐项：
  - **机器条件（rubric #1-4）**：亲跑确认全绿，但明确指出机器脚本
    `scripts/docs.py` **不检查覆盖率百分比**——四条绿只覆盖"场景/
    证据/bug 状态/KILL"，不覆盖 M4 的定义性出口条件本身。
  - **rubric #5**（coverage closure≠risk closure）：挑 3 个良好命中
    bin 逐一核实确系预期场景命中（含 `axi_mux` 仲裁重试路径的
    "模块级 100% 实为跨 8 实例并集、实际仅 1/8 端口真转绿"这一颗粒度
    警示）；重读 atop_filter 环境约束不可达论证并**活体证伪**佐证
    （注入 atop 到未命中地址后 FSM 确实 engage）。
  - **rubric #6**（guard 消费+证伪）：实地证伪 BUG-0032 guard——注入
    `atop=6'h30` 到 M3-DE01 未命中序列，`SB_ATOP_DECODE` 6 端口报红；
    恢复后 `git diff` 净。
  - **rubric #7/#8**（spec debt / accepted debt）：BUG-0044/0045/0046
    均确认有可证伪解锁条件、非软承诺。
  - **rubric #9**（chain audit）：逐类给处置意见。
  - **REV-017 条件 3 正式兑现**：atop_filter FSM 书面豁免（逐弧列出
    未覆盖状态/迁移，行号对当前 vendor 树逐条复核——orch 独立复验
    `grep vendor/axi/src/axi_atop_filter.sv` 确认 BLOCK_AW:151/
    HOLD_B:161/INJECT_B:163/ABSORB_W:167/WAIT_R:228/R_HOLD:275/
    INJECT_R:281 全部准确）+ BUG-0032 guard 机械抽查（grep + 计数=0
    两种形态均满足）。
  - **核心否决理由**：M4-coverage-baseline.md §6 的 ~9 类残余缺口里
    只有 2 类得到合法处置（atop_filter 环境约束豁免 + addr_decode/
    axi_demux 结构性 N/A），其余 ~6 类（`axi_demux_simple`/
    `addr_decode_dync`/`axi_mux` Toggle/`axi_err_slv`/`spill_register`
    等）是"可达但未测"——按 REV-016 §9，豁免须给可证伪的不可达论证，
    这些是"没测"非"测不到"，**不可合法豁免，必须补定向场景**。
  - **附带发现并建议登记的方法学张力**：M4 出口条件"六类含 Toggle
    ≥90%"与项目"M5 前仅定向、随机不得替代 M4 定向关闭"纪律叠加，对
    宽 AXI 总线的 Toggle bin 产生可行性冲突——两条规则各自无误，组合
    时无解，需 rev/arch 后续裁决扩展豁免框架或重议判据口径。
- **orch 独立复验**（不采信卡内自报）：`git status`/`git diff` 确认
  falsification 改动已完全恢复；`make check MILESTONE=4` 复跑确认四条
  仍绿、签核文件条目转"yes"；`grep vendor/axi/src/axi_atop_filter.sv`
  逐行核对 FSM 豁免的 7 处行号（100% 命中）；`sed` 核对 BUG-0032
  guard 的注入点（`tb/seq_lib.sv:962` `atop='0`）与检测点
  （`tb/scoreboard_refmodel.sv:469-472` `SB_ATOP_DECODE`）均如实存在。
- **orch 按无条件登记纪律登记 BUG-0047**（OPEN，spec，SPEC_ISSUE 候选，
  非本条自身触发失败——是签核卡的附带发现）：M4 出口条件与"M5 前仅
  定向"纪律的可行性张力，详见 `doc/bugs/BUG-0047.md`。
- `make check`/`make selftest`（61/61）复跑绿。**`doc/milestone.md` M4
  状态维持 🔲，不转 ✅**（rev 明确裁决，未由 orch 越权改动）。

**Not done**
- M4 仍未签核。REJECTED verdict 给出的后续方向（signoff 记录已列，
  非本周期落地）：
  1. DV 定向覆盖卡（针对 ~6 类"可达但未测"缺口，逐（模块,类型）补
     spec 引用+可证伪具名场景）；
  2. rev 覆盖率豁免卡（先建 `doc/coverage-waivers.md`，为 `rst_ni`/
     `test_i` scan/AW valid-but-not-ready 断言类等真正需要论证的项
     出具可证伪不可达论证）；
  3. **BUG-0047 方法学张力裁决**（arch/rev，二选一：成本豁免扩展 /
     重议 Toggle 判据口径）——这条建议先走，因为它决定其余 Toggle
     类缺口该走"补场景"还是"豁免"这条路；
  4. feature-matrix 补 4 行（M4-RC01/AW01/OV01/FT01，chain audit
     既有 gap）。
- 上述四项工作量不小，且互相有依赖（尤其 3 影响 1 的范围），需要用户
  确认优先级/是否现在就铺开，不是一次性能收尾的小任务。

**Next**
- 向用户汇报 REJECTED 判决全貌，请用户决定：先处理 BUG-0047 方法学
  张力裁决，还是先铺开 DV 定向覆盖卡补场景，还是先建
  `doc/coverage-waivers.md` 做豁免分诊，或调整 M4 出口条件本身的
  优先级安排。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：4/4 机器门禁仍 PASS（signoff 文件条目
  转"yes"，但 verdict 本身是 REJECTED——机器门禁与签核判断是两回事，
  本周期最大的一次认知纠偏）。
- 独立复验详见 Done 段——FSM 行号逐条 grep 核对、guard 注入/检测点
  逐行核对、falsification 恢复用 git diff 核实为空。

## [0.4.13] 2026-08-01 M4 收尾第三项完成：BUG-0046 仲裁应用——`make check MILESTONE=4` 四条机器门禁全绿

**Done**
- **REV-023（独立 rev 实例）仲裁 BUG-0046**：补核许可来源
  `vendor/axi/doc/axi_xbar.md`（L26"must be less than or **equal to**"，
  非严格 `<=`）——**推翻**本条原登记的框架（当初误判"spec 蒸馏遗漏/spec
  允许 RTL 会炸"）。真相：`doc/spec.md` §3.2 条 2 的 `<=` 是这条权威文档
  的**忠实、正确蒸馏**，spec 侧无误；真实矛盾是**上游内部** doc-vs-RTL
  不一致（`axi_xbar.md` `<=` vs common_cells `addr_decode_dync.sv`
  `check_start` 断言 `<`，且该文件自身头注释 L26/L36-38 亦互相矛盾）。
  taxonomy 重框为该上游矛盾的 SPEC_ISSUE 变体，处置 **ACCEPTED@M5**
  （到期锚点与姐妹条 BUG-0045 对齐）——**独立否决"现在把 spec 收紧为
  `<`"**：该路径预设的"文字性错误、成本极低"前提经核实为假，收紧只会
  让 spec 偏离权威文档反向对齐 RTL（spec-from-RTL 红线）。给出可证伪
  解锁条件（任何场景构造 `start==end` 即作废）+ M5 到期二选一动作
  （DV 环境约束 + spec 注记两件套 / 具体论证转 WONTFIX）。
- **orch 应用裁决**（独立复核，未盲从）：`doc/bugs.md` BUG-0046 行
  `OPEN → ACCEPTED@M5`，`suspect` 由 `spec` 订正为 `upstream`（反映
  "spec 无误、根因上游不一致"），`summary`/`root_cause` 按 REV-023 的
  订正框架重写（不再说"spec 允许 RTL 会炸"），`verify_evidence` 点名
  REV-023；`doc/bugs/BUG-0046.md` 顶部加订正提示 + 重写 `## symptom`/
  `## taxonomy`/`## rca`（纠正失实归因）+ 新增 `## arbitration`（含
  addr_decode_dync 头注释内部自相矛盾的上游 issue 线索，并入本条不单开
  行）+ `## regression_guard` 补到期锚点（M5 + 点名 REV-023）。
- `make check`/`make selftest`（61/61）复跑绿。
- **`make check MILESTONE=4` 四条机器门禁全部转 PASS**：1. 全部 M4
  场景 ✅；2. regress evidence 已登记；3. 全部 bug 终态/ACCEPTED-
  unexpired；4. KILL 覆盖已登记（KILL-0004）。仅剩签核文件本身
  （`signoff-M4*.md` "not yet"）+ rev 人工 rubric（第 5-9 条）+
  REV-017 条件 3 未走。

**Not done**
- REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032 guard 机械抽查）
  仍未走——按 REV-017 原文，此条件挂在"M4 签核时"一并出具，非独立前置卡。
- 签核文件 `signoff-M4*.md` 未生成，rev 人工 rubric（`workflow/review.md`
  第 5-9 条：coverage closure 抽查、guards 证伪、SPEC_ISSUE 清单核对、
  ACCEPTED 债务可证伪性、chain audit 归档）未走。

**Next**
- 派完整 M4 签核卡（L3/opus/rev，fresh instance）：机器条件（已全绿）
  + rev 人工 rubric 七问/五条抽查 + REV-017 条件 3（FSM 书面豁免 +
  BUG-0032 guard 抽查）+ 产出 `doc/evidence/v0.4.*/signoff-M4.md`。
  **M4 签核本身不转版本**（v1.0.0 转段挂 M5 签核后，见 `doc/milestone.md`）。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：**4/4 机器门禁 PASS**（本周期完成条件 3
  最后一项）。
- 本周期无仿真运行（纯裁决应用），无新增 evidence/testplan 状态变化。

## [0.4.12] 2026-08-01 M4 收尾第三项（下半）：KILL-0004 登记（M4-OV01 tie-break 自证），M4 机器门禁 4 条中 3 条转 PASS

**Done**
- **DV 卡（L1/sonnet，fresh instance）**完成 M4-OV01 重叠 rule tie-break
  参考模型（`tb/xbar_types_pkg.sv` `decode_mst_port`）的注伤自证：临时给
  扫描全表的 `for` 循环加一行 `break;`，把 tie-break 从"扫描全表、后命中
  覆盖前命中（SPEC-3.1.3 高位置胜出）"改成"取第一个命中即停"。重跑
  `make run TEST=m4_ov01_overlap_test SEED=1`：注伤后 `route: match=12
  mismatch=48`、`UVM_ERROR:49`（DUT 仍正确路由到 port=7，即高位置
  `OV1_HIGH_RULE` 胜出；被注伤的参考模型错误期望 port=0，证明是 TB 侧
  故障非 DUT 问题）；恢复后同 SEED 复跑 `route: match=60 mismatch=0`、
  `UVM_ERROR:0`；全量回归 `make regress` 26/26 PASS。
- **orch 独立复验**：`git status`/`git diff tb/xbar_types_pkg.sv` 确认
  恢复后无残留改动（逐字节一致）；`sim/result_summary.txt` 交叉核对
  26 PASS/0 FAIL 与 `m4_ov01_overlap_test PASS` 一致；`make check`/
  `make selftest`（61/61）复跑绿。
- **orch 登记 KILL-0004**（`doc/bugs.md`，status=KILL，summary 含"M4"
  裸词满足机器门禁扫描）：完整转录注伤/恢复的具体数字、样本报文、重放
  命令，`fix_commit` 列填 `-`（自证记录非缺陷，无 fix 对象）。首次登记时
  误将 KILL-0004 行与紧随的 BUG-0046 行合并到同一物理行（Edit 工具替换
  时遗漏行边界），当场发现并修正——`grep`/`awk` 核实两行独立、8 列结构
  完整后 `make check` 复跑绿。
- `make check MILESTONE=4` 复跑：4 条机器门禁中 **3 条转 PASS**
  （1. 全部 M4 场景 ✅；2. regress evidence 已登记；4. KILL 覆盖已登记）；
  仅剩条件 3（`BUG-0046` 仍 OPEN，REV-023 仲裁中，见 Not done）。

**Not done**
- **条件 3**：`BUG-0046` 仍 OPEN，REV-023（独立 rev 实例）仲裁中，未交付。
- REV-017 条件 3、签核文件仍未动——待条件 3 转 PASS 后再派完整签核卡。

**Next**
1. REV-023 交付后，orch 应用裁决到 `doc/bugs.md`（预期 BUG-0046 转终态
   或 ACCEPTED，视裁决而定）。
2. `make check MILESTONE=4` 四条机器门禁全绿后，派完整 M4 签核卡（L3/opus/
   rev）：机器条件 + rev 人工 rubric + REV-017 条件 3（FSM 书面豁免 +
   BUG-0032 guard 抽查）+ `doc/evidence/v0.4.*/signoff-M4.md`。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：条件 1/2/4 PASS（较上次 1/2 PASS 有进展），
  条件 3 仍 FAIL（阻塞项 = BUG-0046，仲裁中）。
- 本周期无新 evidence 文件；`doc/bugs.md` 新增 1 行（KILL-0004）。

