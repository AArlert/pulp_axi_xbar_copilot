# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.3.15] 2026-07-30 卡④：M3 多配置构建机制落地 + M3-CF01（cfgA）转绿

**Done**
- **卡④（DV，L2）**：落地 `doc/design-prompt/tb_top.md` §5 C5.1-C5.6 的多
  配置构建机制——`tb/xbar_types_pkg.sv` 把硬编码的 `NO_SLV_PORTS`/
  `NO_MST_PORTS`/`LatencyMode` 等改为按编译期宏（`` `ifdef``/`` `elsif``）
  选点，缺省（无宏）逐位等于今日基线（C5.4）；`sim/Makefile` 建立
  `TEST` 名 → 配置点宏 + 独立 `OUT` 子目录（`out/cfgA/`）的映射，基线
  `TEST` 的产物路径/`-l` 目标不变（C5.1/C5.2）；仿真开头新增
  `[CFG_REPORT]` 自报生效的完整 13 字段 `Cfg` + `ATOPs` + `Connectivity`
  + 地址表（C5.3）；`scoreboard_refmodel.sv`/`axi_xbar_worder_sva.sv`/
  `axi_xbar_txlimit_sva.sv` 的 ID 前缀改为移位表达式 + `PREFIX_SW=
  max(PREFIX_W,1)` 存储宽，支持 `NoSlvPorts=1` 的 0 位前缀退化（C5.6）
  不触碰 `scripts/make/vcs-2018.mk`（上游 pinned，C5.1/C5.2 全在
  `sim/Makefile` 本地层解决，无需 fw-feedback）
- 落地 **M3-CF01**（cfgA：1×8 拓扑 + `LatencyMode=NO_LATENCY`），
  `m3_cf01_cfga_test` 转绿：route/resp/resp-route 零失配、decode error
  应答正确、`[CFG_REPORT]` 确认 `PREFIX_W=0`/`Connectivity=0xff`/
  `LatencyMode` 全 0
- **C5.4 基线不变验证（fixer 自证 + orch 独立复核）**：fixer 用
  `git stash` 隔离本卡改动后在 HEAD 重跑关键场景做逐位对照，确认零影响；
  orch 落盘前额外直接核查 `sim/out/simv` 与 `sim/out/cfgA/simv` 是**两个
  独立文件**（非共享产物），佐证 C5.2 落地属实，非文档声明
- 全回归 16/16 PASS（含新场景）；`make check`/`make selftest` 绿

**Not done**
- 机制目前只路由了 cfgA 实际用到的三维（NoSlvPorts/NoMstPorts/
  LatencyMode）；cfgB/C/D 还需要的 UniqueIds/ATOPs/Connectivity/地址表
  覆盖维度尚未接入选点机制——留给卡⑤在同一 `` `ifdef`` 块内补齐
  （fixer 已在交付报告里列出各配置点的坑，见卡⑤派发依据）
- lint-diff 相对冻结基线新增 20 个站点（全部风格类、行号平移导致，非
  新类别）——按 BUG-0021 WONTFIX 载体的既定纪律，属里程碑内正常漂移，
  留给 M3 签核卡重生成基线，非本卡范围
- 五张 M3 执行卡序列中，⑤仍未派（M3-CF02/03/04 + M3-AT02）

**Next**
- 卡⑤：M3-CF02/03/04 + M3-AT02（L1，复用卡④机制，需先补齐 UniqueIds/
  ATOPs/Connectivity/地址表覆盖维度的选点分支）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- 高风险项（C5.2 产物隔离、C5.4 基线不变）均有独立于 fixer 自述的核验：
  fixer 的 git-stash 隔离对照 + orch 直接核查两份 simv 物理独立

## [0.3.14] 2026-07-29 closer 独立复推 cp_stall_state 论证一致，BUG-0018 转 CLOSED

**Done**
- **closer 卡（fresh 独立实例，非卡③ fixer）**：独立重跑 M2-OR01/M2-WO01 +
  15 场景全回归，全 PASS、UVM_ERROR=0；历史守卫（M2-OR03 的 collide/
  stack_diff/w_lost/r_lost 系列）字节级未受判决输入管线改动影响
- **独立重新推导 cp_stall_state 几何论证**（不采信 fixer 结论，从
  `cg_stall` covergroup 定义 + `stall_cls` 赋值逻辑 + M2-OR01 激励构造
  逐步重推）：确认 `cp_stall_state` 只有 3 个 bin（SC_STALLED/SC_SAME_TGT/
  SC_DIFF_DIR），M2-OR01 的构造（同方向、不同目标 master 端口）结构性只能
  触达 SC_STALLED 一类，天花板即 33.33%、且读腿在修复前已达标——**closer
  独立复核后与 fixer 结论一致**：REV-011 §3.3 该子句对 M2-OR01 几何不可达，
  实质判据是 `x_state_dir[stalled][write]`（已由空转非空达标）。订正写入
  `doc/bugs.md`/`doc/bugs/BUG-0018.md`
- 填 `fix_commit=7a1c912`（`git show --stat` 核实确含三份修复文件），
  `make evidence BUG=BUG-0018 TEST=m2_or01_stall_test SEED=1` 一次通过，
  **BUG-0018 转 CLOSED**

**Not done**
- 五张 M3 执行卡序列中，④⑤仍未派（多配置基建 + M3-CF01；M3-CF02/03/04 +
  M3-AT02）

**Next**
- 卡④：多配置基建 + M3-CF01（L2，须先于⑤）→ ⑤ M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；无 terminal rows/blocks 溢出，未跑
  archive）
- closer≠fixer 落地形态：关闭实例独立重跑+独立推导，未采信任何转述数字或
  结论，最终结论与 fixer 一致但过程完全独立

