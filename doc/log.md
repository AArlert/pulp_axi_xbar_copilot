# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.2.2] 2026-07-28 REV-011 spec 条款落地：译码未命中事务的保序地位（BUG-0025 SPEC_ISSUE 半边裁决）

**Done**
- rev 卡 **REV-011** 交付（`doc/review/REV-011.md`）：对 M2 仅剩的三条 active
  bug（0018/0024/0025）做终态再裁决，并**当场完成** BUG-0025 的 SPEC_ISSUE
  半边仲裁。本 chunk 只落地其中的 spec 部分（C-1），其余四项条件（C-2 新登
  BUG-0031、C-3 改写三条 regression_guard、C-4 详情页正文订正、C-5 另派签核
  卡）留给后续 chunk
- **应用条款提案 P-REV011-1**：`doc/spec.md` §5.2 新增第 6 条「译码未命中
  事务的保序地位」——(1) 走 §3.3 default master port 的事务其目标是**真实
  master 端口**（xbar.md L35），§5.2.1-4 原样适用；(2) 走 §4 decode error
  slave 的事务分两层：**完整 ID 维度可断言**（同一 slave 端口上完整 ID 相同、
  同方向事务的 B/rlast 完成序须与接受序一致，**无论**路由去向；依据 §1 +
  §4.5 + §5.2.3 + xbar.md L86 "same ID and direction must remain ordered"
  ——该义务只依赖 slave 端口是 AXI4 接口、不依赖内部路由），**低位 ID 桶
  维度不可断言**（完整 ID 不同且其一走 err_slv 时，次序关系许可来源未定义：
  xbar.md §Ordering and Stalls 只约束"不同 master 端口"、§Decode Errors 未涉
  次序、demux.md/mux.md 对 err_slv 无记载 ⇒ 不得写断言，以非判决 cover 留痕 +
  列上游确认项 + 不阻塞里程碑，同 §7.4.4/§8.4 处置）；(3) checker 对该排除
  必须**显式引本条**，不得以"未登记⇒读默认值⇒比较恰好为假"实现
- **应用条款提案 P-REV011-2**：`doc/spec.md` §4 新增第 6 条一行交叉指针至
  §5.2.6。§5.2.1-5 与 §4.1-5 正文一字未动（surgical）
- Change record 第 6 行登记 + `docs.py --pin-spec` 重 pin（`doc/spec.sha256`
  `bfe8542b…` → `0fd431f7…`）

**Not done**
- REV-011 的其余四项 orch 条件（C-2/C-3/C-4/C-5）——下一 chunk
- 三条 bug 的 `ACCEPTED@M3` 状态改写虽已由 rev 卡在工作树中完成，但**不在本
  commit**：本 chunk 严格限定为 spec 应用，bug 台账变更随 C-2/C-3/C-4 一并
  提交，以免 spec 变更与台账变更混进同一个不可分割的 commit
- M2 里程碑签核（signoff-M2）未做

**Next**
- C-2 登记 BUG-0031（`stall_sva.sv:99-100` 编译期 `ADDR_MAP` 译码 vs
  `sva_bind.sv:33-35` 未传 `cfg_if`——design-prompt §3 的要求只落实了一半，
  误差**双向可假红**）+ C-3 三条 regression_guard 改写 + C-4 详情页正文订正
- C-5 M2 签核卡（rubric #4 明确挑 BUG-0018 作"再读一个被豁免的洞"，#5 须真做
  一次守卫证伪）

**How verified**
- `make docs-check` 绿；`make fw-check` 绿（框架 0.5.2，26 files pinned）
- 结构核对：新条款落在 `doc/spec.md:201`（§5.2 第 6 条，位于原第 5 条之后、
  `### 5.3` 之前）与 `doc/spec.md:151`（§4 第 6 条），编号连续无跳号；
  Change record 第 6 行列数 = 6，与表头一致（FB-14 那类静默串列的自检）
- pin 一致性：`sha256sum doc/spec.md` 与 `doc/spec.sha256` 相符
- spec-from-RTL 红线：REV-011 §1.3 明确声明未读 `axi_xbar.sv`/`axi_demux.sv`
  实现体，条款的许可来源清单全部为 `vendor/axi/doc/*.md` 与 spec 内部章节；
  `axi_mux.md` 对 err_slv 无记载被作为"未定义"的**否定性证据**引用

