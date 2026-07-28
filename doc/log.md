# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.3.0] 2026-07-28 M2 里程碑签核 PASS，收官转入 M3

**Done**
- **M2 签核 PASS**（`doc/evidence/v0.2.5/signoff-M2.md`，rev 新实例——REV-011
  作者不得签自己裁的债）。`make signoff-check` 四项全绿：机器条件 1/2/3 +
  `[yes] signoff file`
- 签核人**没有接受"树未动故条件 2 无需重跑"这条转述**（那是我在卡里给的环境
  事实）：独立重跑 `make regress` 得 11/11，重写 `sim/result_summary.txt` 后
  `git status` 不变脏 ⇒ 与登记证据逐字节相同。并核对分母——`regress.list`
  11 行 ↔ testplan ✅ 11 行、差集为空（BUG-0028 guard 指派给签核人的动作已履行）
- **rubric #5 的证伪是真做的**：废弃分支 `rev011-falsify-scratch` 上把 BUG-0027
  的原缺陷放回 `tb/scoreboard_refmodel.sv`（删掉完成认领 `foreach` 里的
  `break;`），`m2_or03_guard_test SEED=1` ⇒ **`UVM_ERROR: 336` /
  `stall(C5.1/C5.2): violations=336`**，与详情页基线精确相符；复原后归零、
  `SB_SUMMARY` 与登记证据逐字段相同，分支已销毁、工作树干净。选它是因为它守的
  是**七行 M2 场景共用的判决锚点**
- **rubric #7（0.5.3 新条）首次实战，四条 `ACCEPTED@M3` 全数通过**——签核人是
  **带着推翻意图**去查的，12 项承重事实无一得手：BUG-0024 的假红构造三个结构
  前提逐条验证（`stall_sva.sv:131` 无条件覆写 / `:273-283` 合取式里确实没有
  `w_id_open[completing_id]` 项 / `:120-127` 复位只清 `*_id_open`）；BUG-0031
  的三条 grep 事实推翻不了；BUG-0025 的否定性证据复核（`grep -in
  "err_slv|error slave|decode error" axi_demux.md axi_mux.md` = **空集**，
  xbar.md L33/L35/L86 三处引文逐字属实，spec 应用文本与提案逐字相同、无 RTL
  来源）；BUG-0018 的 M4→M3 提前推理成立（`doc/spec.md:25` 六类确不含
  covergroup）。无顺延条目（`ACCEPTED@M<n>` 今日首用），已按 rubric 明确确认
- **一处超出既有记载的发现**：BUG-0018 的盲区差点动摇 **M2-WO01**——其非空转
  判据要求"≥2 不同源 AW 未决"被激励到，而 covergroup 侧 `cp_w_contention` 恰被
  该盲区打空（50%，只填 `single_source`）。实测证明判据由 assert 维度独立承担：
  `axi_xbar_worder_sva.sv:107` 在 master 端口 0 上 `207 attempts, 46 match`
  （同场景 [1..7] 全 0），与 WO01"多源汇聚同一 master 端口"的构造精确吻合
  ⇒ 豁免成立，✅ 不动摇
- REV-011 两条交接条件均已执行，且签核人把 §5.4 那条**推广**成了一张 8 行的
  **判决活性矩阵**——此前记载里只有 CFG01 与 TL02 两个孤点
- **登记 FB-20**（annoyance，由签核人报出）：**终态行携带的未兑现义务对
  `signoff-check` 条件 3 完全不可见——终态即免检**。实例 BUG-0030（WONTFIX，
  却挂着"`LD_LIBRARY_PATH` 必须*恰为*"是否属过度归纳的未做实验）。与 FB-18(b)
  是同一缺口的两侧
- 版本 0.2.5 → **0.3.0（M3）**，tag `v0.3.0`

**Not done**
- 四条 `ACCEPTED@M3` 债务本身未修（0018/0024/0025/0031）——**到期点就是 M3
  签核**，届时 `docs.py:855` 会拦，且不得续期（顺延须重走仲裁，rubric #7）
- BUG-0030 的"恰为"二值实验未做（需 FSDB，已登记为守卫义务 + FB-20）
- M3-TL01 已注册未落地；M3 场景清单尚未设计
- **框架 0.5.4 尚未 pull**（FB-19 已 fixed@0.5.4）——签核卡跑完前刻意不拉，
  避免在其脚下换掉判据来源；现在可拉

**Next**
- `make fw-pull` → 0.5.4
- 派 arch 设计输入卡：**M3 场景清单**（错误路径 / decode error / 多配置回归）。
  两条前置已备好：spec §5.2.6 已定案（译码未命中事务的保序地位三层判据），
  BUG-0025 + BUG-0031 应**同一张修复卡**且其守卫场景与 M3 decode-error 场景
  在**同一张 arch 注册卡**里登记（REV-011 §4 G4）
- 签核人留的两条 M3 指导：(1) `axi_xbar_stall_sva` 的判决活性矩阵须在 M3 新
  场景落地后**重做**；(2) **§5.2.6 2.b 的非判决 cover 是 M3 的硬性抽查项**
  ——M3 主题即错误路径，它缺席时"显式排除"与"忘了写"在报告上同形

**How verified**
- `make signoff-check` 四项全 `[PASS]`/`[yes]`；`make docs-check` / `make
  fw-check`（0.5.3，26 files pinned）绿
- 签核记录 `doc/evidence/v0.2.5/signoff-M2.md`（46 KB）含机器条件输出原文粘贴、
  抽查 4/5/6/7 各自的引证、残留风险 R1–R7、判决 **PASS**
- 判 PASS 而非 conditional 的理由（签核人原文口径）：查出的每一处残留风险
  **都已有登记载体与到期点**，没有一条属于"新发现且无人认领"或"须在 M2 内补做
  才能让 ✅ 成立"；八行 ✅ 的判决锚点均被验证为**存在、非空转、且可变红**
- Taxonomy-class anomaly：**no**。三处候选追查后判定不构成新行，逐条留痕于
  签核记录 §10（`cg_stall` 的 `SC_NONE` 无 bin 是有意设计；stall_sva 空转的成因
  已分属 BUG-0024/0025/0031；BUG-0030 的待兑现实验已在其详情页 `:103-110`）
- 派卡规则偏离（FB-19 那处）经签核人裁断：**未损害本次签核**——rubric #5 本就
  命令签核人自跑同一命令、跑出的 22 条与索引逐条相符；省下的预算实际用在读
  10 份 raw log 与 6 个源文件上，而那正是全部实测结论的来源

**这一轮最该记住的一件事**：本轮三条框架反馈（FB-18/19/20）指向的是**同一个
形状**——机制把最后一道防线放在执行者的自觉上。FB-18(b) 是 ACCEPTED 的
rationale 无人复核，FB-19 是 orch 自行裁量要不要遵守派卡规则，FB-20 是终态行
的未兑现义务无人看见。三次都靠自觉挡住了，三次都说明**凡是需要靠自觉的地方，
就是规则该补的地方**——这句话已入框架 CHANGELOG。与 0.2.1 那轮"看到绿灯要先问
它覆盖了什么"互为表里：那条问的是**门禁的覆盖面**，这条问的是**门禁之外靠什么
兜底**。

## [0.2.5] 2026-07-28 拉框架 0.5.3：FB-18 当日闭环，M2 签核卡解除暂停

**Done**
- **`make fw-pull` → 框架 0.5.3**，`fw-check`（26 files pinned）/ `docs-check`
  双绿。pull 只动 4 个文件（+4 个重新渲染的 agent 文件），逐 diff 核对无外溢：
  `workflow/signoff/rubric.md`、`scripts/docs.py`、`scripts/iverif.manifest.json`、
  `iverif.json`
- **FB-18 → `fixed@0.5.3`**（框架 commit `12b1548`），两半全采纳：
  - (a) rubric 机器条件 3 同步为 "terminal **or unexpired `ACCEPTED@M<n>`**"
  - (b) 新增人工抽查**第 7 条**（`docs.py --signoff` 同步打印，实测已见）：
    "each `ACCEPTED@M<n>` row: the cited REV record states a *falsifiable*
    rationale …… Carry-overs were re-arbitrated — never auto-extended — and
    say why the previous due date slipped"
  ⇒ 本仓库 REV-011 §4 G3 的项目自立规则**入 canon**，§5.4 作为参考形状记入框架
  CHANGELOG；框架侧另加 fuse 钉住 rubric/工具在条件 3 与第 7 条上的永久一致
- **FB-11 → `fixed@0.5.2`**：gate 自证教义按本仓库送出的**对抗原型证伪结论**
  （stamp 候选形态的两个洞 + "elaboration done" 在 VCS O-2018 根本不存在）
  全文重写进框架 deferred 台账；本仓库 `sim/Makefile`（BUG-0022 的无条件重跑 +
  逐文件执行证明）被记为参考实现。本仓库原待办两项已随 BUG-0022 完成，无欠账
- **BUG-0030 上游订正落页，但**不**关闭**：框架 0.5.2（`iverif-workflow@68a7e83`）
  承认尾冒号是**快照缺陷而非环境约束**，`vcs-2018.mk` 改条件拼接。本仓库实测该
  fragment 单独展开确已无尾冒号。**但框架"`env -i` 绕法可退役"的结论未采信**：
  本页判据写的是"必须**恰为** `$VERDI_HOME/share/PLI/VCS/LINUX64`"，而
  `sim/Makefile` 走完整 include 链后实测仍带 VCS lib 前缀 ⇒ **仍不"恰为"**。
  尾冒号与"恰为"是两件事，上游只修了前者；当初的二分定位是逐项**加**变量做的，
  没测过"带无关前缀但无尾冒号"这一形态 ⇒ 二者未经实测无法区分。维持 WONTFIX，
  并在其 `## regression_guard` 登记一项**待兑现的附带义务**（下一张需要 xdebug
  的卡本来就会产 FSDB，顺手做一次二值实验：成功则绕法退役、本条转 CLOSED 走
  FB-16 的 `CMD=`/`EXPECT=` 形态；失败则"恰为"成立、绕法保留）

**Not done**
- M2 签核未做（本 chunk 只解除其前置阻塞）
- BUG-0030 的二值实验未做（需 FSDB，不为不阻塞门禁的终态条目单独烧一次
  编译+仿真；已登记为守卫义务，不是遗忘）
- 四条 ACCEPTED@M3 债务本身未修；M3-TL01 未落地

**Next**
- **派 M2 签核卡**（rev，新实例——REV-011 作者不得签自己裁的债）。三条交接条件：
  1. rubric #4"再读一个被豁免的洞"**明确挑 BUG-0018**（REV-011 §3.3 指定）
  2. **不得**把 `axi_xbar_stall_sva` 的通过计为 M2-CFG01 的独立证据——84/84
     零命中即其空转的机械证明（REV-011 §5.4）
  3. rubric #7 是**新条**，四行 ACCEPTED@M3 全部落在它的抽查范围内
- 签核 PASS 后 `make bump-minor` → 0.3.0 / M3 + `git tag`

**How verified**
- `make fw-check` 绿（0.5.3，26 files pinned）；`make docs-check` 绿
- 新 rubric 逐条读过：条件 3 措辞已含 "or unexpired `ACCEPTED@M<n>`"，人工抽查
  第 7 条存在且 `make signoff-check` 尾部确实打印它（**不是只改文档没改工具**）
- `make signoff-check` 条件 1/2/3 全 PASS，仅余 `[not yet] signoff file`
- BUG-0030 的上游修法是**实测**而非采信：`make -f -` 求值一个只 include 该
  fragment 的临时 Makefile，父变量为空时结果恰为单一路径；对照 `sim/Makefile`
  完整链的实测值带 VCS lib 前缀——正是这个对照支撑了"不采信绕法退役"的判断
- `make guards FILES="sim/Makefile"` 7 条命中，含 BUG-0030 的新增待兑现义务

## [0.2.4] 2026-07-28 FB-18 回流并阻塞 M2 签核：ACCEPTED 只落到机器侧，rubric 两处未同步

**Done**
- 组 M2 签核卡时核对判据来源，发现 **FB-18（blocking）** 并登记 +
  当日送达 iverif-workflow 侧（session「工作流反馈审查」）。两半：
  - **(a) 字面矛盾**：`workflow/signoff/rubric.md:14` 机器条件 3 仍写
    "All bug rows are in terminal states (`CLOSED / TB_BUG / SPEC_CHANGED /
    WONTFIX`)"，而 `scripts/docs.py:877` 已是 "all bugs terminal **or
    ACCEPTED-unexpired**"。0.5.0 改了 `failure_record.md` / `docs.py` /
    `evidence.mk`，**漏了 `rubric.md`**。本仓库正好有四行 `ACCEPTED@M3`
    ⇒ 认真读判据来源的 rev 会判条件 3 不满足，与它自己跑出的 `[PASS]` 冲突。
    按工具走则判据来源形同虚设（连带贬值 rubric #5"必须真做一次证伪"那类
    **只存在于 rubric、无机器背书**的条目）；按 rubric 走则里程碑签不掉
  - **(b) 更实质**：rubric **没有任何条目**要求签核人复核 ACCEPTED 的
    rationale。机器只验两件形式——行内含 `REV-`（`docs.py:489`）、目标里程碑
    未过期（`docs.py:855`）；那份 rationale 是否真的存在、是否可证伪、上一轮
    到期判据是否兑现，**无人查**。而 rubric #6 对 spec debt 恰有同构条目，
    FB-17 提案时正是引它作先例，落地时没推广到 bug debt 这一侧
- 建议两条：机器条件 3 同步措辞；新增人工抽查第 7 条（与 #6 同构，要求
  rationale 存在 + 给出可证伪判据 + 顺延须说明上次判据为何未兑现）。并把
  `doc/review/REV-011.md` §5.4 作为合格形状的参考实现一并送出

**Not done**
- **M2 签核卡按用户指令暂停派发**，待框架闭环 FB-18 → `fwsync --pull` 后再派。
  理由：拿一份已知会误导的判据来源去派签核卡，与 FB-11 那句"没看见错 ≠
  查过了"是同一族错误。绕法（在卡里写明"以 docs.py:877 为准"）存在但没用——
  那等于让项目侧口头覆盖框架文档，不是项目该有的权限
- 四条 ACCEPTED@M3 债务本身未修（语义即如此）；M3-TL01 未落地

**Next**
- 等 iverif-workflow 侧闭环 FB-18 → `make fw-pull` → `make fw-check` 复绿
- 然后派 M2 签核卡（REV-011 交下的两条硬性交接条件不变：rubric #4 明确挑
  BUG-0018；不得把 `axi_xbar_stall_sva` 的通过计为 M2-CFG01 的独立证据，
  84/84 零命中即其空转的机械证明）

**How verified**
- 漂移是逐行比对确认的，非印象：`rubric.md:14` 与 `docs.py:877` 两处原文并列
- `make docs-check` 绿（FB-18 行 6 列）；`make fw-check` 绿（0.5.2，26 files
  pinned——**框架文件一字未改**，本条只走回流，不本地修补）
- `make signoff-check` 条件 1/2/3 仍全 PASS、仅余 `[not yet] signoff file`
  ——即本次暂停**不是**因为机器条件退化，而是因为人工判据来源不可用
- 自 `594bf94`（0.2.1）以来 `tb/`、`sim/` 一字未动，11/11 回归证据与当前树
  逐字节一致，签核恢复时条件 2 无需重跑

