# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.4.7] 2026-08-01 M4 spec-gap sweep 收官——4 条候选场景全部落地，发现并处理 3 个真实缺陷/异常

**Done**
- 上周期（0.4.6）REV-018 裁决注册的 4 条 M4 候选场景全部实现并转 ✅，每张
  DV 卡均 fresh instance，orch 逐一独立复验（亲跑单场景 + 全量回归 + make
  check/selftest，不采信卡内自报数字）后才 commit+push：
  - **M4-OV01**（重叠 rule 优先级）：`decode_mst_port()` 改"扫描全表取最高
    下标命中"（对既有全部非重叠配置行为逐位不变）。落地中发现
    **BUG-0041**（OPEN，DUT 候选）——`addr_decode_dync` 末尾调试专用
    onehot0 断言与其自身文档化的重叠特性冲突，激励侧收尾腿绕过，留 rev
    裁决底层 RTL 是否需上游报告。
  - **M4-FT01**（新增 cfgE，`FallThrough=1`）：非判决 cover 诚实报告 0
    命中（结构性不可达，未凑数）。落地中发现并修复 **BUG-0042**（TB_BUG
    终态）——`mstport_agent.sv`/`axi_chan_sva.sv` 的 AW/W FIFO 配对逻辑
    隐含假设"AW 恒不晚于自己的 W"，`FallThrough=1` 打破该假设，三处组件
    统一改对称双队列修复。orch 复验全量回归时抓到一次自报"24/24"与亲跑
    "23/24"的真实出入（`m1_02_id_prefix_test` 间歇性进程非零退出、日志
    内容干净、后续两次独立复现均转绿），登记 **BUG-0043**（OPEN，
    TOOL_ENV 候选，未定位具体触发条件，判非本次改动回归）。
  - **M4-RC01**（default port 运行时"使能→关闭"回路，此前只测过反方向）：
    两阶段重配，复用既有 scoreboard cfg_hist 机制，无新判决逻辑。顺带核对
    REV-018 遗留开放风险——确认 BUG-0025/BUG-0031 的 TB 修复确实已在位，
    DUT 内建 default 相关 assert real-succeeded 仍为 0 系正交的激励形态
    缺口（读 RTL 确认前提条件从未被满足），非遗留债务。
  - **M4-AW01**（mux 仲裁背压）：`mstport_agent.sv` 加默认关闭、per-instance
    开启的背压开关，激励复用既有 `m2_wo01_worder_vseq` 不改。非判决 cover
    `cg_aw_retry` 39/39 命中，证明仲裁重试路径确实被激励到。
- 全部 4 张卡均遵守"判决门锚 spec 性质、结构角落仅非判决 cover"纪律
  （REV-018 guidance），无一处把结构覆盖动机写成判决期望值。
- `sim/regress/regress.list` 从 22 行增至 26 行，`doc/testplan.md` M4 四行
  全部 ✅（M4: 4/4，此前 0/4）。

**Not done**
- BUG-0041/0043 仍 OPEN，未仲裁/未分诊（前者需 rev 裁决底层 RTL 处置，
  后者需进一步定位触发条件或接受为已知瞬时抖动）。
- REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032 guard 抽查）未动，
  仍留给 M4 签核。
- M4 覆盖率基线报告重出（REV-016 条件 2 遗留）未动——现在 4 条新场景已
  落地，是重出这份报告的合适时机（能看到真实收敛效果）。
- 4 条新场景暂无 feature-matrix 关联（非阻塞 gap，留后续视实现范围判断）。
- **用户已批准一项重大范围拓展**：本周期对话中用户要求把验证方法学拓展到
  工业界标准——约束随机测试、多种子回归、压力/soak 测试、覆盖率驱动闭环
  （现状实测：25→26 个场景全部 `SEED=1`、`axi_seq_item` 声明 `rand` 字段
  但全仓 `.randomize()`/`constraint` 使用次数均为 0、无 soak 测试、覆盖率
  是事后测量非实时闭环）。已用 EnterPlanMode 产出分阶段派卡计划并获批准，
  存档于 `/home/icarray/.claude/plans/misty-petting-horizon.md`：阶段 0
  （arch 起草方法学拓展提案 + rev 把关，含"M5 新开 vs 并入 M4"的里程碑
  归属裁决）→ 阶段 1（既有场景补多种子回归，零新 TB 代码）→ 阶段 2（约束
  随机基础设施 + 首条随机化场景）→ 阶段 3（压力/soak 测试）→ 阶段 4
  （覆盖率驱动闭环脚本）。本周期尚未开始阶段 0。

**Next**
- 启动阶段 0：派 ARCH 起草验证方法学拓展提案（里程碑归属、约束随机架构、
  多种子回归策略、压力测试定义、覆盖率驱动闭环机制），REV 把关后 orch
  应用进 `doc/milestone.md`/`doc/spec.md` §0/`doc/design-prompt/`。
- 分诊 BUG-0041（等 rev 裁决）/ BUG-0043（间歇性异常，视后续复现情况）。
- M4 覆盖率基线报告重出（REV-016 条件 2，现在 4 条新场景已落地，收益最大
  的时机）。
- M4 签核前须兑现 REV-017 条件 3。

**How verified**
- 4 张 DV 卡各自的场景独立重跑 PASS；4 次独立全量回归（22→23→24→25→26
  场景规模递增）逐次亲跑，除一次间歇性 flake（已登记 BUG-0043、非本周期
  改动回归）外全部干净；`make check`/`make selftest` 每张卡收尾均复跑绿。
- 逐 diff 核对每张卡的判决逻辑改动（`decode_mst_port`/`mstport_agent.sv`
  对称双队列/`cg_*` 非判决 cover 定义）与红线合规性，未发现越权把结构角落
  写成判决期望值的情况。
- `doc/evidence/v0.4.6/` 新增 4 条 evidence 记录（M4-OV01/FT01/RC01/AW01），
  `doc/bugs.md` 新增 3 行（BUG-0041/0042/0043），均按无条件登记纪律留痕。

## [0.4.6] 2026-07-31 M4 spec-gap 全面扫描——4 条候选场景注册 + 2 条 spec 提案仲裁应用 + REV-017 条件 2 部分兑现

**Done**
- **ARCH 自新实例（L3/opus，fresh instance）**：M4 spec-gap sweep，范围按
  用户要求扩展到"整个验证空间、已知+未知 gap、主动探索"，不止步于机械
  未引用小节清单。交付 `doc/review/M4-spec-gap-sweep.md`：11 个未引用小节
  逐条处置（以 declined 为主，均附理由）、4 条候选 M4 testplan 行
  （M4-RC01 default-port 运行时关闭方向、M4-AW01 mux 仲裁 lock-retry 背压、
  M4-OV01 重叠 rule 优先级、M4-FT01 `FallThrough=1`）、未知空间主动探索
  6 项 findings（含确认 atop_filter FSM 大缺口"不提案"判断成立）、2 条
  spec change proposal（§0 #3 配置矩阵 `FallThrough` 维度归属；§4 clause 7
  "译码未命中地址"范围两可）。分析用 `doc/evidence/v0.4.0/M4-coverage-baseline.md`
  实测覆盖率数字定位真实缺口，非空转清单。
- **REV 全新实例（L3/opus，与 arch 隔离，未共用）**：审核并出具
  `doc/review/REV-018.md`，CONDITIONAL PASS。4 条候选行全部注册（各附
  conditional 口径：判决门须锚 spec 性质、结构角落仅作非判决 cover，
  M4-FT01 以提案 1 取 (a) 为前提）；11 个 declined 逐条复核全部站得住
  （§6.2 建议补引 anchor）；提案 1 裁 **(a) 增维**（FallThrough 是可达
  spec 合法逻辑，豁免应留给不可达而非不想测）；提案 2 裁 **(b) 确认宽读
  有意保守**（与 M4-RC01 的运行时 default port 可变存在移动靶耦合，宽读
  恒稳且零功能增益）；两个 open risk 关联项均给出立场（RC01 与既有 AW 侧
  default assert 债务联动，留 DV 卡核对，不阻塞；M0-01 同意不回改）；无新
  taxonomy-class 异常。
- **orch 按 REV-018"可机械执行的落地清单"逐条应用**：`doc/spec.md` §0
  item 3 增列 `× FallThrough {0,1}` 维；§4 clause 7 追加范围澄清段（宽读
  有意保守 + 双条理由）；Change record #11；重 pin sha256（
  `a480b728...`）。`doc/testplan.md` 注册 4 条候选行（状态 🔲，判决门/红线
  /env 约束逐条写入描述，与 M2-WO01/M3-TL01 既有先例同款措辞纪律）；
  M3-DE01 约束句范围由"其余全部 M3 场景"扩为"M3 与 M4 全部场景"（REV-017
  条件 2 部分兑现——spec 侧 §4 clause 7 上周期已是"M3 与 M4"，本周期补齐
  testplan 侧措辞同步）；M3-CF04 env 约束锚点由 `SPEC-6` 精化为
  `SPEC-6/SPEC-6.2`（§6.2 补引，非新场景）。另提交并推送用户直接编辑的
  `doc/milestone.md` Abstract 汇总表（M0-M4 场景/状态一览）。

**Not done**
- 4 条新 M4 testplan 行仍是 🔲（planned）：未派 DV 卡实现、未跑仿真、未
  registered evidence——本周期只完成"注册"这一步（spec-gap sweep + rev
  仲裁 + 落地登记），场景实现是下一周期的事。
- 4 条新行暂无 feature-matrix 关联（`make check` 报 orphans 4 个，非阻塞
  gap，非 FAIL）——REV-018 落地清单未要求本周期做这步，留给对应 DV 卡
  实现时按需补（可能挂靠既有 F-M2-01/F-M3-03 或新开 F-M4-xx，由后续
  arch/orch 视实现范围判断，非本周期预判）。
- REV-017 条件 2 仍未**完全**闭合：spec+testplan 两侧措辞已同步"M3 与
  M4"，但条件 2 原文还要求"M4 config-matrix testplan 行须承载"——本周期
  四条新行均已承载该约束句（各行"env 约束"段），此条实质已随本周期落地
  行为同步兑现，留待 M4 签核时由 rev 复核确认。
- REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032 guard 抽查）未动，
  仍留给 M4 签核。
- M4 覆盖率基线报告重出（REV-016 条件 2 遗留）未动。
- regress.list 未动（待 4 行任一转 ✅ 后才需要，BUG-0028/0036 纪律）。

**Next**
- 派 DV 卡实现 4 条新 M4 场景之一或多个（每卡独立、fresh instance，closer
  ≠ fixer 路由预先想清）；M4-OV01 落地时按 REV-018 纪律：若 SPEC-3.1.3
  取向消歧不清则登记 SPEC_ISSUE，不读 RTL；M4-RC01 落地时核对 open risk
  （AW 侧 default assert 是否随之 real-succeed，联动 BUG-0025/BUG-0031/
  M3-DE02）。
- 4 条场景任一 ✅ 后即时并入 `sim/regress/regress.list`（BUG-0028/0036
  常驻纪律）。
- 重出 M4 覆盖率基线报告（REV-016 条件 2 + 现有干净隔离的
  `out/{m0,cfgA..D}/cov.vdb`，同一份 vdb 不必重跑 `make regress COV=1`）。
- M4 签核前须兑现 REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032
  guard 抽查）。

**How verified**
- `make check` 绿：docs-check passed；chain audit 未引用小节由 11 降至 7
  （§2.1/§6.2/§7.3/§7.4.3 经新行/anchor 补引清零，与 arch/rev 裁决的
  declined 集合一致，非误差）；dangling refs 0；orphans 4（本周期预期内的
  非阻塞可见性提示，见 Not done）。
- `doc/spec.sha256` 已重 pin 且与 `doc/spec.md` 当前内容一致
  （`python3 scripts/docs.py --pin-spec` 输出确认）。
- 本周期无仿真运行、无场景转 ✅，故无新 evidence 记录、无 testplan 状态
  回填——纯 spec/testplan/review 文档层落地，`make evidence` 门禁不适用。

## [0.4.5] 2026-07-30 BUG-0037 修复并关闭——COV=1 覆盖率数据库跨拓扑静默合并，orch 独立复验后机械关闭

**Done**
- **DV 自修卡（L1/sonnet，fresh 实例，仅做 fixer，未做 closer）**：诊断并修复
  BUG-0037（`make regress COV=1` 把 `upstream_sanity`/cfgA-D/baseline 三类
  结构不同的拓扑静默合并进同一 `out/cov.vdb`，`make cov` 报 825 行
  `UCAPI-INSTANCEMISMATCH` + 千余行 `CMR-VCINF`）。根因确认：
  `scripts/make/vcs-2018.mk` 的 `CM := ... -cm_dir $(OUT)/cov.vdb` 用 `:=`
  在 `include` 时提前展开、冻结默认 `OUT`，晚于其展开的 `sim/Makefile`
  per-config `override OUT` 改不动已展开字符串。修法两处：① `vcs-2018.mk`
  新增 `COV_DIR` 间接层，`CM`/`COV_DIR` 均改 `=`（递归展开，在
  `compile:`/`run:` recipe 执行时才求值，此时 per-config `override OUT`
  已生效）——cfgA-D 零改动自动获得正确隔离；② `sim/Makefile` 给
  `TEST=upstream_sanity` 分支单加 `COV_DIR := $(OUT)/m0/cov.vdb`，只挪覆盖率
  库路径、不动 `OUT` 本身（避免波及 `make clean` 默认作用域与 M0 构建产物
  路径）。`scripts/make/vcs-2018.mk` 是上游 pinned 文件，本地改动均按
  CLAUDE.md §5 加内联注释 + 登记 `doc/fw-feedback.md` FB-30。
- **orch 独立复验并直接关闭**（非另派 closer DV 实例——按本仓库既有先例
  BUG-0014/0019/0022，非仿真判定类 TOOL_ENV 修复由 orch 亲自复验即满足
  closer≠fixer）：亲跑 `make regress COV=1`（`sim/Makefile`/`scripts/`
  已改后），22/22 PASS 与修复前逐字一致；逐一 `make cov TEST=<domain>`
  核对 baseline（17 场景，确认仍正确合并、未被拆散）/ M0 / cfgA-D 共六个
  查询，0 处 `mismatch`/`CMR-VCINF`。经 `make evidence BUG=BUG-0037
  CMD=... EXPECT=BUG0037_VERIFIED_CLEAN` 机械关闭（非仿真判定关闭形态，
  BUG-0029 先例），证据 `doc/evidence/v0.4.4/BUG-0037.log`；`fix_commit`
  按既有先例（7ebff52 回填 BUG-0014 的做法）在拿到 commit hash 后单独一次
  小提交回填为 `13cdeda`。
- DV 卡在复验本卡自身 guard 清单（BUG-0014/0019/0021/0022）时意外发现
  `doc/lint-baseline.md` 快照（2026-07-28）落后于 `tb/` 0.4.2 重构提交
  （`01e7976`，2026-07-30），`make lint-diff` 报 153 个新站点（7 个既有
  类别、无新类别）；用 `git stash` 确认与本卡改动无关后，按登记无条件规则
  新开 **BUG-0040**（OPEN，TOOL_ENV），未分诊未修。

**Not done**
- BUG-0040 未分诊（153 个新站点风格 vs 真缺陷未逐条核实）、未修。
- 本周期未触碰 M4 backlog 的其余三项：REV-017 条件 2（M4 config-matrix
  testplan 行同步承载延展后的环境约束）、REV-016 条件 2 遗留（M4 覆盖率
  基线须按新三态口径重出，且应一并纳入 atop_filter FSM 书面豁免）、M4
  spec-gap 缺口探测（10 个未被引用的 spec 子节）。

**Next**
- 分诊 BUG-0040（`doc/lint-baseline.md` 差分重跑 + 153 站点逐条风格/真
  缺陷判定）
- 派 arch/dv 卡把 REV-017 延展后的约束落到 M4 config-matrix testplan 行，
  建议与 M4 spec-gap 缺口探测合并规划
- 重出 M4 覆盖率基线报告（REV-016 条件 2 + REV-017 条件 3 书面豁免一并
  纳入，同一份干净 vdb、不重跑仿真——现在有了本次修复后干净隔离的
  `out/{m0,cfgA..D}/cov.vdb`，可直接复用而不必二次跑 `make regress COV=1`）
- M4 签核前须兑现 REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032
  guard 抽查）

**How verified**
- `make check` 绿（docs-check passed；chain audit gap 项与上周期一致，未
  新增）
- `make selftest` 61 tests OK
- `make regress COV=1` 修复前后均 22/22 PASS（功能判定不受本次改动影响，
  仅覆盖率数据库受影响）；修复后六个拓扑域查询 0 处
  `mismatch`/`CMR-VCINF`（orch 亲跑，非采信 DV 自报数字）
- `make evidence BUG=BUG-0037 CMD=... EXPECT=...` 生成
  `doc/evidence/v0.4.4/BUG-0037.log`，`doc/bugs.md` 状态机械回填为 CLOSED

