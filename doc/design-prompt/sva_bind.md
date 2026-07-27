# Design prompt — `sva_bind`（协议/时序 SVA bind 挂接，M1 骨架）

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

## 3. 后续里程碑挂接位（成文，M2+ 激活；M1 不实现）

以下为已知需 SVA 表达但属后续里程碑的时序约束，此处登记挂接位以便 M2 直接扩展，
**M1 不落地断言**：

- **C3.1** 地址表/ default port 不在 AW/AR valid 期间变更（§3.4）——env 侧约束，
  可用 SVA 兜底监视。
- **C3.2** 同 ID 同向跨 master 端口保序 stall（§5.2）——M2 功能场景配合参考模型。
- **C3.3** W-burst 随 AW 同序、burst 内不与他源交织（§5.5.1）——master 端口侧。
- **C3.4** 事务在飞上限 `MaxMstTrans`/`MaxSlvTrans`（§5.4）。
- **C3.5** ATOP 读写通道成对响应与 ID 唯一性约束（§6.3/§6.4）。

## 4. 交付形态与验收锚点

- 产物：`tb/sva/` 下协议 SVA 模块 + tb_top 内 `bind` 语句（tb_top C4.1），收录于
  `sim/flist/tb.f`。
- M1 判据：编译弹起、smoke（M1-01/M1-02）期间 assert 类覆盖有采样且**零 assertion
  失败**（SVA passive 通过）。

## 引用的 spec 章节

§1、§2.3、§3.4、§4.3、§4.5、§5.2、§5.4、§5.5、§6.3、§6.4、§7.4。
