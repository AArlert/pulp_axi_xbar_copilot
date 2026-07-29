# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.3.10] 2026-07-29 BUG-0025+0031 修复落地、BUG-0033 新发→REV-014 仲裁→应用，closer 卡查明关闭被 fix_commit 空挡住

**Done**
- **卡①（DV，L2）**：BUG-0025+BUG-0031 同卡修复落地——`tb/sva/axi_xbar_stall_sva.sv`
  三层译码未命中保序改造（default port 半边入表 / 完整 ID 半边纳入判决 /
  桶级半边显式排除引 §5.2.6）+ `tb/sva_bind.sv` 给该模块接入 `cfg_if` 活值
  地址表（参照 `axi_xbar_route_sva` 现成接法）；M3-CFG02 转绿。M3-DE01/DE02/
  OR04 首次仿真时浮出**新 SPEC_ISSUE：BUG-0033**（err_slv 译码错误读响应
  数据值与 spec §4.4 矛盾，doc-vs-RTL，同 BUG-0016 家族）——按纪律无条件
  登记、未抄 RTL 值入 checker、未派修复，交 rev 仲裁
- **rev 仲裁卡（fresh 独立实例，L3）→ REV-014**：BUG-0033 taxonomy 终判
  SPEC_ISSUE（**不改判 DUT_BUG**——错误响应 `RDATA` 协议上 don't-care，
  DUT 未违反任何显式条款，`RespData` 魔数为刻意设计常量），处置
  SPEC_CHANGED，提案 P-REV014-1：校正 spec §4 clause 4 为 err_slv 默认
  `RespData=64'hCA11AB1EBADCAB1E` 按 `AxiDataWidth` 零扩展/截断（**保持
  宽度参数化**——rev 追加核验发现原文档 L33 只在 32 位宽下恰好正确，不可
  硬编码成 64 位常量）。orch 应用：spec §4 clause 4 外科手术式改写 + change
  record #8 + 重 pin（新 sha `ad5bf8b7…6b3a2c`）；`doc/bugs.md`/
  `doc/bugs/BUG-0033.md` 回填裁决、状态转 `SPEC_CHANGED`；补齐详情页此前
  缺失的 `## regression_guard` 段（docs-check 一度因此报红，已修）
- **卡①.6（DV fixer，L2）**：`tb/scoreboard_refmodel.sv` 的 `ERR_RDATA`
  常量从 pinned spec §4.4 推导校正（不引 RTL 行号），转绿 M3-DE01/DE02/
  OR04；按 CLAUDE.md 不变量 5（本仓库 M3 起生效）做**注伤自证**——
  `KILL-0001`：植入缺陷（高 32 位改回 0）→红（12/3/18 处，落 BUG-0033.md
  §scope 基线区间）→恢复→绿；`sim/regress/regress.list` 补录三行
- **closer 卡（fresh 独立实例）**：独立复验 BUG-0025（三层判据）+ BUG-0031
  （六条判据），逐条核对 cover/assert 命中数（不采信任何转述），**技术判据
  全部通过**；执行 `make evidence BUG=BUG-0025 ...` 时被 `docs.py --check`
  的 `fix_commit` 空值硬门拦下（此前全部修复尚未提交，无 sha 可填）——
  closer 正确回退了这次误关闭尝试、清理孤儿 evidence 文件，**未强行绕过**，
  如实退回 orch
- 顺带：应用 REV-014 时同步 `doc/testplan.md` M3-DE01 crit(2) 措辞；根
  `Makefile` 新增 `help` 目标（列全部 16 个目标+用法，含 `evidence` 三种
  调用形式）+ `.DEFAULT_GOAL := help`（用户直接请求的构建层改动，未走
  dispatch，orch 自行完成并用 `make help`/裸 `make` 验证）；`git fetch
  upstream` 跟进框架仓库（新增 1 个纯文档提交，删除框架自己的
  `doc/VENDOR.md` 模板，与本仓库无关，仅推进移植基线指针至 `e23d938`，
  CLAUDE.md 已记）；`git pull` origin 三个已推送的文档提交（README 数据流图
  微调 + 新增 `doc/axi.md` 面向人的 AXI 入门读物 + `doc/attach/` 配图）

**Not done**
- **BUG-0025/BUG-0031 仍 `ACCEPTED@M3`**（未转 `CLOSED`）——技术判据已满足，
  纯粹卡在 `fix_commit` 空。本次 closeout 提交落定后需**另派一张新 closer
  卡**（非本次任何 fixer/前一 closer 实例）用本 commit 的 sha 填 `fix_commit`
  列、重跑 `make evidence BUG=... TEST=... SEED=...` 完成关闭；预期触发
  终态行数 5>4 归档阈值，须随附 `make archive`
- 五张 M3 执行卡序列中，②③④⑤仍未派（BUG-0024 (b) 收窄 + M3-OR05；BUG-0018
  修 + 重跑 M2-OR01/WO01；多配置基建 + M3-CF01；M3-CF02/03/04 + M3-AT02）
- `doc/testplan.md` M3-DE02/OR04 判据措辞未同步校正后 SPEC-4.4——REV-014
  §4.1 判定不需要（两行不逐字引旧值 `32'hBADCAB1E`，随 refmodel 常量自动
  生效），非遗漏

**Next**
- 派新 closer 卡：commit 落定后为 BUG-0025/BUG-0031 走独立复验→关闭闭环
  （fix_commit 已有 sha 可填），随附 `make archive`
- 卡②起严格顺序：② BUG-0024 (b) + M3-OR05（L2）→ ③ BUG-0018 修 + 重跑
  M2-OR01/WO01（L2）→ ④ 多配置基建 + M3-CF01（L2，须先于⑤）→ ⑤
  M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap；
  `KILL-0001` 使 `make check MILESTONE=3` 条件 4 由红转绿）
- closer 卡独立复验（不采信任何转述数字）：BUG-0025 三层判据（`c_bug25_
  default_aw/ar`、完整 ID 完成序 `order_violations=0`、`c_bug25_errbucket_
  aw/ar`）+ BUG-0031 六条判据（`c_sib_diff_*`、`c_bug31_livev1_*`、双向
  无假红）逐条核对通过；全回归 10 个历史场景 + 4 个新场景全 PASS、
  UVM_ERROR=0、0 assertion failures
- `python3 scripts/docs.py --pin-spec` 的 anti-sneak-edit 检查在 REV-014
  应用时再次验证生效（先加 change-record 行才允许重 pin）
- 注伤自证 `KILL-0001` 数字（12/3/18）精确落在 `doc/bugs/BUG-0033.md`
  §scope 基线区间（12/3-4/18-19）内

## [0.3.9] 2026-07-29 应用 P-REV012-1：spec §4 新增 clause 7 + §6 交叉引用，BUG-0032 落地闭环

**Done**
- **派 arch 卡（L2）起草 P-REV012-1 的 spec 变更提案**：按 REV-012 §Item 1 批准
  的四段模板（照搬 §8.2-8.4/§6 clause 2），起草 §4 新 clause 7（ATOP × 译码
  未命中应答形态许可来源未定义 + env 构造性约束）+ §6 clause 3 交叉引用，
  original/new text、rationale、对 testplan/design-prompt 的 impact 齐全，
  未越 REV-012 已批处置半步
- **派 rev 卡（新实例，L2，spec review 任务型）对该提案文本做 pin 前门禁**：
  产出 `doc/review/REV-013.md`，**CONDITIONAL PASS**——内容/四段结构/上游
  静默（rev 自跑 grep 复验，非采信 arch 复述）/编号惯例四项核查通过，**唯一
  必改**：提案原文两处 `M3/M4` 收窄为 `M3`。理由：REV-012 处置确认句与
  BUG-0032 fix 段均锚 M3；BUG-0032 更明写 M4 覆盖率收敛是最可能触发该组合、
  须重开仲裁的场景；"照搬 §8.4 模板"是形态指令非范围授权，写 M4 会让 spec
  断言一个当前无 M4 config-matrix testplan 行承载的约束（Retention 不一致）。
  reopening 路径由 part④ + guard 承接，收窄不损失
- **orch 按 REV-013 订正后的逐字文本应用**：`doc/spec.md` §4 追加 clause 7、
  §6 clause 3 追加交叉引用（均为外科手术式追加，§4.1-6/§6.1-2/4-5 正文未改
  一字）；change record 新增 #7（引 REV-012+REV-013 为依据）；
  `python3 scripts/docs.py --pin-spec` 重 pin，新 sha256
  `9347b4ac71f824a05581468502109d78160781fd1712710d0d783a2f03b3b806`
- `doc/bugs.md` BUG-0032 行与 `doc/bugs/BUG-0032.md` `## arbitration` 段回填
  REV-013 门禁记录 + 应用记录（spec 锚点、change record 序号、新 sha256）——
  BUG-0032 的约束持久归宿自此是 spec 正文本身，不再只活在 testplan/
  design-prompt/guard 三处
- **卡分级 vs 实际**：arch 卡定级 L2、rev 门禁卡定级 L2，两者实际交付均与
  定级相符，无失配。本次采用"三步子闭环"（arch 起草→rev 门禁→orch 应用）
  而非单卡直接应用，符合高后果动作（spec pin 变更）应有独立把关的谨慎度

**Not done**
- `doc/testplan.md` M3-DE01 行与 `doc/design-prompt/uvm_env.md` §6 C6.2**未
  补充引用新 spec 锚点** SPEC-4.7——arch 交付已指出这是可选的 impact 项（约束
  内容不变，只是引用权威从"review 记录"升级为"spec 正文"），非本次必需，留
  作后续小改
- 本 chunk 不含任何仿真，testplan 计数不变（M3 仍 ✅0/11）
- FB-24 仍 `open`；五张 M3 执行卡仍全部待派
- **REV-012/REV-013 的门禁副作用**：chain-audit 的 parent-anchored 由 15 降至
  8（clause 7 正文内联提及 §4.2/§4.3/§6.3，§6 clause 3 交叉引用内联提及 §6.3）
  ——这是 FB-24 已诊断的解析器口径本身的自然结果（内联提及即计入"被引用"），
  不是本卡刻意追求的指标，未做任何"为降数字而写"的编辑（REV-012 §Item 2 明确
  否决了那类动机）；如实记录以免误读为本卡目标

**Next**
- 五张 M3 执行卡（严格顺序，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）
- FB-23~27 按 0.3.7 新性质重新分类（local/noted/upstreamed）——仍是欠框架的
  观察项

**How verified**
- `make check` 绿（docs-check passed；chain-audit dangling 仍 0，本 chunk
  无新增悬空引用）
- `python3 scripts/docs.py --pin-spec` 的 anti-sneak-edit 检查实测生效：先加
  change-record 行后才允许重 pin（脚本对比 change-record 行数 vs git HEAD，
  行数未增会直接 `sys.exit`）
- `grep -n "REV-013\|clause 7" doc/spec.md` 确认新 clause 7 与 §6 交叉引用均
  已落盘；`grep -n "9347b4ac" doc/spec.sha256` 确认新 sha 已写入 pin 文件
- `doc/bugs.md`/`doc/bugs/BUG-0032.md` 均已回填应用记录，`grep -n "已应用"
  doc/bugs/BUG-0032.md` 实读确认
- 三步子闭环的隔离自检：arch 卡与 rev 门禁卡为独立新实例（非同一 session），
  rev 门禁卡自行复验上游 grep 而非采信 arch 复述的静默断言

