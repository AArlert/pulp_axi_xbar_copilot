# signoff-M4 — M4（六类结构覆盖率收敛）里程碑签核

- 日期：2026-08-01 · 版本：v0.4.13 · 里程碑：M4
- 签核人：rev（全新 fresh 实例，未与本轮任何 M4 相关卡作者共用）
- 判据来源：`workflow/review.md`（七问 + 签核 rubric #1-#9）、`doc/milestone.md`
  M4 出口条件、`doc/spec.md` §0 item 4/5、§4 clause 7（pinned）
- **本记录引用既有 REV 记录，不誊抄其内容**（review.md L120 明示的失败模式）。

> **总体裁决前置摘要（详见文末 §Verdict）：REJECTED —— M4 尚不具备签核条件。**
> 四条机器门禁确实全绿，但机器门禁**不含覆盖率百分比判据**（`make check` 只查
> 场景 ✅ / regress 证据 / bug 终态 / KILL，不查 ≥90%）。M4 的**定义性出口条件**
> 是「六类 ≥90%，缺口逐条**或修或书面豁免**」——而
> `doc/evidence/v0.4.9/M4-coverage-baseline.md` §6 列出的 ~9 个（模块,类型）缺口
> 里，只有 2 类得到合法处置（atop_filter 环境约束豁免〔本记录 §REV-017 兑现〕+
> addr_decode/axi_demux 父模块结构性 N/A〔BUG-0038 终判〕）；其余 ~6 类是
> **可达但未测**（报告 disposition 列逐条写「需补场景」），**既未修、亦不可
> 合法豁免**（豁免须给可证伪的不可达性论证，REV-016 §9；「没测」≠「测不到」）。
> 故 M4 的核心风险（结构覆盖缺口掩盖未测逻辑）**未收敛**。以下逐条落 rubric。

---

## 机器条件（rubric #1-#4，`make check MILESTONE=4` 亲跑，2026-08-01）

```
[PASS] 1. all M4 scenarios ✅
[PASS] 2. regress summary registered as evidence (result_summary.txt in doc/evidence/v0.4.*)
[PASS] 3. all bugs terminal or ACCEPTED-unexpired, closures evidenced
[PASS] 4. kill coverage: >=1 KILL row tagged M4 (KILL-0004)
[not yet] signoff file (signoff-M4*.md) in doc/evidence/v0.4.*
```

- 条件 1：M4-RC01/AW01/OV01/FT01 均 ✅（testplan），26/26 regress PASS
  （`doc/evidence/v0.4.9/M4-coverage-baseline.md` §2）。
- 条件 2：regress 证据 `doc/evidence/v0.4.9/result_summary.txt`（26/26），
  含全部 regression-guard 定向用例（M1-02 等）。
- 条件 3：BUG-0038/0039=SPEC_CHANGED、0041/0043=WONTFIX、0044/0045/0046=
  ACCEPTED@M5（未到期）——逐条见 §rubric#7/#8。
- 条件 4：KILL-0004（M4-OV01 tie-break refmodel 注伤自证），登记于
  `doc/archive/bugs-archive.md`（`check_kill_coverage` 同读 bugs.md + archive，
  `scripts/docs.py:928`）。KILL 集合**是否够**见 §rubric#5。
- **机器条件本身不构成签核**——它不判覆盖率百分比。签核判断在下方人工抽查。

---

## rubric #5 — Coverage closure ≠ risk closure

### 良好命中 bin：由**预期场景**命中、非偶然（3 例，独立核实）

1. **`axi_xbar` 顶层 Toggle `en_default_mst_port_i[5:0]` 的 1→0 方向**
   （`M4-coverage-baseline.md` §5 第 5 条，mod39.html）。**预期场景 = M4-RC01**
   （运行时把已使能的 default master port 关闭）。非偶然：1→0 只可能由「运行中
   把 en_default 从 1 改回 0」产生；M0-M3 全部场景无任何 default-port 运行时
   关闭动作（v0.4.0 基线该位「只 0→1、从未 1→0」）。**核实通过**。
2. **`axi_mux` 仲裁「下游背压后锁定重试」路径 Line/Branch（`lock_aw_valid_q`
   相关行）100%**（§5 第 1 条，mod19.html per-instance：仅
   `gen_mst_port_mux[0].i_axi_mux` 达 100%）。**预期场景 = M4-AW01**（对某 master
   端口持续 `mst_aw_ready=0` 制造 AW 仲裁锁定重试）。非偶然：进入
   `lock_aw_valid_q` 分支须在一次 AW 仲裁中持续背压，唯 AW01 背压序列构造。
   **核实通过**——但附**实例级颗粒度警示**（§5 第 1 条自陈）：模块级 100% 是
   跨 8 实例并集，实际仅 1/8 master 端口达 100%，其余 7 个仍停在 Line 72.41%。
   这条「命中」满足 spec §0 item4「（模块,类型）取子树并集」字面判据，但**不代表
   8 个端口的该路径均已覆盖**——如实记录，计入残余风险清单。
3. **err_slv decode-error 响应路径 + BUG-0032 env-guard**：`slvport_de01_seq`
   的未命中写/读由 **M3-DE01** 命中。独立**活体**核实：本签核对 de01 miss 序列
   注入非零 atop（见 §rubric#6 falsification）后 `SB_ATOP_DECODE` 在 t=125000
   逐端口报错，证明该 miss 路径确被 M3-DE01 实时激励、且 env-guard 非空转。
   **核实通过**。

### 书面豁免的洞：重读不可达论证（1 例）

- **`axi_atop_filter` W/R FSM 7.14%（环境约束致不可达）**。重读 REV-017 §Item1/3
  的不可达论证并**独立复核当前代码树**：`axi_atop_filter.sv` 离开
  `W_FEEDTHROUGH`/`R_FEEDTHROUGH` 的唯一触发是
  `aw.atop[5:4]!=ATOP_NONE`（:121/:143），而本 DUT 层次内 6 个 atop_filter 全
  在 `axi_err_slv` 内（`axi_err_slv.sv:45-58`），事务仅经译码未命中抵达——正是
  §4 clause 7 环境约束所禁。**论证站得住，且被本签核的活体 falsification
  正向佐证**：注入 atop 到未命中地址后，FSM 确实开始 engage（DECERR 变为 OKAY、
  出现 R beat），即「点亮该 FSM」= 违反约束、= 让 checker 面对无源期望值。豁免
  成立（书面豁免本体见文末 §REV-017 兑现）。

### KILL 集合是否**够**（不只是「有」）

- M4 引入的**唯一全新期望值类别** = M4-OV01 重叠 rule tie-break 参考模型
  （`decode_mst_port`），已由 **KILL-0004** 注伤自证（植入 `break;` → route
  mismatch=48/UVM_ERROR:49 → 恢复 route match=60/0，`git diff` 净）。
- M4-RC01/AW01/FT01 **未引入新期望值类别**，复用 M3 已建立并已 KILL 的 checker
  类（DECERR 响应、resp-route、stall/chan SVA）。本签核另**活体**证实
  `SB_ATOP_DECODE`（env-guard 类）可见红（§rubric#6）。
- **判断：KILL 集合对 M4 实际新增的 checker 类别为最小充分**。附注：这是「够」
  的下限判断——若后续为关上 §6 可达缺口新增 checker（如 slave 端口 AW
  valid-but-not-ready 稳定性断言的定向激励），须各自补 KILL。

---

## rubric #6 — Guard consumption + falsification

### 消费清单（`make guards FILES="<M4 实际改动文件>"`）

M4 改动文件（由 commit `8b548e0/9c4e01d/fd4b5b6/3bfe9b1/1085653/2629c75/48f80a2`
自证，非照抄卡片）：`tb/seq_lib.sv`、`functional_coverage.sv`、
`scoreboard_refmodel.sv`、`sva/axi_chan_sva.sv`、`mstport_agent.sv`、
`slvport_agent.sv`、`test_lib.sv`、`xbar_types_pkg.sv`、`axi_txn.sv`。命中 guard：
BUG-0007/0009/0012/0013/0015/0017/0018/0021/0023/0024/0027/0031/**0032**/0033/
0034/0040/0041/0042。逐条抽查其被 M4 各卡遵守：
- **BUG-0032 guard**（对象 = 约束不被悄悄解除）：核实全部非零 atop 赋值点
  （`seq_lib.sv:394/426/1509`）均落**已映射**地址（`tgt*REGION_SIZE+off`，tgt 为
  master 端口下标 = 命中）；全部未命中/miss 序列 `atop='0`（de01:962、de02:1005、
  `slvport_basic_seq` 从不设 atop）；`axi_seq_item` 默认 `atop='0`
  （`axi_txn.sv:49/119`）。**且存在活体机械抽查**：`scoreboard_refmodel.sv:469-472`
  的 `SB_ATOP_DECODE` uvm_error 在「写 × 未命中 × atop!='0」时报错，26/26 PASS
  即该计数恒 0。**遵守，达 REV-017 条件 3b 要求的两种形态（grep + 计数=0）**。
- BUG-0041 guard（M4-OV01 收尾腿激励侧 hygiene，REV-020 §4）、BUG-0042 guard
  （M4-FT01 cfgE）等 M4 新登记项：命中于对应 M4 文件，遵守（对应场景 ✅）。

### Falsification（活体证伪，rubric 强制「至少一条见红」）

选 **BUG-0032 guard**（本签核的 atop_filter 豁免所依赖，最载荷）：
- 注伤：`seq_lib.sv:962` `it.atop = '0` → `it.atop = 6'h30`（向未命中地址注入
  ATOP）。
- 重跑 `make run TEST=m3_de01_decerr_test SEED=1`：`SB_ATOP_DECODE` 于 t=125000
  **逐 slave 端口报错 6 次**（`slv port 0..5 sent an ATOP (atop='h30) to unmapped
  address ... env violated the BUG-0032 / spec §4.7 no-ATOP-to-decode-error
  constraint`），并连锁触发 DECERR/BRESP/RDATA 失配 → 转红。
- 恢复原文，`git diff` / `git status --short` **均空**（无残留）。
- **结论：guard 真实、可证伪，非装饰**。同时正向佐证 §rubric#5 的 atop_filter
  不可达论证（注入即令 FSM engage）。

---

## rubric #7 — Spec debt zero-or-accepted

- open SPEC_ISSUE 列表**非空**，但每条均有书面接受理由：
  BUG-0044/0045/0046 均 `ACCEPTED@M5`（非 OPEN），各点名 REV-019/021/023，
  均为**潜伏型**缺口（当前无任何场景触及，不产生无源/错源期望值，故不阻塞 M4
  证据）。BUG-0044（§6 非-load atop 应答条款缺口，containment=有界子集）、
  BUG-0045（§3.2 `end_addr=='0` 哨兵分支）、BUG-0046（§3.2 `<=` vs RTL `<`）。
  **满足 rubric #7**。

---

## rubric #8 — Accepted debt is real debt（可证伪性逐条核实）

- **BUG-0044 / REV-019**：可证伪解锁 = 「有界子集 `{'0}∪load` 下 scoreboard 有
  oracle 且 store/swap/compare 构造性挡在约束外」；**被推翻即作废** = 任一场景
  构造非-load atop 需该 oracle 时。到期 M5。**falsifiable，非软承诺**。
- **BUG-0045 / REV-021**：**被推翻即作废** = 「任一场景（含 M5）构造 `end_addr=='0`
  的 rule、或依赖地址空间末端语义」。到期 M5。**falsifiable**。
- **BUG-0046 / REV-023**：**被推翻即作废** = 「任一场景/配置构造
  `start_addr==end_addr`（end≠0）的 rule」；REV-023 明写到期动作二选一且
  「never auto-extended」。到期 M5。**falsifiable**。
- 三条均**首次登记**、到期 M5、无自动延期。WONTFIX 两条（BUG-0041 REV-020
  accepted-vendor-quirk、BUG-0043 REV-022 accepted-transient）为真终态、各保留
  可证伪的功能检查/永久 checklist guard，非软延。**满足 rubric #8**。

---

## rubric #9 — Chain audit answered（`make check` 输出粘贴 + 逐类处置）

```
== chain audit ==
[PASS] dangling spec refs (cited, no such section): 0
[gap] scenarios citing no spec clause: 1 — M0-01
[gap] scenarios in no feature-matrix row: 4 — M4-RC01, M4-AW01, M4-OV01, M4-FT01
[gap] refs anchored only at a parent section: 13 — ... (M1-02/M2/M3/M4 混合)
[gap] spec subsections cited by no scenario: 7 — §1.3, §2.2, §2.3, §6.1, §7.1, §7.1.2, §7.4.4
[gap] ✅ evidence without a spec_ref header: 26/26 (convention, not yet enforced)
```

逐类处置意见：
- **dangling refs = 0**：无悬挂引用，无需修（rubric「dangling refs are fixed」满足）。
- **M0-01 无 spec 引用**：M0 sanity（upstream tb），非行为 checker；书面接受
  （历史冻结记录，不回改）。
- **M4-RC01/AW01/OV01/FT01 不在 feature-matrix 行**：既有 gap（非本签核新增）。
  处置意见 = **由 orch 派 L0 文档卡补 feature-matrix 4 行**（把 4 条 M4 场景登进
  矩阵），或书面接受「本仓库 feature-matrix 未强制覆盖 M4 sweep 行」。此为
  Retention 可见性缺口，**不阻塞签核判断本身**，但应在 M4 状态转 ✅ 前一并补，
  否则 spec-vs-artifact 追溯留洞。
- **父节锚定 13 条 / 未被引用子节 7 条**：可见性提示，非门；书面接受（既有
  引用粒度，后续卡可细化）。
- **26/26 无 spec_ref header**：约定未强制（`iverif.json` 未开该门）；书面接受。

---

## REV-017 条件 3 兑现（本卡独有实质工作）

> 归宿 = 本签核文档（REV-017 §豁免记录归宿）。以下为**准予采纳的**书面豁免
> 本体；因总体裁决 REJECTED，本豁免**随 M4 正式签核生效**（论证与逐弧清单已就绪、
> 已对当前代码树复核，M4 一旦补齐 §6 可达缺口即可直接引用）。

### a. `axi_atop_filter` FSM 书面豁免（逐弧，已对当前 vendor 树复核行号）

- **成因**：spec §4 clause 7 环境约束（BUG-0032/REV-012；M4 重开并延展至 M4，
  BUG-0039/REV-017）——M3 与 M4 全部场景不向译码未命中地址发起任何 ATOP，使
  err_slv×ATOP 无源应答组合构造性不可触发。本 DUT 层次内 6 个 atop_filter 全在
  err_slv 内，其非-FEEDTHROUGH 状态仅经被禁激励可达。
- **被豁免的状态/迁移（`vendor/axi/src/axi_atop_filter.sv` @ v0.39.9，SHA
  a256a3b8；行号 = 迁移目标赋值行，本卡逐条 grep 复核与当前树一致）**：
  - 写侧 FSM `w_state_q`（7 状态，覆盖 2/7 = 仅 `W_RESET`/`W_FEEDTHROUGH`）：
    未覆盖 5 状态 —— `BLOCK_AW`(:151)、`HOLD_B`(:161)、`INJECT_B`(:163)、
    `ABSORB_W`(:167)、`WAIT_R`(:228)，及其间全部迁移弧。
  - 读侧 FSM `r_state_q`（4 状态，覆盖 2/4 = 仅 `R_RESET`/`R_FEEDTHROUGH`）：
    未覆盖 2 状态 —— `R_HOLD`(:275)、`INJECT_R`(:281)，及其间迁移弧。
  - 相应 Line/Cond/Toggle/Branch 中仅经上述被禁激励可达的 bin 一并豁免
    （§4 clause 7 覆盖率后果条款）。
- **归属**：`axi_atop_filter` 有 bin（FSM 7.14%），属 spec §0 item4「有 bin 但
  <90%」分支，走**书面豁免**（非 §0 item4「无 bin ⇒ N/A」三态规则）；豁免后该
  FSM **不计入 ≥90% 的分子与分母**。
- **解锁条件（可证伪）**：补 err_slv×ATOP 应答的许可来源（当前五份许可来源皆空，
  REV-012 rationale）并重开 BUG-0032；一旦补齐即须放行激励、消豁免、点亮 FSM。
- **引证**：REV-017 §Item1/3、REV-016 §6.2、spec §4 clause 7、
  `M4-coverage-baseline.md` §5 第 3 条。

### b. BUG-0032 guard 机械抽查

- **grep 侧**：未命中地址构造点（de01:962/de02:1005/basic-seq）`atop` 恒 `'0`；
  非零 atop 仅在命中地址（§rubric#6）。**恒成立**。
- **计数侧**：`SB_ATOP_DECODE`（scoreboard_refmodel.sv:469-472）对「未命中地址上
  atop!='0」计数，26/26 PASS ⇒ **该数 = 0**。活体 falsification 已证其非零即报红。
- **结论：约束未被悄悄解除，豁免前提成立。**

---

## 残余风险清单（M4 定义性出口条件未满足项）

来源 `doc/evidence/v0.4.9/M4-coverage-baseline.md` §6 三态判定表，逐条给 M4 出口
判定（✔=合法处置完成；✗=未修且不可合法豁免 → 阻塞签核）：

| 模块 | 类型 | 数值 | 处置状态 | 阻塞？ |
|---|---|---|---|---|
| `axi_atop_filter` | Line/Cond/Toggle/FSM/Branch | 46/35/40/7.14/34.78% | ✔ 书面豁免（本记录 §REV-017，环境约束不可达） | 否 |
| `addr_decode`/`axi_demux`（父） | Line/Cond/Branch/Assert 空白 | N/A | ✔ 结构性 N/A（BUG-0038 终判，判据转子模块） | 否 |
| `axi_xbar` | Toggle | 40.74% | 部分可豁免（`rst_ni` 无热复位/`test_i` scan 出范围）+ **部分可达未测（`default_mst_port_i` 具体 bit 双向翻转）** | **是** |
| `axi_xbar_unmuxed` | Assert | 53.85% | 待定：slave 端口 AW valid-but-not-ready 稳定性断言 0 real-succeeded；须先判「定向激励下是否结构不可达」再决定补场景 or 豁免 | **是** |
| `axi_demux_simple` | Line/Cond/Branch/Assert | 83.72/72-76/77.78/50% | **可达未测**（路由/ID 跟踪逻辑，需补场景）；Assert 同 unmuxed valid-but-not-ready 类 | **是** |
| `addr_decode_dync` | Toggle/Branch | 53-57/83.33% | **可达未测**（更多样地址/rule 组合、边界分支） | **是** |
| `axi_mux` | Toggle | 55-58% | **可达未测**（ID/地址/数据位更广翻转）+ §rubric#5 实例级：7/8 端口重试路径未测 | **是** |
| `axi_err_slv` | Cond/Toggle | 83.33/42-44% | **可达未测** | **是** |
| `axi_multicut`/`axi_cut`/`spill_register` | Cond | 55-65% | 部分 N/A + **部分可达未测（Cond）** | **是** |

**核心问题**：出口条件「缺口逐条**或修或书面豁免**」中，~6 类为**可达但未测**
（报告 disposition 逐条写「需补场景」）。按 REV-016 §9，书面豁免须给**可证伪的
不可达性论证**（「测不到」），而这些是「没测」——**不可合法豁免，必须补定向场景**。
`doc/coverage-waivers.md` 尚不存在（REV-016 §9.5 早已点名）。

**方法学张力（须一并处置）**：部分 Toggle 缺口（宽 AXI 数据/地址/ID 总线的位
翻转）在**纯定向激励**下天然难达 ≥90%，现实上依赖 M5 约束随机；但项目原则
（`milestone.md` M5 注）明令「随机只能加固/发现，不能替代 M4 的定向关闭」，且
M4 排在 M5 前。即 **M4「六类含 Toggle ≥90%」目标与「M5 前仅定向」约束存在可行性
张力**——对纯定向难达的 Toggle bin，出口只能是「rev 签核的书面（部分）不可达/
成本论证豁免」或「重议 M4 Toggle 判据口径」，二者当前均未落地。此张力**未在
`doc/bugs.md` 显式立行**（见文末 taxonomy 字段）。

---

## Overall verdict

**REJECTED —— M4 尚不具备签核条件。**

- 机器门禁（rubric #1-#4）全绿，但**不含覆盖率百分比**；rubric #5-#9 人工抽查
  除覆盖率闭合外**全部通过**（guard 活体证伪见红、accepted debt 可证伪、spec
  debt 已接受、chain audit 逐类给处置、KILL 集合对新增 checker 类最小充分）。
- **否决理由（唯一但决定性）**：M4 的**定义性出口条件**——六类 ≥90%、缺口逐条
  修或 rev 签核书面豁免——**未满足**。`M4-coverage-baseline.md` §6 的 ~9 类缺口
  中，仅 2 类得到合法处置（atop_filter 环境约束豁免〔本记录已兑现〕+
  addr_decode/axi_demux 结构性 N/A）；其余 ~6 类为**可达但未测**，既未修、又不可
  合法豁免（豁免须不可达论证，这些是「没测」非「测不到」）。M4 的核心风险
  （结构覆盖缺口掩盖未测逻辑）**未收敛**。签核不是「覆盖率数字够高」，更不是
  「机器四条绿」——它是「证据是否支撑本里程碑风险已收敛」的回答，此处**不支撑**。

### 后续该派什么卡（指方向，不代写卡）

1. **DV 定向覆盖卡（可达缺口，L1-L2，逐（模块,类型））**：针对
   `axi_demux_simple`（Line/Cond/Branch：更全的路由/ID-bucket/背压组合）、
   `addr_decode_dync`（Toggle/Branch：更多样地址表 + rule 边界）、`axi_mux`
   Toggle（8 端口重试路径均覆盖 + 更广数据/ID 翻转）、`axi_err_slv` Cond/Toggle、
   `axi_xbar` `default_mst_port_i` 具体 bit 双向翻转、`spill_register` Cond。
   每卡须给 spec 引用 + 可证伪具名场景（项目原则：定向关闭，非等 M5 随机）。
2. **rev 覆盖率豁免卡（真不可达/结构，L3）**：先建 `doc/coverage-waivers.md`；
   为 `rst_ni`（无热复位场景、须先判是否引入运行中复位场景 or 豁免）、`test_i`
   scan（出验证范围）、以及 `axi_xbar_unmuxed`/`axi_demux_simple` 的 AW
   valid-but-not-ready 稳定性断言类（**须先核实定向激励下 demux 是否结构性无法
   在 slave 端口 AW 阶段制造 valid-but-not-ready**——若不可达则豁免，若可达则归
   入卡 1）逐条写可证伪不可达论证。atop_filter FSM 豁免本记录 §REV-017 已备。
3. **方法学张力立行 + 处置（arch/rev，L3）**：把「M4 Toggle ≥90% vs M5 前仅定向」
   可行性张力显式登记（见 taxonomy 字段），二选一裁决——(i) 对纯定向难达的
   Toggle bin 出 rev 签核的（部分）不可达/成本豁免；(ii) 重议 M4 Toggle 判据
   口径（须走 spec §0 变更提案，rev 门禁）。**在此之前 M4 Toggle 类缺口悬空**。
4. **feature-matrix 补 4 行**（chain audit gap，L0 文档卡）：M4-RC01/AW01/OV01/
   FT01 登进矩阵，闭 spec-vs-artifact 追溯洞。

M4 状态维持 🔲，版本照常走 0.4.x/0.5.x（v1.0.0 挂 M5 签核后，本签核不触发大版本
跳变）。上述 1-3 闭合后重开 M4 签核卡（全 rubric 复跑）。

---

## 强制字段 — taxonomy-class anomaly

**是（yes）——建议新开 1 行，本 rev 不代建（rev 不改 bugs.md 非裁决列）。**

本签核浮出一个 `failure_taxonomy.md` SPEC_ISSUE / planning-gap 类、尚无
`doc/bugs.md` 行的实例：**M4 出口条件「六类含 Toggle ≥90%」与项目「M5 前仅定向、
随机不得替代 M4 定向关闭」约束之间的可行性张力**——对宽 AXI 总线 Toggle 等纯
定向难达的 bin，出口只能走 rev 书面豁免或重议判据口径，二者均未落地，且该张力
在台账上**不可 grep**。按 CLAUDE.md §2「登记无条件」（M1-01 教训），建议 orch 立
`doc/bugs.md` 行：suspect=`spec`，status=`OPEN`，`## similar` 指 BUG-0038/BUG-0018，
summary =「M4 六类含 Toggle ≥90% 在 M5 前仅定向激励约束下对宽总线 bin 可行性
存疑，须 rev 豁免或重议判据口径」。**登记是无条件的**——即便 M4 最终对这些 bin
走豁免，此张力也须先在台账可见。

其余已浮出项（feature-matrix 4 行缺、`coverage-waivers.md` 未建）非
failure_taxonomy 类，属 Retention/流程可见性，已在 §rubric#9 / §后续卡 给处置。

---

## 七问（`workflow/review.md` L5-51，签核视角逐条）

1. **Origin**：M4 四场景均溯 spec（SPEC-3.1.3/3.2.1/3.4.1/4.4/5.5.4 等，见
   testplan）；覆盖率判据溯 spec §0 item4（BUG-0038/REV-016 例化闭包）。**pass**。
2. **Falsifiability**：本签核活体证伪 BUG-0032 guard（SB_ATOP_DECODE 见红）+
   核 KILL-0004（refmodel tie-break 注伤见红）。checker 非装饰。**pass**。
3. **Replayability**：`make run TEST=m3_de01_decerr_test SEED=1`（falsification）、
   `make regress`（26/26）、`make cov TEST=...`（覆盖率，baseline §0）均自足可复放。
   **pass**。
4. **Attribution**：M4 bug 行终态/ACCEPTED 齐备，closer≠fixer（KILL-0004 由 DV
   自证、orch 独立复核；本签核由独立 rev）。**pass**。
5. **Judgment**：现有证据**不支撑** M4「结构覆盖风险已收敛」——~6 类可达缺口未测
   未豁免。缺口清单见 §残余风险。**这正是本签核的可执行产出（REJECTED）**。
6. **Retention**：atop_filter 豁免落本文档、方法学张力建议立行、后续卡指向
   `coverage-waivers.md`/feature-matrix 补齐——教训落持久处，不留聊天记录。**pass**。
7. **Kill coverage**：见 §rubric#5——M4 新增期望值类（OV01 tie-break）有 KILL-0004；
   复用类继承 M3 KILL + 本签核活体证 env-guard。最小充分，附「够」的下限判断。**pass**。
