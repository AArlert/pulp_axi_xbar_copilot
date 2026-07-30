# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.3.21] 2026-07-30 closer 独立复验+收口 BUG-0036，M3 里程碑完整签核成立

**Done**
- **closer 卡（fresh 独立实例，非修复卡，DV/sonnet/L1）**：独立复验 0.3.20
  BUG-0036 修复（`4d712f9`：`sim/regress/regress.list` 补入
  `m3_cfg02_reconfig_test 1`）——亲跑 `make run TEST=m3_cfg02_reconfig_test
  SEED=1`（UVM_ERROR=0、SB 全 mismatch=0、2143 assertions 0 failures、
  `c_bug31_livev1_aw/ar` 六实例各 1 match）+ `make regress`（22/22 PASS）+
  证据链核对（`doc/evidence/v0.3.20/M3-CFG02.log` 首行即重放命令），未采信
  修复卡 `## rerun` 段的转述数字
- **BUG-0036 收口**：`make evidence BUG=BUG-0036 CMD='make regress'
  EXPECT='22/22'` 机械生成 `doc/evidence/v0.3.20/BUG-0036.log`，
  `doc/bugs.md` 行 status 转 `CLOSED`、`fix_commit=4d712f9`；
  `doc/bugs/BUG-0036.md` 追加「closer 收口」子节记录独立复验过程
- **KILL-0003 转录准确性核对**（C2）：对照 `doc/bugs/BUG-0034.md`
  `## rerun` 段两次独立红→绿注伤自证，逐字核对 `doc/bugs.md` KILL-0003
  行的四路数字/样本报文/证据路径，确认转录无误；未重新做 KILL 实验
- **`doc/evidence/v0.3.20/signoff-M3.md` 追加 §八「C1/C2 兑现记录」**
  （一至七节 rev 原文未改动，本卡只追加）：按 rev 终裁段预授权的机械路径
  确认 C1（BUG-0036 CLOSED）与 C2（KILL-0003 入台账）均已兑现，未重开任何
  功能验证、未新增 spot-check 判定
- **orch 独立复核**（本次收尾，不同于 closer）：亲跑 `make check
  MILESTONE=3`（4 条机器条件全 `[PASS]`：全 M3 场景 ✅、regress 摘要登记、
  bug 终态/证据、KILL 覆盖率 ≥1 条 M3 标签）+ `make selftest`（61 tests
  OK）+ diff 核对 closer 改动范围（`doc/bugs.md`/`doc/bugs/BUG-0036.md`/
  `doc/evidence/v0.3.20/signoff-M3.md` 仅追加、`doc/evidence/v0.3.20/
  BUG-0036.log` 新增），未采信 closer 的自我报告
- **M3 里程碑完整签核成立**：五张 M3 执行卡（CF01-04+AT02）+ 4 个配置点 +
  DE01/DE02/OR04/OR05/TL01/CFG02 共 11 条场景全绿 + BUG-0010/0011/0012/
  0013/0016/0018/0021/0023/0024/0025/0028/0031/0032/0033/0034/0036 全部
  终态或已接受 + KILL-0001/0002/0003 三条注伤自证 + rev 签核记录齐备

**Not done**
- M4（六类功能覆盖率收敛 ≥90%）尚未启动，待用户确认后再排期；BUG-0018
  cross bin 待 M4 重采；lint baseline 285+ 条装饰性告警持续差分中
- chain audit 既有记账缺口（M0-01 缺 spec_ref、8 处父节点锚定、10 个未
  引用 spec 子节、22/22 evidence 缺 spec_ref header）本卡未触碰、未变化

**Next**
- 若用户确认推进：scope M4（六类覆盖率收敛）为下一里程碑；否则等待用户
  下一步指示

**How verified**
- `make check MILESTONE=3` 全绿（4 条机器条件 PASS，signoff 文件存在）
- `make selftest`（61 tests）通过
- closer 与 orch 两次独立复跑 `make run TEST=m3_cfg02_reconfig_test
  SEED=1` / `make regress`，数字逐位吻合，非采信

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

