# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.4.11] 2026-08-01 M4 收尾第三项（上半）：BUG-0045/0043 转终态，新登记 BUG-0046（同批发现的独立 spec-gap）

**Done**
- 并行派两张独立 rev 仲裁卡（L3/opus，各自 fresh instance，互不共享，均只产出
  裁决记录不改 bugs.md）+ 一张 M4 KILL 覆盖自证 DV 卡：
  - **REV-021 仲裁 BUG-0045**（spec §3.2 未载 `end_addr=='0` 末端哨兵）：
    独立核实（算术自验 8 条 rule 的 `end_addr` 不回绕到 0 + tb 全域构造点
    扫描）确认"当前无场景触及"为真——taxonomy 维持 SPEC_ISSUE（潜伏型，
    "完全未定义"支），处置 **ACCEPTED@M5**，排除"现在补 spec"（会造不可
    证伪 refmodel 死代码）与 WONTFIX（会永久埋没 RTL 全链路一等公民
    特性）。给出可证伪解锁条件（任何场景构造 `end_addr=='0` 即刻作废）+
    M5 到期二选一动作（覆盖哨兵走标准处置三件套 / 具体论证转 WONTFIX）+
    ready-to-apply 的 spec 条款草案备料。**核实过程中独立发现新缺口**：
    spec §3.2 条 2 `start_addr<=end_addr`（非严格）与 RTL `check_start`
    严格 `<` 约束松紧不符——独立、非阻塞，orch 按无条件登记纪律登记为
    **BUG-0046**（OPEN，spec，SPEC_ISSUE 候选）。
  - **REV-022 处置 BUG-0043**（间歇性 `make regress` 非零退出）：独立复算
    退出码机制归因（`rc!=0→FAIL` 是 `vcs-2018.mk` 明载的有意设计）+ 三次
    两清一异事实链，taxonomy 确认 TOOL_ENV，终态 **WONTFIX（accepted-
    transient）**——排除 `ACCEPTED@M<n>`（无可调度工作、无可证伪到期
    条件，强设只会把不可复现现象伪装成日程债）。给出收紧后的
    `regression_guard` 建议文本（声明终态、明确复现不重开本行、机械化
    TODO 写诚实——诊断采集方向而非自动重跑）。
  - **M4 KILL 覆盖自证卡**：仍在跑（见 Not done）。
- **orch 应用两张裁决**（独立复核裁决记录，非采信自报结论）：
  - `doc/bugs.md` BUG-0045 行 `OPEN → ACCEPTED@M5`（verify_evidence 点名
    REV-021）；`doc/bugs/BUG-0045.md` `## fix` 段落补裁决记录，
    `## regression_guard` 补到期锚点（M5 + 点名 REV-021）。
  - `doc/bugs.md` BUG-0043 行 `OPEN → WONTFIX`（`fix_commit`/
    `verify_evidence` 均 `-`，与既有 WONTFIX 行先例 BUG-0021/0024 写法
    一致；suspect 保持 TB，class=TOOL_ENV 记在详情页）；
    `doc/bugs/BUG-0043.md` `## fix` 补裁决记录，`## regression_guard`
    按 REV-022 建议文本整体替换（声明终态 + 复现处置 + 可证伪解锁 +
    不可机械化理由与唯一可行的诊断采集改进方向）。
  - **新登记 BUG-0046**（OPEN，spec，SPEC_ISSUE 候选，非阻塞）：`doc/spec.md`
    §3.2 条 2 用非严格 `<=`，RTL `check_start` 用严格 `<` 并对
    `start==end`（`end≠0`）的 rule 判 fatal——spec 允许 RTL 会炸的配置。
    与 BUG-0045 同源（同一次 REV-021 逐行核验）但内容/解锁条件独立，
    不合并登记（`doc/bugs/BUG-0046.md`）。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- **`make check MILESTONE=4` 条件 3 仍红，但阻塞项已从 BUG-0045/0043 转移
  到新登记的 BUG-0046**——已派 REV-023（并行）仲裁，待其交付后 orch 应用。
- **条件 4（KILL 覆盖）仍红**：M4-OV01 tie-break 的 KILL 自证 DV 卡仍在
  后台跑，交付后 orch 登记 KILL-0004 行。
- REV-017 条件 3、签核文件仍未动——待条件 3/4 转 PASS 后再派完整签核卡。

**Next**
1. REV-023（BUG-0046 仲裁）+ KILL 自证 DV 卡交付后，orch 应用两者到
   `doc/bugs.md`。
2. `make check MILESTONE=4` 四条机器门禁全绿后，派完整 M4 签核卡（L3/opus/
   rev）：机器条件 + rev 人工 rubric + REV-017 条件 3（FSM 书面豁免 +
   BUG-0032 guard 抽查）+ `doc/evidence/v0.4.*/signoff-M4.md`。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：条件 1/2 PASS，条件 3 阻塞项从"BUG-0045,
  BUG-0043"变为"BUG-0046"（净减少两项、新增一项，均为同批核验中独立
  发现，非遗漏），条件 4 仍 FAIL（KILL 自证进行中）。
- 本周期无仿真运行（纯裁决应用/登记），无新增 evidence/testplan 状态
  变化——`make evidence` 门禁不适用。

