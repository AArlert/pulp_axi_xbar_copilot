# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.2.0] 2026-07-27 M1 里程碑签核 PASS：M1-02 落地 + BUG-0008/0009 终态 + regress 覆盖补全，转入 M2

**Done**
- DV 卡：M1-02（ID 前缀响应路由 smoke）落地——`tb/seq_lib.sv`/`test_lib.sv`
  新增 `m1_02_id_prefix_{seq,vseq,test}`（多 slave 端口共享低位 ID、各指
  不同 master 端口，规避 §5.2.1 假冲突 stall）；`tb/scoreboard_refmodel.sv`
  新增 C3.2 源端口响应路由判据（`resp_expect[]`，独立于既有 payload/resp-
  code 判据，可捕获 B 通道无 payload 的跨端口错送）；evidence
  `doc/evidence/v0.1.2/M1-02.log`（96/96/96 match），testplan M1-02 🔲→✅
- 落地期发现并修复 **BUG-0009**（TB_BUG，CLOSED）：`mstport_monitor` 单槽
  AW/W 配对方案在 master 端口 AW-W 解耦/多写 burst 汇聚时错配（第二个 AW
  覆盖首个未收尾 burst 的元数据）；改 AW FIFO 队列配对（`aw_q[$]`，镜像
  `mstport_responder` 既有写法）；同轮修复 scoreboard `pending_by_id` 键加
  方向位（读写独立通道，同 id 不再别名）。DUT 全程功能正确（resp-route
  C3.2 96/0）。detail page `doc/bugs/BUG-0009.md` 补齐（orch 发现该行初始
  漏建详情页 + taxonomy 标签误用非正典的 "DV_ISSUE"，均已订正为 TB_BUG）
- rev 卡 REV-004：仲裁 BUG-0008（M0 三条存量证据 `## Key check lines` 段
  为空）处置——赞同不追溯重写、不改 signoff-M0，并纠正终态应由 OPEN 转
  **WONTFIX**（已应用）；独立核验 CLAUDE.md 两处"本地重述→指针"收成
  （taxonomy 登记无条件、执行纪律→discipline.md）语义无损，本地仪式
  （`/closeout`+`git push`+等待指令）确认仍落在保留句里，未悄悄消失
- 补全 `sim/regress/regress.list`：M0 期只有 `upstream_sanity`，M1 落地后
  一直未跟进；补入 `m1_01_smoke_test`/`m1_02_id_prefix_test`（恰对应
  BUG-0007/0009 的 min_repro，满足清单自身"每个已闭合 bug 失败 seed 永久
  入列"的约定），`make regress` 3/3 PASS，`doc/evidence/v0.1.2/
  result_summary.txt` 登记，`make signoff-check` 机器条件三项转全绿
- rev 卡：M1 里程碑签核 `doc/evidence/v0.1.2/signoff-M1.md`——**PASS**（带
  2 项非阻塞残留风险：R1 已登记的 `v0.1.0/M1-01.log` 字节滞后于 BUG-0009
  后的当前树，功能面由回归摘要+详情页+签核三路独立复跑覆盖；R2 本轮改动
  提交前 `fix_commit` 为占位，随本次 closeout 提交回填）。人工抽查 5 对
  BUG-0009 做了真实的一次性废弃分支守卫证伪：回退 monitor 单槽版本后
  确定性复现"4 route 失配+7 dangling"登记签名，逐字节复原后丢弃分支

**Not done**
- M2（功能场景 + SVA + 功能覆盖）未开始
- BUG-0008 存量三条 M0 证据仍未重生成（REV-004 裁决为不重写，非待办）
- signoff-M1 R1：`doc/evidence/v0.1.0/M1-01.log` 未随 BUG-0009 修复重生
  （非阻塞，功能面已三路复验覆盖，留给后续视需要处理）

**Next**
- 派 arch 设计输入卡：M2 功能场景清单（保序/stall/decode error/ATOP 等，
  design-prompt C2/C5 已成文待激活）+ SVA 覆盖点规划
- M2 功能覆盖率采集基建（六类覆盖率路线图见 CLAUDE.md §6）

**How verified**
- 独立重跑 `make run TEST=m1_02_id_prefix_test SEED=1`（96/96/96 match，
  UVM_ERROR 0，SVA 0 failures）与 `make run TEST=m1_01_smoke_test SEED=1`
  回归（48/48/48，0 错误，新判据无回归）；`make regress` 3/3 PASS；
  `make signoff-check` 全绿（含 `[yes] signoff file`）；`make docs-check`/
  `make fw-check` 全绿；REV-004/signoff-M1 见 `doc/review/`、
  `doc/evidence/v0.1.2/`

