# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.3.17] 2026-07-30 5 个 M3 covergroup 落地；BUG-0034 三工具诊断→rev 否决 DUT_BUG、改判 TB_BUG

**Done**
- **卡⑥（DV，L2）**：落地 `doc/design-prompt/functional_coverage.md` §4
  规划、`functional_coverage.sv` 此前未实现的 5 个 M3 covergroup
  （`cg_decode_error`/`cg_decerr_shape`/`cg_miss_order`/
  `cg_default_port_tracked`/`cg_live_addr_map`）——按用户明确原则，真正
  实现而非走"文档指向已有 SVA cover"的捷径；两个与既有 `stall_sva.sv`
  SVA cover（`c_bug25_default_*`/`c_bug31_livev1_*`）重叠的项，接的是
  同一信号事实源（桥接静态句柄 `m_probe`，喂入已折叠的 always_comb/wire
  事实，BUG-0015 安全），不重复实现判断逻辑；判决 assert/property 条件
  零改动。回归防线逐位对照 HEAD 通过；全回归 20/20 PASS。副产物登记
  **BUG-0035**（TOOL_ENV，回归防线期间手工 stash+增量编译触发
  `VFS_ZLIB_ERROR`，clean rebuild 不复现，同 `scripts/regress.py` 已知
  VFS_SDB_ERROR class；orch 收卡时发现该卡自行设成 CLOSED——违反
  closer≠fixer 且证据列不合规，改判 **WONTFIX**，对齐 BUG-0017/BUG-0030
  同类先例）
- **卡⑦（DV 诊断卡）**：对 BUG-0034 用 xdebug（改用 `event.export`，
  非上一轮踩坑的 `value.at`）+ xwave（独立实现交叉核对）+ xtrace（RTL
  因果）三工具诊断，物理层证据扎实（两个独立 FSDB 解析器逐拍一致：id0
  4 拍、id8 单拍插入其中）——但**诊断卡自己给出的 taxonomy 结论（DUT_BUG
  candidate）经 rev 独立复核被否决**（见下）
- **rev 卡 → REV-015**：独立复核 100% 采信诊断卡的 RTL/波形观测，但指出
  其援引的"spec §1/§5.5.3 禁止读交织"在 spec 钉定本中**不存在**——真实
  条款只在 §5.5.1 禁 **W** 通道交织，R/响应侧 §5.1.4 + 上游
  `axi_mux.md:18` **明文允许**不同完整 ID 响应交织（框定为性能特性），
  §5.5.4 明文禁止 checker 断言 round-robin 发生序。逐拍代入诊断卡自己
  的表格，证明四路"证据"是 `slvport_agent.sv` monitor 与 `axi_chan_sva`
  bind SVA **共模同一"R 永不交织"重建假设**在合法交织下的必然误报，非
  DUT 协议违反；物理层收发计数全对、无数据丢失。**taxonomy 改判
  TB_BUG，不发起上游 issue、不走 P-xxx**——DUT 行为与其自身上游文档
  （`axi_demux.md` §Atomic Transactions 原文承认此交互"额外假冲突
  stall"，从未框定为正确性问题）一致，二者无矛盾
- `doc/bugs/BUG-0034.md` 按 fl_schema_enforce 的英文标准 section
  （symptom/first_anomaly/taxonomy/rca/fix/rerun/regression_guard/
  similar）重新组织（原文件全用中文自定 header，状态转终态后触发
  schema 检查失败，趁此机会订正结构，内容无损）

**Not done**
- BUG-0034 修复（r_id 感知的 R burst 重建）未派发——按 REV-015 要求须
  独立 TB 修复卡（不与诊断/落地同链），随后由非修复者复跑收 evidence
- 遗留的 M3-AT02 多拍交织覆盖缺口尚未在任何签核记录里正式披露（REV-015
  Item 4 要求 M3 签核时须记 residual risk 或 `ACCEPTED@M<n>`）

**Next**
- 派独立 TB 修复卡：`tb/slvport_agent.sv`/`tb/sva/axi_chan_sva.sv` 的 R
  burst 重建改按逐拍 r_id 分流；修复后恢复 M3-AT02 多拍两腿复跑转绿，
  regression_guard 由非修复者收口
- M3 里程碑收尾：`make check MILESTONE=3` + rev 全 rubric，须显式引用
  REV-015 的 residual risk 披露

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap；
  `doc/bugs/BUG-0034.md` schema 校验通过）
- `make selftest`（60 tests）通过
- rev 独立复核的方法学价值：证明"三个工具观测一致"不等于"观测解读正确"
  ——这正是派发 REV-015 时特意提醒的陷阱，实测命中

## [0.3.16] 2026-07-30 卡⑤（五张 M3 执行卡收官）：M3-CF02/03/04+AT02 转绿

**Done**
- **卡⑤（DV，L2，升级自原计划 L1）**：复用卡④建的多配置构建机制，扩展
  `xbar_types_pkg.sv`/`sim/Makefile` 补齐 cfgB/C/D 三个配置点（`UniqueIds`/
  `ATOPs`/`Connectivity`/地址表覆盖维度接入选点机制）；`tb/functional_
  coverage.sv` 新增 `cg_cfg_point`（design-prompt functional_coverage.md
  §4 规划、义务范围内的唯一一项，其余四个 M3 covergroup 明确留在范围外）。
  落地并转绿四条 testplan 行：**M3-CF02**（cfgB 6×1+`CUT_ALL_PORTS`）、
  **M3-CF03**（cfgC 4×4+`UniqueIds=1`，env 侧 `SB_UNIQUEIDS` 兜底监视）、
  **M3-CF04**（cfgD 4×4+稀疏 `Connectivity`+`ATOPs=0`，按 tb_top.md C5.7
  逐字构造）、**M3-AT02**（ATOP 跨方向假冲突守卫）。基线+cfgA 回归防线
  在验证新场景前先行核对，逐位一致（C5.4 持续成立）。全回归 20/20 PASS
- **KILL-0002**：为 cfgC 的 `SB_UNIQUEIDS` 兜底监视做注伤自证——植入
  §5.3.1 违例（同完整 ID/同方向/异目标 master 端口）→ 红
  （`violations=1`）→ 撤销 → 绿，证明该监视器非恒真空转
- **新发 BUG-0034（OPEN，DUT/TB 未决，不阻塞）**：M3-AT02 构造多拍两腿
  重叠时，slave 端口 R 通道四路独立证据（`MON_RNOAR`/`SVA_RLAST_LEN`/
  `SB_RBEATS`/`SB_ATOP_DANGLING`）同时命中，疑似 atop 影子读 R 与同桶
  普通读 R 交织（AXI4 §1 禁止读交织）；`r_ready` 恒 1 排除背压，xdebug
  `signal.changes` 显示同一连续 `r_valid` 块内 `r_id` 跳变 3 次，是交织
  的结构性证据。**DUT_BUG（真交织）vs TB_BUG（monitor/SVA 无交织重建
  缺口）未决**——需波形逐 beat decode `r_id`/`r_last` 定性，本卡 `value.at`
  在该 FSDB 上返回 unknown，未能落定，留待专卡。本卡**合法绕过**：
  M3-AT02 改单拍两腿，§6.5 假冲突仍真实发生、三条判据完整满足，不阻塞
  M3；未在判决本体加临时补丁、未把观测行为抄成期望值

**Not done**
- BUG-0034 定性未决（需要 xdebug 更细粒度取证或 Verdi 波形逐 beat decode，
  留待独立诊断卡）
- 遗留四个 M3 covergroup 缺口（`cg_decode_error`/`cg_decerr_shape`/
  `cg_miss_order`/`cg_default_port_tracked`/`cg_live_addr_map`，早于本次
  五卡序列即存在，design-prompt 已规划但 `functional_coverage.sv` 未实现）
  ——非本卡引入，留给独立记账/整改卡
- cfgC 的 §5.3.1 前置保证目前靠单发（single-outstanding）构造性满足；
  若 M4 需要多发在飞需补集中式 ID 分配器（fixer 交付报告已记）

**Next**
- **五张 M3 执行卡序列至此全部完成**（①②③④⑤ + 各自 closer/rev 支线）。
  剩余 M3 收尾项：BUG-0034 定性（独立诊断卡）、四个遗留 covergroup 缺口
  （独立整改卡）、M3 里程碑签核（`make check MILESTONE=3` + rev 全 rubric）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- 全回归 20/20 PASS（基线 + cfgA + 卡①②③④已交付场景 + 本卡四场景）

