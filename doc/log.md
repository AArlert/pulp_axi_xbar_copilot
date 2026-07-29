# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.3.12] 2026-07-29 卡②：BUG-0024 (b) 收窄 + M3-OR05 落地，closer 转 WONTFIX

**Done**
- **卡②（DV fixer，L2）**：落地 REV-011 §2.3 对 BUG-0024 的裁决——择路 (b)，
  收窄 `tb/sva/axi_xbar_stall_sva.sv` 的判决范围至"每完整 ID 至多一笔在飞"，
  N≥2 明文交给 `tb/scoreboard_refmodel.sv` C5.1/C5.2 每事务队列判据承担。
  `w_reorder()`/`r_reorder()` 新增独立于既有 §5.2.6 `is_err` 排除的 N≥2
  早退分支（复用既有 `w_n[]`/`r_n[]` 在飞计数，不新造机制），文件头注 +
  `doc/design-prompt/sva_bind.md` C3.2 补齐范围声明。落地 testplan
  **M3-OR05**（REV-011 §2.2 四步构造的定向证伪场景，读/写镜像跨多桶迭代）
- **closer 卡（fresh 独立实例）**：亲读代码独立复验 b-1~b-4——b-1 两处范围
  声明齐备；b-2 亲读 `w_reorder`/`r_reorder` 确认新排除分支真实存在且与
  `is_err` 排除并存不覆盖，独立重跑 `m3_or05_range_test`
  `SVA_OR_W_REORDER`/`R_REORDER` 命中 0；b-3 据实报出 `w_lost_now`=144、
  `r_lost_now`=138（范围边界被真实触达，非要求归零）；b-4 全回归 11/11
  PASS；另交叉核对 BUG-0023/0025/0031 共享同一函数的既有 cover 命中数未受
  扰动。四项齐备后**亲自**把 `doc/bugs.md`/`doc/bugs/BUG-0024.md` 转
  `WONTFIX`（范围声明为 rationale，引 REV-011 §2.3）——WONTFIX 不经
  `make evidence` 机制、不需要 `fix_commit`
- `make archive` 消化转态触发的终态行 5>4 溢出（bugs.md 归档 3 行、
  log.md/status.jsonl 各归档 1 块/1 行）

**Not done**
- 五张 M3 执行卡序列中，③④⑤仍未派（BUG-0018 修 + 重跑 M2-OR01/WO01；多
  配置基建 + M3-CF01；M3-CF02/03/04 + M3-AT02）

**Next**
- 卡③起严格顺序：③ BUG-0018 修 + 重跑 M2-OR01/WO01（L2）→ ④ 多配置基建 +
  M3-CF01（L2，须先于⑤）→ ⑤ M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap；
  终态行数由 5 降至 archive 后的合规值）
- `make selftest`（60 tests）通过
- closer≠fixer 落地形态：转态实例（本卡 closer）与落地 (b) 修复的实例
  （卡②）分离，转态前逐条亲读代码 + 独立重跑，未采信 fixer 交付报告数字

## [0.3.11] 2026-07-29 closer-v2：填 fix_commit + 独立复验，BUG-0025/BUG-0031 转 CLOSED

**Done**
- **closer 卡（fresh 独立实例，非上一张 closer、非任何 fixer）**：上一轮
  closer 已确认 BUG-0025/BUG-0031 全部到期验收判据通过，但因修复代码当时
  未提交、`fix_commit` 空而被 `docs.py --check` 拦下机械关闭。0.3.10 commit
  `482a47e` 落定后，本卡先自行 `git log`/`git show --stat` 核实该 commit
  确含 `tb/sva/axi_xbar_stall_sva.sv`/`tb/sva_bind.sv`/
  `tb/scoreboard_refmodel.sv` 等修复文件（不盲信提示里的 sha），把
  `doc/bugs.md` 两行的 `fix_commit` 列由 `-` 填为 `482a47e`（只改此列）
- **独立重跑三条判据场景**（不采信任何转述数字）：`m3_or04_order_test`
  （BUG-0025 完整 ID + 桶级半边）、`m3_de02_default_test`（BUG-0025 default
  port 半边）、`m3_cfg02_reconfig_test`（BUG-0031 全部六条），逐条核对
  `## regression_guard` 点名的 cover 命中数（`c_bug25_default_aw/ar`
  0/2/4 端口各 1、`c_bug25_errbucket_aw/ar` 六端口各 1、`c_sib_diff_*`/
  `c_bug31_livev1_*` 六端口各 1、双向无假红），与详情页记载一致
- 执行 `make evidence BUG=BUG-0025 TEST=m3_or04_order_test SEED=1` /
  `make evidence BUG=BUG-0031 TEST=m3_cfg02_reconfig_test SEED=1`——两条
  命令均一次通过（`fix_commit` 已非空），机械回填 `CLOSED` +
  `verify_evidence`（`doc/evidence/v0.3.10/BUG-0025.log`、`BUG-0031.log`）

**Not done**
- 五张 M3 执行卡序列中，②③④⑤仍未派（BUG-0024 (b) 收窄 + M3-OR05；BUG-0018
  修 + 重跑 M2-OR01/WO01；多配置基建 + M3-CF01；M3-CF02/03/04 + M3-AT02）
- 本 commit 未触发 bugs.md 归档阈值（terminal rows 未 > 4），未跑
  `make archive`

**Next**
- 卡②起严格顺序：② BUG-0024 (b) + M3-OR05（L2）→ ③ BUG-0018 修 + 重跑
  M2-OR01/WO01（L2）→ ④ 多配置基建 + M3-CF01（L2，须先于⑤）→ ⑤
  M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- closer≠fixer 落地形态：关闭实例（本卡）与修复实例（0.3.10 各卡）分离，
  `fix_commit` 精确指向修复真正落盘的 commit

