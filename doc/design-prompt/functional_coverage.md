# Design prompt — `functional_coverage`（M2 functional/assert 覆盖采集）

> 约束层：本文规定覆盖采集组件的**实现结构**（covergroup 挂点/采样时机、cover
> property 配对约定）；bin 的判定依据全部**引用 `doc/spec.md`**，本文不新增 spec
> 未载的判决语义（behavior-leak 禁区）——覆盖 bin 只记录"某情形是否发生过"，不是
> pass/fail 判决，判决仍在 `scoreboard_refmodel.md`/`sva_bind.md`。
> 前置：CLAUDE.md §6 覆盖率口径「六类 line+cond+fsm+tgl+branch+assert，≥90% 合格」
> （spec §0 行 4 同述）。

## 0. 目标与范围

六类覆盖口径中，`line`/`cond`/`fsm`/`tgl`/`branch` 由 VCS 对 DUT RTL 的编译期插桩
机械产生（`sim/Makefile` 编译选项开关），是不涉及行为设计的工具/编译配置事项，
**本文不涉及**。`assert` 类由已挂接的 SVA（`sva_bind.md`）的 `assert`/`cover
property` 原生产生（VCS assertion 覆盖数据库），但它天然只反映"断言的触发前提是否
被真实激励到、断言是否失败"，不反映"场景组合是否被激励覆盖到"——这正是本文新增的
**functional 覆盖（covergroup）**要补的维度。本文的设计输入聚焦两件事：

1. 新增 covergroup 的挂点、采样时机、bin/cross 设计（本节起 §1/§2）。
2. `assert` 类覆盖与 M2 新增 SVA 的配对约定（§3，呼应 `sva_bind.md` §3 每条新增
   `assert property` 均须配一条 `cover property` 的要求）。

## 1. Covergroup 挂点与采样时机

- **C1.1** 建议独立文件 `tb/functional_coverage.sv`（模块或 class，嵌入 scoreboard
  还是独立 collector 由 DV 判断）；**唯一硬约束**：采样点取自已有 monitor/
  scoreboard 产生的事务对象/判决状态，不重新解析总线信号——避免出现第三套独立
  解码逻辑，与 scoreboard_refmodel C1.1/C1.5 的"单一事实源"原则一致。
- **C1.2** 采样时机：每笔事务在 scoreboard 完成判决（route/resp 匹配或 stall 判定
  落地）的那一刻采样一次，而不是在 driver 发起时采样——保证 bin 记录的是"实际
  发生的情形"而非"意图发起的情形"（例如 M2-OR01 的 stall 触发 bin，只在 scoreboard
  确认 stall 语义生效后才计入）。

## 2. M2 覆盖点清单（逐条引用 spec + 对应 testplan 场景）

- **`cg_addr_reconfig`**：coverpoint「本次事务发生在地址表变更前/变更后的哪一批」
  （bins：`pre_change`、`post_change`）；cross 源 slave 端口 idx。依据 spec §3.4；
  场景 M2-CFG01。
- **`cg_stall`**：coverpoint「本次 AW/AR 请求相对 §5.2.1 的状态」（bins：
  `stalled`、`not_stalled_same_target`、`not_stalled_diff_direction`）；cross
  方向（读/写）。依据 spec §5.2；场景 M2-OR01/OR02。
- **`cg_tx_limit`**：coverpoint「该（slave 端口, 低位 ID 桶, 方向）组合的在飞峰值
  计数」（bins：按 `0..MaxMstTrans` 分桶，至少含 `== MaxMstTrans` 一档）——分桶
  维度依据 spec §2.1 `MaxMstTrans` 行 + §5.4.1（分桶口径的规范来源；spec 该条自身
  出处标注 axi_demux.md L70-74）。master 端口的对应 coverpoint（依据 spec §5.4.2）
  随 M2-TL02 的**已解锁弱化上界 checker** 一并补齐——分组取「每 master 端口 × 每
  可观测（前缀后）ID × 每方向」的在飞峰值（bins 含 `== MaxSlvTrans` 一档；方向
  分开计，见 `doc/bugs/BUG-0011.md` ## regression_guard 不假红约束）；机制级触发点
  仍为 spec §5.4.3 上游确认项、不采集。本处先登记 slave 侧。场景 M2-TL01（+ M2-TL02）。
- **`cg_w_order`**：coverpoint「某 master 端口在一笔 W burst 起始时，是否存在
  ≥2 个不同源 slave 端口贡献的 AW 处于未决」（bins：`single_source`，
  `multi_source_contended`）。依据 spec §5.5；场景 M2-WO01。
- **`cg_atop`**：coverpoint 该 ATOP 事务发起 slave 端口 idx × 是否为要求读响应的
  编码；依据 spec §6.3；场景 M2-AT01。
- **`cg_atop_read_interaction`（观察性，非判决，依据 spec §6.5 + §5.2.5）**：
  coverpoint「该 ATOP 原子读发起时，是否存在低位 ID 相同的普通读在同一 slave
  端口在飞」（bins：`none`、`colliding_read_present`）。**本 bin 只记录情形是否
  发生，不附带任何 pass/fail 判定**——spec §6.5（+ §5.2.5 交叉引用）已把"原子读
  ID 注入 AR 计数器可致读方向跨方向假冲突 stall"蒸馏为派生条款，并明确该现象
  属正常设计行为、只影响是否被 stall（性能/时序）、不影响功能正确性，故任何
  checker 均不得依据该 bin 的命中与否下判决结论（spec §6.5 该条 self-sourced 至
  `axi_demux.md` §Atomic Transactions→Implementation L83-87）。场景 M2-AT01。

## 3. assert 类覆盖：cover property 配对约定

- `sva_bind.md` §3 每条 M2 新增 `assert property`（C3.1/C3.2/C3.4-slave 侧/C3.5）
  以及 C3.3 的既有断言，均须配一条**同触发前提**的 `cover property`（清单见
  `sva_bind.md` 各条目下方的"cover"小节）。目的：在 VCS assert 覆盖数据库中区分
  "从未失败因为从未被触发"与"被真实触发且未失败"，让 `assert` 类覆盖数字有意义，
  而不仅是"零失败"。依据：CLAUDE.md §6 覆盖口径 assert 类、spec §0 行 4。
- 本文的 covergroup（§2）与 SVA 的 cover property（本节）是**互补而非重复**的两
  层：covergroup 记录"场景组合"（跨事务、跨端口的宏观情形），cover property 记录
  "某条具体断言的触发前提"（单笔事务/单个属性局部条件）。两者对同一情形可能都有
  记录（例如 `cg_stall` 的 `stalled` bin 与 sva_bind C3.2 主属性的 cover 大致
  对应同一激励），这是有意的交叉验证，不是重复劳动的信号。

## 4. M4 收敛口径的占位

本文登记的 bin 是 M2 场景对应的最小集合，用于证明"M2 新增的判决机制不是靠空转/
偶然通过"。M4 六类 ≥90% 收敛时若发现缺口，遵照 `workflow/dispatch/coverage_hole.md`
的流程处理（先问"testplan 场景是否存在"，而非直接派 DV 试图硬凑激励命中）；本文
不预判 M4 的具体缺口，也不在此提前给出 M3（decode error/错误路径）或 M4（配置矩阵）
的 bin 设计——那些属于各自里程碑的 arch 设计输入卡范围。

## 引用的 spec 章节

§0（行 4）、§2.1、§3.4、§5.2、§5.4、§5.5、§6.3、§6.5。
