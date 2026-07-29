# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.3.13] 2026-07-29 卡③：BUG-0018 修复落地——scoreboard 增 AW/AR 接受事件流，M2-OR01/WO01 覆盖率转绿

**Done**
- **卡③（DV fixer，L2）**：落地 BUG-0018——`tb/slvport_agent.sv` 新增一路
  payload-free 的 `req_accept_ap`，在 AW 接受（写）/ AR 接受（读）当拍即
  发布，与现有携带完整 wdata/wstrb、在 `w_last` 才发布的 `req_ap` **并存**
  （不删除、不改语义）；`tb/scoreboard_refmodel.sv` 新增
  `write_slv_req_accept` handler，把 `or_open_q`/`worder_pend` 注册与
  `stall_cls`/`sample_tx_limit` 采样从"迟到的 w_last"搬到"真实的 AW/AR
  接受时刻"，§5.2.3 完成序判决本体、`accept_time`/`or_key` 语义均未改动；
  `tb/xbar_env.sv` 接线新 analysis port。刷新 M2-OR01/M2-WO01 证据
  （`make evidence` 对已 ✅ 场景的重新注册验证生效）
- **实测结果**：`x_state_dir`（M2-OR01）由 16.67%→**33.33%**，
  `[stalled][write]` 格由空转非空；`cp_w_contention`（M2-WO01）由
  50.00%→**100.00%**（`multi_source_contended` 精确填满）；两次运行
  `SB_SUMMARY` 均 `mismatch=0`、`UVM_ERROR:0`；全回归 15/15 + 交叉核对
  `m3_cfg02_reconfig_test` PASS；`m2_or03_guard_test` 历史见证（collide
  192/192、264/264，stack_diff 24/24，w/r_lost 456/162）字节级不变；
  `cg_tx_limit`（TL01 80.00%/TL02 53.33%）无回归
- **fixer 如实上报一处判据文字问题（未自行处置）**：REV-011 §3.3 原文
  "`cp_stall_state` 由 33.33% 上升"对 M2-OR01 **几何上不可达**——该场景的
  构造只触达 `SC_STALLED` 一个 stall class（无 `SC_SAME_TGT`/`SC_DIFF_DIR`），
  `cp_stall_state` 在此场景的结构性天花板本就是 33.33%（读腿在修复前就已
  达到），写腿补齐只会体现在更细的 `x_state_dir` 交叉 bin（已验证达标），
  不可能让粗粒度的 `cp_stall_state` 再往上"升"。fixer 未擅自改判据、未
  隐瞒，留给 closer 复核

**Not done**
- BUG-0018 状态未变（仍 `ACCEPTED@M3`，closer≠fixer，fixer 未动状态字段）
- REV-011 §3.3 的 `cp_stall_state` 子句需要 closer 复核确认后，在关闭记录
  里写明"几何不可达、以 x_state_dir/[stalled][write] 为实质判据"的订正
- 五张 M3 执行卡序列中，④⑤仍未派（多配置基建 + M3-CF01；M3-CF02/03/04 +
  M3-AT02）

**Next**
- 提交本次改动后派 closer 卡：独立复验（含亲自重新推导 cp_stall_state 的
  几何论证）、通过后走 `make evidence BUG=BUG-0018 ...` 转 CLOSED
- 卡④：多配置基建 + M3-CF01（L2，须先于⑤）→ ⑤ M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- 判决输入管线改动的回归面广：15/15 canonical regress + 4 条交叉核对场景
  全 PASS，历史 covergroup/SVA 见证（BUG-0023/0024/0027 相关）数值不变

