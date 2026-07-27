# signoff-M1 — 里程碑 M1 签核记录

- 签核人：rev（独立实例；非本里程碑任何 review/fix 的当事人；未复用
  REV-002/003/004 的推理，仅作过程评审引用）
- 日期：2026-07-27
- 版本：v0.1.2（`version.json` = `{version: 0.1.2, milestone: M1}`；HEAD
  77f08e8，M1-02 卡工作树 + 本签核 pending 于 0.1.2 closeout 提交）
- 判据来源：`workflow/signoff/rubric.md`（机器条件 ×3 + 人工抽查 4/5/6）、
  `workflow/signoff/six_questions.md`
- 引用的过程评审（**引用不复述**，rubric L38–41）：
  - `doc/review/REV-002.md`（M1 design-prompt 集交付门 + behavior-leak 检查 +
    vendor v0.39.10 升级 memo 事实核验）
  - `doc/review/REV-003.md`（VCS-2018 `bind`→直接例化偏离复核，BUG-0007）
  - `doc/review/REV-004.md`（BUG-0008 处置仲裁 + CLAUDE.md 收成语义核验）
- **总体裁决：PASS**（带 2 项非阻塞残留风险，见 §3）

---

## 1. 机器条件（`make signoff-check` 自跑输出，未采信卡片粘贴）

```
[PASS] 1. all M1 scenarios ✅
[PASS] 2. regress summary registered as evidence (result_summary.txt in doc/evidence/v0.1.*)
[PASS] 3. all bugs terminal, closures evidenced
[not yet] signoff file (signoff-M1*.md) in doc/evidence/v0.1.*
```

- 条件 1：两条 M1 行 `M1-01`、`M1-02` 状态均 ✅（`doc/testplan.md:8-9`）。
- 条件 2：`doc/evidence/v0.1.2/result_summary.txt` = `passed=3/3`，
  逐行 `PASS upstream_sanity / m1_01_smoke_test / m1_02_id_prefix_test
  SEED=1`；回归清单 `sim/regress/regress.list` 含三守卫用例
  （`upstream_sanity 1` / `m1_01_smoke_test 1` / `m1_02_id_prefix_test 1`）
  ——每个已闭合 bug 的失败 seed 均永久入列。
- 条件 3：`doc/bugs.md` 四行全终态——BUG-0005 `SPEC_CHANGED`（M0 期）、
  BUG-0007 `CLOSED`（verify_evidence `v0.1.1/BUG-0007.log`）、BUG-0008
  `WONTFIX`（REV-004 Scope A 裁决，rca/rationale/guard 三要件齐备）、
  BUG-0009 `CLOSED`（verify_evidence `v0.1.2/M1-02.log`）。
  `fl_schema_enforce=true` 下 FL 详情页必填段非空，机器检查通过。
- `[not yet] signoff file` 即本文件，写入后满足 `docs.py --next` 的里程碑
  完成判定。

机器条件均 PASS。以下人工抽查由签核人独立执行，非机器可判。

---

## 2. 人工抽查

### 抽查 4 — 覆盖闭合 ≠ 风险闭合

**M1 尚无功能覆盖采集**（覆盖率六类从 M2/M4 起，见 CLAUDE.md §6 里程碑路
线图）。故 rubric L23–26 的"抽 2–3 命中 bin 核验其由目标场景命中、复读 1 个
豁免洞"在 M1 无对应 covergroup/waiver 客体——**不适用，显式声明而非静默跳
过**（与 signoff-M0 同处置）。

按该抽查的**精神**（"通过是否由目标机制达成、而非偶然/空跑"）对两条 M1 场
景**独立复跑源日志**核验（非仅采信已登记证据文件）：

**M1-01**（`make run TEST=m1_01_smoke_test SEED=1`，签核人本机复跑重生，
非采信 `doc/evidence/v0.1.0/M1-01.log`）：
- 目标机制（`doc/testplan.md:8`）：6 slave 端口各发命中地址表写/读 burst，
  scoreboard 参考模型校验路由目标（SPEC-3.1/3.2）、ID 前缀（SPEC-5.1）、
  数据完整性（SPEC-1）。
- 复跑尾部 `SB_SUMMARY`：`route: match=48 mismatch=0 | resp: match=48
  mismatch=0 | resp-route(C3.2): match=48 mismatch=0 | pending(unmatched at
  end)=0`；`UVM_ERROR: 0`；`Summary: 2119 assertions, 846 with attempts,
  0 with failures`；`$finish` 自然收敛。
- **反空跑核验**：scoreboard 记分板计数**非零**（route/resp/resp-route 各
  48 笔实打实配对、pending=0 即无悬挂），证明通过由目标激励命中达成，非
  0 事务的假通过。48 = 6 slave 端口 × 8 事务（写 + 读并发轮次），与
  testplan 场景形状一致。

**M1-02**（`make run TEST=m1_02_id_prefix_test SEED=1`，签核人本机复跑重
生，非采信 `doc/evidence/v0.1.2/M1-02.log`）：
- 目标机制（`doc/testplan.md:9`）：多 slave 端口发低位相同 slave ID、目标
  不同 master 端口的事务，scoreboard 校验每笔 B/R 按 master 侧 ID 高
  clog2(NoSlvPorts) 位回送到正确源 slave 端口（SPEC-5.1.2/5.1.3）。
- 复跑尾部 `SB_SUMMARY`：`route: match=96 mismatch=0 | resp: match=96
  mismatch=0 | resp-route(C3.2): match=96 mismatch=0 | pending(unmatched at
  end)=0`；`UVM_ERROR: 0`；`2119 assertions ... 0 with failures`；自然
  `$finish`。
- **反空跑核验**：记分板计数**非零**（三判据各 96 笔配对、pending=0），
  且新增的 resp-route(C3.2) 判据 96/0 独立佐证响应回送到正确源端口。96 事
  务紧密汇聚正是本场景（同低位 ID 跨端口）区别于 M1-01 的关键激励形状。

**结论：M1-01/M1-02 的通过均由目标机制达成、记分板计数非零且与 testplan
场景形状吻合，非偶然/空跑，可信。**

（附注：已登记的 `doc/evidence/v0.1.0/M1-01.log` 其 `SB_SUMMARY` 落在
`scoreboard_refmodel.sv:190`、无 resp-route(C3.2) 字段——因该证据取于
v0.1.0，早于 BUG-0009 修复引入 C3.2 判据（现 `:244`）。此为点时刻里程碑
证据与当前树的字节差，非功能缺陷，另记为残留风险 R1。）

### 抽查 5 — 守卫证伪（Guard falsification）

选 **BUG-0009**（`mstport_monitor` AW→W 写 burst 错配，TB_BUG，运行期记分
板守卫）——较 BUG-0007（编译期 TOOL_ENV，与 M0 的 BUG-0006 同类）更能检验
M1 新落地的功能级守卫是否真会见红。procedural template 依 signoff-M0 §2
抽查 5（BUG-0006 一次性废弃分支证伪）。

**工作树前置事实**：M1-02 卡（含 BUG-0009 修复）尚未提交——`tb/
mstport_agent.sv` 等在工作树 modified，`doc/evidence/v0.1.2/`、
`doc/bugs/BUG-0009.md` 为 untracked。HEAD（77f08e8）的
`tb/mstport_agent.sv`（blob a8fb78a）恰为**修复前的单槽 `w_id`/`w_len` 版
本**（M1-01 期，BUG-0009.md 述"M1-01 未暴露"），工作树的改动即 AW FIFO
（`aw_q[$]`）修复。因 M1-02 的 seq/test 本身亦未提交，`git stash` 会连带
撤走被测用例；故采**外科式单文件回退 + scratchpad 备份保证逐字节复原**，
在一次性废弃分支上执行。

实际操作（绝不合并/推送）：
1. 备份工作树已修复的 `tb/mstport_agent.sv` 至 scratchpad 并记 sha256；
   `git checkout -b signoff-throwaway-bug0009`（工作树改动随之保留）。
2. `git show HEAD:tb/mstport_agent.sv > tb/mstport_agent.sv`——装回修复前
   的单槽 monitor（核验：`w_id = vif.aw_id` 单槽赋值在位、无 `aw_q`）。
3. `make run TEST=m1_02_id_prefix_test SEED=1`（scoreboard 保持已修复版，
   仅 monitor 回退）→ **守卫如期转红**，`sim/out/m1_02_id_prefix_test_1.log`：
   - `SB_SUMMARY`：`route: match=88 mismatch=4 | resp: match=96 mismatch=0
     | resp-route(C3.2): match=96 mismatch=0 | pending(unmatched at end)=7`
   - `UVM_ERROR : 5`（`SB_NOPEND` ×3、`SB_WDATA_LEN` ×1、`SB_DANGLING` ×1）
   - **与 BUG-0009.md `min_repro` 记录的"4 route 失配 + 7 dangling"逐条
     吻合**；且 `resp`/`resp-route(C3.2)` 仍 96/0——正是 BUG-0009 症状核
     心："请求侧配对判据失配、响应侧路由判据零失配"的两判据分歧，实证
     指向 TB monitor 而非 DUT。
4. 从 scratchpad 备份复原 `tb/mstport_agent.sv`（`sha256sum -c` **成功**，
   逐字节一致）；`git checkout master && git branch -D
   signoff-throwaway-bug0009`。核验：回到 master、工作树恢复到证伪前的
   WIP 状态（`aw_q[$]` 修复复位）、无残留 throwaway 分支。复原后
   `make run TEST=m1_02_id_prefix_test SEED=1` 复跑：`route 96/0 | resp
   96/0 | resp-route 96/0 | pending=0`、`UVM_ERROR : 0`——修复态复绿。

**守卫为真**：M1-02 定向激励形状（同低位 ID 跨端口、共享 master 端口写
burst 紧密汇聚）作为回归守卫，在 monitor 配对缺陷复现时**确定性转红并复
现登记签名**——该守卫**已亲眼见红**，非仅假设。
（说明：本次仅回退 monitor、保留已修复 scoreboard，故失配以记分板级
`SB_NOPEND/SB_WDATA_LEN/SB_DANGLING` 面貌显现，命中 BUG-0009 的**主守卫**
（激励形状 → 记分板失配 4+7）；`MON_WNOAW` 属 AW 队列耗尽子情形的次级带式
守卫，本次未触其触发条件，不影响主守卫见红结论。）

### 抽查 6 — spec 债务为零或已受理

M1 期**未开任何 SPEC_ISSUE-class 行**。`doc/bugs.md` 四行分类：
- BUG-0005 = `SPEC_CHANGED`（终态，M0 期 NoAddrRules 口径，REV-001 受理）；
- BUG-0007 = TOOL_ENV / TB，`CLOSED`；
- BUG-0008 = TOOL_ENV / TB，`WONTFIX`；
- BUG-0009 = TB_BUG，`CLOSED`。

**开放 SPEC_ISSUE 清单为空**（无 M1 新增、无非终态 SPEC_ISSUE）。M1 的两处
行为面处置（BUG-0007 `bind` 偏离、BUG-0009 monitor 缺陷）均为 TOOL_ENV/
TB_BUG，非 spec 歧义——REV-002 §2 behavior-leak 猎捕亦确认 M1 design-prompt
集无向 spec 未载行为的越线、未新增 bugs.md 行。

**结论：M1 无未受理的 spec 债务。**

---

## 3. 残留风险（均非阻塞）

| # | 风险 | 严重度 | 依据 | 处置建议 |
| --- | --- | --- | --- | --- |
| R1 | 已登记的独立证据 `doc/evidence/v0.1.0/M1-01.log` 取于 v0.1.0，**早于** BUG-0009 修复对 `scoreboard_refmodel.sv`/`mstport_agent.sv` 的改动——其 `SB_SUMMARY` 落 `:190`、无 `resp-route(C3.2)` 字段，与当前树（`:244`、含 C3.2 48/0）字节不一致。即 M1-01 的独立证据文件字节滞后于其所验代码。 | 低 | `doc/evidence/v0.1.0/M1-01.log:26` vs 签核人本机复跑 `sim/out/m1_01_smoke_test_1.log`（`:244` + C3.2）；BUG-0009.md §rerun | 不阻塞：当前代码对 M1-01 的复验由三路独立覆盖——① 回归摘要 `v0.1.2/result_summary.txt` 中 `m1_01_smoke_test` 在修复态 PASS；② BUG-0009.md §rerun 载 orch 独立复跑 `route 48/0`；③ 签核人本抽查 4 独立复跑 `48/48/48`。M1-01.log 未随 BUG-0009 重生（与 BUG-0008 同源的证据保真主题）。建议：或于后续卡重生 M1-01.log 至当前树，或按 BUG-0008/REV-004 的不变性论据接受其为点时刻里程碑产物（后者更一致）。 |
| R2 | BUG-0009 修复与 M1-02 证据/详情页当前在工作树（modified + untracked），未提交；BUG-0009.md `fix_commit` 为占位（"同 M1-02 卡提交（orch 提交后回填 sha）"）。机器条件 3 因状态 CLOSED + verify_evidence 在档而 PASS，但 fix_commit sha 尚未回填、`doc/evidence/v0.1.2/` 尚未纳入版本控制。 | 低 | `git status`（`tb/*.sv` modified、`doc/evidence/v0.1.2/`+`doc/bugs/BUG-0009.md` untracked）；BUG-0009.md `## fix` | 不阻塞签核（此为标准 pre-closeout 态，与 signoff-M0 写于其 closeout 提交前同构）：核心不变量"证据与所证代码同 commit 落地"要求 0.1.2 closeout 提交须**同批**纳入 M1-02 代码 + `doc/evidence/v0.1.2/*` + 本签核，并回填 BUG-0009 `fix_commit` sha。列为 orch closeout 完成项，非 M1 质量缺口。 |

**非风险的观察（备查，不计入残留风险）**：signoff-M0 的 R1/R2（M0 证据摘
要保真、末拍在飞断言）已分别经 BUG-0008（WONTFIX，REV-004 仲裁）与 M0 签
核判为良性——均为 M0 期客体，不构成 M1 债务。

---

## 4. 六问框架收敛（本里程碑证据整体）

1. **Origin**：M1-01 溯 `doc/testplan.md:8`（SPEC-3.1/3.2/5.1/1）、M1-02 溯
   `:9`（SPEC-5.1.2/5.1.3）；design-prompt 集逐约束溯回 spec v0 章节经
   REV-002 §3 抽查通过、无 behavior-leak。达标。
2. **Falsifiability**：M1-01/M1-02 由 scoreboard 参考模型（route/resp/
   resp-route 三判据）+ 2119 SVA 保证可红；BUG-0009 守卫经本抽查 5 亲验见
   红（复现 4 route 失配 + 7 dangling 登记签名）。达标。
3. **Replayability**：两证据 line-1 均为对应 `make run ... SEED=1`，
   evidence.py 生成、与源日志自洽（M1 起 UVM tb 摘要窗口已经 0.2.1 修复，
   `## Key check lines` 段非空——见 BUG-0008 对照组）。证据须随 0.1.2
   closeout 与代码同 commit 落地（R2）。达标。
4. **Attribution**：BUG-0007（TOOL_ENV）/BUG-0009（TB_BUG）失败记录含
   first_anomaly/taxonomy/rca/fix/rerun/regression_guard；closer≠fixer 由
   框架实例隔离保证（BUG-0007 §rerun、BUG-0009 §rerun 均载独立重跑者）。
   达标。
5. **Judgment**：机器条件 3×PASS + 抽查 4/5/6 通过；证据支持"M1 风险已退
   役"，缺口仅 R1/R2（非阻塞）。达标。
6. **Retention**：教训落 bugs.md 行 + BUG-0007/0009 详情页 + REV-002/003/
   004 + `sva_bind.md` C1.1 订正 + CLAUDE.md §4 工具备忘（`bind`→直接例化）
   + regress.list 三守卫 + 本签核。达标。

---

## Taxonomy-class anomaly（强制字段，每类任务）

**No.** 本次签核（含两场景独立复跑 + BUG-0009 守卫证伪）未surface任何
`workflow/taxonomy/failure_taxonomy.md` 类别尚无 `doc/bugs.md` 行者。证伪时
复现的失配即 BUG-0009（TB_BUG，已登记 CLOSED）本身；R1（M1-01.log 字节滞
后于所证代码）虽形似 taxonomy "evidence older than the code it certifies"，
但其功能复验由回归摘要 + 独立复跑三路覆盖、且同 BUG-0008 已登记的证据保真
主题同源，作为非阻塞残留风险 R1 记录，不另立新 bugs.md 行。未发现任何被内
联绕过而漏登的失败类。

---

## 5. 裁决

**M1 里程碑签核：PASS。**

M1（自研 UVM env + smoke，含 vendor v0.39.10 升级评估 Defer）的风险已退役：
两条功能场景 M1-01（48/48/48）、M1-02（96/96/96）由目标激励实打实通过、记
分板计数非零且与 testplan 场景形状吻合、2119 SVA 零失败、自然收敛；一处
VCS-2018 工具挂接偏离（BUG-0007 `bind`→直接例化）经 REV-003 独立复现并保真
核验、闭环具守卫；一处 M1 落地期发现的 TB monitor 配对缺陷（BUG-0009）已修
复、闭环，其回归守卫经本签核**亲验见红**（复现 4 route 失配 + 7 dangling 登
记签名并复原复绿）；M1 无未受理 spec 债务（开放 SPEC_ISSUE 清单为空）。残
留 R1（M1-01.log 字节滞后于所证代码）与 R2（M1-02 修复/证据尚待 0.1.2
closeout 同 commit 落地 + 回填 BUG-0009 fix_commit sha）均非阻塞、均属证据
落地节奏而非功能缺口。可进入 M2（功能场景 + SVA + 功能覆盖）。

> 本签核仅执行只读机器检查 + 人工抽查（含两场景独立复跑 + 一次性废弃分支
> 的守卫证伪，已逐字节复原并丢弃分支），未改 rtl/tb/vendor 行为、未改
> spec、未改 testplan/bugs.md、未改任何交付代码；产出仅本签核记录。
> `make docs-check`：**docs-check passed**（本机 2026-07-27 实跑）。
