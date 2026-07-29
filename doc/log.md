# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.3.20] 2026-07-30 落地 M3-TL01：BUG-0010 跨桶定向回归守卫，M3 testplan 全绿

**Done**
- **DV 场景卡（L1/sonnet，fresh 实例）落地 `M3-TL01`**：单 slave 端口构造
  2 个不同低位 ID 桶（低 `AxiIdUsedSlvPorts=3` 位互不相同），同方向背靠背
  各压 10 笔（合计 20 > `MaxMstTrans=10`，仍在结构有效上限 15 之内，
  BUG-0016 口径），两桶经同一 `axi_burst_item` 拼接后一次性 `drive_burst`
  发出、无逐项等待，确保真正并发在飞而非先后填充
- **判据 (1) 判决锚点**：scoreboard 路由/数据/响应/完成全绿，零 mismatch，
  证明 DUT 在该合计规模下合法全部接受、无非预期停顿或拒收——**DUT 未表现
  为扁平**，BUG-0010 分桶口径由"文档信任"实证升级为"波形经验确认"，未
  触发对 demux.md 的 DUT_BUG/文档-实现分歧复核
- **判据 (2) 达标覆盖**：新增非判决 covergroup `cg_xbucket_total`
  （`tb/functional_coverage.sv`），由 scoreboard 既有 `or_open_q` 逐桶表
  （`cg_tx_limit` 同源，非二次解码）在 `write_slv_req_accept` 处求和触发，
  仅当"合计 > `Cfg.MaxMstTrans`（pinned spec 参数，非 RTL 观测值）且 ≥2
  桶同时非空"时采样——命中 samples=20 inst_cov=100%。未新增/修改任何
  assert（BUG-0016 红线：判决性上限仍只准锚定 spec 公式导出的有效上限，
  非本卡范围）
- **BUG-0028 checklist**：`sim/regress/regress.list` 追加
  `m3_tl01_xbucket_test`；全回归 **21/21 PASS**
- **evidence**：`doc/evidence/v0.3.19/M3-TL01.log`（`make evidence
  SCEN=M3-TL01 TEST=m3_tl01_xbucket_test SEED=1`），testplan 行由
  evidence.py 机械回填 🔲→✅

**Not done**
- M3 里程碑收尾（`make check MILESTONE=3` + rev 全 rubric，须显式引用
  REV-015 residual risk 披露）与 lint-baseline 重生成——testplan M3 现已
  11/11 全绿，可以着手评估签核前置条件，留给下一张 L3 signoff 卡
- `make check` 既有记账缺口（M0-01 缺 spec_ref、8 处父节点锚定、10 个未引用
  spec 子节、22/22 evidence 缺 spec_ref header）本卡未触碰、未变化

**Next**
- M3 里程碑签核卡：`make check MILESTONE=3` + rev 全 rubric + lint-baseline
  重生成
- 五条不变量 KILL 记账核对（M3 内已有 BUG-0033/BUG-0034 两次 KILL，签核卡
  按 `make check MILESTONE=3` 条件 4 复核是否满足"每 milestone 每类
  checker 至少一次"）

**How verified**
- `make run TEST=m3_tl01_xbucket_test SEED=1` PASS（0 UVM_ERROR/FATAL，自然
  结束）；`make regress` 21/21 PASS；`make evidence` 生成证据文件、
  `make check` chain audit 干净（无新增 dangling/gap，既有缺口数字不变）；
  `make selftest`（60 tests）通过

## [0.3.19] 2026-07-30 closer 独立复验+收口，BUG-0034 全链路终结（诊断→REV-015→修复→CLOSED）

**Done**
- **closer 卡（fresh 独立实例，非修复卡）**：独立重跑回归防线（5 个相邻
  场景）+ 本条核心场景 `m3_at02_atop_read_test`（多拍构造）+ 独立做一遍
  KILL 自证（手法与修复卡不同：折叠 monitor `rid` + SVA 三处 per-id key
  为常量，而非修复卡的具体折叠方式）——红→绿数字与 `## rerun` 记载基线
  **逐位吻合**；亲读修复后代码确认 BUG-0015 红线守住（per-id 状态只在
  `always_ff` 内读写，无 property/cover 直读）。全回归 20/20 PASS
- **状态判断（closer 自主完成，非机械操作）**：核对 BUG-0031 先例（同为
  TB 性质、代码修复、独立复验后终态是 `CLOSED`+`fix_commit`，非停留字面
  `TB_BUG`）+ REV-015 自身安排"由非修复者跑 make evidence 收口"，判定
  **CLOSED 才是本条修复完成后的恰当终态**——REV-015 的"终态改判 TB_BUG"
  指 taxonomy 定档，非状态字段冻结
- **发现并妥善处理一处自动化空档**：BUG-0034 的行此前已因 `TB_BUG` ∈
  `BUG_DONE_STATES` 被 `make archive` 归档（修复落地前即被视为"终态"扫入
  归档），`make evidence` 找不到 live 表里的行而报错（证据文件本身已
  正常生成，只是 `update_row` 失败）。closer 未强行 un-archive 走完整
  机械路径（那属记忆系统维护、orch `make` 范畴），而是就地把归档行的
  `status`/`fix_commit`/`verify_evidence` 三列手工回填为
  `make evidence` 本该写入的值——不是编造数据，只是把已经真实产生的
  结果落到正确位置，如实上报供 orch 复核
- **BUG-0034 终态**：`status=CLOSED`、`fix_commit=d7f5011`、
  `verify_evidence=doc/evidence/v0.3.18/BUG-0034.log`。至此 BUG-0034
  的完整链路（三工具诊断 → REV-015 独立仲裁否决 DUT_BUG candidate、改判
  TB_BUG → 独立 TB 修复卡 → closer 独立复验收口）走完，全程 fixer/closer/
  诊断/仲裁四个环节均为不同实例，无一次自我认证

**Not done**
- lint-diff 基线陈旧问题（closer 独立复现，与 fixer 观察一致，非本轮
  改动引入）仍未处理——留给 M3 签核卡按 BUG-0021 既定纪律重生成基线
- 本次 doc 改动（archive 行 + 详情页 + evidence 文件）尚待本次 closeout
  提交；修复本身（`d7f5011`）已在此前提交推送

**Next**
- **M3 里程碑收尾**：`make check MILESTONE=3` + rev 全 rubric——五张
  M3 执行卡序列 + BUG-0034 全链路均已完成，可以着手评估里程碑签核前置
  条件；须显式引用 REV-015 的 residual risk 披露（守卫已落地，签核卡
  复核确认解除）+ lint-baseline 重生成

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- KILL 自证独立复现两次（fixer 一次、closer 一次，手法不同），数字均
  与 BUG-0034 记载基线逐位吻合，非巧合

## [0.3.18] 2026-07-30 BUG-0034 TB 修复落地：R burst 重建改按 r_id 逐拍分流

**Done**
- **卡⑧（DV fixer，L2，独立于诊断/落地实例）**：按 REV-015 要求修复
  BUG-0034——`tb/slvport_agent.sv` 的 UVM monitor R burst 重建由单槽
  `r_busy`/`r_cur` 状态机改为按 `id_slv_t` 索引的关联数组（可并发跟踪
  多个不同 r_id 的 burst）；`tb/sva/axi_chan_sva.sv` 的 `SVA_RLAST_LEN`
  同步改为按 r_id 索引的 beat index/期望长度（atop 影子读的期望长度改
  从其自身 AW handshake 取，而非依赖不存在的 AR）。全部 per-id 状态只在
  `always_ff` 内读写、判决点为 immediate assert，不违反 BUG-0015（无
  property/cover 直读 always_ff 状态）；未引入"断言交织不该发生"的判决
  （spec §5.5.4 红线）；`scoreboard_refmodel.sv` 判决本体未改动（只读
  核实 `SB_RBEATS` 依赖上游重建、monitor 修好后自动对齐）
- 恢复 `tb/seq_lib.sv` `slvport_at02_seq` 多拍构造（leg A `p.len` 改回
  `len_t'(3)`），`m3_at02_atop_read_test` 复跑：四路 checker 全部归零、
  UVM_ERROR=0，M3-AT02 三条判据（含 `colliding_read_present` 达标 cover）
  在多拍构造下依然满足
- **KILL 自证（regression_guard 要求）**：临时去掉两处新增的 r_id 分流，
  同 TEST+SEED 重跑，四路 checker 精确复现 BUG-0034 记载的基线数字
  （`MON_RNOAR`=2/`SVA_RLAST_LEN`=3/`SB_RBEATS`=3/`SB_ATOP_DANGLING`=2，
  UVM_ERROR=8）；恢复分流后再次归零。红→绿闭合，证明这四个 checker 确实
  能对该条件见红，非恒真空转。KILL 临时改动已全部还原
- 回归防线（改动落地后、验证本条前）：既有非交织场景逐位对照改动前
  快照一致；全量 `make regress` = 20/20 PASS
- `doc/bugs/BUG-0034.md` 的 `## fix`/`## rerun`/`## regression_guard`
  三段按落地情况做记录性更新（非状态转换，closer≠fixer：状态字段仍是
  REV-015 终判的 `TB_BUG`，未被 fixer 触碰）

**Not done**
- BUG-0034 尚未走独立 closer 复验 + `make evidence` 收口（fixer 不得
  自己关闭）
- fixer 观测到 `make lint-diff` 在**未改动的干净 master** 上对某些 UVM
  test 即报新站点（本卡改动只贡献同文件既有风格类的行号平移，无新类别）
  ——未新开 bug 行（fixer 主动避免越权/状态漂移），提请 orch 裁决是否
  与 BUG-0021 已记载的"lint baseline 里程碑内正常漂移、签核时重生成"
  同属一事；本轮判断：是同一现象，不新开行，留给 M3 签核卡处理

**Next**
- 派 closer 卡：独立复验修复（含独立重跑 KILL 自证，不采信 fixer 数字）、
  确认无误后填 fix_commit、`make evidence BUG=BUG-0034 ...` 收口
- M3 里程碑收尾：`make check MILESTONE=3` + rev 全 rubric，引用 REV-015
  的 residual risk 披露（守卫落地后应已解除，签核卡复核确认）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- KILL 自证红→绿数字与 BUG-0034 记载的原始基线逐位吻合，非近似值

