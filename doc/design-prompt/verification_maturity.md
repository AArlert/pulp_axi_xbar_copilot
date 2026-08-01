# Design prompt — `verification_maturity`（M5 方法学拓展：约束随机 + 多种子回归 + 压力/soak + 覆盖率驱动闭环）

> **性质：提案草案。** 本文经 rev 评审通过、orch 落地前不派任何 DE/DV 卡。
> 约束层：只约束**实现方式**（stimulus 组织、脚本行为、回归契约）。DUT 外部可见
> 行为一律引用 `doc/spec.md`，本文不新增 spec 未载行为（behavior-leak 禁区）；判决仍
> 落 `scoreboard_refmodel.md` / `sva_bind.md`（spec 推导），覆盖率脚本**只测量、不做
> oracle**（spec-from-RTL 红线）。
> 前置：`uvm_env.md`（现有 env / 序列惯例）、`functional_coverage.md`（covergroup 挂点）、
> `doc/spec.md` §0 item 4（覆盖率口径）、CLAUDE.md §4（xverif 取事实的边界）。

## 0. 目标、动机与边界

现状（本卡起点事实，DV 落地时须自行复核）：`axi_seq_item` 四个 `rand` 字段
（`is_write/addr/len/id`）从未被 `.randomize()` 驱动（全仓 `constraint` 块 0 个、
`.randomize()` 调用 0 次），激励靠各 `*_seq` 过程式赋值；`regress.list` 26 行全
`SEED=1`；"压力"场景是单计数器窄口径定向构造；覆盖率是"定向→事后测量→人工补
定向"。本项目被当工业界 UVM 验证的初学者参考资料，须补齐四支柱：**约束随机、
多种子回归、压力/soak、覆盖率驱动闭环**。

**硬边界（贯穿全文）**：

- **B0.1 期望值只来自 spec。** 约束块的合法性边界（`§4` clause 7、`§6.2`、`§6.4`、
  `§8.3`、`§5.3.1`）必须编码进 `constraint`，不能只靠 scoreboard 事后判"违反环境
  约束"兜底——那样求解器持续产生事后被否的废激励，效率低且掩盖真正想测的空间。
  依据：arch 角色文件「checker 期望值只能从 spec 推导——约束随机的 constraint 块
  同样守这条」。
- **B0.2 覆盖率是完备度、不是 oracle。** 闭环脚本经 xcov/urg 读"命中了什么"只用于
  **决定何时停止生成**与**列残余缺口**；判 PASS/FAIL 的 oracle 恒在 scoreboard+SVA
  （spec 推导）。波形/覆盖事实不得抄成期望值。依据：CLAUDE.md §4「边界不变」。
- **B0.3 只有 `make evidence` 能把场景变绿（不变量 1）。** 闭环脚本、多种子回归本身
  **不turn green**任何 testplan 行；它们是缺口发现 + 回归加固工具。缺口 → 派生
  **可派卡的 planning gap**（新 testplan 行）或书面记录为随机不可达。
- **B0.4 延迟不敏感（§7.4）。** soak / 随机场景的一切判决锚延迟不敏感可观测量，
  不断言固定拍数。

范围：本文承载**五个决策点**的提案。Decision 1 给里程碑归属并已在 `milestone.md`
起草 M5 草稿；Decision 2–4 是 M5 内待派 DE/DV 卡的架构输入；**Decision 5（cov_loop）
随里程碑重构移交 M6**（六类 ≥90% 收敛工具，见 `doc/design-prompt/milestone_restructure.md`）。

---

## 1. 决策点 1 — 里程碑归属：新开 M5，排在 M4 签核之后

**建议：新开 M5「约束随机 + 多种子回归 + 压力/soak」，不并入 M4；且 M5 排在 M4
签核之**后**（作方法学加固线）。**（**里程碑重构后**：覆盖率驱动闭环＝决策点 5 移交
M6，M4 出口改"测量 + 三态扫描 + 每格具名归属"、六类 ≥90% 门迁 M6；版本方案见
`doc/design-prompt/milestone_restructure.md` §7.3，M4 不再转 v1.0.0。）

理由（轴不同 + 时序不宜）：

- **C1.1 两条正交的轴。** M4 是**结构覆盖率百分比**这**单一轴**（`§0` item 4：
  line+cond+fsm+tgl+branch+assert ≥90%，例化闭包，`make check MILESTONE=4` 机器判）。
  约束随机/多种子/压力/闭环是**验证方法论成熟度**这条**不同**的轴。并入 M4 会让
  M4 出口条件失焦——无法机器区分"M4 关闭是因为覆盖到 90% 还是因为加了随机测试"。
  历史先例同构：M3（多配置回归）与 M2（功能场景）分立，正因配置矩阵与功能场景是
  不同轴（`milestone.md` M3）。
- **C1.2 关系是"帮上忙"而非"同目标"。** M5 的随机/闭环产出**可能**帮更省力地关上
  M4 的结构缺口，但这是副产品：本项目的证据链哲学要求每个 ✅ 行是**有 spec 引用、
  可证伪描述的具名场景**（`workflow/records.md` testplan 契约）。一颗随机种子"恰好
  撞到某 bin"不是这样的场景——它没有可证伪的 scenario 描述。故 M4 的结构收敛须
  **定向优先**（每缺口→具名场景→spec 引用，可审计），M5 的随机只能**加固/发现**，
  不能**替代** M4 的定向关闭。→ **定向先（M4）、随机后（M5）恰是证据链项目的正确
  顺序**，非浪费。
- **C1.3 不扰动在飞的 M4。** M4「进行中」且背 REV-017 条件化未闭合债（条件 2/3
  未兑现，`spec.md` change record #10）。往在飞里程碑注入大改动违反"小闭环即停"
  （`workflow/discipline.md`）并会拖住 M4 签核。M5 从 M4 签核后起步，M4 的定向闭包
  正好成为 M5 随机引擎的**已知答案参照**（闭环残余缺口对照 M4 已达 bin 集）。
- **C1.4 新 checker 类需自己的 KILL 背书（不变量 5）。** M5 引入的新 checker 类
  （soak watchdog liveness、饱和探测器、随机约束合法性 env 兜底监视）须在 M5 各做
  一次注伤自证（植入→红→复原→绿），`bugs.md` 记 `KILL` 行。这在 M4 内无处安放，
  独立里程碑更干净。

**版本方案（里程碑重构后定稿，见 `doc/design-prompt/milestone_restructure.md` §7.3）**：
0.M.P 规则下 **M5=v0.5.\*、M6=v0.6.\***，**v1.0.0 挂 M6 签核**（M4 不再转 v1.0.0）。
本文按 M5 起草 `milestone.md` 草稿（决策点 5 cov_loop 移交 M6，见该文件）。

**M5 出口条件草稿**见 `doc/milestone.md` M5 章。

---

## 2. 决策点 2 — 约束随机架构

### 2.1 现有 `rand` 字段的约束设计（`axi_seq_item`，`tb/axi_txn.sv`）

四个字段配约束如下。**软约束（`soft` / 分布加权）压角落，硬约束编码 spec 合法性
边界**。DV 落地时 constraint 块以 `Cfg`/模块参数（经 config 对象传入）为条件——
不同配置点复用同一 seq、约束按配置自适应（C2.5 延伸，`uvm_env.md` C6.10）。

- **C2.1 `len`（AxLEN，8 位，beats−1）。**
  - 硬：INCR 下 0..255 全合法（`§1` 完整 AXI4；`burst` 固定 `BURST_INCR`）。
  - 软角落加权：`{0}`（单拍）、`{1..7}`（现基线档）、`{15,16}`（4/8 拍边界）、
    `{254,255}`（最大 burst）各给显式权重，避免均匀分布把 corner 稀释。依据：
    `§1`（协议合法域）；角落选取为覆盖率动机（结构/功能），非新增行为。
  - env 实现约束（非 DUT 行为，可入本文；REV-019 G-4 校正措辞——不断言 DUT 译码
    基数，spec §3.2 未规定 per-AW vs per-beat 译码是单次还是逐拍）：`addr +
    (len+1)*BEAT_SIZE` 建议不跨出该 AW 译码命中的 region，纯为**参考模型简化**——
    使 per-master slave memory model 对该 burst 的地址范围在构造激励时即可预测、
    不依赖任何译码基数假设（`scoreboard_refmodel.md` 数据完整性对照源）。此约束
    只收窄激励空间，不对 DUT 行为下任何断言。
- **C2.2 `addr`（32 位）。**
  - 软角落加权：每条 rule 的 `start_addr` / `end_addr−1`（区间边界，`§3.2.1` 含起
    不含终）、未命中地址（decode-error/default，`§3.3`/`§4`）、重叠区间地址
    （`§3.1.3` 高位 rule 胜出，M4-OV01 同构）各给权重。
  - **硬（关键耦合）**：`atop != '0 → addr 命中某条 rule`（`§4` clause 7 宽读，
    REV-018：不论该端口是否使能 default port，凡不匹配任何 rule 的地址均禁 ATOP）。
    err_slv×ATOP 应答许可来源未定义，此约束使其构造性不可触发。
  - **硬（cfgD，配置条件）**：稀疏 `Connectivity` 下地址不得译码到源 slave 端口的
    非连通 master 端口（`§8.3`）。
- **C2.3 `id`（5 位 slv 侧）。**
  - 软角落加权：**桶撞车概率**——令低 `AxiIdUsedSlvPorts=3` 位相同（同桶、异完整
    ID）的组合以有意义概率出现（`§5.2.2` 假冲突桶是 `§5.2` stall 与本周期
    BUG-0009/BUG-0023/BUG-0024「同拍时序巧合」类缺陷的栖息地——这类缺陷正是换种子
    最易自然撞见者）。均匀 5 位随机会把同桶撞车稀释到 1/8，须显式加权抬高。
  - **硬（cfgC，`UniqueIds=1`）**：`§5.3.1` 前置条件（同方向在飞 ID 唯一，或同 ID
    同向在飞全部目标同一 master 端口）须构造性满足，`§5.3.3` 明述不满足则 DUT 行为
    **未定义**、届时判决无意义。此为**跨事务不变量**，单条 item 约束兜不住 → 见
    C2.6 集中 ID 分配器。
- **C2.4 `is_write`（1 位）。** 软加权（读写比例可调，默认近均衡）；无硬约束。

### 2.2 是否新增 `rand` 字段：`atop` 有界随机化

**建议：把 `atop` 升为 `rand`，但约束到 `{'0} ∪ {合法 atomic-load 编码}` 的有界
子集，不放开 store/swap/compare。**

- **C2.5 `atop` 约束。**
  - 硬：`ATOPs==0 → atop == '0`（`§6.2`，cfgD，BUG-0003 环境约束）。
  - 硬：`atop != '0 → addr 命中 rule`（同 C2.2，`§4` clause 7）。
  - 硬（合法编码域）：`atop != '0` 时取值限于 `axi_pkg` 的合法 atomic-load 编码
    （`{ATOP_ATOMICLOAD, endianness, op}`，DV 唯一可读参数源 `vendor/axi/src/axi_pkg.sv`，
    同 M2-AT01 现用编码）。软加权：绝大多数事务 `atop=='0`，少数为 load 编码——
    ATOP 是 §6 特殊路径，不宜淹没普通读写空间。
  - **硬（跨事务，`§6.4`）**：ATOP 事务 ID 须与该端口当前**所有**（读+写）在飞事务
    ID 不同。同 C2.3 的 UniqueIds，属跨事务不变量 → C2.6 集中分配器。
  - ATOP 引发的读方向跨方向假冲突 stall（`§6.5`/`§5.2.5`）**不加约束**（属正常设计
    行为），仅由 `cg_atop_read_interaction`（`functional_coverage.md` §2）留痕。
- **不放开 store/swap/compare 的理由（→ 见 Spec change proposal SP-1）**：`doc/spec.md`
  §6 只规定 **atomic-load** 的 B+R 应答义务（`§6.3`）；atomicstore（应仅 B）、
  atomicswap/compare（应 B+R，且 len 有约束）的响应义务 **spec 未列**，scoreboard
  无 oracle。放开须先补 spec §6 → 登记为**延迟的**spec change proposal，**不阻塞**
  M5 本文提的有界子集（有界子集 `§6.3` 已完全支持，零 spec 改动）。

**保持非 rand 的字段**：`size`（固定 `BEAT_SIZE` 全宽）、`burst`（固定 `BURST_INCR`）
——放开 narrow transfer / WRAP / FIXED 是大扩张，须 scoreboard 支撑，**本文不纳入**，
列 M5 后续可选扩张（Open risk）。`fallthrough_probe` 保持定向探针语义（cfgE 专用，
`§7.3.1`），可在 cfgE 内软随机，非通用随机维。

### 2.3 集中 ID 分配器（跨事务不变量的落点）

- **C2.6** 单条 item 的 `randomize()` 兜不住 C2.3（UniqueIds）与 C2.5（ATOP §6.4）
  的**跨事务**唯一性。复用 `uvm_env.md` C6.7 已确立的"集中 ID 分配器（单一分配器，
  不由各序列各自猜）"：随机 seq 在 finalize `id`/`atop` 前向分配器查当前在飞 ID
  集，用 `randomize() with { id inside {legal_set}; }`（`legal_set` = 分配器给出的
  可用集）或 post-randomize 合法性校验 + 回退重摇。依据：`§5.3.1`（UniqueIds 前置）、
  `§6.4`（ATOP 全方向唯一）、`§5.3.3`（不满足则未定义，故是硬约束非偏好）。

### 2.4 通用随机激励虚拟序列（sequence/vseq 层设计，不写 SV）

- **C2.7 `xbar_random_vseq`（配置无关，全配置点复用）。**
  - 端口范围由生效配置点的 `NoSlvPorts`/`NoMstPorts` 推导（`uvm_env.md` C6.10；复用
    `fanout_per_slv#(SEQ_T)` 骨架），故 baseline + cfgA/B/C/D/E **同一套原语**跑通。
  - 每 slave 端口 fork 一个 `slvport_random_seq`，循环内：`create` → 从 config 对象
    取生效配置（`ATOPs`/`UniqueIds`/`Connectivity`/`addr_map`/`en_default`）→ 经
    C2.6 分配器约束 `id`/`atop` → `randomize() with { <C2.1–C2.5 约束> }` → 驱动。
  - payload 仍走既有 `fill_wr_payload`（`$urandom`，`tb/seq_lib.sv`），不变。
  - 旋钮（knobs，供 soak/闭环调）：`num_iter`/`duration`、`atop_weight`、
    `collision_weight`（同桶撞车权重）、`unmapped_weight`、`target_convergence_bias`
    （偏置多端口向同一 master 汇聚，压 mux 仲裁竞争，`§5.5`）。
  - responder 侧复用 `uvm_env.md` C3.5（随机合法 ready/valid 反压）+ C5.3
    （有界 `resp_hold`），使在飞计数真被压到 `§5.4.1` 每桶有效上限而非空转。
  - **判决不变**：路由/数据/ID 前缀/响应/保序全由 `scoreboard_refmodel.md`
    （spec 推导）判，本 vseq 只提供激励（B0.1/B0.3）。

伪代码骨架（接口/约束示意，实现留 DV 卡）：

```
class slvport_random_seq extends uvm_sequence #(axi_seq_item);
  xbar_cfg_ctx cfg;        // ATOPs/UniqueIds/Connectivity/addr_map/en_default
  id_allocator alloc;      // C2.6 集中分配器（共享句柄）
  knobs k;                 // C2.7 旋钮
  task body();
    repeat (k.num_iter) begin
      it = axi_seq_item::create();
      start_item(it);
      // C2.6：先从分配器取合法 id 候选集（UniqueIds/ATOP §6.4）
      legal_ids = alloc.available(slv_port_idx /*dir 由 randomize 后回填或分两步*/);
      assert(it.randomize() with {
        // C2.4 读写比
        // C2.1 len 软角落 + region 不跨界
        // C2.2 addr 软角落；atop!='0 -> addr 命中 rule（§4.7）；cfgD §8.3
        // C2.3 id 同桶撞车软加权；id inside legal_ids（§5.3.1）
        // C2.5 ATOPs==0 -> atop=='0（§6.2）；atop!='0 -> 合法 load 编码（§6.3）
      });
      alloc.reserve(it.id, it.is_write, it.atop);   // 登记在飞
      finish_item(it);                              // 完成后 alloc.release(...)
    end
  endtask
endclass
```

---

## 3. 决策点 3 — 多种子回归策略

### 3.1 每场景种子数 N 与理由

**建议：M1–M4 全部 UVM 定向场景统一底线 N=5（1 典型 + 4 附加）；
时序/保序高价值子集 N=10。`upstream_sanity`（M0 遗留、非本 env）保持 1。**

- **C3.1 经济学：种子扫描在预编译 simv 上是纯运行时开销。** `+ntb_random_seed`
  是**运行时**旋钮（`sim/Makefile:118`），配置点是 elaboration 期
  `+define+XBAR_CFG_*`（`sim/Makefile`，每配置点独立 simv）。同一 TEST 换种子**复用
  同一 simv**（`regress.py` 的 `make run` 见 simv 存在即跳过编译）。故一场景 N 种子
  = 1 次编译 + N 次运行。编译（每配置约 2 min）是成本主导，运行（这类 6×8 小 UVM
  仿真约数十秒）廉价。粗算：24 场景约 7 次编译（baseline 共享 + cfgA–E + sanity）
  + 24×5≈120 次运行；~14 min 编译 + ~60 min 运行 ≈ 75 min/全回归，N=10 高价值子集
  另 +~35 min，均 <2 h，可做 milestone/nightly 回归。**（注：每 run 精确墙钟时间
  DV 落地时须实测，此为量级估算；"种子复用编译"这一经济事实是结论骨架。）**
- **C3.2 N=5 底线的理由。** 5 足以抖出 payload/RNG-order 依赖的间歇性——本周期
  BUG-0023/BUG-0024 正是「两事件同拍与否」的 RNG-order 敏感缺陷（`seq_lib.sv`
  build_or03 注释实测「uniform AxLEN=0 给 0 次写侧撞车，alternating 给 192 次」），
  换种子最易自然撞见；同时 5 保持多种子汇总人可审计、回归墙钟可控。
- **C3.3 时序子集 N=10。** 保序/stall/汇聚/上限类（OR01/OR02/OR03/OR04/OR05/WO01/
  AT01/AT02/TL01/TL02/CFG01/CFG02/RC01/AW01）对种子最敏感，给更高种子数。纯确定性
  译码类（DE01/DE02/CF01–04/OV01/FT01）种子收益低，留底线 5。
- **C3.4 种子须固定、记录（可复现硬规则）。** `workflow/records.md`「record 须可
  按写照重放（same test, same seed）」。种子取**固定整数列表**（如 baseline
  `{1,2,3,5,7}`、高价值追加 `{11,13,17,19,23}`），列于 M5 design-prompt / regress
  头注，**非**每日随机。闭环（决策 5）另有确定性种子序列。
- **C3.5 前置耦合。** 多种子只有在**约束随机（决策 2）落地后**才真正扩空间——今日
  `$urandom` 只填 payload，换种子几乎不换激励结构。故多种子回归与约束随机同属 M5、
  同批推进。

### 3.2 "N 颗种子全过"的契约（不改 scripts schema）

**建议：用既有机制表达，零 schema 改动。**

- **C3.6 `regress.list` 即种子集事实源。** 其格式已是 `<TEST> <SEED>` 每行
  （`sim/regress/regress.list`，头注「每个已关闭 bug 的失败种子永久加入」）。N 种子
  = 该 TEST 的 N 行。`regress.py` 已逐行迭代、逐 log 判 verdict，`result_summary.txt`
  已逐 `(test,seed)` 列 PASS/FAIL。**机器契约零 schema 改动即支持**。
- **C3.7 testplan 行不动（canonical seed 仍是 ✅ 锚）。** `workflow/records.md` 的
  testplan 行 `repro`/`evidence` 是脚本owned 单命令/单路径，为 canonical 种子。多
  种子**不**改 testplan 列。
- **C3.8 "N 全过"是独立机器制品 = 回归摘要入证据。** 复用 milestone 出口既有的
  「regress 摘要入证据」机制（`milestone.md` 首行）：M5 签核把 `result_summary.txt`
  捕获为回归证据（如 `doc/evidence/v0.5.*/regress-multiseed.log`，M5=v0.5.\* 按 §7.3），显示全部种子行
  `passed=N/N`。**契约长相**：
  1. `regress.list` = 权威种子集（新增 N-种子行）；
  2. 每场景种子列表在 M5 design-prompt 固定记录（确定性）；
  3. 签核捕获 `result_summary.txt` 入 evidence（既有机制，无新 schema）；
  4. testplan 行不变。

**条件（REV-019 §G-3，落地卡范围强制项，非本卡自证）**：C3.6-C3.8 只论证了
runner 机制零 schema 改动，**未覆盖**"`regress.list ⊇ testplan ✅ 集合"这条既有
隐性完备度纪律（BUG-0028/BUG-0036 的经验教训）在种子行从个位数膨胀到约 120 行后
如何保持可审——REV-019 亲验 `scripts/docs.py`/`scripts/regress.py` 均**无**任何
机器交叉校验此差集，现状是纯人工比对。**Decision-3 落地卡（派发时）必须显式承接**
这一项：方向建议（不代拟实现）把该纪律升级为机器交叉校验（对 `regress.list` 的
**去重 TEST 投影** ⊇ testplan ✅ 集合），使其反而比膨胀前更牢固而非更脆——这属
本仓库自有 `scripts/` 资产，不受上游同步约束，可自由改动。

---

## 4. 决策点 4 — 压力/soak 测试定义

### 4.1 规模

- **C4.1 端口/拓扑。** 主 soak 跑 baseline 6×8；另至少 cfgB（6×1，mux 汇聚仲裁最紧）
  与 cfgA（1×8）各一。全部 slave 端口用 C2.7 随机 vseq 持续背靠背发事务。
- **C4.2 时长/规模由事务数 + 饱和定义，不锚固定拍（`§7.4`）。** 建议每 soak 配置
  ≥10k 事务/run，或"覆盖率饱和"，或预算上限，三者先到为准。responder 施加 C3.5/C5.3
  有界随机反压，使各桶在飞计数**同时**压到 `§5.4.1` 有效上限（基线 15/桶），而非
  单桶窄口径（区别于 M2-TL01/TL02/M3-TL01 的定向单计数器构造）。

### 4.2 判据（自检三层照旧 + 两条新增）

- **C4.3 scoreboard**：路由/数据/ID 前缀/响应/保序零 mismatch，延迟不敏感
  （`§7.4`，`scoreboard_refmodel.md`）。
- **C4.4 SVA**：全部协议/时序 assert 零失败（`sva_bind.md`）。
- **C4.5 functional coverage**：covergroup 正常采样（`functional_coverage.md`）。
- **C4.6【新增】无 watchdog 超时（liveness）。** 一个 heartbeat watchdog：若有界窗口
  内无任何事务完成（B/rlast）则判失败。**这是 spec 推导的活性检查、非新增行为**：
  依据 `§5.5.4`「无饿死——每个持续 valid 的请求终将被授予」（REV-019 校正：该性质
  逐字落在 §5.5.4 checker 期望值告诫条，非 §5.5.3——原稿引用有误；`§5.5.4`/REV-006
  允许取此**性质**，禁断言具体仲裁序）。watchdog 只测"是否终将前进"，不测"第几拍
  前进"。
- **C4.7【新增】覆盖率趋于饱和（停止判据，非 PASS/FAIL）。** 定义"饱和"= 连续 K 个
  覆盖测量窗口（每窗口 M 事务，建议 K=3）内，六类结构覆盖 **与** 功能 covergroup
  bin 数的增量均 < ε（建议 ε = 0 新 bin 或 <0.1% 绝对增量）。
  - **边界**：饱和**不是**覆盖目标（≥90% 目标归 M4，`§0` item 4）；饱和只表示"该
    种子/配置下随机引擎已到平台期、边际收益递减"。soak 的 **PASS = C4.3–C4.6 全净**；
    **饱和是停止条件 + 上报指标**。soak 在缺口以下就饱和 = **发现**（喂给闭环/定向
    补场景，决策 5），**不是**通过。

---

## 5. 决策点 5 — 覆盖率驱动闭环机制（`scripts/` 驱动脚本，功能规格）

> **里程碑归属（里程碑重构后）：本决策点移交 M6**（六类 ≥90% 收敛线），不再属 M5；
> M5 保留 Decision 2–4（约束随机 + 多种子 + soak）。本节内一切"M4 六类 ≥90% 目标"
> 的引用（C5.3 可选覆盖目标、C5.4 覆盖范围），重构后**目标门指 M6 收敛门、口径指
> spec §0#4**——§0#4 六类测量口径本身不变（M4 测量、M6 收敛），故 C5.x 功能规格
> **无需逐行改动**。见 `doc/design-prompt/milestone_restructure.md` §2/§3.4。

`scripts/` 本仓库自有资产（CLAUDE.md §5，不受上游同步约束）。建议新增
`scripts/cov_loop.py`。**只给功能规格，不写 Python。**

### 5.1 输入

- **C5.1** 目标 TEST（决策 2 的随机/soak vseq test）+ 配置点集。
- **C5.2** 确定性种子序列（`seed_0, seed_1, …` 由 base 派生并记录，可整链重放）。
- **C5.3** 预算：最大种子数（或最大墙钟）、可选覆盖目标（镜像 M4 六类 ≥90%，`§0`
  item 4）、饱和窗口参数（K、ε，同 C4.7）。
- **C5.4** 覆盖范围：与 M4 **逐字相同**的例化闭包六类（`§0` item 4）+ 功能
  covergroup。**不改 `§0` item 4**（见 SP 说明：无 spec 改动）。

### 5.2 循环

- **C5.5** 逐种子：`make run TEST=… SEED=seed_i COV=1`（写 per-run 覆盖库，
  `-cm_name TEST_seed`；BUG-0037/BUG-0040 修复保证跨拓扑库不静默合并，`vcs-2018.mk`
  cov 目标 `-dir $(COV_DIR)`）。
- **C5.6** 累积合并覆盖（`urg`/`xcov`），查总六类 % + 功能 bin 数。
- **C5.7** 记录每颗种子**边际贡献**（本种子相对已合并库新增的 bin/覆盖 delta）——
  核心制品，把每颗种子的价值可归因（同 `seq_lib.sv` 已实测「alternating 给 192
  撞车」的量化风格）。
- **C5.8** 停止：(a) 覆盖目标达成，或 (b) 饱和（连续 K 颗各 < ε），或 (c) 预算耗尽。

### 5.3 输出与日志形态

- **C5.9** 机器日志（JSONL 或摘要 txt）：逐种子 `{seed, cum_cov, delta_cov,
  new_bins, wall_time}` + 终判 `{target_met | saturated | budget_exhausted}` + **停止
  时的残余缺口清单**（仍未覆盖的 bin/模块/类型）。
- **C5.10 反馈闭合（不变量 1，B0.3）**：残余缺口 → 每条**或** (a) 注册为新**定向**
  testplan 行（可派卡 planning gap，`workflow/bugs.md`「Dispatch: coverage hole」先问
  "场景是否存在"）→ **或** (b) 书面记为随机不可达 → 走 `§0` item 4 的 N/A 三态或
  rev 签核书面豁免。**脚本自身不 turn green 任何行**（B0.3）。
- **C5.11 边界重申（B0.2）**：脚本读覆盖**事实**只用于"何时停、缺什么"；PASS/FAIL
  oracle 恒在 scoreboard+SVA（spec 推导）。覆盖率是完备度度量、不是 oracle。
- **C5.12 确定性**：种子记录 ⇒ 整链可重放；覆盖库处置复用 BUG-0037/0040 per-拓扑
  隔离。

---

## 6. Spec change proposals（本文附）

- **SP-1（延迟的、可选）：spec §6 补 ATOP 非-load 子类型的应答义务。**
  - 原文：`§6.3` 只规定 atomic-load「B 与 R 两通道都返回」。
  - 拟新增（示意，非最终措辞）：§6.x 逐条列 atomicstore（仅 B）、atomicswap/
    atomiccompare（B+R，及其 len/data 约束）的应答义务与响应码期望，许可来源
    = `vendor/axi/doc/axi_demux.md §Atomic Transactions` + `axi_pkg.sv` ATOP 编码段。
  - rationale：C2.5 若放开 `atop` 到 store/swap/compare，scoreboard 需其响应义务作
    oracle，而 spec 现只覆盖 load。**不补则不能放开**。
  - impact：启用更广 `atop` 随机化；新增 scoreboard 期望逻辑 + 新 testplan 行
    （atomic-store/swap/compare 定向场景）。
  - **状态：延迟、不阻塞 M5。** M5 本文的有界子集（`{'0} ∪ load 编码`）**零 spec
    改动**（`§6.3` 已支持）。SP-1 仅当未来决定放开时才走仲裁。

- **无其他 spec 改动。** 特别地，**`§0` item 4 覆盖率口径不改**：item 4 是**测量
  范围**（例化闭包 + 六类），与激励**如何产生**（定向 vs 随机）无关；随机激励贡献
  到**同一**测量。M5 闭环（决策 5）逐字复用 M4 口径作测量基础，避免 spec 与制品
  分叉。soak 饱和用 covergroup 只作**停止判据**、非 spec 判决（功能 covergroup 本就
  不在 M4 机器口径内，REV-011 §3.3）；watchdog liveness 引 `§5.5.4` 既有条款
  （REV-019 校正）。

---

## 7. 引用的 spec 章节

§0（item 3/4/5）、§1、§3.1、§3.2、§3.3、§4（clause 7）、§5.2.2、§5.3.1、§5.3.3、
§5.4.1、§5.5.4、§6.2、§6.3、§6.4、§6.5、§7.4、§8.3。
