# 术语表

> 一术语一行白话。按首字母排序。本仓库语境下的含义优先于教科书泛义。
> 交叉引用用 →。本表不是判据来源，判据仍以 `doc/spec.md` 为准。

| 术语 | 白话解释 |
|---|---|
| **ABV** (Assertion-Based Verification) | 用 SVA 断言作为验证手段的方法学——断言跑在仿真里（动态）或形式工具里（静态） |
| **accept_time** | scoreboard 记录 DUT 接受一笔请求的时刻，用来判保序（→ ordering）：完成序不得反超接受序 |
| **addr_map / rule** | 地址映射表，定义"哪段地址范围路由到哪个目标端口"。每条规则 = {start_addr, end_addr, idx} |
| **ATOP** (Atomic Operation) | AXI 原子操作——atomicload/store/swap/compare 四子类型，靠 `aw.atop[5:0]` 编码区分 |
| **ATOP_R_RESP** | `atop[5]` 位——=1 表示该原子操作需要读响应（load/swap/compare），=0 仅需写响应（store） |
| **backpressure** | "背压"——下游拉低 ready 让上游等。验证里故意制造背压测 DUT 在拥塞下是否仍正确 |
| **bin** | 覆盖率的最小度量单元。Line 的一个 bin = 一行代码；Toggle 的一个 bin = 一个信号位的一个翻转方向（0→1 或 1→0）；Cond 的一个 bin = 一个条件项的一个取值组合 |
| **checker** | 判定 DUT 输出是否正确的组件。本仓库有两种：scoreboard（事务级比对）和 SVA（周期级断言） |
| **Cond (Condition) coverage** | 覆盖率六类之一：组合条件中每个子表达式的真/假取值组合是否都见过 |
| **covergroup / coverpoint** | SV 功能覆盖结构——covergroup 包一组 coverpoint，每个 coverpoint 定义"我想看到什么值" |
| **cross coverage** | 两个或多个 coverpoint 的笛卡尔积——看"A=x 且 B=y"这种组合是否到过 |
| **CLOSED-STATIC** | bug 以静态分析/论证关闭（而非仿真 PASS 证据）。证据强度弱于 CLOSED，须显式标记 |
| **decode error / DECERR** | 请求地址不在任何规则内→路由到 err_slv→返回 `RESP_DECERR (2'b11)` |
| **default port** | 地址未匹配时回退到的端口（spec §3.3）。没配 default port 则走 err_slv |
| **DUT** (Design Under Test) | 被测设计——本仓库的 DUT 是 `axi_xbar`（AXI4+ATOP 全连接 crossbar） |
| **env constraint** | 验证环境施加的约束——保证激励合法。如"不向未映射地址发 ATOP"（spec §4.7） |
| **evidence** | 证明一个 testplan 行达标的仿真日志摘录。由 `make evidence` 从 PASS log 中提取，不可手写 |
| **例化闭包 (instantiation closure)** | 以 DUT 顶层实例为根，递归例化的全部模块实例集合。覆盖率口径 = 闭包内 |
| **fault injection / 注伤自证** | 故意注入错误（改 ID、改地址、注入非法值）验证 checker 能检出——"没 bug 不是因为 checker 瞎了" |
| **flaky test** | 间歇性失败的测试——同一代码同一种子有时 PASS 有时 FAIL。本仓库 266/266 无 flaky |
| **格 (cell)** | 覆盖率的判定单位 =（模块, 类型）二元组。如 `(axi_err_slv, Toggle)` 是一格 |
| **五类分诊** | bug 归因排他顺序：TOOL_ENV → TB_BUG → CONSTRAINT_BUG → SPEC_ISSUE → DUT_BUG |
| **FSM coverage** | 覆盖率六类之一：状态机的每个状态和每条状态迁移弧是否到过 |
| **ID prepend** | xbar 内部给 AXI ID 高位拼接源端口编号（spec §5.1），用于响应路由回发起端口 |
| **Kind-A / Kind-B** | waiver 分类——A = 结构/环境永久不可达；B = 方法论受限（临时，补激励后可能解锁） |
| **Line coverage** | 覆盖率六类之一：每行可执行 RTL 是否执行过 |
| **modinfo.txt** | urg 产出的模块级覆盖率明细文件——每个未覆盖 bin 的信号名、行号、取值全在这里 |
| **must-reach** | testplan 行的反稀释机制——"这个角落必须真正到达，不是 checker 没报错就算过" |
| **oracle** | 产生期望值的组件。本仓库的 oracle = scoreboard 的 `decode_mst_port()` + `predict_beat_data()` |
| **ordering / 保序** | spec §5.2：同 full-ID 同方向同目标的响应完成序不得反超 AW/AR 接受序 |
| **red line / 红线** | 不可让步的约束。红线 1 = testplan 只经 `make evidence` 翻绿；红线 2 = 期望值只从 spec 推导 |
| **rev** | 独立评审代理——只读分析+写判决，不改代码。用于 spec 变更/checker 评审/里程碑收口 |
| **scoreboard** | UVM 参考模型比对器——把 DUT 输出与 oracle 期望值逐拍比对，有差异就报 `uvm_error` |
| **seed** | 随机种子——决定约束随机的具体激励序列。固定种子 = 确定性复现 |
| **SVA** (SystemVerilog Assertions) | SV 断言——写在 RTL 旁边的形式化属性，运行时检查每拍是否成立 |
| **tie-off** | 端口/信号硬接常量（如 `.flush_i(1'b0)`）。tie-off 的信号 Toggle 永远不覆盖 |
| **Toggle coverage** | 覆盖率六类之一：每根信号的 0→1 和 1→0 翻转是否都发生过 |
| **UNOWNED** | 覆盖率格（cell）无人认领——既不达标、也没 waiver、也没债务行。出口条件要求 UNOWNED = 空集 |
| **urg** (Unified Report Generator) | VCS 配套覆盖率报告工具，从 `.vdb` 覆盖率数据库生成人读报告 |
| **vacuous** | SVA 断言的前提为假→断言平凡为真但从未真正检查过。urg 里看到 "Attempts=N / Real Successes=0" 就是 vacuous |
| **vdb** | VCS 覆盖率数据库文件——仿真时 `-cm` 选项产出，urg 读入 |
| **VIP** (Verification IP) | 商业/开源的协议 checker（如 Synopsys AXI VIP）。本仓库未用——xbar 是透传设备，大部分高级协议不适用 |
| **vplan** | 验证计划表——testplan 的工业称呼。每行 = 一个验证场景 + 判据 + checker + 证据 |
| **waiver** | 覆盖率豁免——书面论证某些 bin 结构不可达，rev 签核后正式排除出分母。见 `doc/coverage-waivers.md` |
| **xbar** | crossbar——全连接交换矩阵，N 个输入 × M 个输出，任意到任意路由 |
