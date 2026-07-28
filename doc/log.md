# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.2.3] 2026-07-28 REV-011 台账落地：四条债务转 ACCEPTED@M3 + 新登 BUG-0031，signoff-check 条件 3 转绿

**Done**
- **REV-011 条件 C-2/C-3/C-4 落地**（C-1 spec 部分见 0.2.2）：
  - **C-2 新登 BUG-0031**（TB_BUG）：`tb/sva/axi_xbar_stall_sva.sv:99-100` 调
    `decode_mst_port(aw_addr, **ADDR_MAP**, …)`，地址表取编译期 localparam，而
    `tb/sva_bind.sv:33-35` 该模块**结构上拿不到** `cfg_if`（隔壁 `:41-47` 的
    `axi_xbar_route_sva` 却接了）。`design-prompt/sva_bind.md` §3 明文要求改传
    运行时活值表——函数签名已改（`xbar_types_pkg.sv:148` 收 `amap` 形参），
    **调用点没改，要求只落实了一半**。M2-CFG01 确实在运行时改表
    （`seq_lib.sv:993-996`，rule 0 的 idx 0→5）⇒ 重配后命中 region0 的事务
    `w_id_tgt` 记 mst0、实际 mst5。**误差双向（可假红）**，与 0023/0024/0025 的
    单向漏检不同类
  - **C-3 三条 `## regression_guard` 改写**：0024 的 (a) 路线旧口径
    （"`w_lost_now` 归零即修复"）**明文作废**——(b) 路线下该数不必归零，两种
    口径不得并存；0025 由"待 spec 结论"改为按 §5.2.6 定形的三段式；0018 补入
    M3 归属理由与逐 test 基线数
  - **C-4 三处订正同步进详情页正文**：0024 `## symptom`（"只漏检不会假红"
    不成立，附四步假红构造）、0025 `## symptom`/`## rca` 第 3 点/`## 对已登记
    证据的影响`（"读到 X 恒假"错、"从未被触发"错）、0018 `## symptom` scope
    补 `cg_tx_limit`
  - 额外订正一处 rev 未点到的矛盾：**BUG-0025 的 `min_repro` 列**原值是
    "无（当前激励集全为译码命中路径，本条不可触发）"，与 REV-011 §5.2 的实测
    直接冲突，已改为 `make run TEST=m2_cfg01_reconfig_test SEED=1`
- **BUG-0031 的状态退回 rev 补裁**（orch 不自填）：`ACCEPTED@M<n>` 的 rationale
  按 schema 须 rev 签名，而 `docs.py:489` 只校验行内含 `REV-`、校验不了那份
  rationale 是否真的存在——orch 自行落 ACCEPTED 恰是 REV-011 §4 G3 警告的
  "ACCEPTED 变成新地毯"。rev 补裁 **`ACCEPTED@M3`**（REV-011 §5.4），并给出
  三条**可被同样 grep 推翻**的依据：(1) 全仓只有 `tb_top.sv:59` 与
  `seq_lib.sv:994` 两处写 `cfg_vif.addr_map` ⇒ 除 CFG01 外所有场景编译期表恒等
  于活值表；(2) 唯一用到陈旧表的 `m2_cfg01_reconfig_test_1.log` 里该模块
  **84 条 cover 行全部 0 match**（对照 or01 同名 cover 非零 ⇒ 非日志假象）⇒
  结构性空转、贡献零判决；(3) testplan M2-CFG01 的判决锚点是 scoreboard +
  独立 SVA C3.1，**不含** C3.2。任一条被证伪则该裁决失效、须改判 M2 内修
- **`make signoff-check` 条件 3 转 PASS**：四条 active bug（0018/0024/0025/0031）
  各自获得一份 rev 签名、各自带证伪条件的排期理由，到期点**均为 M3 签核**
  （`docs.py:855`：n ≤ 被签核里程碑即拦）

**Not done**
- M2 里程碑签核（`doc/evidence/v0.2.*/signoff-M2.md`）未做——`signoff-check`
  仅剩 `[not yet] signoff file` 一项
- 四条 ACCEPTED 债务本身未修（这正是 ACCEPTED 的语义：已分析、已排期、未做）
- M3-TL01 已注册但未落地

**Next**
- 派 **M2 签核卡**（rev，新实例）。REV-011 交下来两条**硬性交接条件**：
  1. rubric 第 4 条"再读一个被豁免的洞"**明确挑 BUG-0018**，不得绕开它另挑
     好看的 bin；
  2. **不得**把 `axi_xbar_stall_sva` 的"通过"计为 M2-CFG01 的独立证据——
     84/84 零命中即其空转的机械证明；该场景证据链是 scoreboard
     （`route: match=30 mismatch=0`）+ `axi_xbar_route_sva`(C3.1)。与 BUG-0024
     的 b-3 同一条纪律：任何"SVA 也过了"必须附上那次运行的空转/范围见证
  rubric 第 5 条用 `make guards FILES=<里程碑触及文件>` 定复核范围，至少证伪一条
- M3 开工时：BUG-0025 + BUG-0031 **同一张修复卡**（同一调用点的两个实参，
  REV-011 §4 G4），其守卫场景与 M3 decode-error 场景应在**同一张 arch 注册卡**
  里登记（构造要素重叠）

**How verified**
- `make docs-check` 绿；`make fw-check` 绿（框架 0.5.2，26 files pinned）
- `make signoff-check` 条件 1/2/3 全 PASS，仅余 `[not yet] signoff file`
- `make guards FILES="tb/sva/axi_xbar_stall_sva.sv"` **8 条命中**（原 7 条 +
  新登的 BUG-0031）——新 guard 的注入机制生效得证，下一张动该文件的卡会自动
  收到它
- 台账终态核对：0018/0024/0025/0031 四行均 `ACCEPTED@M3`，各行文本含 `REV-011`
  （`docs.py:489` 的两道校验：须含 `REV-`、n ≥ 当前里程碑）

**这一段最该记住的一件事**：登记 BUG-0031 让刚刚转绿的条件 3 **立刻又变红**，
而把它填成 ACCEPTED 只需我改一个单词、机器完全查不出来。门禁在这里挡不住
orch——挡住的是"ACCEPTED 的 rationale 必须由 rev 签名"这条**约定**，以及
rev 交回来的那三条**可被 grep 推翻**的依据。可证伪性是自愿交出来的，不是被
门禁逼出来的；这与 REV-011 §4 G1 的"沉默的通过"是同一枚硬币的两面。

