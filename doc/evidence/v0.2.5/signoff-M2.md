# M2 里程碑签核（signoff-M2）

> **判据来源**：`workflow/signoff/rubric.md`（框架 0.5.3——机器条件 1-3 + 人工
> 抽查 4-7，其中**第 7 条为 0.5.3 新增**，本仓库四行 `ACCEPTED@M3` 是它入 canon
> 后的首批考生）、`workflow/signoff/six_questions.md`、
> `workflow/schema/evidence_record.md`、`workflow/taxonomy/failure_taxonomy.md`。
>
> **本记录是签核（verdict），不是评审（review）**：它**引用** REV-005~REV-011
> 并陈述本签核人**自行执行**的抽查结果与判决，不复制任何评审文件的正文。
>
> **独立性声明**：本签核人为全新实例，**非** REV-005~REV-011 任一记录的作者，
> 非 M2 各场景的 DV/DE，非本轮任何 arch 实例。本卡要签核的四条
> `ACCEPTED@M3` 债务全部由 REV-011 的实例裁出，故本记录**不采信** REV-011 的
> 任何结论摘要——其每一条承重事实均由本签核人**当场重跑或亲读代码/原文**独立
> 复核，逐条在下文标注取得方式。凡与既有记载一致处标 ✔，不一致处显式写出。

- 里程碑：**M2**（功能场景 + SVA + 功能覆盖）
- 签核工作树：commit `2a3bd25`（框架 0.5.3，26 files pinned）
- spec pin：`0fd431f788ce8499e450e706c95adb53177c24e4efebe25ec20fec2546c027a8`
- 日期：2026-07-28

---

## 0. 本签核人当场执行的动作清单（全部亲跑，非引用）

| # | 动作 | 结果 |
|---|---|---|
| S1 | `make docs-check` / `make signoff-check` | 见 §1 原文粘贴 |
| S2 | `make fw-check` | `fw-check passed (framework 0.5.3, 26 files pinned)` |
| S3 | `sha256sum doc/spec.md` vs `doc/spec.sha256` | 逐字节相同，见 §6 |
| S4 | `make guards FILES="<22 个 M2 触及文件>"` | **22 条命中**，id 集合与派卡索引逐条相符，413 行；见 §3 |
| S5 | **守卫证伪实验**（废弃分支 `rev011-falsify-scratch`，已销毁） | 缺陷放回 ⇒ **336 条 `SB_OR_REORDER` / `UVM_ERROR: 336`**；复原后 0；见 §3.2 |
| S6 | `make regress`（**独立重跑全表**，未采信"树未动故无需重跑"） | **11/11 PASS**，`sim/result_summary.txt` 与已登记证据**逐字节相同**（`git status` 未变脏） |
| S7 | `make lint-diff TEST=m2_or03_guard_test` | `[LINT-GATE] 执行证明 OK：分析了 ../tb/ 全部 20 个源文件` + `[LINT-DIFF] 本次 225 站点 / 基线 225 站点` + `PASS` |
| S8 | 逐 cover 行聚合 10 份 raw sim log 的命中数（跨场景对照矩阵） | 见 §2 |
| S9 | 亲读 `vendor/axi/doc/axi_xbar.md` L31-35 / L82-86、`grep` demux.md+mux.md 的 err_slv | 见 §5、§4.3 |
| S10 | 亲读 `tb/sva/axi_xbar_stall_sva.sv` L90-105/L118-140/L236-300、`tb/slvport_agent.sv` L370-425、`tb/scoreboard_refmodel.sv` L615-680、`tb/functional_coverage.sv` L55-100、`tb/sva_bind.sv` L30-50 | 见 §4 |

---

## 1. 机器条件（`make signoff-check`，本签核人当场执行，输出原文粘贴）

```
$ make docs-check
docs-check passed

$ make signoff-check
[PASS] 1. all M2 scenarios ✅
[PASS] 2. regress summary registered as evidence (result_summary.txt in doc/evidence/v0.2.*)
[PASS] 3. all bugs terminal or ACCEPTED-unexpired, closures evidenced
[not yet] signoff file (signoff-M2*.md) in doc/evidence/v0.2.*

Human spot checks (rev-led, recorded in the signoff file — workflow/signoff/rubric.md):
  4. coverage closure ≠ risk closure: verify 2-3 hit bins were hit by the intended scenario; re-read 1 waived hole
  5. guards: make guards FILES=<touched> lists the review scope; falsify at least one (re-introduce its defect, see red)
  6. open SPEC_ISSUE list empty, or each entry has a written acceptance rationale
  7. accepted debt: each ACCEPTED row's REV rationale is falsifiable; carry-overs re-arbitrated, never auto-extended
```

（`[not yet]` 一行指的正是本文件；本文件落地后条件齐备。）

**条件 1 人工复核**：`doc/testplan.md` M2 行共 **8** 条——M2-CFG01 / M2-OR01 /
M2-OR02 / M2-TL01 / M2-TL02 / M2-WO01 / M2-AT01 / M2-OR03，全部 ✅ 且均带
`doc/evidence/v0.2.0/*.log` 与 repro 命令。**M3-TL01** 状态 🔲、milestone 列写
明 `M3`（BUG-0010 的跨桶定向守卫），**不属 M2 范围**，其缺席不构成条件 1 缺口。

**条件 2 的独立复验（S6，超出机器条件要求）**：派卡人指出自 `594bf94` 起
`tb/`、`sim/` 一字未动、故无需重跑。本签核人**仍然重跑了全表**——理由是"树未
动"是一条转述，而 rubric 的判据是证据本身。结果 11/11 PASS，且
`sim/result_summary.txt` 重写后 `git status` 不变脏 ⇒ 与
`doc/evidence/v0.2.0/result_summary.txt` **逐字节相同**。转述属实，且现在有了
当场证据。

**条件 2 的分母核对（BUG-0028 守卫要求签核人做的动作）**：`sim/regress/regress.list`
11 条非注释行 vs `doc/testplan.md` 状态为 ✅ 的行 11 条（M0-01, M1-01, M1-02,
M2-CFG01/OR01/OR02/TL01/TL02/WO01/AT01/OR03）——**差集为空**，`11/11` 的分母
不缩水。BUG-0028 guard（`note: 里程碑签核时须人工核对清单与 testplan ✅ 行的
差集`）**已履行**。

---

## 2. 抽查 4 —— Coverage closure ≠ risk closure

### 2.1 三组命中 bin：确认是被**意图中的场景**打中

方法：不看 merged 报告，直接从 10 份 raw sim log（`sim/out/*_1.log`，含 M0/M1
场景作对照）逐 cover 行聚合命中数，构成**跨场景对照矩阵**。判据是"该 bin 只在
它的意图场景里非零、在其余场景里为 0"——顺带命中会表现为多场景弥散非零。

**Bin 组 A — `axi_xbar_stall_sva.sv:360/362`（§5.2.1 主判据前提：异目标同桶兄弟
被呈现）与 `:378/380`（BUG-0013 字面接受边界前提）**
代码注释自述"激励来源 **M2-OR01**"（`stall_sva.sv:357-359`）。

| 场景 | L360 | L362 | L378 | L380 |
|---|---|---|---|---|
| m1_01 / m1_02 / cfg01 / or02 / or03 / tl01 / tl02 / wo01 / at01 | 0 | 0 | 0 | 0 |
| **m2_or01_stall_test** | **6** | **6** | **6** | **6** |

⇒ 10 个场景中**只有** M2-OR01 打中，且 6 = 6 个 slave 端口各一次，与该场景
"每端口构造一对同桶异目标事务"的设计完全吻合。**意图命中，非顺带。**

**Bin 组 B — `stall_sva.sv:368/370`（§5.2.4 同目标对照前提）**
代码注释自述"激励来源 **M2-OR02**"。

| 场景 | L368 | L370 |
|---|---|---|
| 其余 9 个场景 | 0 | 0 |
| **m2_or02_nonstall_test** | **6** | **6** |

⇒ 与 A 组**正交**：OR01 只打 A 不打 B，OR02 只打 B 不打 A。两个场景各自证明了
自己那条 spec 分支（§5.2.1 异目标 / §5.2.4 同目标），没有互相借力。

**Bin 组 C — `axi_xbar_txlimit_sva.sv:252/254`（达 `MaxMstTrans`）与 `:256/258`
（达 `MaxSlvTrans`）**——testplan M2-TL01 / M2-TL02 的"达标 cover（非空转）"判据。

| 场景 | L252/254（达 10） | L256/258（达 6） |
|---|---|---|
| **m2_tl01_txlimit_test** | **1 / 端口 ×6** | 0 |
| **m2_tl02_slvtrans_test** | 0 | **1 / 端口 ×6** |
| 其余 8 个场景 | 0 | 0 |

⇒ TL01 只打 MaxMstTrans 侧、TL02 只打 MaxSlvTrans 侧，**互不串味**。同批
`:263/265`（越 10）与 `:267/269`（越 6）分别在 TL01/TL02 命中 1 次——即
BUG-0016（SPEC_CHANGED）所述"越字面上限"的可复现见证仍然活着、未被静默删除。

**Bin 组 D — `cg_atop`（`functional_coverage.sv`）**：`cp_src=100.00%`、
`samples=18`，**仅** `M2-AT01.log` 非零（其余 7 份 M2 证据均 `cg_atop:
samples=0 inst_cov=0.00%`）；同批 `SB_SUMMARY` 的 `atop(C6.3): pairs=18
open(unpaired at end)=0`。⇒ ATOP 覆盖完全由其意图场景产生。

### 2.2 再读一个被豁免的洞：**BUG-0018**（按 REV-011 §3.3 末段的交接条件，明确挑它）

> REV-011 §3.3 末段原文要求："本条是 rubric 第 4 条那句『再读一个被豁免的洞』的
> 现成对象——签核人应**明确挑它**复读本节的书面理由，而不是绕开它另挑好看的
> bin。" 本签核人照办，且不止复读，逐条实测了它的承重事实。

**洞的形状**：`slvport_agent.sv` 把写事务的 request 观测发在 W burst 的
`w_last` 而非 AW 握手当拍 ⇒ `cg_stall.x_state_dir[stalled][write]`、
`[not_stalled_diff_direction][read]`、`cg_w_order.multi_source_contended` 在**各自
对口场景**恒空。豁免理由 = "**判决路径不受影响**，代价只在 covergroup 侧"。

**本签核人对该豁免理由的三条承重事实的独立复核**：

| 事实 | 记载说法 | 本签核人取得方式 | 结论 |
|---|---|---|---|
| 排序键是真实 AW 握手时刻 | `slvport_agent.sv:376/418` | 亲读：`:376` `a.accept_time = $time;` 在 `aw_valid && aw_ready` 分支内；`:418` `ro.accept_time = w_cur.accept_time;` **原样转抄**，未重新取 `$time` | ✔ 成立 |
| 判据键含方向、跨方向相位差不入判决 | `or_key(port,is_write,bucket)` | 亲读 `scoreboard_refmodel.sv:141` 函数签名 + `:397/:630` 调用点 | ✔ 成立 |
| M4 的机器判据接不住它（故定档 M3 而非 M4） | spec §0 #4 六类不含 covergroup | 亲读 `doc/spec.md:25`：`六类 line+cond+fsm+tgl+branch+assert` | ✔ 成立——covergroup 确不在内，REV-011 把它由 M4 提前到 M3 的推理**站得住** |

**本签核人的追加验证（记载中没有的一步）**：这个洞是否**动摇了任何 M2 ✅**？
最危险的一条是 **M2-WO01**——它的 testplan 判据明写要求"一条**非空转 cover**
证明『某 W burst 起始时该 master 端口有 ≥2 个不同源 AW 未决』的竞争真被激励到
（SPEC-5.5.2）"，而 BUG-0018 正好让 covergroup 侧的 `cp_w_contention` 只填
`single_source` 一格（实测 50.00%）。若非空转判据**只**挂在 covergroup 上，
M2-WO01 的 ✅ 就是无支撑的。

实测结果：非空转判据挂在 **assert 维度**（F-M2-08 登记的两个覆盖维度之一），
且它是活的——

```
"../tb/sva/axi_xbar_worder_sva.sv", 107: tb_top.gen_mst_worder_sva[0]...  207 attempts, 46 match
（同场景 gen_mst_worder_sva[1..7] 均 0 match）
```

`worder_sva.sv:107` 即 `compete_start`（`:90` `if (distinct_pending() >= 2)
compete_start <= 1'b1;`）。46 次命中全部落在 **master 端口 0**，与 M2-WO01
"≥2 个 slave 端口并发向**同一** master 端口"的构造精确吻合。跨场景对照：
该 cover 在 m1_01/m1_02/or01/or02/or03/tl01/tl02/at01 全为 0，仅 cfg01 顺带 6 次
（远小于 WO01 的 46）。
⇒ **M2-WO01 的非空转判据由 SVA 侧独立承担，BUG-0018 未动摇它。** 豁免成立。

**顺带澄清一处易被误读为缺陷的现象（本签核人主动追查后判定非缺陷）**：
`cg_stall.cp_stall_state` 在 M2-WO01/M2-AT01 显示 `0.00%` 却 `samples=24/48`
——看似"有采样却零覆盖"（即样本落在所有 bin 之外，属"沉默的通过"家族）。亲读
`functional_coverage.sv:87-93` 后确认是**有意设计**：`SC_NONE`（无同桶兄弟）
**故意不设 bin**，代码内有明文注释说明。WO01/AT01 的事务本就无同桶兄弟，故
100% 落入 `SC_NONE`。**非缺陷，不登记。**

---

## 3. 抽查 5 —— Guard consumption + falsification

### 3.1 Guard 消费（本签核人自跑 `make guards`）

`FILES` = `git diff --name-only 5dc53f9..HEAD -- tb/ sim/` 的 22 个文件。本签核人
当场执行同一条命令，输出 **413 行 / 22 条命中**，id 集合为：
`0007 0009 0010 0011 0012 0013 0014 0015 0016 0017 0018 0019 0020 0021 0022
0023 0024 0025 0027 0028 0030 0031`——与派卡索引**逐条相符**，无多无缺（派卡
人预设的"条数或 id 集合不符即停"自检**未触发**）。

逐条履约判定（抽查而非逐行复述；引证为文件路径 : 行 / 实测输出）：

| guard | 要求 | 本签核人核验 | 判定 |
|---|---|---|---|
| BUG-0007 | `tb/sva/` 一律不走 `bind <interface> <module>`，走宿主模块 generate 内直接例化 | `grep -rn "^\s*bind " tb/` **空集**；`tb/sva_bind.sv:33-47` 为 `for (genvar …) begin … u_axi_xbar_*_sva (…)` 直接例化 | 履约 |
| BUG-0015 | SVA property/cover 表达式内**不得**直接调用读跟踪状态的函数，须先折叠为 `always_comb` 信号 | 6 个 SVA 文件全查：property/cover 行内无 `w_reorder(...)`/`w_sibling_open(...)` 之类调用；`stall_sva.sv:297-300` 有明文"folded into combinational signals … preponed sampling"注释 | 履约 |
| BUG-0022 | 任何"lint 通过"结论须说明是否走强制重编，且须双向验证 | S7 实测：`recompiling module tb_top` + `[LINT-GATE] 执行证明 OK：分析了 ../tb/ 全部 20 个源文件` ⇒ 走了强制重编，非假绿 | 履约 |
| BUG-0021 | `doc/lint-baseline.md` 为 WONTFIX 守卫载体，`make lint-diff` 为执行入口 | S7：`本次 225 站点 / 基线 225 站点` → `PASS：无新类别、无新站点` | 履约 |
| BUG-0028 | 签核时人工核对 `regress.list` 与 testplan ✅ 行的差集 | §1 已做，差集为空 | 履约 |
| BUG-0016 | 越/达上限见证维持为非判决 cover、**不**升格 assert | `txlimit_sva.sv` 共 8 条 property，**全部为 cover，零 assert**；`:252-258` 达标、`:263-269` 越限 | 履约 |
| BUG-0010 / BUG-0011 | 跨桶定向场景留待 M3/M4 注册 | `doc/testplan.md` **M3-TL01** 行已注册（🔲，milestone=M3） | 履约（M3 到期） |
| BUG-0012 / BUG-0013 | `cg_atop_read_interaction` 与"接受边界"读法维持**非判决**、不升格 | `functional_coverage.sv` 的 `cg_atop_read_interaction` 为独立 covergroup；`stall_sva.sv:378/380` 为 cover 非 assert | 履约 |
| BUG-0023 | 4 条同沿 cover 由既有 9 场景全 0 变正 | 实测 or03：`:388`=192 `:389`=**192** `:390`=264 `:391`=**264**，其余 9 场景全 0 | 履约（见 3.3） |
| BUG-0024 / BUG-0025 / BUG-0018 / BUG-0031 | `ACCEPTED@M3`，守卫改写为到期验收形态 | 四条的 guard 正文均已含到期机械判据（§4 逐条复核） | 到期 M3 |
| BUG-0009 / 0014 / 0017 / 0019 / 0020 / 0027 / 0030 | checklist / 定向用例类 | 未发现被绕过的迹象；BUG-0027 见 3.2 | 履约 |

### 3.2 证伪实验（rubric #5 要求"真做一次"——本签核人真做了，非引用记录）

**选条理由**：选 **BUG-0027**，因为它守的是**整个 M2 的判决锚点**——
`doc/testplan.md` 八行 M2 场景中有七行把判决门写成 scoreboard 参考模型的
`stall(C5.1/C5.2)` / 路由 / 数据判据。若这条判决路径不能变红，M2 的
"零 mismatch"就是装饰。故本签核人不选那些只影响 cover 的守卫。

**实验（一次性废弃分支 `rev011-falsify-scratch`，基于 `2a3bd25`）**：

1. 把 BUG-0027 的原缺陷放回 `tb/scoreboard_refmodel.sv`——删掉完成认领
   `foreach` 循环中的 `break;`（使 `this_idx` 取**最后一个**同完整 ID 记录而非
   **最早**那个）。改动仅 1 行。
2. `make run TEST=m2_or03_guard_test SEED=1`
3. 结果——**守卫见红**：

```
UVM_ERROR ../tb/scoreboard_refmodel.sv(661) @ 775000: uvm_test_top.env.sb [SB_OR_REORDER] slv port 5 id-bucket 'h5 dir=R: id 'h5 (accepted @775000, mst 6) completed ahead of older still-open id 'h5 (accepted @635000, mst 5) — spec §5.2.1/§5.2.3 response reordering
...
[SB_SUMMARY] ... stall(C5.1/C5.2): violations=336 ...
UVM_ERROR :  336
```

   `SB_OR_REORDER` 计数 **336**、`UVM_ERROR: 336`——与 BUG-0027 详情页
   `## regression_guard` 记载的定量基线"336 条"**精确相符**（该数是本签核人当场
   跑出来的，不是抄的）。
4. `git checkout -- tb/scoreboard_refmodel.sv` ⇒ md5 复原为
   `10eed74513d14680f34b73b59d9b3bdc`（与改动前一致）；重跑同一 TEST+SEED ⇒
   `SB_OR_REORDER` **0 条**、`violations=0`、`UVM_ERROR: 0`，且 `SB_SUMMARY` 的
   计数（route 864 / resp 864 / resp-route 864 / worder 432）与已登记证据
   `doc/evidence/v0.2.0/M2-OR03.log` **逐字段相同**。
5. `git checkout master`；`git branch -D rev011-falsify-scratch` ⇒ 分支已销毁，
   工作树无残留（唯一 `M` 项 `doc/fw-feedback.md` 是派卡人本轮登记 FB-19 的
   在途改动，与本实验无关）。

**结论**：M2 的核心判决锚点**可以变红，且红得精确**（336 与基线一致 ⇒ 不是
随便报个错，而是同一失效模式的同一规模）。这条守卫**不是假设，是守卫**。

### 3.3 附带查明的一件事：M2 的判决其实由谁承担（REV-011 §5.4 交接条件的推广）

> REV-011 §5.4 末段原文交接条件："**不得**把 `axi_xbar_stall_sva` 的通过计为
> M2-CFG01 的独立证据——上表第 2 条的 84/84 零命中即其在该场景空转的机械证明。"
> 本签核人**照办**，并把同一把尺子量到了全部 8 个 M2 场景（记载里没人做过这步）。

`axi_xbar_stall_sva` 的两条判决 assert（`:345` `SVA_OR_W_REORDER` / `:351`
`SVA_OR_R_REORDER`）要有候选集，必须存在"同桶、**不同**完整 ID、异目标、仍
open 的兄弟"。本签核人用 `:360/:362`（兄弟异目标被呈现）的命中数作机械探针，
逐场景聚合 raw log：

| M2 场景 | stall_sva 兄弟异目标 cover | 该模块判决 assert 状态 | 该行 testplan 的判决锚点 |
|---|---|---|---|
| M2-OR01 | **6 / 6**（非零） | **活的** | scoreboard + stall_sva |
| M2-OR02 | 0（兄弟同目标，`:368/370`=6） | 空转（**设计如此**：它是非 stall 对照组） | scoreboard |
| M2-OR03 | 0（单一完整 ID，无兄弟） | 空转 | scoreboard（§3.2 已证其可红） |
| M2-TL01 | 0 | 空转 | scoreboard + 达标 cover |
| M2-TL02 | 0 | 空转 | scoreboard + 达标 cover |
| M2-WO01 | 0 | 空转 | scoreboard + `worder_sva` C3.3 |
| M2-AT01 | 0 | 空转 | scoreboard + `atop_sva` C3.5（实测 `:161`=3、`:168`=1 ×6 端口，非空转） |
| M2-CFG01 | 0（**84 条 cover 行全部 `0 match`**，本签核人 `grep` 复核：84 行、非零行 **0** 条；对照 m2_or01 同文件非零行 24 条 ⇒ 非日志假象） | 空转 | scoreboard（`route: match=30 mismatch=0`）+ `route_sva` C3.1 |

**判决**：REV-011 §5.4 的 84/84 事实**成立**（本签核人独立复核），其交接条件
**已履行**。且推广后的事实是：**`axi_xbar_stall_sva` 的判决 assert 在 8 个 M2
场景中只有 1 个（M2-OR01）是活的**。这不构成任何 ✅ 的缺口——每行 testplan 的
判决锚点本就写的是 scoreboard（+ 各自的独立 SVA），而 scoreboard 的可红性已由
§3.2 当场证明；但它是一条必须被记住的**范围事实**，故写入 §7 残留风险，兑现
REV-011 §2.3 b-3 立下的纪律（"任何『SVA 也过了』的说法都必须附上它那次运行的
空转/范围见证"）。

**M2-OR01 的判决非空转正证**（避免上表被读成"连 OR01 也可能空"）：该运行
`cg_stall.cp_stall_state=33.33%`（3 个 bin 命中 1 个）——被命中的正是
`stalled` bin，即 scoreboard 在某笔事务的接受时刻**确实**观察到"更老、仍 open、
同桶同向、异目标"的记录 ⇒ `or_open_q` 里真有 ≥2 条同键记录、§5.2.3 判据有真实
候选。同批 SVA 侧 `:360/:362` 各 6 次命中，两条独立观测路径互证。

---

## 4. 抽查 7（0.5.3 新增）—— Accepted debt is real debt

判据（rubric 原文）：每条 `ACCEPTED@M<n>` 行，其**引用的 REV 记录**须给出
**可证伪**的 rationale（**哪条事实被推翻则裁决失效**）；顺延条目须**重新仲裁**、
不得自动续期，并说明上次到期判据为何未兑现。

**顺延条目核查（rubric 明文要求的一项，本轮结论为空但必须确认）**：
`ACCEPTED@M<n>` 是框架 **0.5.0 今日引入**的状态（`doc/fw-feedback.md` FB-17
`fixed@0.5.0`），本仓库此前从未使用过。故本轮四条**全部是首次裁决，无一条是
顺延**——"上次到期判据为何未兑现"一问**不适用**，非"跳过"。M3 签核时这一问将
首次真正生效（四条到期点均为 M3）。

四条逐条判定如下。**判据不是"理由写得长不长"，而是：能否指出一条具体的、
第三方可用命令或原文推翻的事实，且推翻它就使裁决失效。** 本签核人对每条都
**尝试去推翻它**。

### 4.1 BUG-0018 → `ACCEPTED@M3`（引用 REV-011 §3.3）

**声称的可证伪点**：(i) 判决路径不受影响（三条结构事实）；(ii) M4 没有能接住
它的机器 gate（spec §0#4 六类不含 covergroup），故定档 M3 而非 M4；
(iii) 到期判据是**逐 test 的数值对照**——`m2_or01` 的 `x_state_dir` 须由
**16.67%** 上升且 `[stalled][write]` 格非空、`cp_stall_state` 由 **33.33%** 上升；
`m2_wo01` 的 `cp_w_contention` 须由 **50.00%** → **100.00%**。

**本签核人的推翻尝试**：三条结构事实逐条亲读（§2.2 表格），**全部成立**；
spec `doc/spec.md:25` 亲读，六类确为 `line+cond+fsm+tgl+branch+assert`，
**covergroup 不在内** ⇒ "挂到 M4 等于挂到一个不存在的 gate 上"这句**推翻不了**。
基线数值 16.67% / 33.33% / 50.00% 与本签核人从
`doc/evidence/v0.2.0/M2-OR01.log`、`M2-WO01.log` 读到的 `FCOV_SUMMARY` **完全
一致**。

**判定：可证伪 ✔，且经复核成立。** 到期形态是**数字**不是态度——M3 签核时任何
人跑两条 `make run` 就能判它兑现与否。**通过。**

### 4.2 BUG-0024 → `ACCEPTED@M3`（引用 REV-011 §2）

**声称的可证伪点**：REV-011 推翻了三处既有记载的"只漏检、不会假红"，给出一条
**四步可构造的假红路径**，并自陈"任何人可按该构造证伪本卡；反之若无人能构造出
该序列，本卡结论即被推翻"。裁决据此**拒绝**落 WONTFIX（因为 (b) 路线的"零
代码"前提被推翻，仍有实质工作）。

**本签核人的推翻尝试**（这是本卡最该被第二双眼睛看的一条，因为它把一个本可
以立刻终结的条目改判成了债务）——逐条对照代码：

| 构造所依赖的前提 | 亲读结果 | 成立？ |
|---|---|---|
| 登记侧对同一完整 ID 的每次 AW 接受**覆写** `w_id_seq` | `stall_sva.sv:131` `w_id_seq[aw_id] <= w_seq_ctr;` 在 `aw_valid && aw_ready && aw_hit` 分支内**无条件**执行，无"已 open 则跳过"守卫 ⇒ 表内留的是该 ID **最新**一笔的序号 | ✔ |
| `w_reorder()` 用 `w_id_seq[cand] < w_id_seq[completing_id]` 判"更老" | `stall_sva.sv:273-283` 逐字如此 | ✔ |
| `w_reorder()` **不**检查完成侧自身的 open 位 | `:273-283` 的合取式为 `cand != completing_id && w_id_open[cand] && tgt != && seq <` ——**确实没有** `w_id_open[completing_id]` 项 | ✔ |

⇒ 假红路径的三个结构前提**全部成立**，本签核人**未能推翻**该构造。
连带确认：REV-011 §5.2(2)(ii) 对 BUG-0025 的订正（"`int unsigned` 是 2-state
缺省 0，且陈旧的非零 seq/tgt 会继续参与比较，因为 reset 只清 `*_id_open`"）
——亲读 `stall_sva.sv:120-127`，复位分支**只**清 `w_id_open`/`r_id_open` 与两个
计数器，`w_id_seq`/`w_id_tgt` 不清 ⇒ 该订正**成立**。

**判定：可证伪 ✔，且经复核成立（本签核人尝试推翻未果）。** "不落 WONTFIX"是
**正确的从严选择**，不是拖延：终态会让一份仍有实质工作的东西消失在台账里。
**通过。**

### 4.3 BUG-0025 → `ACCEPTED@M3`（引用 REV-011 §1，含 spec §5.2.6 条款提案）

**声称的可证伪点**（两层）：
(i) **spec 仲裁层**——第 3 层"低位 ID 桶维度未定义"依赖一条**否定性证据**：
`demux.md`/`mux.md` 对 err_slv **一字未提（grep 空集）**；第 2 层"完整 ID 维度
可断言"依赖 `xbar.md` L86 的一句**原文**。
(ii) **排期层**——M2 无证据依赖被丢弃的译码未命中路径（M2-CFG01 batch 2 的 6 笔
未命中读虽**确实**被丢弃，但该运行兄弟集恒空故无可观测差别）。

**本签核人的推翻尝试**——这一条特别重要，因为它的裁决**已经变成了 spec 正文**
（§5.2.6，pin `0fd431f7`）。若前提是假的，红线就破在 spec 里。

```
$ grep -in "err_slv|error slave|decode error" vendor/axi/doc/axi_demux.md vendor/axi/doc/axi_mux.md
（空集）
$ sed -n '35p' vendor/axi/doc/axi_xbar.md
… any address on that slave port that does not match any rule is routed to the
default master port instead of the decode error slave. …
$ sed -n '86p' vendor/axi/doc/axi_xbar.md
The reason for this ordering constraint is that AXI transactions with the same
ID and direction must remain ordered. …
$ sed -n '33p' vendor/axi/doc/axi_xbar.md
Each slave port has its own internal *decode error slave* module. …
```

⇒ 三处引文**逐字属实**，否定性证据（grep 空集）**属实**。第 1 层
（default master port 是真实 master 端口）与第 2 层（完整 ID 维度可断言）
的许可来源**推翻不了**；第 3 层判"未定义"**推翻不了**。

**已应用的 spec 文本核对**：`doc/spec.md:200-227` 的 §5.2.6 与 `:152` 的 §4 第 6
条，与 REV-011 §1.3 的提案 P-REV011-1 / P-REV011-2 **逐字相同**，Change record
第 6 条已登记来源清单并声明"无 RTL 实现体来源"。`sha256sum doc/spec.md` 与
`doc/spec.sha256` 一致（§6）⇒ **spec 修改由 rev 提案、orch 应用并重 pin 的
分工未被越权，spec-from-RTL 红线未破。**

**排期层的推翻尝试**：`M2-CFG01` 运行中 `axi_xbar_stall_sva.sv` 的 **84 条
cover 行零非零**（§3.3 实测）⇒ 兄弟候选集全程为空 ⇒ 那 6 笔被丢弃的未命中读
**不可能**产生可观测差别。**推翻不了。**

**一处措辞完备性备注（不改变判定）**：REV-011 §1.4 本身陈述的是"SPEC_ISSUE 半边
已终结 + 剩下三件是 TB 落地"，那条真正让"可以等到 M3"成立的**事实**
（M2 无证据依赖它）写在同一记录的 §5.2(2)(i) 与 §5.4 而非 §1.4 里。rubric #7
问的是"**引用的 REV 记录**是否给出可证伪 rationale"——REV-011 作为一份记录整体
给出了，故**满足**；但若日后只读 §1.4 会读不到那条承重事实。此点记入 §7 残留
风险，供 M3 签核人留意，**不作为条件**。

**判定：可证伪 ✔，且经复核成立。通过。**

### 4.4 BUG-0031 → `ACCEPTED@M3`（引用 REV-011 §5.4 补裁）

**声称的可证伪点**：这条把证伪条件写得最露骨——"上面三条事实各自独立、且都可
被任何人用同样的 grep 推翻；**若其中任何一条被证伪**（例如指出另有 M2 场景改表，
或 cfg01 某条 cover 其实非零），本裁决即失效，BUG-0031 须改判『M2 内修完』。"

**本签核人逐条实施推翻尝试**：

| 事实 | 本签核人的验证命令/亲读 | 结果 |
|---|---|---|
| (1) 全仓只有两处写 `cfg_vif.addr_map` ⇒ 除 m2_cfg01 外编译期表恒等于活值表 | `grep -rn "cfg_vif.addr_map\|cfg_if.addr_map *=\|addr_map *=" tb/` → 写点仅 `tb/tb_top.sv:59`（复位初始化 V0）与 `tb/seq_lib.sv:994`（CFG01 `do_reconfig()`）；`scoreboard_refmodel.sv:283/294` 是**读**进快照结构体，非写接口 | **推翻不了** |
| (2) cfg01 运行中 stall_sva 84 条 cover 行全 `0 match` ⇒ 两条 assert 结构性空转 | `grep -c` 该文件 cover 行 = **84**，其中非 `0 match` 行 = **0**；对照 m2_or01 非零行 = 24 ⇒ 非日志/`-assert verbose` 假象 | **推翻不了** |
| (3) testplan M2-CFG01 的判决锚点不含 C3.2 | 亲读 `doc/testplan.md` 第 10 行：判决写的是 scoreboard 参考模型（SPEC-3.1/3.2/3.3）+ "**由独立 SVA C3.1 监视**"——全行无 C3.2 | **推翻不了** |

补充亲读缺陷本体（确认这条 bug 真实存在、不是虚记）：
`tb/sva/axi_xbar_stall_sva.sv:99-100` 确为
`decode_mst_port(aw_addr, ADDR_MAP, 1'b0, '0, aw_tgt)`——第 2 实参是编译期
`localparam`、第 3 实参 `en_default` 硬编码 `1'b0`；`tb/sva_bind.sv:33-35` 该模块
端口表**只有** `.axi(slv_if[k])`，结构上确实拿不到 `cfg_if`，而同文件 `:41-47`
的 `axi_xbar_route_sva` 确实接了 `cfg_if.addr_map` / `en_default_mst_port[r]` /
`default_mst_port[r]`（正确接法就在隔壁 6 行）。**缺陷属实。**

**判定：可证伪 ✔（本条是四条里证伪条件写得最好的一条：它自带失效条件与改判
后果），且三条事实经独立复核全部成立。通过。**

### 4.5 抽查 7 小结

四条 `ACCEPTED@M3` **全部通过**。本签核人对每条都**主动尝试推翻**其承重事实
（共 12 项，用 grep / sed / 亲读代码 / 亲读上游文档取得），**无一项被推翻**。
无顺延条目（首轮使用该状态）。

**但通过不等于风险消失**——四条的到期点均为 **M3 签核**，届时
`scripts/docs.py:855` 将到期拦截。本签核人在此**重申并背书** REV-011 §4 G3 立下、
框架 0.5.3 已入 canon 的红线：**不得以"再顺延一个里程碑"续期**；续期须重走
rev 仲裁并说明上次判据为何未兑现。四条的到期验收形态分别见
`doc/review/REV-011.md` §3.3 / §2.3 / §1.4 / §5.4，M3 签核人有义务逐条抽查。

---

## 5. 抽查 6 —— Spec debt is zero or accepted

**open SPEC_ISSUE 行清单：空。**
- `doc/bugs.md` 全表：无 `SPEC_ISSUE` 状态行（唯一出现的 "SPEC_ISSUE" 字样在
  BUG-0025 的正文里，指的是**已由 REV-011 §1 仲裁完毕**的那半边）。
- `doc/archive/bugs-archive.md`：25 行全部终态（CLOSED 12 / SPEC_CHANGED 8 /
  WONTFIX 3 等），`SPEC_ISSUE` 出现 **0** 次。历史上的 SPEC_ISSUE
  （BUG-0002/0003/0004/0005/0010/0011/0012/0013/0016）均已走完仲裁→
  `SPEC_CHANGED` 并落 Change record。

**spec 内标注为"上游确认项"的条目**（派卡人要求判断它们是否落在 rubric #6 的
许可范围内）——rubric #6 的原文许可是"each entry has a written acceptance
rationale"。逐条判定：

| 位置 | 内容 | 书面接受理由是否成文 | 落在许可范围？ |
|---|---|---|---|
| §7.4.4 | cycle-accurate 时序核查若将来确需，须另行上游确认后再补 spec | ✔ 成文：理由是"§7.4 全节已裁定**任何 latency checker 不得断言固定周期数**，功能 checker 必须延迟不敏感"，故该确认对 M1-M4 判据**无需求**；明写"不阻塞里程碑" | **是**——它是一条"目前不需要"的声明，不是悬空的未知 |
| §8.4 | 强行违反 §8.3 约束触发未定义情形时 DUT 如何应答 | ✔ 成文：§8.3 已裁定 M3/M4 稀疏 `Connectivity` 场景须构造为**构造性不可触发**该情形（BUG-0002/REV-001），故该未定义**够不着**；明写"不阻塞 M3/M4"；并说明"未取 DUT_BUG（无任何波形/证据显示行为违规）" | **是** |
| §5.2.6 2.b（0.2.2 新增） | 低位 ID 桶维度 + err_slv 的完成序关系未定义 | ✔ 成文：附**否定性证据**（demux.md/mux.md 无记载，本签核人 §4.3 已复核 grep 空集）、附**处置**（不得断言、须非判决 cover 留痕）、附**先例**（同 §7.4.4/§8.4 处置）、附**代价说明**（无来源的断言会在 M3 错误路径假红，同 BUG-0013/REV-006 学费） | **是** |
| §5.4 | ~~MaxSlvTrans 机制未定义~~ | 已**升级为已定结论**（"mux 侧在飞机制根本不存在"，BUG-0016/REV-007），**不再是**上游确认项 | 不适用（已消解） |

⇒ **三条现存"上游确认项"各自有成文接受理由、有处置方式、有不阻塞判断，
全部落在 rubric #6 的许可范围内。抽查 6 通过。**

**一处必须点名的时序风险（不影响 M2，M3 生效）**：§5.2.6 2.b 要求的"非判决
cover 留痕"**目前尚未落地**——它是 BUG-0025 `ACCEPTED@M3` 债务的第三项。M2 没有
任何 decode-error 场景，故本里程碑内不构成缺口；但 **M3 的主题就是错误路径**，
届时 §5.2.6 2.b 的 cover 若仍缺席，"排除"与"忘了写"在报告上将完全同形
（REV-011 §4 G1 命名的"沉默的通过"家族——本仓库已在 BUG-0022 lint 假绿、
BUG-0028 分母缩水上付过两次学费）。M3 签核人须把它当作硬性抽查项。

---

## 6. 证据链完整性与 spec pin

**spec pin 一致性（本签核人当场执行）**：

```
$ sha256sum doc/spec.md
0fd431f788ce8499e450e706c95adb53177c24e4efebe25ec20fec2546c027a8  doc/spec.md
$ cat doc/spec.sha256
0fd431f788ce8499e450e706c95adb53177c24e4efebe25ec20fec2546c027a8
```
⇒ **一致**。Change record 第 6 条（0.2.2，§5.2、§4）记载了本轮唯一一次 spec
变更，依据 REV-011 §1，来源清单完整。

**八条 M2 证据的记录形态**（逐份 `head -2` 核对，非抽样）：

| 证据 | 第 1 行（回放命令） | 第 2 行（生成器） | 与 testplan repro 列自洽 |
|---|---|---|---|
| M2-CFG01.log | `make run TEST=m2_cfg01_reconfig_test SEED=1` | `# Generated by scripts/evidence.py on 2026-07-28, source log: sim/out/m2_cfg01_reconfig_test_1.log` | ✔ |
| M2-OR01.log | `make run TEST=m2_or01_stall_test SEED=1` | 同上形态 | ✔ |
| M2-OR02.log | `make run TEST=m2_or02_nonstall_test SEED=1` | 同上形态 | ✔ |
| M2-OR03.log | `make run TEST=m2_or03_guard_test SEED=1` | 同上形态 | ✔ |
| M2-TL01.log | `make run TEST=m2_tl01_txlimit_test SEED=1` | 同上形态 | ✔ |
| M2-TL02.log | `make run TEST=m2_tl02_slvtrans_test SEED=1` | 同上形态 | ✔ |
| M2-WO01.log | `make run TEST=m2_wo01_worder_test SEED=1` | 同上形态 | ✔ |
| M2-AT01.log | `make run TEST=m2_at01_atop_test SEED=1` | 同上形态 | ✔ |

八份**全部**由 `scripts/evidence.py` 生成（非手工拼装）、**回放命令在第 1 行**、
`source log` 指向的 `sim/out/*_1.log` 名字与命令自洽、`UVM_ERROR: 0` /
`UVM_FATAL: 0` / `0 with failures`。**四条核心不变式（no sim log no ✅ · 回放
命令第一行 · closer ≠ fixer · spec 由 sha256 锁定）在 M2 证据集上成立。**

**`result_summary.txt` 覆盖 `regress.list` 全表**：`sim/regress/regress.list`
11 条非注释行 ↔ `doc/evidence/v0.2.0/result_summary.txt` 11 条 `PASS` 行，
**逐条同名同 SEED、无缺无多**，头行 `passed=11/11`。S6 的独立重跑产出与之
逐字节相同。

**BUG-0029 遗留的可追溯性提醒已被遵守**：M2 期间转 CLOSED 的非仿真类条目
（BUG-0029 自身）用的是框架 0.5.0 的 `CMD=`/`EXPECT=` 形态
（`doc/evidence/v0.2.1/BUG-0029.log`），不是借一次无关的通过运行。

---

## 7. 残留风险清单（M2 通过，但这些必须带进 M3）

| # | 风险 | 引证 | 到期/承接 |
|---|---|---|---|
| R1 | **四条 `ACCEPTED@M3` 是真债不是已了结**：0018（覆盖相位盲区）、0024（单槽模型可假红）、0025（译码未命中不入表）、0031（编译期地址表） | `doc/bugs.md` 四行；`doc/review/REV-011.md` §3.3/§2.3/§1.4/§5.4 | M3 签核到期拦截；**禁止顺延续期** |
| R2 | **`axi_xbar_stall_sva` 的判决 assert 在 8 个 M2 场景中只有 1 个（M2-OR01）是活的**；其余 7 个结构性空转（其中 OR02 是设计如此的对照组） | 本记录 §3.3 实测表 | M3 新场景须重做此空转核查；兑现 REV-011 §2.3 b-3 纪律 |
| R3 | **spec §5.2.6 2.b 要求的非判决 cover 尚未落地**；M3 主题即错误路径，届时"显式排除"与"忘了写"同形 | `doc/spec.md:216-222`；BUG-0025 债务第 3 项 | M3 硬性抽查项 |
| R4 | **`make lint` 的 259 条既有告警以 baseline 形式 WONTFIX**（BUG-0021），门禁是"无新增"而非"零告警" | `doc/lint-baseline.md`（225 站点）；S7 输出 | 长期；新增即红 |
| R5 | **BUG-0030 处于终态 WONTFIX，却挂着一项未兑现的二值实验**（"`LD_LIBRARY_PATH` 必须**恰为**"是否为过度归纳，未经实测）。终态行**不进** `signoff-check` 条件 3 的视野，该义务只靠 `make guards` 与详情页 `note` 存活 | `doc/bugs/BUG-0030.md:103-110` | 下一张产 FSDB 的卡顺手兑现；**并非 M2 缺口**（TOOL_ENV，无 M2 证据依赖） |
| R6 | **REV-011 §1.4 未在本节内自陈"M2 无证据依赖 BUG-0025"这条承重事实**（它在同记录 §5.2/§5.4）；只读 §1.4 会读不到裁决的失效条件 | 本记录 §4.3 末段 | M3 签核人读 REV-011 时须连读 §5.2/§5.4 |
| R7 | **六类覆盖率（line/cond/fsm/tgl/branch/assert ≥90%）在 M2 未采集**，且 `xcov` 因 Verdi 版本不可用（BUG-0017 WONTFIX） | spec §0 #4；`doc/bugs.md` BUG-0017 | M4 判据；路径须在 M3 期内确定 |

---

## 8. 六问收敛（`workflow/signoff/six_questions.md`）

| 问 | 本签核的收敛结论 |
|---|---|
| **1 Origin** | M2 八行 testplan **每一行**的判据都带 `SPEC-x.y` 锚点（本签核人逐行核对 `doc/testplan.md`），并可回溯到 `doc/spec.md` 对应条款；`doc/feature-matrix.md` F-M2-01~08 与八行 testplan 双向对齐、无孤儿特征。抽查的 covergroup/cover 亦有条款来源：`cg_stall`←§5.2（`functional_coverage.sv:84`）、`cg_atop`←§6.3/§6.4、txlimit 达标 cover←§5.4.1/§5.4.2、`worder_sva` `compete_start`←§5.5.2。**未发现无来源的判据**。本轮唯一一次 spec 变更（§5.2.6/§4.6）经本签核人复核，来源全部为上游文档原文与 spec 内部条款，**无 RTL 实现体来源**（§4.3）——spec-from-RTL 红线未破。 |
| **2 Falsifiability** | **当场证明，非推理**：把 BUG-0027 的原缺陷放回后，M2 的核心判决锚点产出 **336 条 `SB_OR_REORDER` / `UVM_ERROR: 336`**，复原后归零且计数与已登记证据逐字段相同（§3.2）。具体被捕获的错误行为 = "同一完整 ID 的完成被归属给该组**最新**（异目标）的那笔，从而把 §5.2.4 的合法堆积误报为 §5.2.3 乱序"。此外本签核人查明了判决**范围边界**（§3.3）：stall SVA 只在 OR01 活，其余靠 scoreboard——范围被写下来，而不是被默认。 |
| **3 Replayability** | 八份 M2 证据**全部**第 1 行为 `make run TEST=… SEED=1`、第 2 行为 `evidence.py` 生成戳与 source log 路径（§6）；证据与其证明的代码同处 `594bf94` 及以前的 commit。**陌生人可复现性由本签核人当场验证**：仅凭仓库执行 `make regress`，得到与登记证据**逐字节相同**的 `result_summary.txt`（S6）。 |
| **4 Attribution** | 台账 4 行 active + 25 行归档，`docs-check` 的 schema 校验（`fl_schema_enforce`）全绿；四条 `ACCEPTED@M3` 的 taxonomy 均为 `TB_BUG`，本签核人逐条复核**有代码/日志支撑**而非假设（§4：12 项承重事实用 grep/亲读取得，无一被推翻）。closer ≠ fixer：M2 期间的关闭由 REV-010/REV-011 的独立 rev 实例执行，本签核人非其中任一实例，也非任何 DV/DE。**BUG-0029 已把"非仿真类复验的关闭件与实质证据脱节"这一 Attribution 缺陷本身修掉**（框架 0.5.0 `CMD=`/`EXPECT=`）。 |
| **5 Judgment** | 证据支持 **"M2 的风险已被收敛到可接受、且残留风险有名有姓有到期日"**，不支持"M2 无遗留"。缺口清单即 §7 的 R1-R7，全部**已有归属**（R1/R3 → 四条 ACCEPTED@M3；R2/R6 → M3 签核抽查项；R4/R7 → 长期/M4；R5 → 下一张 FSDB 卡）。**无一条缺口是"新发现且无人认领"**——这正是本次签核可以判 PASS 的实质理由。 |
| **6 Retention** | 教训落在可 grep 的位置：22 条 guard 由 `make guards` 索引（本记录 §3.1 逐条判履约）；spec §5.2.6 把 BUG-0025 的"不可断言"写进了比任何评审记录都活得久的正文；四条债务的到期机械判据写在 REV-011 §1.4/§2.3/§3.3/§5.4 并由 `docs.py:855` 到期拦截。**本记录自身新增两项留痕**：(i) §3.3 的"stall SVA 判决活性矩阵"——此前只有 CFG01 与 TL02 两个点被零散记载过，现在是完整 8 行表；(ii) §5 的三条"上游确认项"逐条许可范围判定表。二者均非任何评审文件的拷贝。 |

---

## 9. 判决

# **PASS**

M2 里程碑**予以签核**。

**依据**：
1. 机器条件 1/2/3 全部 PASS（§1 原文），且条件 2 由本签核人**独立重跑全表**
   复验（11/11、逐字节相同），不依赖任何转述。
2. 抽查 4 通过：四组命中 bin 经**跨 10 场景对照矩阵**证明是被意图场景打中
   （OR01/OR02/TL01/TL02/AT01 各打各的，互不串味）；被豁免的洞按 REV-011 §3.3
   的交接条件**明确挑了 BUG-0018**，其三条承重事实经亲读全部成立，且本签核人
   追加验证了它**未动摇 M2-WO01 的非空转判据**（SVA 侧 46 次命中独立承担）。
3. 抽查 5 通过：22 条 guard 全部在案且经抽查履约；**证伪实验真做了**——原缺陷
   放回后守卫见红 336 条、复原后归零，废弃分支已销毁、工作树复原干净。
4. 抽查 6 通过：open SPEC_ISSUE 清单为空；三条"上游确认项"各有成文接受理由与
   不阻塞判断，落在 rubric #6 许可范围内。
5. 抽查 7（新条）通过：四条 `ACCEPTED@M3` 的 rationale **均可证伪**，本签核人
   对 12 项承重事实**主动尝试推翻、无一得手**；无顺延条目（首轮使用）。
6. 证据链完整（八份 evidence.py 生成、回放命令首行、summary 覆盖 regress 全表）；
   spec pin 与 `doc/spec.sha256` 一致，本轮 spec 变更来源无 RTL。

**不判 conditional 的理由**：本签核人查出的每一处风险（§7 R1-R7）**都已有登记
载体与到期点**，没有任何一条属于"新发现且无人认领"或"需要在 M2 内补做才能让
✅ 成立"。M2 的八行 ✅ 各自的判决锚点均被验证为**存在、非空转、且可变红**。

**不判 FAIL 的理由已在上述六条**；但需明确记录一句：本次签核**最接近**触发
conditional 的点是 BUG-0024——若它的假红构造被证明不可构造，REV-011 就应当在
M2 内把它落 WONTFIX 而不是留成债务。本签核人逐条亲读 `stall_sva.sv:131` /
`:273-283` / `:120-127` 后**未能推翻**该构造，故该债务成立、排期正当。

**移交 M3 签核人的硬性抽查项**（本记录留给下一张签核卡的交接条件，与 REV-011
留给本卡的两条同性质）：
1. 四条 `ACCEPTED@M3` **逐条按其到期机械判据抽查**（REV-011 §1.4/§2.3/§3.3/§5.4），
   **不得顺延续期**；若确需续期，须重走 rev 仲裁并写明上次判据为何未兑现。
2. **重做 §3.3 的"判决活性矩阵"**：M3 新场景落地后，须逐场景报出
   `axi_xbar_stall_sva` 的兄弟异目标 cover 与 `w_lost_now`/`r_lost_now` 命中数；
   任何"SVA 也过了"的说法必须附带该次运行的空转/范围见证。
3. **spec §5.2.6 2.b 的非判决 cover 必须已落地**（R3）——M3 是错误路径里程碑，
   它缺席即等于"沉默的通过"。

---

## 10. Taxonomy-class anomaly（强制字段）

**no。**

本次签核**未浮出**任何尚未登记为 `doc/bugs.md` 行的
`workflow/taxonomy/failure_taxonomy.md` 类实例。三处曾被本签核人当作候选、
追查后判定**不构成新登记**的现象，为免下一位重复排查，逐条记录：

1. **`cg_stall.cp_stall_state` 在 M2-WO01/M2-AT01 有 samples 却 0.00%**——
   曾疑为"样本落在所有 bin 之外"的沉默通过。亲读 `functional_coverage.sv:87-93`
   后确认 `SC_NONE` **故意不设 bin** 且有明文注释，WO01/AT01 的事务本就无同桶
   兄弟。**有意设计，非缺陷。**
2. **`axi_xbar_stall_sva` 判决 assert 在 7/8 个 M2 场景空转**（§3.3）——其**成因**
   已分别登记为 BUG-0024（单槽模型）、BUG-0025（未命中丢弃）、BUG-0031（编译期
   表），其余是**激励构造属性**（那些场景本就不验跨目标同桶保序，OR02 更是设计
   上的对照组）。不是新缺陷类；作为**范围事实**写入 §7 R2 与 §3.3 的活性矩阵。
3. **BUG-0030 终态 WONTFIX 却挂未兑现的二值实验**——该义务**已登记**在
   `doc/bugs/BUG-0030.md:103-110`（"2026-07-28 触发点已到，待兑现"），并由
   `make guards` 索引，不是无记录的遗漏。**不新开行。**

（第 3 条同时是一条**框架层面的观察**，超出本签核人的编辑权限，故不在此处落地、
仅向 orch 报告：**终态行携带的未兑现义务对 `signoff-check` 条件 3 完全不可见**
——终态即免检。本仓库靠 `make guards` 与详情页 note 兜住了，但兜底机制是项目
自觉，与 FB-18 指出的"ACCEPTED 的 rationale 无人复核"是同一形状的缺口，只是
出现在终态一侧。是否登记 FB-20 由 orch 决定。）

---

- 签核人：rev（全新独立实例；**非** REV-005~REV-011 任一记录的作者，非 M2 各
  场景的 DV/DE，非本轮任何 arch 实例）
- 本卡的产出与编辑范围：**仅**本文件（`doc/evidence/v0.2.5/signoff-M2.md`）。
  未编辑 `tb/`、`rtl/`、`doc/spec.md`、`doc/testplan.md`、`doc/bugs.md`、
  `scripts/`、`workflow/`、`.claude/`。§3.2 的证伪实验在一次性废弃分支
  `rev011-falsify-scratch` 上进行，改动 1 行、跑完即 `git checkout --` 复原
  （md5 校验一致）、分支已 `git branch -D` 销毁，master 工作树无残留。
- 派卡规则偏离的意见（派卡人要求本签核人在认为受损时写下）：orch 未按 dispatch
  skill 逐字粘贴 22 条 guard 正文（413 行），改为给出确定性 `FILES` 清单 +
  逐字命中索引 + "条数不符即停"自检。**本签核人认为该偏离未损害本次签核**，
  理由有二：(i) rubric #5 的原文本就命令签核人自跑同一条命令，本签核人跑出的
  22 条与索引逐条相符，自检未触发；(ii) 省下的预算实际用在了读 10 份 raw sim
  log 与 6 个源文件上，而那正是本记录 §2/§3.3/§4 全部实测结论的来源——若把
  413 行粘进卡里，这些复核多半做不完。该偏离已由 orch 登记为 FB-19。
