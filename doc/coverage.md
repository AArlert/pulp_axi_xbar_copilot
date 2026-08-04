# 覆盖率：从零读懂六类覆盖、urg 报告与 waiver 签核

> **这份文档是什么**：`doc/axi.md`（被测对象）、`doc/uvm.md`（验证环境）的
> 姊妹篇。目标读者是**知道 SV/UVM 但没碰过覆盖率收敛实务**的新人。全部例子
> 来自本仓库（`pulp_axi_xbar_copilot`，AXI4 crossbar 6×8 验证项目）。
>
> **这份文档不是什么**：它不是覆盖率的判据来源。判据定义见 `doc/spec.md` §0#4
> 和 `doc/milestone.md` M6 出口条件。

---

## 1. 覆盖率在验证中干什么

验证的核心问题：**怎么知道测够了？**

- **功能正确性**由 checker（scoreboard/SVA）回答——"DUT 做错了吗？"
- **充分性**由覆盖率回答——"还有哪些路径/状态/条件没走到？"

100% 覆盖率不等于没 bug（checker 可能漏判），但低覆盖率一定意味着有些
代码从未被激励击中——那些角落里的 bug 根本没机会被检出。

## 2. 六类代码覆盖

VCS 的 `-cm` 开关支持六个类型关键字。本仓库用全部六类（spec §0#4）：

| 类型 | 测什么 | 一句话 |
|---|---|---|
| **Line** | 每行 RTL 是否执行过 | 最粗的度量——某行没跑到就是没覆盖 |
| **Cond** | 组合条件各项的真/假组合 | `if (A && B)` 需要看到 A=0、B=0、A=1&&B=0、A=0&&B=1、A=1&&B=1 |
| **FSM** | 状态机的状态和状态迁移弧 | 每个状态到过吗？每条弧走过吗？ |
| **Toggle** | 每根信号的 0→1 和 1→0 翻转 | 某位恒 0 或恒 1 就是没覆盖 |
| **Branch** | if/case 的每个分支 | Line 告诉你"走过"，Branch 追加"每个分支都走过了吗" |
| **Assert** | SVA 断言的触发/成功/失败 | 断言从没被触发（vacuous）也算没覆盖 |

### 本仓库真实例子

- **Line 未覆盖**：`stream_register.sv:37-38` 的 `if(clr_i)` 两行从未执行
  ——因为 `clr_i` 在例化点硬接 `1'b0`（CW-014）。
- **Cond 未覆盖**：`axi_demux_simple.sv:168` 的 `w_open == {Width{1'b1}}`
  取 0——因为 `w_open` 可达上界封顶在 9，远低于全一值 15（CW-009）。
- **FSM 未覆盖**：`axi_atop_filter` 的非-FEEDTHROUGH 状态全死——进入这些
  状态需要 `atop!=0` 的请求抵达 err_slv，被环境约束禁止（CW-001）。
- **Toggle 未覆盖**：`lzc.sv:67` 的 `index_lut` 是编译期常量查找表，18 位
  值由 localparam 固定，任何激励都翻不动（CW-011）。
- **Branch 未覆盖**：`addr_decode_dync.sv:146` 的 IF else 支——唯一触达
  路径是地址表取 X 值，但 env 从不注 X（CW-008）。
- **Assert 未覆盖**（vacuous）：`spill_register_flushable.sv:99` 的
  `flush_valid` 断言，前提 `flush_i` 恒 0，断言永真但 vacuous——2,912,000 次
  尝试、零次真命中（CW-010）。

## 3. urg：覆盖率报告工具

`urg`（Unified Report Generator）是 VCS 配套工具，从仿真 `.vdb`（覆盖率
数据库）生成报告。本仓库用文本模式（`-format text`）产出到 `out/urgText6/`。

### urg 报告里看什么

1. **模块页**（`modinfo.txt`）——每个模块的六类覆盖率总分 + 每条未覆盖
   bin 的信号名、行号、取值。**这是分诊的主要输入。**
2. **实例页**——区分同一模块的不同例化实例。本仓库按"例化闭包"口径取模块
   级合并值（spec §0#4），不单独看实例。
3. **摘要页**——全局数字一览。本仓库基线结果：132 cells，108 ≥90%，
   24 waivered，0 UNOWNED。

### 一个 bin 长什么样

以 `axi_err_slv` Toggle 页为例（CW-015）：

```
Signal: err_req.aw.atop[5]   0->1: No   1->0: No   INPUT
Signal: err_req.aw.atop[4]   0->1: No   1->0: No   INPUT
...
```

每行 = **一个 bin**。`No` = 该方向的翻转从未发生。`0->1` 和 `1->0` 是
Toggle 的两个方向。每个信号位的每个方向就是一个独立的 bin。

`err_req.aw.atop[5:0]` 共 6 位 × 2 方向 = 12 个 bin，全部 `No`——因为
`axi_atop_filter.sv:252` 在 FEEDTHROUGH 状态把 `mst_req_o.aw.atop` 硬清零。

## 4. 覆盖率格（cell）与三态判定

本仓库的**判定单位 =（模块, 类型）二元组**。例如 `(axi_err_slv, Toggle)` 是
一格。全部 132 格用三态判定：

| 状态 | 含义 |
|---|---|
| **≥90%** | 达标——该格合格 |
| **<90% 且有 waiver** | 已 waive 的 bin 是结构不可达的，排除后可达部分达标 |
| **N/A** | 该模块在该覆盖类型上无 bin（如纯例化包装模块无 Line 可测） |

"UNOWNED"（无归属）= 空集是出口条件——每一格必须有人认领。

## 5. waiver 是什么、怎么写

**waiver =** "这些 bin 永远不可能被覆盖，而且**原因不是测试不够**，是**设计
结构决定的**。" 本仓库全部 waiver 是 **Kind-A**（结构/环境不可达，永久）。

### 一条 waiver 的构成（以 CW-015 为例）

| 字段 | CW-015 内容 |
|---|---|
| **覆盖哪些 bin** | `err_req.aw.atop[5:0]` 12 bit-dir |
| **Kind** | A（结构不可达，永久）|
| **不可达论证** | `axi_atop_filter.sv:252` FEEDTHROUGH 状态 `mst_req_o.aw.atop = '0` 硬清零 |
| **解锁条件** | atop_filter 设计改为透传 atop（`:252` 不再硬清零）|
| **rev 记录** | M6 闭环 4 rev APPROVE |

关键点：
- **论证必须指到 RTL 行号** + urg bin 明细，不能只说"应该不可达"。
- **解锁条件**必须是可证伪的——你说"不可达"，我说"如果哪个事实变了就可达"。
- **独立 rev 签核**——waiver 不能自己批自己。

### CW-015 为什么重要

`axi_err_slv` Toggle raw % = 89.71%。差 0.29% 过不了 90% 门槛。排除 CW-015
的 12 个 bin 后，可达 % = 90.74%——这 12 个死 bin 是**跨越 90% 门槛的关键项**。

## 6. 定向闭合 vs 种子饱和——两条收敛路线

覆盖率未达标时有两条补救路线：

### 路线 A：种子饱和（random-first）

多跑几个种子、多跑几轮——约束随机的覆盖率通常随种子数单调递增。在种子边际
贡献趋零前一直跑。

**优点**：不用人工干预，自然发现角落。
**缺点**：某些 bin 靠随机打中的概率极低（如 ATOP inject + ID 计数器 saturate）。

### 路线 B：定向闭合（directed-fallback）

针对未命中的 bin 手工写定向激励。本仓库 M6 的 5 个定向场景：

| 场景 | 目标 bin | 激励设计 |
|---|---|---|
| M6-CV01 | `axi_err_slv` len/addr/size toggle | 长 burst（len≥15）+ 低地址位翻转 + size 多样化 |
| M6-CV02 | `axi_err_slv` resp/user toggle | slave 返多样 resp（含 SLVERR/EXOKAY）|
| M6-CV03 | B/R backpressure toggle | 故意拉低 ready 制造背压 |
| M6-CV04 | `axi_demux_id_counters` AR ID 满 | 同 ID 堆 14 笔在飞 + ATOP inject |
| M6-CV05 | `axi_err_slv` FIFO toggle | 多样 ID + 连续译码未命中 |

### 本仓库的实际选择

M6 原则：**random-first, directed-fallback**。先用 M5 随机层的 266 测试
跑覆盖率基线，只对随机没打中的 30 格做定向分诊，最终 5 个定向场景补齐了
随机层无法到达的角落。其余 bin 全部是结构不可达（waiver 覆盖）。

EC-3 的 scope reduction 是一个真实取舍：计划中的 per-seed 边际贡献分析工具
被定向闭合路线替代——hand-triage 30 格反而比自动化工具更快收敛，因为大部分
未命中 bin 是 Kind-A 结构死因而非激励不足。

## 7. 功能覆盖（covergroup）vs 代码覆盖

上面讲的六类都是**代码覆盖**——度量 RTL 源码的覆盖。另一个维度是
**功能覆盖**（functional coverage），用 SV covergroup 定义"我想看到什么"。

### 区别

| | 代码覆盖 | 功能覆盖 |
|---|---|---|
| **度量什么** | RTL 哪些行/条件/信号被碰过 | 功能场景哪些组合被碰过 |
| **谁定义** | 工具自动从 RTL 提取 | 验证者手写 covergroup |
| **盲区** | RTL 没写的功能=没有对应代码→不知道缺 | 验证者没想到的组合=没写→不知道缺 |

### 本仓库的功能覆盖

`tb/functional_coverage.sv` 里有几个 covergroup：

- `cg_stall`：背压/仲裁停顿场景
- `cg_tx_limit`：在飞事务数到达有效上限（spec §5.4.1 的 15）
- `cg_atop_read_interaction`：ATOP 读响应交互
- `cg_decode_error`：译码错误路径
- `cg_xbucket_total`：跨桶并发
- `cp_atop_subtype`：四子类型（store/load/swap/compare）

这些 covergroup 是 bug 回归守卫和角落到达见证，不是 spec 条款驱动的系统化
交叉覆盖——这是 M7 方法学评估中的 G2 缺口（`doc/M7-methodology-review.md`）。

## 8. 覆盖率收敛工作流（M6 实录）

```
步 0  make regress COV=1 → urg → cov_baseline.py → 132格×三态现状表
步 1  30格逐格分诊 → doc/M6-cov-triage.md → 五组分流
步 2  CW候选论证 → rev签核 → doc/coverage-waivers.md 登记
步 3  DV场景编码+仿真 → make evidence → testplan翻绿
步 4  全量重跑 → 132格全闭合 → rev收口
```

每一步都有具体产出（文件名/rev 编号），不是空转。步 1 的分诊逻辑：

1. 找到未覆盖 bin 的**信号名和行号**（urg modinfo.txt）
2. **回到 RTL** 看这行代码的语义——是运行时逻辑还是编译期常量？
3. **回到例化点**看这个端口怎么接的——tie-off 还是活信号？
4. **判断**：结构死因（→ waiver）还是激励不足（→ 定向场景）？

这个循环对每一格的每一个未覆盖 bin 都走了一遍——30 格总计几百个 bin。

## 9. 常见误区

| 误区 | 实际 |
|---|---|
| "覆盖率 100% = 无 bug" | 错——checker 可能漏判。100% 只说明每条路径被走过 |
| "waiver = 偷懒" | 错——waiver 是论证"这些路径在当前设计中不可达"，比硬凑更难 |
| "功能覆盖 > 代码覆盖" | 两者互补。代码覆盖漏 spec 里没实现的功能，功能覆盖漏你没想到的 |
| "跑更多种子就行" | 对某些角落有效，但结构死 bin 跑再多也是 0% |
| "Toggle 低 = 测不够" | 可能是。也可能是硬接常量（tie-off）——先查例化点再下结论 |
