# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.2.1] 2026-07-28 M2 场景收官 + 框架五版回流 + bug 台账 12→4：签核前最后一段

**Done**
- **F-M2-08 功能覆盖采集基建落地**：`tb/functional_coverage.sv` 六个 covergroup，
  采样点全部取自既有 monitor/scoreboard 的判决状态（单一事实源，未新增第三套解码）。
  merged 后 `cg_addr_reconfig`/`cg_w_order` 100%、`cg_stall` 88.9%、`cg_tx_limit` 80%，
  其中 `above_max_11/12` 各命中 12 次——BUG-0016 的越限现象被 covergroup 独立留痕。
  派卡前发现四份 design-prompt 落后于 BUG-0016 重 pin 后的 spec（REV-007 §5 只列了
  spec 正文、漏了设计输入同步），先派 arch 再锚定 + REV-008 增量门禁才放行。
- **M2-OR03 守卫场景落地**（testplan 由 7 条增至 8 条，全 ✅）：为 BUG-0023/0024 定向
  构造「同完整 ID 多笔在飞 + 目标跨 master 端口切换」。BUG-0023 守卫闭环——
  `w/r_collide_kept_now` 由既有 9 场景的 0/0 变 192/264，且去掉同沿保护后双双归 0
  （证伪成立，不是恒真空守卫）。写方向原本打不中的原因值得留档：均匀 `AxLEN=0` 的
  写流与 B 流锁相，同沿永不发生；按 `k%2` 交替 `AxLEN` 扫相位后才命中。
- **`make lint` 门禁从「三层坏」修到可用**：BUG-0014（缺 `-assert svaext`）→ 暴露
  BUG-0019（缺 `-top`）→ 暴露 BUG-0021（285 条既有告警）→ 分诊出 11 条真缺陷
  （F1/F2/F3，全在 `tb/sva/`）→ 修复期又撞出 BUG-0022（增量假绿）。BUG-0022 的修法是
  **无条件重跑 + 逐文件执行证明**（枚举源是 `find ../tb` 而非 flist，故 flist 缩水也挡得住）。
- **BUG-0020 修复**：`make run … FSDB=1` 可选波形路径，默认路径成本逐项对齐未变；
  `xdebug session.open` 首次在本仓库成功（`mode: waveform`）。
- **框架 0.3.0 → 0.4.5 连拉五版**，FB-10~FB-17 八条回流，其中 FB-10（guard 注入）
  当日进入 canon 0.4.1：`regression_guard` 新增 `paths:` glob、`make guards` 纯路径求交、
  dispatch + rubric #5 双消费挂点。本仓库 18 条存量 guard 全部回填 `paths:`，复验
  `make guards FILES="tb/sva/axi_xbar_stall_sva.sv"` 命中含 BUG-0015——**被 F1 违反的
  正是它**，缺口关闭得证。此后每张卡都按该机制注入，DV 反馈「BUG-0013 没有它我很可能会漏」。
- **bug 台账 12 条 active → 4 条**（REV-010 逐条裁决 + 复验）：5 条 CLOSED（rev 在
  一次性 worktree 内亲手证伪，非仅看日志）、3 条 WONTFIX（0017 版本墙 / 0021 附守卫
  改写 / 0030 环境约束）、2 条由 orch 复验后 CLOSED（0020/0022）。新增
  `doc/lint-baseline.md` 作为 BUG-0021 WONTFIX 的守卫载体（285 条按类别×文件×行登记），
  `make lint-diff` 为其执行入口。

**Not done**
- **M2 未签核**：`signoff-check` 条件 3 剩 4 条 active——BUG-0018（covergroup 采样相位，
  rev 判为 **M4** 前置而非 M3）、BUG-0024（`w_id_open` 单 bit，须择 REV-010 §4 G4 的
  (a) 重建队列 / (b) 正式收窄 SVA 判决范围）、BUG-0025（含**必须先仲裁的 SPEC_ISSUE
  半边**：error slave 响应能否越过更老响应，spec 未定义）、BUG-0029（等框架 FB-16）。
- `doc/evidence/v0.2.0/signoff-M2.md` 未出（rubric 人工抽查三项未做）。
- M3-TL01 已注册但未落地（BUG-0010 守卫，其 guard 原文钉在 M3/M4，不挡 M2）。

**Next**
- BUG-0025 的 SPEC_ISSUE 半边派 rev 仲裁——**必须在 M3 场景被设计之前**完成，
  M3 判据形态取决于结论。
- BUG-0024 择 G4 的 (a) 或 (b)；BUG-0018 落终态（M4 前置的书面接受理由）。
- 四条清零后派 rev 签核卡（rubric #5 现要求「里程碑触及文件命中的全部 guard 入围复核 +
  至少证伪一条」，用 `make guards` 定范围）。

**How verified**
- `make regress` **11/11 PASS**（此前只有 3/3——BUG-0028：七个 M2 场景自落地起从未进过
  回归清单，`make regress` 报绿而分母静默缩水，本轮补齐并登记
  `doc/evidence/v0.2.0/result_summary.txt`）。
- 八条 M2 证据全部重跑重登记（框架 0.4.3 起每条含 5 个 SVA 模块的聚合行，
  `axi_xbar_stall_sva.sv: 60 properties/covers, 2640 attempts, 24 match` 首次进入证据——
  正是 BUG-0026 说「从来就不在证据文件里」的那个数字，该条据此 CLOSED）。
- orch 独立复验 BUG-0020/0022（非修复方）：lint 连跑三次 exit 2/假绿签名归零/
  `lint-diff` 225/225；默认 `make run` 不产波形而 `FSDB=1` 产出 345 KB 且 xdebug 可开 session。
- `make docs-check` / `make fw-check`（框架 0.4.5，26 files pinned）全绿。

**这一轮最该记住的一件事**：`make lint` 从 M0 起就是坏的，因为它**不在任何门禁清单里**——
没有机制去验证「验证工具本身是否有效」。同一形状在本轮出现了五次（lint 假绿 / fwsync 缺
profile 静默降级 / bugs.md 表格错位后门禁照过 / regress 分母缩水 / BUG-0015 的 guard 写下了
却没有强制消费）。前四条已回流框架成 FB-11/12/14 与 BUG-0028，第五条促成了 0.4.1 的
guard 注入机制。**看到绿灯要先问它覆盖了什么。**

