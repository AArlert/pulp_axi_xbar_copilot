# M5 spec-gap sweep（ARCH 交付物，rev 门禁前）

> 本文是 arch 的 spec-gap 分析交付物（非 REV-xxx，非 evidence）。产出粒度到
> "候选 testplan 行 + spec 锚点 + 声明式 decline 理由"，**不写 checker/覆盖率
> 判据、不写 RTL/TB**。候选行**不直接进 `doc/testplan.md`**——须先过 rev 门禁
> （rev 裁决注册哪些行、哪些 decline 理由成立）。
> spec pin = `doc/spec.sha256`
> `c8279a87cde1eefa94ac0e0094e19fbe97917d7e9eceade57b09a865feedfb8d`
> （本卡只读；已核 `sha256sum doc/spec.md` 与 pin 一致，含 2026-08-03 落地的
> Change record #13 / §3.2 clause 3-4）。
> 版本 0.5.3，里程碑 M5。

## 0. 范围、方法与前沿溯源

### 0.1 输入

- `make explore`（M5，**0 场景行**）给出的 7 个未引用小节（逐字转录于 §1）+
  一条 sourceless 场景 `M0-01`。
- `doc/spec.md`（按小节读）、`doc/testplan.md`（30 行，M0–M4 全 ✅）、
  `doc/feature-matrix.md`、`doc/milestone.md` §M5、
  `doc/design-prompt/verification_maturity.md` 决策点 2–4、`workflow/records.md`。
- guard 面：`make guards FILES="doc/spec.md doc/testplan.md"` 实测命中 **10 条**，
  id 集合 = {G-0010, G-0028, G-0032, G-0033, G-0036, G-0038, G-0039, G-0044,
  G-0045, G-0046}，与卡片给定索引**逐一致**（无多、无缺）。逐条正文已读，与本卡
  结论的耦合见 §4 / §5。

### 0.2 两条方法学前提（决定本卡结论的形状）

**(a) M5 的出口是"能力落地 + KILL 自证"，无覆盖率百分比门**（`doc/milestone.md`
M5；六类 ≥90% 收敛属 M6）。因此本卡不以覆盖率数字作动机——这与 M4 sweep 不同，
M4 sweep 的每条候选行都挂了一条 baseline 覆盖率定位线索，M5 没有等价的机械线索
可挂。M5 的动机只能来自两处：**spec 条款的未激励半边** 与 **M5 出口条件本身要求
的证据落点**。

**(b) M5 的场景形态与 M0–M4 定向场景不同**（约束随机 + 多种子 + soak）。这一点
对"可证伪的具名场景"契约构成真实压力，处置见 §3.2——本卡不接受"跑随机就算覆盖"
这一稀释路径。

### 0.3 前沿溯源：这 7 条是 M4 decline 的残余，不是新信息 ★

对比 `doc/review/M4-spec-gap-sweep.md` §2 的 11 条处置表：M4 sweep 当时 **11 条
全部 declined**（其中 §2.1/§6.2/§7.3/§7.4.3 附带"建议补引"或经新行承接）。其后
`SPEC-2.1`/`SPEC-7.3.1`/`SPEC-7.4.3` 经 M4-FT01 落地、`SPEC-6.2` 经 M3-CF04 补引
落地，四条离开前沿；**剩下的 7 条 = M4 已 decline 且无人补锚的那 7 条**，逐一对应：

| 本卡前沿条目 | M4 sweep 处置 | 状态 |
| --- | --- | --- |
| §1.3 | declined（概述层） | 未补锚 ⇒ 复现 |
| §2.2 | declined（定义性表格） | 未补锚 ⇒ 复现 |
| §2.3 | declined（定义性表格） | 未补锚 ⇒ 复现 |
| §6.1 | declined（概述层） | 未补锚 ⇒ 复现 |
| §7.1 | declined（属性由跨配置承接） | 未补锚 ⇒ 复现 |
| §7.1.2 | declined（延迟不敏感属性） | 未补锚 ⇒ 复现 |
| §7.4.4 | declined（理由性/上游确认项） | 未补锚 ⇒ 复现 |

**结论**：`scripts/docs.py` 的前沿计算**对 decline 决定无记忆**——一条经 rev 签核
declined 的小节，下个里程碑会原样再次出现在前沿上，逼迫下一位 arch 重做同一判断。
这不是 spec 缺口，是工具缺口。处置见 §6 落地清单第 (5) 项（另开 L0 卡 + FB 留行，
本卡不动 `scripts/`）。本卡对这 7 条**重新独立判断**（不因 M4 已 decline 就自动
沿用——M5 方法学变了，判断前提可能变），但凡结论相同者显式标注"与 M4 一致"。

### 0.4 前沿条目的机器溯源（一条是解析假阳性）

`scripts/docs.py:1374` 的 `SPEC_SEC_RE = (?:^#{1,6}\s*|§)(\d+(?:\.\d+)*)` 把
`doc/spec.md` 正文里**任何** `§N.N` 串都收进"小节集合"，不区分它指的是 spec 自身
小节还是别的文档的小节。实测四条无标题条目的出处：

| 条目 | 唯一出处 | 性质 |
| --- | --- | --- |
| §1.3 | `doc/spec.md:498`（Change record #6）中的 **"依据 REV-011 §1.3"** | **假阳性**——指的是 `doc/review/REV-011.md` 的 §1.3，不是 spec §1 的第 3 条 |
| §6.1 | `doc/spec.md:499`（Change record #7）中的 `§4.1-6、§6.1-2/4-5 正文未改动` | 真实条款（§6 clause 1），但入集经由**范围记法**而非正文编号 |
| §7.1.2 | `doc/spec.md:59`（§2.1 `PipelineStages` 行）`（与 §7.1.2 spill register 同类）` | 真实条款（§7.1 clause 2），经内部交叉引用入集 |
| §7.4.4 | `doc/spec.md:282`（§5.2.6）`（同 §7.4.4 / §8.4 处置）` | 真实条款（§7.4 clause 4），经内部交叉引用入集 |

补充事实：**spec §1 正文用的是无编号 `-` 项目符号，不存在编号条款 §1.1/§1.2/§1.3**
（`doc/spec.md:31-44`）。M4 sweep 把 §1.3 读作"第 3 个项目符号（master 端口 ID 宽
> slave）"并 decline——结论不变，但溯源事实应记准，见 §1 表首行。

---

## 1. 7 个未引用小节逐条处置

判定口径（声明式，rev 可逐条复核）：一条小节需要 M5 场景行，当且仅当
**(i)** 它含可证伪的外部可观测行为断言，**(ii)** 该断言在既有 M0–M4 行中未被
判决过或只被判决了一半，**且 (iii)** M5 的方法学（随机/多种子/soak）能真正激励
它——三者缺一即 decline。

| 小节 | M5 结论 | 理由（声明式） |
| --- | --- | --- |
| **§1.3**（无标题；机器溯源见 §0.4） | **不需要 · declined** | 双重理由：(a) **该编号在 spec 中不存在**——§1 用无编号项目符号，前沿上的 `§1.3` 实为 Change record #6 引用 `REV-011 §1.3`（他文档小节）被正则误收，对它提场景等于对不存在的条款提场景；(b) 即便按 M4 sweep 的"第 3 个项目符号"读法（master 端口 ID 宽 > slave，高位为响应路由前缀），其可断言语义已由 §5.1 承接、经 M1-02 实测判决，§1 系导言层、无独立可测行为。**与 M4 一致**。 |
| **§2.2 模块参数**（`Cfg`/`ATOPs`/`Connectivity`/五通道 struct 类型/`slv_req_t…`/`rule_t`/`MstPortsIdxWidth`） | **不需要 · declined** | 参数**定义性表格**，本身不是场景（`workflow/records.md`："runs without error" 不是场景；一张类型/默认值表同理不可证伪）。各参数的**非基线取值**已由 M3 配置矩阵承接并实测：`ATOPs=0`→M3-CF04、稀疏 `Connectivity`→M3-CF04（+SPEC-8.3/8.4）、`MstPortsIdxWidth` 退化（1×N/N×1）→M3-CF01/CF02、`rule_t` 宽度→基线用 `xbar_rule_32_t`（§0 #2 钉定）已被全部 M1–M4 行行使。M5 的通用随机 vseq 是**配置无关**的（design-prompt C2.7），在全配置点复用只是把同一批参数取值再跑一遍随机激励，**不新增任何 §2.2 断言**。**与 M4 一致**。 |
| **§2.3 端口** | **不需要 · declined** | 端口方向/位宽**定义性表格**，被每一条场景隐式行使，无独立可断言行为。两条容易被误当作缺口的子项已有明确归属：(a) `test_i`——spec 正文自声明"**功能验证恒 0**"，即 spec 自己把它排除出功能场景空间，构造 `test_i=1` 场景将测 spec 未定义行为；(b) `rst_ni` 运行中热复位（1→0）——spec 仅定义"异步、低有效"，**未定义运行中热复位的功能语义**，M4 sweep §3.6 已 decline 并指出须先补 spec 才可测，M5 随机化**不得**把 `rst_ni` 纳入随机维（否则激励进入无 oracle 区）。**与 M4 一致**，并对 M5 追加一条约束提示（见 §6 落地清单第 (4) 项）。 |
| **§6.1**（ATOP 概述：完整 AXI4+AXI5 ATOP；ATOP 由 `aw.atop != '0` 的 AW 发起） | **不需要 · declined** | 概述 + **定义性谓词**。前半句"实现完整 AXI4"是 §1 的重述，其可测面（AxLEN 全合法域 0..255 等）由 §1 承接、M5 随机层 C2.1 已引 `§1`；后半句"`aw.atop != '0` 发起 ATOP"是**约束层用的定义**（design-prompt C2.5 据此写 `atop` 约束），不是可证伪的 DUT 行为断言——没有任何 DUT 输出能"违反一个定义"。ATOP 的可判语义在 §6.3（B+R 两通道应答）/§6.4（ID 唯一环境约束）/§6.5（跨方向假冲突 stall），已由 M2-AT01/M3-AT02 实测。**与 M4 一致**。 |
| **§7.1 spill register 位置语义**（标题） | **需要 · 由 M5 soak 三行集合承接锚点**（不新增独立定向场景） | 见 §3.1 完整论证。一句话：§7.1 的可判半边是"spill 的**位置**（mux 后 / demux 前）与存在与否**不改变功能响应**"，这在 M5 之前只被 M3-CF01（NO_LATENCY）/M3-CF02（CUT_ALL_PORTS）的定向激励打过，且那两行**未引** SPEC-7.1；M5 soak 三行恰好横跨三档 `LatencyMode`（cfgA=NO_LATENCY / baseline=CUT_ALL_AX / cfgB=CUT_ALL_PORTS）并施加**同一套随机激励与同一套延迟不敏感判据**，是本项目对该条款最强的可证伪构造。锚点落在 M5-SK01/SK02/SK03 三行上（集合级可证伪，逐行声明所属集合）。 |
| **§7.1.2**（spill 切断组合路径、每通道 +1 拍、**不损吞吐**） | **需要（仅"不改变功能响应"半边）· 由同一 soak 三行承接；"+1 拍/不损吞吐"半边显式 declined** | 本条**必须切两半**，否则违反 §7.4.3：<br>• **可判半边**（spill 存在与否不改变功能响应）——同 §7.1，由 soak 三行集合承接。<br>• **不可判半边**（"每通道增加一拍延迟""不损失吞吐"）——**declined，且是硬性的**：§7.4.3 明文"**任何 latency checker 不得断言固定周期数**"，而"+1 拍"就是固定周期数断言；"不损吞吐"若要判，需要一个**吞吐下界**，而许可来源（xbar.md §Pipelining 只说"每 spill 加一拍、不损吞吐"，无任何端到端数字）**未给**任何可推导的下界，且 soak 下的实际吞吐还被 responder 随机反压、mux 仲裁、§5.4.1 每桶上限共同决定——从 spec 推不出期望值。故该半边**至多做非判决 cover / 上报指标，不得升格为 checker**。**与 M4 结论一致，但本卡把 decline 的边界画到了半条款粒度**，因为 M5 是第一个真有可能被"soak 下测吞吐"诱惑的里程碑。 |
| **§7.4.4**（基线 `PipelineStages=1`+`CUT_ALL_AX` 不影响 M1 smoke；cycle-accurate 时序核查须上游确认后补 spec） | **不需要 · declined** | 纯**理由性条款 + 上游确认项**：前半句是对 M1 落地可行性的论证（已由 M1-01/M1-02 绿灯事后证实，非独立断言）；后半句自声明"须另行上游确认后再补 spec（上游确认项，**不阻塞里程碑**）"——在上游确认到位前**无 spec 依据可测**，构造 cycle-accurate 场景即违反不变量 4（期望值无来源）。**与 M4 一致**。附注：M5 soak 会把 `PipelineStages=1` 的线路在高压下跑满，若真出现功能异常，判决锚点是 §7.4.2（插桩不改变功能响应）而非 §7.4.4。 |

**小结**：7 条中 **5 条 declined**（§1.3 / §2.2 / §2.3 / §6.1 / §7.4.4），
**2 条需要**（§7.1 / §7.1.2 的可判半边），且这 2 条**不新增定向场景**，而是由 M5
本就要交付的 soak 三行承接锚点——零额外激励成本。

---

## 2. `M0-01`（sourceless 场景）：既不退役，也不补行为锚点，而是补 §0 锚点

### 2.1 事实

- M0-01 = 上游 `tb_axi_xbar` sanity（6×8 随机读写各 200 笔并发、ATOP 开），
  状态 ✅，evidence `doc/evidence/v0.0.1/M0-01.log`（首行
  `make run TEST=upstream_sanity SEED=1`，合规），regress.list 第 2 行常驻
  `upstream_sanity 1`。
- feature-matrix 对应行 `F-M0-01` 的 **module 列写的是 `(infra)`**，feature 描述
  是"仿真基建：vendored DUT + 依赖库在 VCS-2018 下编译/弹性/运行"——**记账体系
  早已把它归为基建行、而非 spec 行为行**。
- 它的 oracle 是**上游 tb 自带的 FIFO 参考网络**，不是本项目从 `doc/spec.md`
  推导的 scoreboard。

### 2.2 判断

**退役 = 错。** 三条理由：(a) 它是一条真实的、可重放的绿，退役等于把已记录的绿
抹掉——属"narrowing"，且抹掉的是本项目唯一一次"独立激励路径"证据（
`workflow/bugs.md` DUT_BUG 判据明写"reproducible with an independent stimulus
path (e.g. upstream smoke TB)"——将来若真要指控 DUT，这条路径是必需的第二支点）；
(b) M0 只有这一行，退役后 M0 里程碑变成 0 行，`make handoff`/`make check` 的
里程碑完成度由行数推导，会凭空产生一个空里程碑；(c) BUG-0001（VCS-2018 编译 NCE）
的解决见证就挂在这条线上。

**补行为锚点（SPEC-1/3.1/3.2/5.1/5.2 等）= 也错。** 那些条款的判决在本项目里
由 spec 推导的 scoreboard 承担（M1-01/M1-02 起）。给 M0-01 挂行为锚点，等于宣称
"这条行的期望值从 §3.1/§5.1 推导"——**而事实是它的期望值来自上游 tb 自己的参考
网络**。这正是不变量 4 与 `workflow/bugs.md` TB_BUG 判据（"scoreboard's expected
value derived wrongly — or derived **from the RTL instead of the spec**"）警戒的
方向。为了让机器检查变绿而虚构一条推导链，是本仓库明令禁止的记账污染。

**正确解 = 补 `SPEC-0` 锚点（§0 适配表 #1）。** §0 #1 逐字写着：
"上游 tb 经 `axi_xbar_intf`（AXI_BUS interface 包装，xbar.sv 声明 L174-193）驱动，
**M0 sanity 沿用**"。这就是 M0-01 存在的 spec 依据本身——它验证的是**适配表 #1
所声明的那条 bring-up 路径成立**（vendored DUT + 依赖库在 VCS-2018 下编译、弹起、
经 `axi_xbar_intf` 跑通上游 tb 并零 mismatch 自然结束）。可证伪性完好：若该路径
跑不通或 tb 报 mismatch，§0 #1 的前提即被证伪（历史上 BUG-0001 正是它红过一次）。
引用形式已有先例——M3-CF01/CF02/CF03/CF04 四行均引 `SPEC-0`。

**配套**（rev 裁决，非机械）：在 M0-01 描述里补一句**oracle 归属声明**——
"判决由上游 tb 自带 FIFO 参考网络给出，**非**本项目 spec 推导 scoreboard；本行
为 bring-up sanity，**不承载任何 §1–§8 行为条款的判决权威**，该权威自 M1-01 起
由 `scoreboard_refmodel` 承担"。这句话把"为什么它只引 §0 不引行为条款"写进真值表
本身，防止后人再次把它读成缺口。

### 2.3 副作用提示（给 orch/rev）

`doc/evidence/v0.0.1/M0-01.log` 无 `# spec_ref:` 头（`docs.py` 对该头是**计数不
强制**的约定层）。补 `SPEC-0` 后若要让约定自洽，可在该 evidence 补一行
`# spec_ref: SPEC-0`——但那会改动一份**已归档的 M0 证据文件**。本卡建议：**不动
evidence**，理由是改历史证据的风险高于约定层收益；若 rev 认为必须动，须作为独立
L0 卡处理并在 commit 说明。

---

## 3. M5 场景形态：哪些该由随机/soak 承接，以及如何不稀释契约

### 3.1 §7.1 / §7.1.2 为什么该由 soak 承接（而不是新开定向场景）

三个可选构造，逐一权衡后取第三：

1. **新开定向"spill 等价"场景**（同一激励在 NO_LATENCY / CUT_ALL_AX /
   CUT_ALL_PORTS 三档下逐笔比对）——**否决**。它要求同一 topology 下只变
   `LatencyMode` 的三个新配置点（现有 cfgA/cfgB 把 LatencyMode 与拓扑捆在一起：
   cfgA=1×8+NO_LATENCY、cfgB=6×1+CUT_ALL_PORTS），意味着新增 elaboration 配置点
   + 一套"跨 run 逐笔比对"的对拍设施——现有 scoreboard 是"对参考模型"而非"对另一
   次 run"，这是新基建。成本远大于收益，违反"最小实现"。
2. **回填锚点到已关闭的 M3-CF01/CF02 行**（给它们补引 SPEC-7.1/7.1.2）——**不
   推荐**。这两行确实实测了该条款的可判半边（同一套功能判据在无 spill / 全 spill
   下逐条成立），补引在语义上站得住；但它要回改**已 ✅ 归档行**的描述，且与其
   evidence 的 `spec_ref` 头产生漂移。M4 sweep 有过"建议补引 SPEC-6.2 到 M3-CF04"
   的先例且被采纳，故这条路**不是禁行**，留给 rev 定夺（见 §6 第 (3) 项，标为
   可选）。
3. **由 M5 soak 三行承接**——**推荐**。M5 出口条件本就要求"每拓扑类（baseline
   6×8 + cfgB 6×1 + cfgA 1×8）至少一条长随机饱和场景"，而这三个拓扑**恰好**分别
   是 CUT_ALL_AX / CUT_ALL_PORTS / NO_LATENCY 三档 `LatencyMode`。零额外激励成本，
   且比 M3-CF01/CF02 的定向激励强得多（随机激励 + 长时饱和 + 三层自检）。

### 3.2 "可证伪的具名场景"契约在随机/soak 下如何不被稀释 ★

这是本卡最需要 rev 复核的方法学结论。随机/soak 最容易滑向的稀释形态是：
写一行"跑随机，不出错即通过"——那正是 `workflow/records.md` 点名拒绝的
"runs without error is not a scenario"。本卡提出**四条硬要求**，要求 rev 把它们
作为 M5 所有随机/soak 行的注册前置条件：

- **R1 判据全部前置、全部 spec 锚定。** 每一条随机/soak 行的 PASS 判据必须逐条
  写在行里、逐条挂 SPEC-x：路由（§3.1/§3.2）、ID 前缀（§5.1）、数据完整性（§1）、
  响应码（§4）、同 ID 同向完成序（§5.2）、活性（§5.5.4 无饿死）、在飞上限
  （§5.4.1 有效上限 15）。**判据集合与定向场景完全相同**——随机只换激励生成方式，
  不换 oracle。这一条使"通过"永远意味着"这些具名断言在这批激励上成立"，而不是
  "没人报错"。
- **R2 激励空间前置声明，且必须可达其声明的角落。** 行里写明该行**必须真正到达**
  的构造（如 soak 行的"各（低 3 位 ID 桶 × 方向）在飞计数**同时**压到 §5.4.1 有效
  上限"）。到不了 = 该行未成立，即便零 mismatch——这就是可证伪性的落点，也是防
  `CONSTRAINT_BUG`（"约束过紧致目标不可达"）的前置守卫。饱和探测器本身要有 KILL
  自证（M5 出口条件已列）。
- **R3 停止判据 ≠ 通过判据。** "覆盖率趋于饱和"（连续 K 窗口增量 < ε）是**停止
  条件 + 上报指标**，**不是** PASS/FAIL（design-prompt C4.7 已如此定义）。soak 的
  PASS = R1 的判据全净 + R2 的角落真到达。**M5 无覆盖率百分比门**（那是 M6）。
- **R4 种子确定性 + 多种子不改真值表结构。** 每行的 `repro` 仍是单条 canonical
  `TEST=/SEED=` 命令（`workflow/records.md` 契约），多种子集合活在
  `sim/regress/regress.list` 与签核捕获的 `result_summary.txt` 里，
  **testplan 不新增列、不新增"多种子"伪场景行**（design-prompt C3.7/C3.8）。
  推论：**"多种子回归"本身不是一条 testplan 行**——它是对既有 30 行的重复执行，
  证据形态是回归摘要，出口条件已如此写。本卡**不**为它提任何场景行。

### 3.3 M5 骨架行提案（超出 7 小节前沿，rev 可整体接受/拒绝/延后）

前沿只回答"哪些 spec 小节没人引"，但 M5 真正的头号 gap 是 `make explore` 标题里
那半句：**M5, 0 scenario rows registered**。按 `workflow/records.md` 规则 1
（"Register before you code"），M5 的 DE/DV 卡在场景行注册前**不可派发**。故本卡
一并提出 M5 骨架行——**6 行，与 M5 出口条件一一对应**，不多不少：

| 候选 id | config | 一句话场景 | spec 锚点 | 对应 M5 出口条件 |
| --- | --- | --- | --- | --- |
| M5-RN01 | cfgC | 通用随机 vseq 在 `UniqueIds=1` 配置点跑通，集中 ID 分配器构造性满足前置条件 | §5.3.1/§5.3.3、§6.4、§1、§3.1/§3.2、§5.1、§5.2、§7.4 | 约束随机激励层 |
| M5-RN02 | cfgD | 通用随机 vseq 在稀疏 `Connectivity` + `ATOPs=0` 配置点跑通，约束保证 `atop≡'0` 且地址不译码到非连通端口 | §6.2、§8.3、§8.1、§3.1/§3.2、§5.1、§1、§7.4 | 约束随机激励层 |
| M5-RN03 | cfgE | 通用随机 vseq 在 `FallThrough=1` 配置点跑通，功能判据与 `FallThrough=0` 逐条相同 | §2.1（`FallThrough`）、§7.3.1、§7.4.2、§3.1/§3.2、§5.1、§1 | 约束随机激励层 |
| M5-SK01 | baseline | 长随机饱和 soak（6×8，`CUT_ALL_AX`），各桶在飞压至 §5.4.1 有效上限，三层自检全净 + 无 watchdog 超时 | §5.4.1、§5.5.4、§5.2、§5.1、§3.1/§3.2、§1、§4、§7.4、**§7.1/§7.1.2 可判半边** | 压力/soak |
| M5-SK02 | cfgB | 同上，6×1（`CUT_ALL_PORTS`），mux 汇聚仲裁最紧，W burst 随 AW 同序不交织 | §5.5.1/§5.5.2/§5.5.4、§5.4.1、§7.4、**§7.1/§7.1.2 可判半边** | 压力/soak |
| M5-SK03 | cfgA | 同上，1×8（`NO_LATENCY`，零 spill），全组合路径下同一套判据 | §5.4.1、§5.5.4、§7.2、§7.4、**§7.1/§7.1.2 可判半边** | 压力/soak |

完整行文本（可直接粘贴）见 §6.1。

**为什么恰好 6 行**：出口条件"通用随机虚拟序列在 baseline + cfgA–E 全配置点复用
跑通"共 6 个配置点，而其中 baseline/cfgA/cfgB 三点由 soak 行（长随机 = 随机 vseq
的超集）同时承担，故只需 RN01–RN03 覆盖 cfgC/cfgD/cfgE。`workflow/records.md`
"One scenario id per config point that matters" 因此**恰好**满足，无冗余行。

**其余两条出口条件不需要场景行**（声明式）：
- **多种子回归**——见 R4，证据形态是 `result_summary.txt` 回归摘要，非场景行。
- **KILL 覆盖（不变量 5）**——证据形态是 `doc/bugs.md` 的 `KILL` 行 +
  `make check MILESTONE=5` 机器门，非场景行。
- **BUG-0044 到期二选一仲裁**——rev 裁决动作，非场景行；但其结果**可能**新增
  场景行，见 §5 开放风险 1。

---

## 4. Spec change proposals

### SP-A（阻塞级）§4 clause 7 环境约束的里程碑作用域未含 M5

- **original**（`doc/spec.md` §4 clause 7，环境约束段）：
  > **环境约束（BUG-0032 裁决，REV-012 §Item 1；M4 重开并延展至 M4，BUG-0039
  > 裁决，REV-017 §Item 3）**：**M3 与 M4 全部场景**不向译码未命中地址发起任何
  > ATOP（送往未命中地址的 AW 恒 `aw.atop ≡ '0`），使上述未定义情形**构造性
  > 不可触发**。
- **new（二选一，由 rev 裁决）**：
  - (a) **逐里程碑延展**（沿用 M3→M4 的既有形态）：把 "M3 与 M4 全部场景" 改为
    "**M3、M4 与 M5 全部场景（含 M5 起的约束随机与 soak 激励）**"，并在裁决依据
    栏追加 "M5 延展，BUG-xxxx 裁决，REV-xxx"；或
  - (b) **改为里程碑无关口径**：改为 "**本项目全部场景**不向译码未命中地址发起
    任何 ATOP……；解除本约束须先补齐 err_slv×ATOP 应答的许可来源并重开 BUG-0032"
    ——与 §3.2 clause 4、§6.2、§5.3.3、§8.3 中已有的**无里程碑限定**环境约束
    写法一致，从此不再需要逐里程碑重裁。
- **rationale**：
  1. **事实**：现行文本作用域**逐字**只覆盖 M3 与 M4。M5 的约束随机会随机化
     `addr`（含未命中地址，design-prompt C2.2 的 `unmapped_weight` 旋钮）**与**
     `atop`（C2.5 升为有界 `rand`），二者的笛卡尔积**必然**产生"未命中地址 ×
     `atop != '0`"——而该组合的 err_slv 应答形态在许可来源中**未定义**（§4 clause 7
     本身的结论：§4.3 单拍 B 与 §6.3 B+R 两读互斥）。届时 scoreboard **没有
     oracle**，只能现场发明期望值 = 触碰 spec-from-RTL 红线（不变量 4）。
  2. **precedent（这是决定性的）**：REV-013 曾把提案原文的 `M3/M4` **主动收窄
     为 `M3`**，理由逐字为"M4 覆盖率收敛若需触发该组合须**重开仲裁**，spec 现无
     M4 config-matrix 承载该约束，写 M4 会构成 spec-vs-artifact 的 Retention 不
     一致"（Change record #7）；随后 BUG-0039/REV-017 才正式把它延展到 M4。**同
     一逻辑逐字适用于 M5**：spec 现在**没有**任何条款把该约束绑到 M5 激励上。
  3. **已存在的分叉**：`doc/design-prompt/verification_maturity.md` C2.2 与 C2.5
     已经把 "`atop != '0 → addr` 命中某条 rule（`§4` clause 7 宽读，REV-018）"
     写成 M5 随机层的**硬约束**——即 design-prompt 正依赖一条其作用域并不覆盖
     M5 的 spec 条款。这是 arch 侧行为定义与 spec 之间的**潜在分叉**（DE 读
     design-prompt 会照做，DV 读 spec 会发现 M5 无此约束），须在 M5 任何 DE 卡
     派发前弥合。
  4. guard **G-0044** 的 `ref:` 段亦指向同一面（放开 `atop` 随机化范围前必须先
     走仲裁补 §6 条款）——本提案与 BUG-0044 到期仲裁**同面不同条**：BUG-0044 管
     "能不能放开到 store/swap/compare"，SP-A 管"已批准的有界 load 子集在 M5 随机
     化下，未命中地址那一格谁来禁"。两者应在同一轮 rev 会审，避免各自留半边。
- **impacted entries**：M5-RN01/RN02/RN03、M5-SK01/SK02/SK03 六行的环境约束句
  （现按 (a)/(b) 未定，行文中标注"待 SP-A 裁决"）；
  `doc/design-prompt/verification_maturity.md` C2.2/C2.5；guard G-0032/G-0039
  的作用域（其"里程碑签核机械抽查"形态需相应写到 M5 签核）；BUG-0032 详情页
  （若取 (b)，其 reopening 路径措辞需同步）。
- **arch 倾向**：**(b)**。理由：(a) 会在 M6/M7 再次到期，制造第三次同形仲裁；
  而 spec 里同类环境约束（§3.2 clause 4"含 M5 起的随机化"、§6.2、§8.3 之外的
  §5.3.3）本就以里程碑无关形态存在，(b) 使写法归一。但 REV-013 的收窄理由
  （"spec 现无 M4 config-matrix 承载该约束"）在 (b) 下不再自然成立，故**必须由
  rev 裁决，arch 不代决**。

### SP-B（阻塞级）§8 clause 3 稀疏 `Connectivity` 环境约束的作用域未含 M5

- **original**（§8 clause 3）：
  > **环境约束（BUG-0002 裁决，REV-001 §5）**：**M3/M4 稀疏 `Connectivity`
  > 配置下**，地址表（`addr_map_i`）与 default master port 须构造为**不把任一
  > slave 端口 `i` 的任何地址译码到其非连通 master 端口 `j`**……
- **new（与 SP-A 同口径二选一）**：(a) "M3/M4/**M5**……"；或 (b) "**本项目全部
  稀疏 `Connectivity` 配置下**……"。§8 clause 4 的"不阻塞 M3/M4"同步处理。
- **rationale**：M5-RN02 在 cfgD（稀疏 `Connectivity`）上跑**随机地址**。§8.2
  明写"命中非连通 master 端口时如何应答，许可来源未定义"，故随机地址生成器必须
  受本约束绑定；而现行文本只绑 M3/M4。与 SP-A 同构、同一轮裁决最经济。
  design-prompt C2.2 已把它写成 cfgD 硬约束（引 `§8.3`），分叉形态同 SP-A。
- **impacted entries**：M5-RN02 行；`verification_maturity.md` C2.2；§8 clause 4。

### 无需提案的邻接条款（本卡已逐条核实，声明式记录）

- **§6.2**（`ATOPs=1'b0` 时环境保证不发起任何 ATOP）——约束句本身**无里程碑
  限定**（只有其后"M4 配置矩阵的 `ATOPs{0}` 维度……"一句是 M4 语境的**举例**）。
  M5-RN02 直接受其绑定，**无需改 spec**。
- **§3.2 clause 4**（`start_addr < effective_end`）——原文逐字含"**含 M5 起的
  随机化**"，已前瞻覆盖，**无需改**。配套义务见 guard G-0045：若 M5 随机地址表
  要构造 `end_addr=='0'` 哨兵，须**同批**落地 testplan 行 + refmodel 哨兵分支 +
  判决锚；否则生成器必须**排除** `end_addr=='0'`。本卡提案的 M5 骨架行**均取
  排除路线**（见 §6.1 行文本），不解锁哨兵——这是一次**声明式收窄**，请 rev 明确
  记录：M5 不实现哨兵分支，§3.2 clause 3 的实测归属继续悬空（现由 guard G-0045
  承接，非 M5 债务）。
- **§5.3.1/§5.3.3**（UniqueIds 前置条件）——"验证侧：`UniqueIds=1` 配置下激励
  必须构造性满足前置条件"，无里程碑限定，M5-RN01 直接受绑，**无需改**。
- **§0 #3 配置矩阵**——已含 `FallThrough {0,1}`（REV-018 落地），M5-RN03 有矩阵
  归属，**无需改**。

---

## 5. Open risks（未决架构问题 / 待裁决 BUG）

1. **BUG-0044 到期于 M5 签核，且其裁决结果可能新增 M5 场景行。** 若 rev 裁决
   "补 §6 条款、放开 store/swap/compare 编码"，则需新增至少一条 M5 ATOP 子类型
   场景行 + scoreboard oracle 扩展；若裁决"维持有界 load 子集"，则本卡的 6 行
   骨架不变。**本卡按后者（维持有界子集）起草**——这是 design-prompt C2.5 的既定
   方向且零 spec 改动。**若 rev 取前者，§3.3 的行集须重开。** guard G-0044 同时
   把该行钉为 `(axi_mux, Toggle)`/`(axi_err_slv, Toggle)` 两格中 `aw.atop[4]/[5]`
   非-load 子类型位的覆盖率归属主体——**改写/关闭该行时须同卡重裁那两格归属**，
   否则静默产生 UNOWNED（BUG-0049 形态）。
2. **SP-A / SP-B 未裁决前，M5 的 DE 卡不可派发。** 六条骨架行的环境约束句悬在
   "待裁决"状态；行可以先注册（`🔲` 状态本就是"已规划未实现"），但**约束块的
   实现**（design-prompt C2.2/C2.5 硬约束）依赖裁决结果的措辞。建议 orch 把
   SP-A/SP-B 与 BUG-0044 打包成同一张 L3 rev 卡。
3. **R2（"角落真到达"）目前无机器守卫。** "各桶在飞同时压到 §5.4.1 有效上限"
   若未达成而 soak 仍零 mismatch，行会假绿。M5 出口条件已要求"饱和探测器"配 KILL
   自证，但**探测器与判据的绑定关系**（探测器红 ⇒ 该行不算 PASS）需在 DV 卡里
   明确落地，否则 R2 只是文字。
4. **`regress.list ⊇ testplan ✅ 集合` 的差集检查仍未机械化**（BUG-0028/BUG-0036
   两度复发，guard G-0028/G-0036 均记为"补行不是守卫"）。M5 多种子把 regress.list
   从 22 行膨胀到约 120 行后，人工比对将不可持续；REV-019 §G-3 已把该项列为
   Decision-3 落地卡的强制承接项。**本卡不代拟实现**，只在此重申它是 M5 的记账
   级风险，且新增 6 行会同步扩大差集面。
5. **前沿工具对 decline 无记忆**（§0.3）。不处理的话，M6 sweep 会第三次收到同一
   批小节。属工具缺口，非 spec 缺口。

---

## 6. orch 可机械执行的落地清单

> 顺序即依赖序。凡标 **[rev 前置]** 者，未经 rev 裁决**不得**执行。

### 6.1 [rev 前置] 注册 6 条 M5 testplan 行

rev 批准后，向 `doc/testplan.md` 追加以下 6 行（`status` 一律 `🔲`，
`evidence`/`repro` 一律 `-`，脚本 owned）。行内标注 `【SP-A 裁决后按最终措辞
对齐】` 的环境约束句，须在 SP-A/SP-B 落地后由同一张卡同步为裁决文本。

```
| M5-RN01 | M5 | 通用随机虚拟序列 `xbar_random_vseq` 在 cfgC（4×4，`UniqueIds=1'b1`）跑通：四个 slave 端口并发发约束随机事务（`len`/`addr`/`id`/`is_write`/`atop` 按 rev 批准的约束块，`atop` 限于 `{'0} ∪ 合法 atomic-load 编码`），集中 ID 分配器**构造性满足** SPEC-5.3.1 前置条件（同方向在飞 ID 唯一，SPEC-5.3.3 明述不满足即行为未定义、判决无意义）与 SPEC-6.4（ATOP 事务 ID 与全部读写在飞 ID 互异）；判决沿用既有 spec 推导 scoreboard——路由目标（SPEC-3.1/SPEC-3.2）、master 侧 ID 前缀（SPEC-5.1）、数据完整性（SPEC-1）、响应码、同 ID 同向完成序（SPEC-5.2）零 mismatch，SVA 零失败，仿真自然结束。**环境约束**：不向译码未命中地址发起任何 ATOP（SPEC-4 clause 7 宽读，REV-018；【SP-A 裁决后按最终措辞对齐】）、地址表构造取 `start_addr < effective_end` 且**排除** `end_addr=='0'` 哨兵（SPEC-3.2 clause 4；哨兵分支本里程碑不实现，见 guard G-0045）。判决延迟不敏感（SPEC-7.4），不断言拍数、不断言仲裁发生序（SPEC-5.5.4） | cfgC | 🔲 | - | - |
| M5-RN02 | M5 | 通用随机虚拟序列 `xbar_random_vseq` 在 cfgD（4×4，稀疏 `Connectivity`，`ATOPs=1'b0`）跑通：约束**构造性保证** (a) 全部 AW 恒 `aw.atop ≡ '0`（SPEC-6.2 环境约束，`ATOPs=0` 时 ATOP 行为未定义）、(b) 任一 slave 端口的随机地址不译码到其非连通 master 端口（SPEC-8.3 环境约束，SPEC-8.2 明述该情形许可来源未定义；【SP-B 裁决后按最终措辞对齐】）；判决沿用既有 scoreboard——路由目标（SPEC-3.1/SPEC-3.2、SPEC-8.1 连通矩阵）、ID 前缀（SPEC-5.1）、数据完整性（SPEC-1）、响应码与未命中 DECERR（SPEC-4）零 mismatch，SVA 零失败。**环境约束**：同 M5-RN01（未命中地址恒 `aw.atop≡'0` 在本配置下由 (a) 蕴含；地址表排除 `end_addr=='0'` 哨兵）。判决延迟不敏感（SPEC-7.4） | cfgD | 🔲 | - | - |
| M5-RN03 | M5 | 通用随机虚拟序列 `xbar_random_vseq` 在 cfgE（`FallThrough=1'b1`，其余同基线）跑通：W beat 可与对应 AW 同拍被接受（SPEC-2.1 `FallThrough` 字段语义、SPEC-7.3.1），随机激励下功能判据与 `FallThrough=0` 基线**逐条相同**——路由（SPEC-3.1/SPEC-3.2）、ID 前缀（SPEC-5.1）、数据完整性（SPEC-1）、响应码、同 ID 同向完成序（SPEC-5.2）零 mismatch，SVA 零失败（SPEC-7.4.2：延迟不敏感插桩不改变功能响应）。**环境约束**：同 M5-RN01。不断言 W 与 AW 同拍被接受的**具体拍号**（SPEC-7.4.3 禁固定周期断言），只判功能等价 | cfgE | 🔲 | - | - |
| M5-SK01 | M5 | 长随机饱和 soak（baseline 6×8，`LatencyMode=CUT_ALL_AX`）：六个 slave 端口用 `xbar_random_vseq` 背靠背发 ≥10k 事务（或覆盖率饱和、或预算上限，三者先到为准），responder 施加有界随机反压，使**每（低 `AxiIdUsedSlvPorts`=3 位 ID 桶 × 方向）在飞计数同时**压到 SPEC-5.4.1 有效上限（`2^⌈log₂MaxMstTrans⌉−1 = 15`，**非**字面 10）——**该角落未真正到达即本行不成立**，即便零 mismatch。PASS 判据：三层自检全净（scoreboard 路由 SPEC-3.1/SPEC-3.2、ID 前缀 SPEC-5.1、数据完整性 SPEC-1、响应码与 DECERR SPEC-4、同 ID 同向完成序 SPEC-5.2 零 mismatch；SVA 零失败；functional covergroup 正常采样）+ **无 watchdog 超时**（活性：SPEC-5.5.4「无饿死——每个持续 valid 的请求终将被授予」；watchdog 只判是否终将前进、不判第几拍前进，SPEC-7.4.3）。**覆盖率趋于饱和（连续 K 窗口增量 < ε）是停止判据与上报指标，不是 PASS/FAIL**（M5 无覆盖率百分比门）。判决延迟不敏感（SPEC-7.4），不断言仲裁发生序（SPEC-5.5.4）。**环境约束**：同 M5-RN01。**本行与 M5-SK02/M5-SK03 构成跨 `LatencyMode` 三档（本行 = CUT_ALL_AX，两侧 AW/AR spill）的同判据集合，共同承载 SPEC-7.1/SPEC-7.1.2 中「spill register 的位置与存否不改变功能响应」这一可判半边；「每通道 +1 拍 / 不损吞吐」半边不作判据**（SPEC-7.4.3 禁断言固定周期，且许可来源未给任何吞吐下界） | baseline | 🔲 | - | - |
| M5-SK02 | M5 | 长随机饱和 soak（cfgB 6×1，`LatencyMode=CUT_ALL_PORTS`）：六个 slave 端口全部汇聚到单一 master 端口，mux round-robin 仲裁竞争最紧；规模/反压/饱和角落要求同 M5-SK01（各桶在飞同时压至 SPEC-5.4.1 有效上限）。PASS 判据同 M5-SK01，另重点核 W burst 随其 AW 保持同序且 burst 内不与他源交织（SPEC-5.5.1/SPEC-5.5.2）与无饿死活性（SPEC-5.5.4）；**不得断言任何一条特定 round-robin 发生序、不得断言某一拍的具体被授权端口**（SPEC-5.5.4 checker 期望值告诫）。**环境约束**：同 M5-RN01。**本行为 SK 三行集合中的 CUT_ALL_PORTS（五通道全 spill）档，SPEC-7.1/SPEC-7.1.2 承接口径同 M5-SK01** | cfgB | 🔲 | - | - |
| M5-SK03 | M5 | 长随机饱和 soak（cfgA 1×8，`LatencyMode=NO_LATENCY`，零 spill、全组合路径）：单 slave 端口向八个 master 端口持续发随机事务；规模/反压/饱和角落要求同 M5-SK01（该端口各（ID 桶 × 方向）在飞同时压至 SPEC-5.4.1 有效上限）。PASS 判据同 M5-SK01（SPEC-7.2 该档位编码 `10'b000_00_000_00`）。**环境约束**：同 M5-RN01。**本行为 SK 三行集合中的 NO_LATENCY（零 spill）对照档，SPEC-7.1/SPEC-7.1.2 承接口径同 M5-SK01** | cfgA | 🔲 | - | - |
```

### 6.2 [rev 前置] 注册 3 条 feature-matrix 行（否则 6 条新场景会被判为 orphan）

```
| F-M5-01 | M5 | 约束随机激励层：`axi_seq_item` 四 rand 字段 + 有界 `atop`（`{'0} ∪ 合法 atomic-load 编码`）的 constraint 块 + 集中 ID 分配器 + 配置无关通用随机虚拟序列，在 baseline+cfgA–E 全配置点复用；spec 环境约束编码进约束块而非事后兜底（SPEC-5.3.1/5.3.3、SPEC-6.2、SPEC-6.4、SPEC-4 clause 7、SPEC-8.3、SPEC-3.2 clause 4） | uvm_env+seq_lib | M5-RN01, M5-RN02, M5-RN03, M5-SK01, M5-SK02, M5-SK03 |
| F-M5-02 | M5 | 压力/soak 与活性守卫：长随机饱和 + 各（ID 桶 × 方向）在飞同时压至 SPEC-5.4.1 有效上限（饱和探测器，未达即该行不成立）+ heartbeat watchdog 活性判据（SPEC-5.5.4 无饿死，不判具体拍号 SPEC-7.4.3）+ 覆盖率饱和作停止判据非 PASS/FAIL | uvm_env+tb_top | M5-SK01, M5-SK02, M5-SK03 |
| F-M5-03 | M5 | 跨 `LatencyMode` 三档功能等价：NO_LATENCY / CUT_ALL_AX / CUT_ALL_PORTS 下同一套随机激励与同一套延迟不敏感判据逐条成立，承载 SPEC-7.1/SPEC-7.1.2「spill 不改变功能响应」可判半边；「+1 拍 / 不损吞吐」半边显式不作判据（SPEC-7.4.3） | uvm_env+scoreboard_refmodel | M5-SK01, M5-SK02, M5-SK03 |
```

### 6.3 [rev 前置] `M0-01` 锚点补齐（§2）

- 在 `doc/testplan.md` 的 M0-01 描述中补 **`SPEC-0`**（§0 适配表 #1：上游 tb 经
  `axi_xbar_intf` 驱动、M0 sanity 沿用）+ 一句 oracle 归属声明（"判决由上游 tb
  自带 FIFO 参考网络给出，非本项目 spec 推导 scoreboard；本行为 bring-up sanity，
  不承载任何 §1–§8 行为条款的判决权威"）。
- **不**给它挂任何 §1–§8 行为条款锚点（理由见 §2.2）。
- **不**动 `doc/evidence/v0.0.1/M0-01.log`（`spec_ref` 头属约定层，计数不强制；
  改历史证据风险 > 收益。若 rev 坚持要补，须另开 L0 卡）。
- 可选：`doc/feature-matrix.md` 的 `F-M0-01` module 列现为 `(infra)`，与本处置
  一致，**无需改**。

### 6.4 声明式记录：5 条"不需要场景"的决定（rev 逐条复核并签核）

以下 5 条 M5 **不注册**场景行，理由已在 §1 逐条给出，请 rev 在裁决记录中逐条
确认（这是 narrowing，须显式声明，不得沉默略过）：

| # | 小节 | decline 一句话理由 |
| --- | --- | --- |
| D1 | §1.3 | 该编号在 spec 中不存在（正则误收 Change record 里的 `REV-011 §1.3`）；即便按"§1 第 3 个项目符号"读，其语义由 §5.1 承接、M1-02 已实测 |
| D2 | §2.2 | 参数/类型定义表非场景；各参数非基线取值已由 M3 配置矩阵（CF01–CF04）实测承接；M5 配置无关随机 vseq 不新增 §2.2 断言 |
| D3 | §2.3 | 端口定义表非场景；`test_i` 经 spec 自声明"功能验证恒 0"排除；`rst_ni` 运行中热复位语义 spec 未定义，须先补 spec 方可测（M5 随机化**不得**纳入 `rst_ni` 维） |
| D4 | §6.1 | 概述 + 定义性谓词（"`aw.atop != '0` 发起 ATOP"是约束层用的定义，非可证伪 DUT 行为）；ATOP 可判语义在 §6.3/6.4/6.5，已由 M2-AT01/M3-AT02 实测 |
| D5 | §7.4.4 | 理由性条款 + 自声明"上游确认项，不阻塞里程碑"；cycle-accurate 时序核查在上游确认前无 spec 依据，构造场景即违反不变量 4 |

**附加声明式收窄（同样须 rev 记录）**：
- **N1**：§7.1.2 的「每通道 +1 拍 / 不损吞吐」半边在 M5 **不作判据**——SPEC-7.4.3
  禁固定周期断言，且许可来源无吞吐下界；至多作非判决 cover / 上报指标。
- **N2**：M5 随机地址表**排除** `end_addr=='0'` 哨兵构造，故 §3.2 clause 3 的
  实测归属继续悬空，由 guard G-0045 承接，**不列为 M5 债务**。
- **N3**：「多种子回归」**不是** testplan 行（证据形态 = `result_summary.txt`
  回归摘要）；「KILL 覆盖」**不是** testplan 行（证据形态 = `doc/bugs.md` KILL 行
  + `make check MILESTONE=5`）。二者均不注册场景。

### 6.5 [rev 裁决] 两条 spec change proposal + 一条 BUG 登记

1. **SP-A**（§4 clause 7 环境约束延展至 M5，(a) 逐里程碑 / (b) 里程碑无关二选一）
   ——**阻塞** M5 任何 DE 卡派发。arch 倾向 (b)，但由 rev 定。
2. **SP-B**（§8 clause 3 稀疏 `Connectivity` 环境约束延展至 M5，口径同 SP-A）
   ——**阻塞** M5-RN02。
3. **登记一条 `doc/bugs.md` 行承载 SP-A+SP-B**（`suspect=spec`，taxonomy
   `SPEC_ISSUE`）——依据 CLAUDE.md §3"bug 卡派发前 `doc/bugs.md` 对应行必须已
   存在"，且 M4 的同形先例 BUG-0039 正是这样登记的。登记是无条件的，即便本卡
   内已给出提案文本。**本卡不写 `doc/bugs.md`**（交付边界），由 orch 登记。
4. **建议与 BUG-0044 到期仲裁同轮会审**（同属 §6 ATOP 面，guard G-0044 已把
   两格 Toggle 覆盖率归属绑在该行上；分轮裁决易各留半边）。

### 6.6 [可选，rev 定夺] 回填锚点与工具缺口

- **(可选) 回填 `SPEC-7.1`/`SPEC-7.1.2` 到已关闭的 M3-CF01/M3-CF02 行**——语义
  站得住（那两行确实在无 spill / 全 spill 下跑同一套功能判据），先例是 M4 sweep
  的"SPEC-6.2 补引 M3-CF04"。**arch 不推荐**：会改动已 ✅ 归档行并与其 evidence
  的 `spec_ref` 头漂移；§6.1 的 SK 三行已足够承接该锚点。
- **(另开 L0 卡 + `doc/fw-feedback.md` 留行) 前沿工具对 decline 无记忆**
  （§0.3）——7 条前沿条目全部是 M4 已 decline 的残余，M6 会第三次收到。方向建议
  （不代拟实现）：让 `scripts/docs.py` 的前沿计算减去一份**rev 签核过的 decline
  登记**，使 decline 成为可累积的机器事实而非每轮重做的人工判断。**本卡不动
  `scripts/`。**
- **(另开 L0 卡) `SPEC_SEC_RE` 假阳性**（§0.4）——正则把 spec 正文里指向**其他
  文档**的 `§N.N`（如 Change record 的 `REV-011 §1.3`）收进 spec 小节集合，制造
  幽灵前沿条目。与上一条同属 `scripts/docs.py` 的前沿计算面，宜合并一张卡处理，
  同样须在 `doc/fw-feedback.md` 留行（CLAUDE.md §5 硬要求）。
