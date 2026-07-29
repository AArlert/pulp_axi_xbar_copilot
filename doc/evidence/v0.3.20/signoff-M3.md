# signoff-M3 — 里程碑 M3（多配置回归 + 错误路径）签核记录

- 版本：0.3.20
- 日期：2026-07-30
- 签核人：rev（全新实例，独立复核；未采信 DV/DE/前序 rev 的口头结论，log/diff/代码/仿真亲读亲跑）
- 判据来源：`workflow/review.md`「七问」+「Milestone signoff rubric」九条 · `doc/milestone.md` M3 Exit criteria · `CLAUDE.md` 五条不变量
- **本文件引用过程评审（REV-xxx）+ spot-check 结果 + 终裁；非任何评审文件的逐字复制**（rubric「Signoff ≠ review」）

## 终裁（先给结论）

**有条件 PASS（CONDITIONAL PASS，附 2 项阻塞条件 C1/C2）。**

M3 的实质风险（多配置回归、错误路径/decode-error、译码未命中保序、ATOP 跨方向交互）
均由**逐场景有效证据 + 独立复验**退休；四条机器硬条件在本卡复跑前全绿；spec 已 sha256
钉死且工作副本与钉值自洽；守卫可证伪（本卡实证注伤见红）。**唯二缺口均为记账/回归网
层面、非功能破损**，且底层场景经本卡独立复跑确认为 PASS：

- **C1（阻塞）**：M3-CFG02（`m3_cfg02_reconfig_test`）是 ✅ 场景却缺席 `regress.list`
  与 21/21 全回归摘要——已登记 **BUG-0036**。orch 须派 L0 修复卡补入清单、`make regress`
  转 22/22、刷新证据、重登摘要、重跑 `make check MILESTONE=3`。
- **C2（阻塞，轻）**：BUG-0034 R burst 重建 checker 类别的注伤自证（红→绿）已在
  `doc/bugs/BUG-0034.md` 做过两次（fixer + closer 独立），但**未在台账落一行 KILL**——
  须补一行 M3 标签的 KILL 行（或在 KILL 台账注明 BUG-0034 修复循环即其击杀见证），
  兑现不变量 5「记一行 KILL」的字面要求。

C1/C2 均为机械动作、不需重开任何功能验证。二者兑现后 M3 即完整签核。**未为让状态好看
放松任一机器条件或 spot check**（deliverable #3）：登记 BUG-0036 会使 `make check
MILESTONE=3` 条件 3 由绿转红——这正是机器门对 C1 的强制背书，非缺陷。

---

## 一、机器条件打印（本卡亲跑 `make check MILESTONE=3`，非采信派卡转述）

```
[PASS] 1. all M3 scenarios ✅
[PASS] 2. regress summary registered as evidence (result_summary.txt in doc/evidence/v0.3.*)
[PASS] 3. all bugs terminal or ACCEPTED-unexpired, closures evidenced
[PASS] 4. kill coverage: >=1 KILL row tagged M3 (KILL-0002, KILL-0001)
[not yet] signoff file (signoff-M3*.md) in doc/evidence/v0.3.*
```

> **注**：以上为登记 BUG-0036 **之前**的读数。登记后条件 3 将转 `[FAIL]`（BUG-0036 为
> OPEN）——这是 C1 的机器背书：M3 完整签核以 BUG-0036 关闭（22/22 回归）为前置，
> 条件 3 回绿即 C1 兑现。条件 4 由本 closeout 内 L0 脚本卡打通（FB-29：
> `check_kill_coverage()` 此前漏扫 `doc/archive/bugs-archive.md`，KILL-0001/0002 已归档
> 而被漏计；修复 `scripts/docs.py`，commit `616c137`）——本卡复核该修复：两 KILL 行确在
> 归档表、summary 含 M3 token，条件 4 绿属实。

**invariant 4（spec 钉死）本卡亲验**：`doc/spec.sha256` =
`ad5bf8b7575608bbd1e640592aa9eb7ae31bae38df55cb27ae1a6b657e6b3a2c`，与
`sha256sum doc/spec.md` **逐位相同** ⇒ 工作副本 == 钉值。BUG-0032 行所记 `9347b4ac…`
是 change record #7 当时值，已被 #8（BUG-0033/REV-014 §4 clause 4 校正）取代，现钉值反映
#8 为最新 spec 编辑，自洽。

---

## 二、九条 rubric 逐条 spot-check

### 条件 1 — 全 M3 场景 ✅（机器 PASS + 逐行人工核）

11 条 M3 场景（DE01/DE02/OR04/CFG02/OR05/AT02/CF01~04/TL01）证据文件逐一亲读：
首行均为重放命令（`make run TEST=… SEED=1`）、均由 `scripts/evidence.py` 生成（证据链
完整、非手改）、均 `UVM_ERROR:0 / UVM_FATAL:0 / 0 assertion failures / SB 全 mismatch=0`。
逐场景守卫 cover（结构性恒 0 → 兑现后 >0）由 rev 回源 `sim/out/*.log` 亲验：

| 场景 | 证据 | 守卫 cover 兑现（回源 sim/out 核） |
|---|---|---|
| M3-DE01 | v0.3.9/M3-DE01.log | decerr resp=24、SB 全 match；ERR_RDATA 判据见条件 6 注伤 |
| M3-DE02 | v0.3.9/M3-DE02.log | `cg_default_port_tracked cp_entered=100%`(samples=6)＝BUG-0025 default-port 守卫 >0 |
| M3-OR04 | v0.3.9/M3-OR04.log | `cg_miss_order cp_miss=100%`(24)＋`c_bug25_errbucket_aw/ar` 各 1 match＝桶级排除 cover ≥1 |
| M3-CFG02 | v0.3.9/M3-CFG02.log | `c_bug31_livev1_aw/ar` 各 1 match＝活值表 V1 目标判据兑现（**见 C1 回归网缺口**） |
| M3-OR05 | v0.3.11/M3-OR05.log | `w_lost_now/r_lost_now` 非 0（范围边界见证）、`SVA_OR_*_REORDER`=0（范围外解除武装） |
| M3-AT02 | v0.3.15/M3-AT02.log | `cg_atop_read_interaction.colliding_read_present` 命中、atop pairs=1（多拍腿，见残余风险） |
| M3-CF01~04 | v0.3.14, v0.3.15 | `cg_cfg_point` point_id=0/2/3/4 各命中；cfgC 另有 `SB_UNIQUEIDS`；cfgD default-port 流量 cover |
| M3-TL01 | v0.3.19/M3-TL01.log | `cg_xbucket_total=100%`(20)＝合计在飞 >MaxMstTrans 且 ≥2 桶非空 |

判据锚点均为 scoreboard 参考模型（期望从 pinned spec 推导），非空转、非 spec-from-RTL。
**结论：PASS。**

### 条件 2 — 全回归摘要入证据（机器 PASS，但 spot check 6 抽查发现实质缺口 → C1）

`doc/evidence/v0.3.20/result_summary.txt` = `passed=21/21`，已入证据。**但**本卡对
`regress.list`（21 行）与 testplan ✅ 场景集做差集：**`m3_cfg02_reconfig_test` 缺席**
（testplan 22 条 ✅，regress.list 缺 CFG02 这一条）。rubric 条件 2 原文要求摘要
「includes every regression-guard case」——M3-CFG02 承载 BUG-0031 `c_bug31_livev1` 活值
守卫，正是 regression-guard case，其缺席使机器门（只校验清单内条目全 PASS）看不见该缺口。
详见 **BUG-0036 / 条件 C1 / §四残余风险**。**结论：机器 PASS，实质缺口 → 条件性签核 C1。**

### 条件 3 — bug 全终态或未到期 ACCEPTED，关闭有证据（登记 BUG-0036 前 PASS）

live `doc/bugs.md` + `doc/archive/bugs-archive.md` 全表亲读：M3 相关行状态终态性核验——
BUG-0032 SPEC_CHANGED、BUG-0031/0025/0018 CLOSED（各带 verify_evidence）、BUG-0024/0021/
0017/0030/0035 WONTFIX、BUG-0033/0016/0010~0013/0002~0005 SPEC_CHANGED、BUG-0034 CLOSED
（fix d7f5011，verify v0.3.18/BUG-0034.log）。CLOSED 行 verify_evidence 逐条存在。
**本卡新登记 BUG-0036（OPEN）会使本条转 FAIL**——见终裁 C1 说明。**结论：登记前 PASS；
登记后由 C1 承接。**

### 条件 4 — ≥1 条 M3 标签 KILL 行（机器 PASS；完整性判断见 spot check 5）

KILL-0001（decerr-rdata）、KILL-0002（cfgC UniqueIds 兜底监视）两行均在归档表、打 M3
标签。机器 PASS。**完整性另判见条件 5 / C2。结论：PASS（机器最小值）。**

### 条件 5（spot check）— 覆盖闭合 ≠ 风险闭合；KILL 集完整性判断

**2–3 个命中 bin 由意图场景命中（非顺带）**，回源 sim/out 核实：
- `cg_default_port_tracked cp_entered=100%` 仅在 **m3_de02**（default-port 场景，samples=6）
  命中；在 m3_tl01/m3_at02 为 0 ⇒ 意图命中。
- `cg_miss_order cp_miss=100%` 仅在 **m3_or04**（SPEC-5.2.6 桶级排除场景，samples=24）命中；
  m3_de02 为 0 ⇒ 意图命中。
- `cg_xbucket_total=100%` 仅在 **m3_tl01**（跨桶合计超限场景，samples=20）命中 ⇒ 意图命中。

**1 个豁免 hole 重读不可达论证**：BUG-0032（err_slv × 译码未命中 ATOP 的应答形态）——
许可来源（xbar.md §Decode Errors 全段、demux.md/mux.md）**未定义**，env 构造性约束使
M3 全场景不向未命中地址发 ATOP（spec §4 clause 7 + §6 clause 3，change record #7；活载体
= testplan M3-DE01 行 + uvm_env C6.2）。不可达论证成立且有书面裁决（REV-012/REV-013），
可证伪 rationale：五源任一定义该形态即须重开。属"构造性不可达"，非"忘了测"。

**KILL 集完整性判断**：M3 新增的**判决型** checker 类别 = decerr-rdata（KILL-0001 ✓）、
cfgC UniqueIds 兜底监视（KILL-0002 ✓）、**R burst 逐拍 r_id 重建**（MON_RNOAR/SVA_RLAST_LEN/
SB_RBEATS/SB_ATOP_DANGLING，BUG-0034 修复后）。前二者有 KILL 行；**第三类的红→绿注伤自证
已做（`doc/bugs/BUG-0034.md` `## rerun` + closer 收口，两次独立：去 r_id 分流 → 四路见红
MON_RNOAR=2/SVA_RLAST_LEN=3/SB_RBEATS=3/SB_ATOP_DANGLING=2/UVM_ERROR=8，恢复归零，与
`## first_anomaly` 基线逐字吻合），但未在台账落 KILL 行**。其余 M3 新 cover（miss_order
排除、livemap、default_tracked、xbucket）为**非判决**型（cover 不产生 pass/fail 裁决），
无需独立 KILL。**判断：机器最小值满足；第三类的可证伪性已证且已在详情页留存，唯缺一行
台账登记 ⇒ 条件 C2**（同框架反复吃亏的"自证只落详情页、未进台账"形状）。**结论：PASS +
条件 C2。**

### 条件 6（spot check）— 守卫消费 + 注伤证伪

`make guards FILES="…"`（M3 全部执行卡触及文件并集）列出命中守卫（BUG-0007/0009/0010/
0011/0012/0013/…），逐条为已尊重的历史守卫（SVA 挂接走直接例化非 bind、AW/W 配对、
分桶口径、延迟不敏感锚点等）。

**至少证伪一条（本卡亲做，git 保证还原）**：选 KILL-0001 类（decerr-rdata，M3 关键）——
临时把 `tb/scoreboard_refmodel.sv:137` `ERR_RDATA` 由 pinned-spec 校正值
`64'hCA11AB1EBADCAB1E` 改回 BUG-0033 前错误值 `64'h00000000BADCAB1E`，`make run
TEST=m3_de01_decerr_test SEED=1` ⇒ `SB_DECERR_RDATA` **见红 12 拍**（`got 'hca11ab1ebadcab1e
expected 'hbadcab1e`，与 KILL-0001 记录一致）；`git checkout tb/scoreboard_refmodel.sv`
还原后工作树干净、常量复位为校正值。**守卫真能红、非装饰。结论：PASS。**

### 条件 7（spot check）— spec 债为零或已接受

live `doc/bugs.md` 无 OPEN SPEC_ISSUE：BUG-0032 已 SPEC_CHANGED（终态）。全表 spec 类
（BUG-0002/0003/0004/0005/0010/0011/0012/0013/0016/0032/0033）**全部 SPEC_CHANGED**、
均经 orch 应用 + change record + 重 pin。上游确认项（MaxSlvTrans 执行机制、ATOPs=0、
Connectivity=0、err_slv×ATOP、cycle-accurate）以 env 构造性约束闭合、书面 rationale 在各
REV/BUG 记录，非 open 尾巴。BUG-0016/BUG-0010 裁决记录（REV-005/REV-007）终结、已重 pin。
**结论：PASS（spec 债为零，接受项有 rationale）。**

### 条件 8（spot check）— 接受债为真债（四条 ACCEPTED@M3 逐条到期核）

milestone.md 点名的四条 `ACCEPTED@M3` 均经 REV-011 **到期再仲裁**（非自动延期）后落终态，
本卡核其 rationale 可证伪、复验为独立 closer（≠fixer）：
- **BUG-0018**（covergroup 接受时刻交叉 bin）→ CLOSED（7a1c912，closer 订正到期判据
  `x_state_dir[stalled][write]` 空转→非空、几何论证 `cp_stall_state` 天花板 33.33%）。
- **BUG-0024**（`w_id_open` 单 bit）→ WONTFIX（择 REV-010 G4 路线 (b) 正式收窄判决范围，
  范围外真解除武装 `w_n/r_n>=2` 早退、非"陈旧默认恰为假"；b-1~b-4 齐备、m3_or05 见证）。
- **BUG-0025**（未命中事务不入跟踪表）→ CLOSED（482a47e，SPEC_ISSUE 半边先仲裁出
  §5.2.6，default-port 半边纯 TB_BUG，errbucket 排除显式注释 + cover）。
- **BUG-0031**（stall_sva 用编译期地址表）→ CLOSED（482a47e，与 BUG-0025 同卡修，
  livev1 活值判据 cover 兑现）。

可证伪 rationale 均具名（如 BUG-0024「五源任一给出 per-full-ID 检测点即须重开路线 (a)」）。
无自动延期。**结论：PASS。**

### 条件 9（spot check）— chain audit 逐 gap disposition

本卡亲跑 `make check MILESTONE=3` 的 chain audit：

```
[PASS] dangling spec refs (cited, no such section): 0
[gap] scenarios citing no spec clause: 1 — M0-01
[gap] scenarios in no feature-matrix row: 0
[gap] refs anchored only at a parent section: 8 — M1-02 SPEC-5.1.2→§5.1, M1-02 SPEC-5.1.3→§5.1,
      M2-WO01 SPEC-5.5.4→§5.5, M2-AT01 SPEC-6.4→§6, M3-DE01 SPEC-4.4→§4, M3-CF02 SPEC-5.5.4→§5.5,
      M3-CF03 SPEC-5.3.1→§5.3, M3-CF03 SPEC-5.3.3→§5.3
[gap] spec subsections cited by no scenario: 10 — §1.3, §2.1, §2.2, §2.3, §6.1, §7.1, §7.1.2, §7.3, §7.4.3, §7.4.4
[gap] ✅ evidence without a spec_ref header: 22/22 (convention, not yet enforced)
```

逐 gap disposition（本卡亲验，未原样采信 FB-24 转述）：
- **dangling refs = 0**：真正的完整性门，绿。**接受（无 disposition 必要）。**
- **M0-01 无 clause**：上游 tb sanity，判据是上游自带 FIFO 参考网络（非蒸馏条款），设计
  如此。**接受**（非 M3 场景，不阻塞）。
- **parent-anchored 8（含 M3 4 条 SPEC-4.4/5.5.4/5.3.1/5.3.3）**：`§4`/`§5.3`/`§5.5` 无
  `###` 子标题、条款为正文列表项，解析器跌回父级——被引条款**真实存在**（本卡亲验 §4
  clause 4 err_slv RespData 值、§5.3.1 UniqueIds 前置在 spec 正文）。按 FB-24：**不得**往
  spec 正文塞自引用去迁就解析器（spec 文体不为工具让步，log [0.3.5] 已建议否决该类提案）。
  **接受为解析器 artifact，不改 spec。**
- **uncited subsections 10**：本卡亲验 spec 标题结构——§2.1/§2.2/§2.3/§7.1/§7.3 **是真标题**
  （Cfg 字段/模块参数/端口/spill 语义/使用约束，声明性/约束性章节，被基线 Cfg 与延迟不敏感
  判据隐式行使，非需专属场景的行为条款）；§1.3/§6.1/§7.1.2/§7.4.3/§7.4.4 **非标题**（列表项/
  跨文档引用，phantom，与 FB-24 全谱统计一致，其中 §7.4.3 是禁令型条款、由 checker 缺席满足）。
  **接受**（真章节为声明性/禁令性、无覆盖洞；phantom 为解析器误报）。
- **evidence 无 spec_ref header 22/22**：约定未强制。溯源实际由 testplan 描述列承载（每条
  M3 行显式引 SPEC-x.y）。**接受为 convention gap**（非阻塞；origin 可溯，只是不在证据头）。

无 dangling ref、无需修 spec、无覆盖洞。**结论：PASS（全 gap 有 disposition，无一为 dangling）。**

---

## 三、lint-baseline 差分结果与分诊结论（BUG-0021 WONTFIX 守卫，每里程碑强制）

本卡按 `doc/lint-baseline.md` 守卫条款执行强制重编 lint：
```
rm -f sim/out/simv_lint.daidir/.vcs.timestamp
make -C sim lint TEST=m2_or03_guard_test    # exit 2（tb/ 范围告警，BUG-0021 恒红属预期）
```
与基线（2026-07-28，8 类别 / 225 唯一站点）站点级（类别 × 文件 × 行）差分：

- **无新类别**：本次 8 类别 = 基线 8 类别（NS/SV-PIU/SVA-AECASR/SVA-CE/SVA-DIU/SVA-UA/
  ULCO/WMIA-L）。**关键安全信号**：`SVA-NSVU`（BUG-0015/0021 F1/F3 真缺陷类）在 `../tb/`
  范围 **= 0**；日志中 2 条 SVA-NSVU 落 `vendor/axi/src/axi_demux_simple.sv:473/477`——
  vendor RTL、守卫 scope 之外、pinned snapshot 不可改、既存，**非本仓库交付物新增**。
- **新增站点 158、消失站点 122**：全部集中于 M3 实际改动的文件——`axi_chan_sva.sv`/
  `slvport_agent.sv`（BUG-0034 R 重建重写）、`axi_xbar_stall_sva.sv`（BUG-0024/0025/0031
  range/errbucket/livemap）、`seq_lib.sv`（新 M3 序列）、`scoreboard_refmodel.sv`（decerr/
  uniqueids/xbucket）、`txlimit/worder_sva`（行位移）。新增/消失对以**行号位移**为主
  （如 SVA-AECASR axi_chan_sva 167/171/…→168/172/… 为 +1 位移的同一断言 action block）。
- **逐类分诊（亲读代表站点）**：全部为基线既判风格类，无一指向真缺陷——
  - SVA-AECASR（axi_chan_sva 168~197/253/273、stall_sva 452/458）= 并发/立即断言的
    `else uvm_error(…)` action block（`SVA_*_STABLE`/`SVA_OR_*_REORDER`），既判风格。
  - WMIA-L（scoreboard 723/793）= `src_port = ro.id >> ID_W_SLV` 加宽赋值，既判风格
    （NoSlvPorts=1 的 0 位前缀合法性所需，scoreboard_refmodel.md C5.7）。
  - ULCO（seq_lib）= `for (int unsigned b=0; b<=len; b++)` 零扩展比较，语义正确既判风格。
  - NS/SV-PIU/SVA-CE/SVA-DIU/SVA-UA = 空语句/`$unit` import/`disable iff` 参数/未命名断言，
    `scripts/svacheck.py` 两层判据均不依赖断言名。
- **BUG-0034 R 重建重写守 BUG-0015 红线**：新 per-id 状态只在 `always_ff` 内读写、RLAST 处
  immediate assert 判决，**无 concurrent property/cover 读该状态** ⇒ 未新增任何 SVA-NSVU
  （亲验，与上「tb 范围 SVA-NSVU=0」一致）。

**分诊结论：新增站点全为风格类，并入 M3 基线；无真缺陷、不另开 bug。** 建议 orch 让
L0 卡把 `doc/lint-baseline.md` 快照刷新至本次 run（2026-07-30 / M3，8 类别不变），使 M4
差分对当前行号；本卡不重写 225 行站点表以免计数方法学漂移，分诊结论以本节为准。

---

## 四、残余风险清单（residual risk）

1. **【C1，阻塞】M3-CFG02 缺席全回归网**（BUG-0036）：`m3_cfg02_reconfig_test` 不在
   `regress.list`；其登记证据（v0.3.9，07-29）早于 BUG-0034 monitor 重写（d7f5011，07-30）
   且未在 BUG-0034 回归防线复跑集内 ⇒ 自该重写起未被复验。**rev 已独立复跑当前 HEAD =
   PASS**（UVM_ERROR=0、SB 全 mismatch=0、2143 assertions 0 failures、`c_bug31_livev1_aw/ar`
   各 1 match）⇒ **latent PASS，非功能破损**。缺口在回归网/记账，属 BUG-0028 复发。
   **兑现 = 补入清单 + 22/22 + 刷新证据 + 重登摘要 + 条件 3 回绿。**

2. **【C2，阻塞·轻】R burst 重建 checker 类别缺 KILL 台账行**：BUG-0034 修复后该类可证伪
   性已由红→绿注伤自证两次背书（详情页），但台账无 KILL 行。**兑现 = 补一行 M3 KILL
   （或台账注明 BUG-0034 修复循环即击杀见证）。**

3. **【REV-015 §6 残余风险——本卡判定已基本解除，随 C2 收尾】**：REV-015 要求 M3 签核披露
   "R burst 重建 checker 处于假阳性缺陷态、多拍交织覆盖缺失"。**本卡核实其今日落地状态**：
   BUG-0034 已 TB_BUG→CLOSED（fix d7f5011）；当前 committed `tb/seq_lib.sv:1670` leg A
   `p.len=len_t'(3)`（多拍已恢复）、`m3_at02_atop_read_test` 即多拍交织守卫且**在
   regress.list 内**、07-30 全回归 PASS ⇒ **多拍交织覆盖缺失已填补、假阳性态已修复**。
   故 REV-015 §6 的 risk **不再需要以 ACCEPTED@M<n> 延续**，仅剩 C2 的 KILL 台账登记这一
   记账尾巴。（DUT 侧：REV-015 已终判 atop 影子读跨方向交互与上游 axi_demux.md/§6.5 一致、
   非缺陷、不发上游 issue。）

4. **【非阻塞·已接受】M4 承接项**：BUG-0018 的 cross bin 在 M4 覆盖收敛时须重采（M3
   monitor 事件流相位；milestone.md M4 出口已点名 BUG-0018 须先解决）；lint 285+ 装饰性
   告警（BUG-0021 WONTFIX）按基线守卫持续差分；上游确认项（err_slv×ATOP 等）留 M4 若需
   覆盖再走仲裁解约束。

---

## 五、taxonomy-class anomaly（强制字段）

**yes。** 本次签核抽查浮出一个 `workflow/` 五类中的 **TB_BUG（回归配置缺口，BUG-0028
家族）**——M3-CFG02 缺席 `regress.list`/全回归摘要，此前**非** `doc/bugs.md` 行。已登记
**BUG-0036**（OPEN，closer≠fixer：rev 登记、orch 另派 L0 修复）。无其它未登记 taxonomy
类别浮出（lint 差分零真缺陷；BUG-0034 已由 REV-015 归位 TB_BUG；BUG-0030/0035 环境已登记）。

---

## 六、引用的过程评审与证据（非复制，仅指针）

- REV-005/006/007（BUG-0010/0011/0012/0013/0016 分桶口径·延迟不敏感边界·上限有效值裁决，重 pin）
- REV-009/010（BUG-0021 WONTFIX + lint 守卫载体 `doc/lint-baseline.md`；BUG-0024 路线择定）
- REV-011（BUG-0018/0024/0025/0031 到期再仲裁五判据）
- REV-012/013（BUG-0032 spec §4 clause 7 + §6 clause 3 补条款，change record #7）
- REV-014（BUG-0033 err_slv RespData doc-vs-RTL → SPEC_CHANGED，change record #8）
- REV-015（BUG-0034 DUT_BUG candidate 否决 + 改判 TB_BUG + residual risk 披露要求）
- 证据：v0.3.9/{M3-DE01,DE02,OR04,CFG02}.log · v0.3.11/M3-OR05.log · v0.3.14/M3-CF01.log ·
  v0.3.15/{M3-AT02,CF02,CF03,CF04}.log · v0.3.19/M3-TL01.log · v0.3.20/result_summary.txt ·
  v0.3.18/BUG-0034.log · v0.3.10/{BUG-0025,BUG-0031}.log · v0.3.13/BUG-0018.log
- KILL：KILL-0001（decerr-rdata）· KILL-0002（cfgC UniqueIds），`doc/archive/bugs-archive.md`

---

## 七、终裁与阻塞清单

**有条件 PASS。** M3 实质风险已退休、机器条件（登记 BUG-0036 前）与 spec 钉死自洽、守卫
可证伪、lint 差分零真缺陷、chain audit 无 dangling。**完整签核前须兑现：**

- **C1（阻塞）**：关闭 BUG-0036——`m3_cfg02_reconfig_test 1` 入 `sim/regress/regress.list`、
  `make regress` = 22/22、刷新 M3-CFG02 证据对当前 HEAD、重登摘要、`make check MILESTONE=3`
  条件 3 回绿。（orch 派 L0 修复卡，closer≠fixer。）
- **C2（阻塞·轻）**：为 R burst 重建 checker 类别补一行 M3 KILL（或台账注明 BUG-0034
  修复循环即其击杀见证），兑现不变量 5 字面要求。

C1/C2 均机械、不重开功能验证；兑现后 M3 完整签核成立。
