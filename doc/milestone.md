# Milestones

版本号 0.M.P，M 即里程碑号。M0–M4 由前任团队完成并签核（评审/签核/证据存档见
git tag `v0.5.3-pre-reset` 及更早历史）；0.5.4 起本仓库以"接手者"姿态轻装运作，
里程碑出口由 `make check` + 本页条目人工核对，不再有独立签核仪式。

## Abstract

| 里程碑 | 内容 | 状态 |
|---|---|---|
| M0 | 基建 + upstream sanity + spec v0 | ✅ |
| M1 | UVM env + smoke（tb_top、多 agent、参考模型记分板） | ✅ |
| M2 | 功能场景 + SVA + 功能覆盖（8 场景） | ✅ |
| M3 | 多配置回归 + 错误路径（11 场景，cfgA–E 配置点） | ✅ |
| M4 | 六类覆盖测量基建 + 全闭包三态扫描 + 每格具名归属 | ✅ |
| M5 | 约束随机 + 多种子回归 + 压力/soak | 🔲 进行中 |
| M6 | 六类覆盖 ≥90% 收敛（含 Toggle） | 🔲 计划 |

M0–M4 的详细出口条件与逐条兑现记录不再在本页维护——git 历史即档案
（`git show v0.5.3-pre-reset:doc/milestone.md`）。

## M5 — 约束随机 + 多种子回归 + 压力/soak 🔲

**性质**：验证方法论成熟度轴，与 M4/M6 的结构覆盖率百分比轴正交。随机只能
加固/发现，不承担 ≥90% 收敛门（那是 M6）。

**步 0（接手基线确认）**：`make regress` 全绿一次，确认前任留下的 30 场景
（M0–M4，见 testplan）+ tb 在当前环境下活着，然后才动代码。

### 约束随机层设计要点（原 design-prompt 蒸馏）

四个 `rand` 字段（`is_write/addr/len/id`）+ `atop` 升为有界 `rand`。
**硬约束编码 spec 合法性边界，软约束/分布加权压角落**：

- `len`：INCR 下 0..255 全合法（spec §1）；角落加权 {0}、{1..7}、{15,16}、
  {254,255}；burst 不跨出译码命中 region（纯参考模型简化，非 DUT 断言）。
- `addr`：角落加权 rule 边界（含起不含终，§3.2）、未命中地址（§3.3/§4）、
  重叠区间（§3.1.3）。**硬**：`atop != '0 → addr 命中 rule`（§4 clause 7，
  宽读）；cfgD 稀疏 Connectivity 下不译码到非连通端口（§8.3）。
- `id`：软加权抬高低 3 位同桶撞车概率（§5.2 stall 栖息地，均匀随机会稀释到
  1/8）；cfgC `UniqueIds=1` 时经集中 ID 分配器保证 §5.3.1 前置条件（跨事务
  不变量，单条 item 约束兜不住）。
- `atop`：约束到 `{'0} ∪ 合法 atomic-load 编码`（§6.3 已支持，零 spec 改动）；
  `ATOPs==0 → atop=='0`（§6.2）；ATOP ID 与该端口全部在飞 ID 不同（§6.4，
  走分配器）。**不放开 store/swap/compare**——其应答义务 spec §6 未载，无
  oracle；放开前须先补 spec（BUG-0044，见下）。
- `size`/`burst` 保持定值（narrow/WRAP/FIXED 是大扩张，不在 M5）。
- 通用虚拟序列 `xbar_random_vseq`：配置无关，端口范围由生效配置点推导，全
  配置点复用；旋钮 = 事务数、atop 权重、撞车权重、未命中权重、汇聚偏置。

### 场景骨架（6 行，注册进 testplan 时逐行落判据）

| id | config | 内容 |
|---|---|---|
| M5-RN01 | cfgC (UniqueIds=1) | 随机 vseq + 集中 ID 分配器保证前置条件 |
| M5-RN02 | cfgD (稀疏 Conn + ATOPs=0) | 随机 vseq，约束保证 atop≡'0 且地址不出连通域 |
| M5-RN03 | cfgE (FallThrough=1) | 随机 vseq，功能判据与 FallThrough=0 逐条相同 |
| M5-SK01 | baseline 6×8 CUT_ALL_AX | 长随机饱和 soak，各桶在飞压到 §5.4.1 有效上限 15 |
| M5-SK02 | cfgB 6×1 CUT_ALL_PORTS | 同上，mux 汇聚仲裁最紧 |
| M5-SK03 | cfgA 1×8 NO_LATENCY | 同上，全组合路径 |

（baseline/cfgA/cfgB 三点由 soak 行顺带承担——长随机是随机 vseq 的超集，
故 6 行覆盖全部 6 个配置点。）

**反稀释四条**（随机场景不得靠"跑了不报错"混绿）：

1. 每行判据预先声明且锚 spec，oracle 与定向场景同一套（scoreboard+SVA）。
2. 每行预先声明**必须真正到达**的激励角落（如 soak 行"各（低 3 位 ID 桶 ×
   方向）在飞计数同时压到有效上限 15"），到不了即该行不成立，哪怕零 mismatch。
3. 覆盖率饱和（连续 K 窗口增量 < ε）只是**停止判据**，不是 PASS。
4. testplan 行只记单一 canonical `TEST=/SEED=` 复现；多种子集合住 `regress.list`。

### Exit criteria

- [ ] **失败可追溯机制落地（第一张活）**：评估现 scoreboard/SVA 的报错形态，
      改造为失败自包含——报错即给出 seed + 该笔事务的完整操作轨迹（发起/各
      触发点/比对点）+ 三方文本（DUT 实际 / 参考模型期望 / spec 条款引文），
      使 `make run TEST=<t> SEED=<n>` 单跑一条即稳定复现并可读懂
- [ ] **约束随机激励层**：上述约束设计落地，`xbar_random_vseq` 在 6 配置点
      全部跑通（M5-RN01..03 + SK01..03 六行 ✅，经 `make evidence`）
- [ ] **多种子回归**：定向场景底线 N=5 固定种子、时序/保序子集 N=10，种子行
      入 `sim/regress/regress.list`，`make regress` 全绿
- [ ] **压力/soak**：三拓扑 soak 行判据 = scoreboard/SVA 零失败 + 无 watchdog
      超时（liveness，§5.5.4 无饿死性质）+ 覆盖率饱和作停止判据；判决延迟
      不敏感（§7.4）
- [ ] **BUG-0044 裁决**：ATOP 非-load 三子类（store/swap/compare）应答义务
      ——补 spec §6 条款 + 定向场景 + oracle，或书面记为范围外（构造随机
      场景时二选一，不拖过 M5）

## M6 — 六类覆盖 ≥90% 收敛（含 Toggle）🔲

**性质**：结构覆盖率百分比达标轴的收敛里程碑，承接 M4 移交的 ≥90% 数字门。
工作原则 = random-first, directed-fallback：先跑 M5 随机层测量，只对随机
未命中的 bin 写定向场景（避免"定向刷宽总线 Toggle"的坏配对）。

### Exit criteria

- [ ] 六类覆盖 ≥90%（line+cond+fsm+tgl+branch+assert，spec §0#4 例化闭包
      口径）：全部（模块,类型）格 ≥90%，未达标格逐条书面豁免（结构不可达
      Kind-A，见 `doc/coverage-waivers.md`）
- [ ] 承接 M4 移交的 UNOWNED 覆盖缺口清单（lzc/counter/delta_counter Toggle
      40% 区间、axi_demux_id_counters 70% 区间、fifo_v3、rr_arb_tree、
      spill_register_flushable Assert 0% 等——清单见
      `git show v0.5.3-pre-reset:doc/evidence/v0.4.35/M4-coverage-final-sweep.md`），
      逐条闭合或豁免
- [ ] 覆盖率驱动闭环工具（逐种子边际贡献测量、饱和/预算停止、残余缺口清单；
      脚本只测量不作 oracle）
- [ ] 完成后转 v1.0.0
