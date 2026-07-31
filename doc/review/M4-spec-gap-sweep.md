# M4 spec-gap sweep（ARCH 交付物，rev 门禁前）

> 本文是 arch 的 spec-gap 分析交付物（非 REV-xxx，非 evidence）。产出粒度到
> "候选 testplan 行 + spec 锚点"，**不写 checker/覆盖率判据、不写 RTL/TB**。
> 候选行**不直接进 `doc/testplan.md`**——须先过 rev 门禁（rev 裁决注册哪些行、
> 哪些 declined 理由成立）。spec pin = `doc/spec.sha256`
> `a177440ce2b6674b6a96614f39336a0d2fe7ab4932e94905b43ad2b18c8fb083`（本卡只读）。

## 0. 范围与方法

- 输入：`scripts/docs.py --explore`（M4，0 场景行）给出的 11 个未引用小节 +
  `make next` 前沿 + `doc/spec.md` 全篇 + `doc/evidence/v0.4.0/M4-coverage-baseline.md`
  实测六类基线。
- 两轴分工（CLAUDE.md / spec §0 #4）：**结构覆盖轴**（六类 ≥90%）不是本卡设计对象；
  本卡只产出 **spec 驱动的功能场景 gap**。覆盖率基线只作"哪些 spec-合法行为从未被
  激励"的定位线索——每条候选行仍锚在 spec 条款上，覆盖率数字只是动机，不是判据。
- M4 的实质出口是覆盖率收敛（`doc/milestone.md` M4）。因此本卡的功能场景 gap 有限
  且**克制**：多数未引用小节是定义性表格/概述/元纪律，其行为已由 M3 配置矩阵子集
  （每维每取值至少一次）+ 结构覆盖轴承接，**declined 是主流、提案是少数**。

## 1. 候选 M4 testplan 行（待 rev 门禁）

| 候选 id | 一句话场景 | spec 锚点 | gap 类 | 动机（覆盖率基线定位） |
| --- | --- | --- | --- | --- |
| M4-RC01 | 运行时把一个**已使能**的 default master port **关闭**（`en_default_mst_port_i` 位 1→0）并/或把 `default_mst_port_i[i]` 索引改回更低值，仍在全端口 AW/AR 空闲窗口内改一次（复用 M2-CFG01 重配纪律），验证关闭后该端口未命中事务改由 err_slv 以 DECERR 应答、关闭前后两批各按生效配置正确路由 | §3.4.2（default port 使能位与索引运行时可变，双向）+ §3.3 + §3.4.1（改动窗口约束）+ §4.2（关闭后落 err_slv） | 已知空间·浅覆盖（§3.4 被 M2-CFG01 引用，但只测了 0→非零"使能/改动"方向，从未测"关闭"方向） | baseline §4 第 4 条：`en_default_mst_port_i[5:0]`/`default_mst_port_i[*]` 顶层 Toggle 只见 0→1、从未 1→0（`axi_xbar` 顶层 1→0 方向 Toggle 仅 3.70%） |
| M4-AW01 | 某 master 端口的 slave-agent 在 mux 仲裁**决定转发某笔 AW 的那一拍**保持 `aw_ready` 为低（≥2 个源 slave 端口对该 master 端口 AW 竞争时施加背压），使 mux 的"仲裁已选中但下游未就绪→锁定选择、下拍重试"路径被激励 | §5.5.2（master 端口 round-robin 仲裁合并）+ §5.5.4（不得断言具体仲裁发生序——本行只施加背压、不断言授权序）+ §7.4（背压是延迟不敏感的合法激励） | 未知空间·激励形态（既有场景从不在仲裁决策拍施加 `aw_ready` 背压） | baseline §4 第 6 条：`axi_mux.sv:293/295-298/308-309/315` 的 `lock_aw_valid_q` 重试路径 8 个 master 实例全部从未进入 |
| M4-OV01 | 地址表配置**两条区间重叠**的 rule（指向不同 master 端口），令某地址同时落入二者，验证事务被路由到地址表中**位置更高（更显著）**那条 rule 的目标 master 端口 | §3.1.3（重叠时更高位置 rule 胜出）+ §3.2.1（含起址不含终址） | 未知空间·浅覆盖（§3.1 被 M2-CFG01 引用，但 clause 3 重叠优先级从未被测；exercises addr_decode_dync 优先级逻辑） | baseline §3.3/BUG-0038：真正的规则匹配逻辑在 `addr_decode_dync`，其 Cond/Branch 需重叠/优先级激励 |
| M4-FT01 | `FallThrough=1'b1` 配置点：验证 W beat 可与对应 AW 同拍被接受（AW 路由决策直通到 W），路由/数据完整性/响应回送与 `FallThrough=0` 基线**逐条相同**（§7.4 延迟不敏感，功能响应不变） | §2.1 `FallThrough` 字段 + §7.3.1（FallThrough 语义与推荐值） | 未知空间·参数边界（`FallThrough=1` 为 spec 合法值，但 §0 #3 配置矩阵不含此维、**任何场景/配置从未激励**） | baseline：`FallThrough` 恒 0 ⇒ demux 的 fall-through 分支（axi_demux_simple 内）从未被覆盖 |

**REV-017 条件 2 强制约束（所有 M4 候选行必须承载）**：以上每条 M4 候选行均须
显式声明 §4 clause 7 / §6 的环境约束——**不向译码未命中（err_slv 目标）地址发起
任何 ATOP，送往未命中地址的 AW 恒 `aw.atop ≡ '0`**。这是 REV-017 CONDITIONAL PASS
条件 2（"M4 config-matrix testplan 行须同步承载延展后的约束"）尚未兑现的落点，M4
签核前置。M4-FT01/M4-OV01/M4-AW01/M4-RC01 无一需要向未命中地址发 ATOP，故承载该
约束不损其目的。

## 2. 11 个未引用小节逐条处置

| 小节 | 处置 | 理由 |
| --- | --- | --- |
| §1.3（概述：master 端口 ID 宽 > slave，高位为响应路由前缀） | **declined** | 概述层条款，其可断言语义已由 §5.1 承接并经 M1-02（ID 前缀响应路由）实测；§1 为导言、非独立可测行为 |
| §2.1（`Cfg` 13 字段表） | **declined（定义性表格）+ 分拆一条候选** | 字段定义表本身不是"场景"；各字段的非基线取值已由 M3 配置矩阵承接（`LatencyMode`→CF01/02、`UniqueIds`→CF03、`ATOPs`→CF04、`NoSlvPorts/NoMstPorts`退化→CF01/02、`MaxMstTrans`→M2/M3-TL01）。**唯一例外 `FallThrough`**：其 `=1` 取值从无场景，已单列 M4-FT01（并见 §3 提案 1）。`NoAddrRules=1` 极小值见 §3 未知空间（低优先 declined） |
| §2.2（模块参数 `ATOPs`/`Connectivity`/`MstPortsIdxWidth`） | **declined（定义性表格）** | `ATOPs=0`→M3-CF04、`Connectivity` 稀疏→M3-CF04、`MstPortsIdxWidth` 退化（1×N/N×1）→M3-CF01/02 已承接；参数定义表非独立场景 |
| §2.3（端口表） | **declined（定义性表格）** | 端口方向/位宽定义，被每一条场景隐式行使；无独立可断言行为 |
| §6.1（ATOP 概述：完整 AXI4+ATOP，`aw.atop!=0` 发起） | **declined（概述层，已承接）** | 概述条款，其可测语义由 §6.3/§6.4/§6.5 承接并经 M2-AT01/M3-AT02 实测 |
| §6.2（`ATOPs` 参数使能 + `ATOPs=0` 环境约束） | **declined（已承接）+ 建议补引** | `ATOPs=0` 行为已由 M3-CF04 实测（该行 env 约束 `aw.atop≡'0` 即 §6.2）。建议 rev 在 M3-CF04 行补引 `SPEC-6.2`（当前只泛引 `SPEC-6`）——**anchor 补链，非新场景** |
| §7.1（spill register 位置语义，标题） | **declined（属性由跨配置承接）** | spill 位置语义是延迟不敏感属性，由 §7.4 原则 + CF01（NO_LATENCY 无 spill）/CF02（CUT_ALL_PORTS 全 spill）的功能等价实测承接；spill 结构覆盖属结构轴 |
| §7.1.2（spill 切断组合路径、+1 拍、不损吞吐） | **declined（延迟不敏感属性）** | 同 §7.1；"不损吞吐/功能不变"由 CF01/CF02 与基线逐条相同的功能判据承接，非独立场景 |
| §7.3（使用约束） | **declined（自声明出矩阵/理由性）** | §7.3.1 为基线配置选择的**理由**（非行为）；§7.3.2 spec 原文自声明"本项目单实例验证，此条仅作集成约束记录，**不进配置矩阵**"。二者均非可测场景 |
| §7.4.3（latency checker 不得断言固定周期、功能 checker 须延迟不敏感） | **declined（跨切纪律）** | 这是对**所有** checker 的横切纪律，已内嵌进每一条 testplan 行的"延迟不敏感"措辞（M2-TL01/M3-DE01/CF01 等均引 SPEC-7.4）；非独立场景 |
| §7.4.4（基线不影响 M1 smoke；cycle-accurate 须上游确认） | **declined（理由性/上游确认项）** | 理由性条款 + 明标"上游确认项，不阻塞里程碑"；cycle-accurate 时序核查未获上游确认，无 spec 依据可测 |

## 3. 未知空间主动探索（机械清单抓不到的角落）

除已落成候选行（M4-AW01/M4-OV01/M4-FT01）外，主动审视 §1–§8 交互角落，findings：

1. **atop_filter W/R FSM 大缺口——已由 spec §4 clause 7 waiver 承接，无需场景。**
   baseline §4 第 1/2 条（本仓库 M4 六类最大单缺口：`axi_atop_filter.w_state_q`
   5/7 状态、`r_state_q` 2/4 状态从未覆盖）。**根因归一**：baseline §4 把它归为
   "序列只用 `ATOP_LOAD_ADD`（AtomicLoad 不带 W burst）"；而 spec §4 clause 7
   （BUG-0039/REV-017）已裁定其真正门控是——atop_filter 例化在 `axi_err_slv` 内，
   离开 `*_FEEDTHROUGH` 唯一触发是收到 `aw.atop[5:4]!=ATOP_NONE` 的 AW，而该 AW
   **仅能经译码未命中路径抵达 err_slv**，恰为 §4.7/§6 环境约束所禁。故这些状态/
   迁移弧是**环境约束致不可达**，按 §0 #4"有 bin 但 <90%"分支走 **rev 签核书面
   豁免**（REV-017 条件 3，M4 签核时兑现）。**处置：不提案功能场景**（提任何"补 ATOP
   子编码"场景都将违反 §4.7 环境约束、需先重开 BUG-0032 补许可来源）。**给 rev 的
   一致性提示**：baseline §4 的"只用 AtomicLoad"表述与 §4.7 的"任何 ATOP 均被禁达
   err_slv"是同一缺口的两种描述，签核豁免文档应以 §4.7 口径为准（AtomicLoad/Store/
   Compare 子编码之别在此不重要——三者都被环境约束挡在 err_slv 外）。

2. **default master port 使能位/索引的"关闭/降位"方向从未激励**——已落 M4-RC01。
   §3.4.2 明述 default port 使能位与索引"同样运行时可变"（双向），既有 M2-CFG01/
   M3-DE02/M3-CFG02 只做 0→非零单向。baseline §4 第 4 条顶层 Toggle 1→0 方向仅
   3.70% 即此症状。

3. **mux AW 仲裁 lock-retry 路径从未激励**——已落 M4-AW01。

4. **重叠 rule 优先级从未激励**——已落 M4-OV01。

5. **§4 clause 7 环境约束的"译码未命中"范围两可**——见 §4 提案 2（spec 澄清）。
   §4.7 约束文本"不向**译码未命中地址**发起 ATOP"字面涵盖"未命中但走 default
   master port（真实 master、well-defined）"的地址；但其 rationale（err_slv×ATOP
   许可来源未定义）只需覆盖 **err_slv 目标**的未命中地址。当前宽读法**保守安全**
   （禁得更多不会假红），不阻塞 M4，但把"ATOP 经 default port 路由"这一 well-defined
   路径也一并禁掉了。列为 spec 澄清提案（低优先、非阻塞）。

6. **`NoAddrRules=1` 极小地址表 / 运行时热复位（`rst_ni` 1→0）——declined。**
   - `NoAddrRules=1`：§2.1 合法域"全表≥1"允许单 rule 表。既有配置均用 8 rule。
     单 rule 表是 spec 合法退化，但 addr_decode_dync 的可覆盖逻辑（含 default/
     err_slv 分流）已由 8-rule 配置 + M4-OV01（重叠优先级）承接，单 rule 表不额外
     暴露 spec 行为。**declined**：无独立 spec 行为增益，若结构覆盖轴事后证明
     addr_decode_dync 仍 <90% 再由 rev 重议。
   - `rst_ni` 1→0（运行中二次/热复位）：baseline §4 第 4 条 + §5 记 `rst_ni` 全程
     只 0→1 一次、无热复位场景。**declined**：spec §2.3 仅定义 `rst_ni`"异步、
     低有效"，**未定义运行中热复位的功能语义**；构造热复位场景将测 spec 未锚定
     的行为，须先补 spec。该 Toggle 1→0 洞建议 rev 按结构轴 waiver 处理（同
     `test_i` 恒 0 的既有 waiver 先例），或若确要纳入热复位须走 spec 新增（另开卡）。

## 4. Spec change proposals

### 提案 1（§0 #3 配置矩阵——`FallThrough` 维度归属）

- **original**（§0 #3）：`端口拓扑 {1×N, N×1, 4×4} × LatencyMode {…} × UniqueIds {0,1}
  × ATOPs {0,1} × 稀疏 Connectivity`（无 `FallThrough` 维）。
- **new（二选一，由 rev 裁决）**：
  - (a) 增列维度：`… × FallThrough {0,1}`，为 M4-FT01 提供 spec 矩阵归属；或
  - (b) 保留矩阵不变，**追加一句明注**：`FallThrough=1` 不进配置矩阵，其 fall-through
    组合路径在六类覆盖中按 rev 签核书面豁免处理（附成因）。
- **rationale**：`FallThrough` 是 §2.1 spec 合法字段，`=1` 行为（W 与 AW 同拍接受）
  spec 有定义（§2.1/§7.3.1），但当前矩阵不含此维 ⇒ 该分支在 M4 六类 branch/cond
  收敛中要么是无解释的 <90% 洞、要么需豁免。矩阵是 pinned spec，arch 不自行增维——
  提请 rev 在(a)注册 M4-FT01 或(b)出具豁免之间裁决。
- **impacted entries**：M4-FT01 候选行（是否注册取决于本提案）；§0 #4 覆盖率豁免
  台账（若取(b)）。

### 提案 2（§4 clause 7——环境约束"译码未命中"范围澄清，低优先·非阻塞）

- **original**（§4 clause 7 环境约束）：`M3 与 M4 全部场景不向译码未命中地址发起
  任何 ATOP（送往未命中地址的 AW 恒 aw.atop ≡ '0）`。
- **new（建议明确二选一，由 rev 裁决）**：把"译码未命中地址"明确为
  (a) **仅指 err_slv 目标**的未命中地址（即未命中 **且** 该端口未使能 default port），
  从而允许"未命中但经 default master port 路由（真实 master、well-defined）"的地址
  上发起 ATOP；或 (b) 确认**宽读法**（含 default-port 未命中地址）为**有意保守**，
  并明记 rationale（避免 default-port 路径引入额外 ATOP 交互的验证面）。
- **rationale**：现文宽读法把 well-defined 的"ATOP 经 default port 路由"路径一并
  禁掉，可能遮蔽一处合法功能覆盖；但宽读法保守安全、不阻塞 M4。仅请 rev 明确意图，
  消除两可。**注**：无论取(a)/(b)，均**不影响** atop_filter FSM 豁免——atop_filter
  在 err_slv 内，default-port 路径本就不经过它。
- **impacted entries**：若取(a)，可另生一条"ATOP 经 default port 路由"候选行（本卡
  暂不预置，待裁决）；M4-RC01 不受影响。

## 5. Open risks / M4 范围外事项（列示，非本卡处置）

- **REV-017 条件 2/3 未兑现**（M4 签核前置）：条件 2＝M4 config-matrix testplan 行
  承载 §4.7/§6 ATOP 环境约束（本卡 §1 已把该约束绑定到全部候选行）；条件 3＝M4 签核
  时 rev 出具 atop_filter FSM 书面豁免 + 跑 BUG-0032 guard 抽查。二者留待后续 DV/rev 卡。
- **M0-01 cites no spec clause**（explore 附带前沿）：M0-01 = 上游 tb sanity，属**冻结
  M0**。按"冻结记录不回改"（CLAUDE.md/FB-23），建议**不**回改该 ✅ 行的锚点；如 rev
  认为需留痕，可加**非规范性**旁注说明其 spec 基＝上游自校验参考网覆盖路由(§3)/保序
  (§5.2)/ID(§5.1)/数据完整性(§1)。本卡不改该行，属 M4 范围外。
- **BUG-0038（addr_decode/axi_demux 4 类结构性空白）**：结构覆盖轴，N/A 三态已裁
  （REV-016），非功能场景 gap，本卡不涉。M4-OV01/M4-FT01 的价值落在其**子模块**
  （addr_decode_dync/axi_demux_simple），与 BUG-0038 的父模块 N/A 判定不冲突。
- **axi_xbar_unmuxed AW-side default assert real-succeeded 0**（baseline §4 第 5 条）：
  同 M3-DE02 行 guard / BUG-0025/BUG-0031 既有债务根因（`stall_sva.sv:99-100` 硬编码
  `en_default=1'b0`），非新场景。M4-RC01 会真实激励 default-port 写路径，可能与该债务
  联动——提请 rev 派 M4-RC01 卡时一并核对该 assert 是否随之 real-succeed。
- **BUG-0037（COV=1 多设计 merge 异常）**：0.4.5 已闭环（fix 13cdeda）；本卡引用的
  baseline 数字取自其 §0 三组隔离测量路径，不受影响。

## 6. 处置一览（逐小节一行）

- §1.3 → declined（概述层，由 §5.1/M1-02 承接）
- §2.1 → declined（定义性表格；例外 `FallThrough`→M4-FT01+提案1）
- §2.2 → declined（定义性表格；各参数非基线取值由 M3-CF01/02/04 承接）
- §2.3 → declined（端口定义表，每场景隐式行使）
- §6.1 → declined（ATOP 概述层，由 §6.3/6.4/6.5 承接）
- §6.2 → declined + 建议 M3-CF04 补引 SPEC-6.2（anchor 补链，非新场景）
- §7.1 → declined（spill 位置属性，由 §7.4 + CF01/CF02 功能等价承接）
- §7.1.2 → declined（延迟不敏感属性，非独立场景）
- §7.3 → declined（§7.3.1 理由性 / §7.3.2 spec 自声明"不进配置矩阵"）
- §7.4.3 → declined（跨切 checker 纪律，内嵌每条行的"延迟不敏感"）
- §7.4.4 → declined（理由性 + 上游确认项，无 spec 依据可测）

候选新行（未知空间/浅覆盖，待 rev 门禁）：M4-RC01（§3.4.2 default 关闭方向）、
M4-AW01（§5.5.2/5.5.4 mux 仲裁背压）、M4-OV01（§3.1.3 重叠优先级）、
M4-FT01（§2.1/§7.3.1 FallThrough=1，附提案1）。
