# Design prompt — `sva_bind`（协议/时序 SVA bind 挂接，M1 骨架 + M2 断言/覆盖点激活）

> 约束层：规定 SVA 模块的**结构与挂接方式**；断言内容一律引用 `doc/spec.md`。SVA 是
> DV checker 的一种，期望只准从 spec 推导（spec §0 行 6）；本文**不**在 SVA 里编码
> spec 未载的时序/行为（behavior-leak 禁区）。
> 前置：CLAUDE.md §6「协议/时序 SVA 在 `tb/sva/` 经 `bind` 挂接」。

## 0. 目标与范围

在 `tb/sva/` 下提供协议/时序 SVA 模块，经 `bind`（tb_top C4.1）挂到 DUT 的每个 slave
端口接口与每个 master 端口接口。M1 只落地**协议基线 SVA + 挂接骨架**，smoke 期间
passive 零告警；深度时序/功能断言随 M2 展开。**只写 tb/sva 代码，不改 `vendor/`。**

## 1. 挂接方式

- **C1.1** SVA 以独立模块（`tb/sva/*.sv`）挂接，不侵入 DUT、不内联进 tb_top 主体。
  依据：CLAUDE.md §6。**挂接机制订正（REV-003，2026-07-27）**：CLAUDE.md §6 原文
  "经 bind 挂接"在本工具链下不可行——VCS-2018.09-SP2 拒绝
  `bind <slvport_if|mstport_if> axi_chan_sva (...)`，报
  `Error-[IIM] ... Interface has a module instantiation which is not allowed`
  （rev 独立复现，见 REV-003）。经证实为 VCS O-2018 对"module bind 进
  interface 作用域"的工具级限制，非本项目代码问题。**实际挂接机制为
  `tb_top.sv` 自身 generate 循环内直接例化**（`tb/sva_bind.sv`，`` `include``
  进 `tb_top.sv`，位于 `slv_if`/`mst_if` 例化之后）：因 `tb_top.sv` 为 DV 自有
  代码（不同于 DUT），`bind` 的"非侵入挂接"优势在此不适用；模块仍保持独立/
  可复用、不内联进 tb_top 主体，满足 C1.1 的实质约束（结构隔离），仅挂接语法
  由 `bind` 改为直接例化。断言内容与观测信号范围均未变（`axi_chan_sva` 仍只读
  `interface axi` 泛型端口上与 `slvport_if`/`mstport_if` 同名的外部可见 AXI4
  通道信号，无 DUT-internal 穿透）。
- **C1.2** 每个 slave 端口接口（6 个）与每个 master 端口接口（8 个）各挂一份协议
  SVA 实例；SVA 观测 `clk_i`（上升沿）/`rst_ni`（异步低有效复位期间禁用断言）。依据：
  spec §2.3（`clk_i`/`rst_ni`）。

## 2. M1 断言集（AXI4 协议基线）

DUT 声明实现完整 AXI4（spec §1、§4.5「协议本身为基线」），故协议层 SVA 的依据为
spec §1；具体条目：

- **C2.1** 握手稳定性：`*valid` 拉高后须保持到 `*ready` 拉高；`*valid=1 && *ready=0`
  期间对应通道 payload 保持不变（AW/W/B/AR/R 五通道）。依据：spec §1（完整 AXI4
  握手基线）。
- **C2.2** 复位后空闲：`rst_ni` 有效期间及释放当拍，所有 `*valid` 为 0。依据：
  spec §2.3（`rst_ni` 异步低有效）、§1（AXI4 复位基线）（N1 订正，REV-002 §3.4：
  原引 §3.1 系误引——§3.1 为地址表结构条款，与复位语义无关）。
- **C2.3** `RLAST`/`WLAST` 与 burst 长度一致（读 R burst 末拍 `RLAST=1`、写 W burst
  末拍 `WLAST=1`），beat 计数与 `AxLEN+1` 相符。依据：spec §1（完整 AXI4 握手基线，
  主锚点）；§4.3（decode error slave 的 beat 数条款，仅作旁证）（N2 订正，
  REV-002 §3.4：主锚点由 §4.3 改为 §1，§4.3 降为参考，原表述把 decode-error-slave
  专属条款"一般化"为主锚点不准确）。
- **C2.4 延迟不敏感**：SVA **不得**断言任何固定周期数/固定延迟拍数（`LatencyMode`/
  `PipelineStages` 为延迟不敏感插桩）；只写握手/协议属性类断言。依据：spec §7.4
  （含 BUG-0004 裁决）。
- **C2.5 禁断言仲裁序**：SVA **不得**断言任一条特定 round-robin 发生序或某拍具体
  被授权端口。依据：spec §5.5.4（C4 裁决）。

## 3. M2 断言与覆盖点激活集（C3.1-C3.5 具体设计，替代 M1 期占位）

**结构性前提（本节新增内容对 C1.1"独立模块"原则的延伸，供 DV 参考、非文件边界强制）**：

- **新增可见性**：C3.1/C3.2 需要观测**全局共享**的 `addr_map_i` 与**逐 slave 端口**
  一位/一索引的 `en_default_mst_port_i[i]`/`default_mst_port_i[i]`——这些不是任一
  AXI 通道接口（`slvport_if`/`mstport_if`）本身携带的信号，现有 `axi_chan_sva` 的
  泛型 `interface axi` 端口覆盖不到。tb_top 需为此新增一条挂接点信号（见 tb_top
  C4.2），把这三路信号接给新增的 SVA 实例；`addr_map_i` 对 6 个 slave 端口是同一
  句柄，`en_default_mst_port_i[i]`/`default_mst_port_i[i]` 按下标传入。依据：
  spec §2.3、§3.4。
- **译码复用（单一事实源）**：任何需要"某笔事务目标 master 端口 idx"的属性
  （C3.2）一律复用 `xbar_types_pkg::decode_mst_port()`（scoreboard_refmodel C1.2
  已在用的同一份译码函数），不得另写第二套译码逻辑。该函数当前把地址表读作
  编译期 `localparam`（M1 假设）；M2-CFG01 场景要求地址表运行时可变，函数签名需
  改为把地址表结构当**输入参数**传入（scoreboard_refmodel C1.5 同步要求此
  项），使 SVA 与 scoreboard 对同一个"运行时活值"表译码，而非各自假设其恒定。
- **实例范围**：C3.1/C3.2/C3.5 只适用于 **slave 端口**（6 个）；C3.4 适用于**两类
  端口**（细节见该条）；C3.3 不新增独立断言实例（见该条）。是否新增一个姊妹模块
  （如 `axi_xbar_route_sva.sv`，6 实例）承载 C3.1/C3.2/C3.5，或改为扩展现有
  `axi_chan_sva`（加端口/加参数区分 slave-only 逻辑）承载 C3.4，由 DV 实现选择；
  本节只约束**必须具备的可见性与判定内容**，不锁定文件边界。
- **cover property 配套（呼应 `functional_coverage.md` §3 的 assert 覆盖类）**：
  下列每条新增 `assert property` 均须配一条**同触发前提**的 `cover property`，
  用以在覆盖数据库中留痕"该属性的前提条件被真实激励到过"，而不仅是"从未失败"——
  区分非空转通过与空转通过（呼应 `workflow/dispatch/coverage_hole.md` 的可证伪性
  要求）。各条目下方逐条点出对应 cover 目标与哪个 M2 场景提供该激励。

### C3.1 地址表/default port 运行时稳定性（依据 spec §3.4）

- 属性：对每个 slave 端口 `i`，在 `(aw_valid[i] || ar_valid[i])` 为真的相邻两拍
  之间，`addr_map_i`、`en_default_mst_port_i[i]`、`default_mst_port_i[i]` 均须
  `$stable`。对 6 个 slave 端口各自独立检查即覆盖 spec §3.4"任一 slave 端口
  AW/AR valid 期间不得更改"的全局约束（对每个端口分别断言"更改与我自己的 valid
  重叠不发生"，其析取形式恰是原始的全局约束，无需跨端口共享状态）。
- cover：`$changed(addr_map_i)`（或 en/default 相应 changed）在仿真中至少发生
  一次——M1 从未变更过地址表（tb_top C2.6：M1 smoke 取恒定表），若不补这条 cover，
  该 assert 此前只是"从不改变故从不违反"式空转通过。激励来源：M2-CFG01。
- 适用端口：仅 slave 端口。

### C3.2 同 ID 跨 master 端口保序 stall（依据 spec §5.2.1/§5.2.2/§5.2.4）

- 状态：每个 slave 端口维护一张按低 `AxiIdUsedSlvPorts` 位 keyed 的"未决记录"表，
  每条记录 = `{方向, 目标 master 端口 idx}`；AW/AR 握手（`valid&&ready`）发生时用
  `decode_mst_port()` 算出本笔目标并登记（若该 key **同方向**已有记录则不重复登记，
  只在配对完成后清除）；对应 B（写方向）或 `rlast`（读方向）握手发生时清除同 key
  同方向记录。**方向是匹配条件的一部分**：只在"新请求方向 == 已有记录方向"时才
  比较目标是否相同——异向的同低位 ID 不落在本属性范围内（5.2.1 明文"同方向"）。
- 主属性（5.2.1/5.2.2）：若某 key 已存在**同方向**未决记录且其目标 `!=` 本次新到
  达同 key 同方向请求的目标，则本次 AW/AR 的 `valid&&ready` **不得**在旧记录清除
  前为真。
- 配套属性（5.2.4，澄清"不误伤"）：若某 key 已存在**同方向**未决记录且其目标
  **等于** 本次新到达同 key 同方向请求的目标，则本次握手**不因该记录的存在**被
  上一条属性推迟（用于捕获 stall 逻辑矫枉过正这类假想缺陷）。
- **范围边界说明（依据 spec §5.2.5 + §6.5，非阻塞）**：以上两条属性只从**外部
  可观测的 AW/AR/B/R 握手**建模未决记录，不感知 demux 内部"原子读 ID 注入 AR
  计数器"的影子机制。spec §6.5（+ §5.2.5 交叉引用）已把该机制蒸馏为派生条款：
  一笔原子读可能使同一 slave 端口上另一笔低位 ID 相同、目标不同 master 端口的
  普通读依 §5.2.1 被 stall——由 ATOP 写事件引发的读方向 stall，属**正常设计行为、
  非退化**（spec §6.5 明述）。若该跨方向 stall 在仿真中出现，因其不满足"同 key
  同方向已有记录"的前提，以上两条属性均不会因此报告违反——这是**有意的范围
  边界**（spec §5.2.5/§6.5 把该现象定为正常行为、不作 §5.2.1 违反判据），不是
  遗漏；亦即 spec §6.5 末句"本条登记前撞见此现象不得判 DUT_BUG"的对应实现侧落点。
- cover：主属性前提发生 ≥1 次（激励来源 M2-OR01）；配套属性前提发生 ≥1 次（激励
  来源 M2-OR02）。
- 适用端口：仅 slave 端口。

### C3.3 W 通道次序（依据 spec §5.5.1/§5.5.2）——沿用既有机制，只新增 cover

- 现有 `axi_chan_sva` C2.3 的 `aw_len_q`/beat 计数机制已隐含"同接口上前后 W burst
  不交织"（该文件顶部注释原话："assumes bursts on this interface are not
  interleaved across sources"）；`mstport_agent.sv` 的 monitor（BUG-0009 修复后）
  用 `aw_q[$]` FIFO 按 AW 接受序配对 W burst，其配对顺序本身即复现 spec §5.5.2
  "select 信号存入 FIFO、按 AW 接受序 pop"的机制。**M2 不新增独立 assert**——若
  交织/错序真的发生，现有 C2.3 的长度校验与 scoreboard 的 burst 归属判定会失配。
- M2 新增的是**非空转证据**：一条 `cover property`（挂在 master 端口侧，紧邻
  `axi_chan_sva` 或其 monitor 逻辑）记录"某 W burst 起始时，该 master 端口存在
  ≥2 个不同源 slave 端口贡献的 AW 处于未决"，用以证明 C2.3 这条既有断言不是只在
  "从未真正竞争"的场景下平凡通过。激励来源：M2-WO01。
- 时序判据的颗粒度新增需求（不落在 SVA，落在 scoreboard）：需要跨 slave 端口的
  AW 接受时间戳，用于校验"master 端口侧观测到的 burst 完成序 == 各源 AW 接受的
  先后序"——见 scoreboard_refmodel C5.5。
- 适用端口：master 端口（复用既有挂点，不新增实例）。

### C3.4 事务在飞上限（依据 spec §2.1 `MaxMstTrans`/`MaxSlvTrans` 行 + §5.4.1/§5.4.2/§5.4.3/§7.4.5；BUG-0016/REV-007 裁决落地后，`MaxSlvTrans` 侧机制已由"上游确认项"改判"mux 侧机制不存在"的已定结论，`MaxMstTrans` 侧字面值改判"计数器定宽提示"、有效上限公式见 §5.4.1）

- 状态：每端口维护一个按（约简 ID、方向）分桶的计数器数组，每桶额外带一个"当前
  绑定目标 master 端口"寄存器——依据 spec §2.1 `MaxMstTrans` 行（分桶口径 + 目标
  绑定寄存器机制，spec 该条款自身出处标注为 demux.md §Ordering and Stalls→
  Implementation L70-74）与 §5.4.1；**不用单一扁平计数器**（§2.1/§5.4.1 已把
  此前的扁平表述纠正为分桶口径）。AW/AR 握手时对应桶 `+1`，B/`rlast` 握手时对应桶
  `-1`。同桶计数非零期间只能绑定一个目标——换目标属于 C3.2 的 stall 判据范围
  （spec §5.2），不属本条计数上限判据（spec §5.4.1），二者为同一底层机制的两面
  （spec §2.1 `MaxMstTrans` 行明述），构造激励时须分清楚（呼应
  scoreboard_refmodel C5.3 的同一说明）。
- slave 端口侧判据（`MaxMstTrans`，依据 spec §5.4.1/§5.4.3/§7.4.5；M2-TL01 场景
  收窄到单一 ID 桶×方向×目标 master 端口三元组；BUG-0016/REV-007 裁决）：该桶
  计数 `> MaxMstTrans` **不构成 `assert property` 判据**——spec §5.4.1 已把
  "≤ `MaxMstTrans`" 改判为**有效上限 `2^⌈log₂MaxMstTrans⌉−1`**（基线 15，非字面
  10）之内的计数器位宽取整效应，越过字面值零功能损害。判决门降级为：路由/数据/
  响应路由/完成正确（scoreboard 侧，spec §1/§3.1/§5.1）作**唯一**判决锚点；本
  属性只保留非判决 `cover property`/`uvm_info`（记"该桶计数达到 `MaxMstTrans`
  至少一次"与"计数越过 `MaxMstTrans` 字面值至少一次"，随裁决可升格）；
  `assert property` **不落地**。
- master 端口侧判据（`MaxSlvTrans`，依据 spec §5.4.2/§5.4.3；BUG-0016/REV-007
  裁决）：REV-005 曾解锁的"≤ `MaxSlvTrans` 绝不假红"弱化可观测上界 checker
  **已被 spec §5.4.2 正式收回**——其前提（mux 侧存在 per-ID 在飞计数机制）不
  成立：`MaxSlvTrans` 经 `axi_xbar.sv` L141 实为 `axi_mux` 的 `MaxWTrans`
  （AW→W ID 高位 FIFO 深度），mux 侧无按 ID 分桶的在飞计数机制，master 端口每
  ID 在飞数受上游 demux 每桶有效上限（§5.4.1）主导、可超 `MaxSlvTrans`（已见证
  8>6）。故 master 侧**无任何可断言在飞上界**——`assert property` 不落地（非
  "仍不落地"的临时状态，而是机制不存在的已定结论）；只保留非判决 `cover
  property`/`uvm_info`（记该（master 端口, 可观测前缀后 ID, 方向）组合计数
  达到/越过 `MaxSlvTrans` 至少一次），判决门同 slave 侧锚定 scoreboard 正确性。
- cover：slave 端口侧，某桶计数达到 `MaxMstTrans` 至少发生一次（`SVA_TXLIMIT`）
  ＋计数越过 `MaxMstTrans` 字面值至少发生一次（`SVA_TXLIMIT_OVER`，非空转见证
  BUG-0016 现象，不隐含判决）——激励来源 M2-TL01；master 端口侧对应 cover（每
  master 端口 × 每可观测前缀后 ID × 每方向计数达到/越过 `MaxSlvTrans` 至少一次）
  随 M2-TL02 落地，同为非判决见证，不再挂靠"随弱化上界 checker 一并落地"
  （该 checker 已被收回，见上）。
- 适用端口：两类端口（同一"分桶计数器"结构的两种读出方式）。

### C3.5 ATOP 读写通道成对响应与 ID 唯一性（依据 spec §6.3/§6.4）

- 属性 1（成对响应，§6.3）：每个 slave 端口上，`aw_valid&&aw_ready` 且 `aw_atop`
  编码要求读响应时，登记一条"待验证"记录；该记录须等到 B 与 `rlast`（同 ID）都
  出现才清除——只断言"两者最终都出现"，**不得**断言二者的相对到达顺序或间隔拍数
  （延迟不敏感红线，C2.4/spec §7.4）。
- 属性 2（ID 唯一性 SVA 兜底，§6.4）：每个 slave 端口上，一笔 ATOP AW 握手发生
  时，其 ID 不得与该端口当前任何（读或写方向）未决事务的 ID 相同。这是**环境应
  遵守**的约束（uvm_env C2.4/C5.5 已在驱动纪律层面保证）；本属性只作 SVA
  兜底监视——若被触发，指向 **env 违反了自身约束**（TB_BUG），不得先入为主判
  DUT_BUG。
- cover：属性 1 前提（原子读发起）至少发生一次（激励来源 M2-AT01）。
- 适用端口：仅 slave 端口。

## 4. M3 增量：C3.2 的判决范围与运行时配置可见性

本节收口三条 `ACCEPTED@M3` 债务在 SVA 侧的落点（BUG-0024/BUG-0025/BUG-0031），
并把 §3 结构性前提里那条"译码复用（单一事实源）"要求补落到位。均为**实现约束**，
判据内容仍只从 spec 推导。

- **C4.1 C3.2 的判决范围正式声明为"每完整 ID 至多一笔在飞"**（BUG-0024，
  REV-011 §2.3 路线 (b)）：这本就是 C3.2 状态定义（"若该 key 同方向已有记录则不
  重复登记"）规定的单槽模型。同一完整 ID 有 **N≥2 笔**在飞时（spec §5.2.4 允许的
  同 ID 同向同目标合法堆积），保序判决由 `scoreboard_refmodel.md` C5.1/C5.2 的
  **每事务队列判据**承担。范围声明须同时出现在模块头注与本条目，且**范围之外必须
  真正解除武装**——只写文档不算兑现：模块内独立于判决表的在飞计数可作该前提的
  来源。范围边界见证（"本次运行有多少笔落在判决范围之外"）须随每次运行报出：
  任何"stall SVA 也过了"的说法都必须附上该数，非 0 即表示该次运行的 SVA 保序判决
  是范围受限的、结论只由 scoreboard 承担。激励来源：M3-OR05。
- **C4.2 C3.2 的译码必须用运行时活值配置**（BUG-0031 + BUG-0025 第 1 层）：§3
  "译码复用"段要求的"与 scoreboard 对同一个运行时活值表译码"须落实到**调用点**
  ——地址表、`en_default_mst_port_i[i]`、`default_mst_port_i[i]` 三个实参一律取
  tb_top C4.2 挂进来的运行时信号，**不得**传编译期常量、也不得把 `en_default`
  写死为 0。依据：spec §3.4（地址表运行时可变）、§3.3（default port 逐端口使能）。
  任何"本模块在某场景下静默/空转"的掩蔽条件**不得只写在代码注释里**（BUG-0007/
  FB-7 同形），须指向 `doc/bugs.md` 的行或其守卫。激励来源：M3-CFG02、M3-DE02。
- **C4.3 §5.2.6 的三层在 SVA 侧落地**（BUG-0025）：default port 路由的事务**必须
  进入**在飞跟踪表（它的目标是真实 master 端口，spec §5.2.6 第 1 条）；完整 ID
  维度的完成序判决**必须**纳入译码未命中事务（spec §5.2.6 第 2.a 条）；低位 ID
  桶维度**不得**写断言，排除须以**引 spec §5.2.6 的注释显式写出**并配一条非判决
  cover（spec §5.2.6 第 2.b/第 3 条）。**红线**：排除不得靠"未登记 ⇒ 读默认或陈旧
  值 ⇒ 比较恰好为假"达成（spec §5.2.6 第 3 条）。激励来源：M3-DE02、M3-OR04。
- **C4.4 配置点相关**：各 SVA 实例数、ID 前缀宽度、目标索引宽度一律由当前配置点的
  `NoSlvPorts`/`NoMstPorts` 推导（`NoSlvPorts=1` 时前缀为 0 位，tb_top C5.6）；
  C2.5 的"禁断言仲裁序"红线在 N×1 配置点（mux 侧汇聚最大）尤须遵守（spec §5.5.4）。

## 5. 交付形态与验收锚点

- 产物：`tb/sva/` 下协议 SVA 模块（+ M2 新增的挂点/姊妹模块，文件边界见 §3 结构
  性前提）+ tb_top 内 `bind`/直接例化语句（tb_top C4.1/C4.2），收录于
  `sim/flist/tb.f`。
- M1 判据：编译弹起、smoke（M1-01/M1-02）期间 assert 类覆盖有采样且**零 assertion
  失败**（SVA passive 通过）。
- M2 判据：C3.1/C3.2/C3.5 及 C3.3 的既有断言随对应场景（M2-CFG01/OR01/OR02/
  WO01/AT01）落地、assert 零失败**且**配套 cover 均非零命中（非空转证据）；
  C3.3 本身不新增 assert，只补 cover。**C3.4（事务在飞上限，slave 侧 M2-TL01 +
  master 侧 M2-TL02）均已从 `assert property` 降级为非判决 cover/`uvm_info`**
  （BUG-0016/REV-007 裁决，spec §5.4.1/§5.4.2/§5.4.3/§7.4.5）：判决门改锚
  scoreboard 路由/数据/响应正确 + 达标 cover 非空转，不阻塞其余场景，不再有
  "上游确认项待落地"的开放项。

## 引用的 spec 章节

§1、§2.1、§2.3、§3.1、§3.2、§3.3、§3.4、§4.3、§4.5、§5.2、§5.2.4、§5.2.6、§5.4、
§5.5、§5.5.4、§6.3、§6.4、§6.5、§7.4。
