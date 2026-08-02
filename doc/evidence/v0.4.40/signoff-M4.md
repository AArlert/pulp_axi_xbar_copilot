# M4 签核 — 六类覆盖测量基建 + 全闭包三态扫描 + 每格具名归属（UNOWNED=∅）

**判词：APPROVED**（推翻 v0.4.13 的 REJECTED——该判词按旧 M4 口径"六类 ≥90%"作出，
里程碑重构 0.4.37 后该口径已废；新出口 = 测量基建 + 三态扫描 + 每格具名归属 +
KILL + 签核，见 `doc/milestone.md` L57-94）。

**签核 = rev 裁决 + orch 机器验证二者缺一不可（CLAUDE.md §3）**。本文件是 rev 判词
+ 人核抽查记录，**引用** REV-039 等过程评审而非其副本。机器二次钥匙由 orch 收卡跑
（回填 BUG-0070/0071/0073 终态后重跑 `make check MILESTONE=4`，条件 3 应 active=0）。

引用评审：`doc/review/REV-039.md`（本卡 A 三条裁决 + B 全 rubric）· REV-032/033
（BUG-0049 漏账闭合链）· REV-031（CW-010~013）· REV-025/026（Kind-B=∅）· REV-035
（sweep 勘误裁决）· REV-019/021/023（三条 ACCEPTED@M5）。

---

## 1. 机器条件印本（`make check MILESTONE=4`，本卡现场跑）

```
[PASS] 1. all M4 scenarios ✅
[PASS] 2. regress summary registered as evidence (result_summary.txt in doc/evidence/v0.4.*)
[FAIL] 3. all bugs terminal or ACCEPTED-unexpired, closures evidenced — active: BUG-0073, BUG-0071, BUG-0070
[PASS] 4. kill coverage: >=1 KILL row tagged M4 (KILL-0005, KILL-0004)
[yes]  signoff file (signoff-M4*.md) in doc/evidence/v0.4.*
```

- 条件 1/2/4 = **PASS**。
- 条件 3 现 FAIL，仅因 **BUG-0070/0071/0073 三条 OPEN**（无其它 active；
  ACCEPTED@M5 的 BUG-0044/0045/0046 未被列出，即已过条件 3）。
- **REV-039 §A 裁决**：BUG-0070 → CLOSED · BUG-0071 → CLOSED · BUG-0073 →
  ACCEPTED@M5。**orch 回填此三终态并重跑后，条件 3 → PASS（active=0）**。此即本
  签核的机器二次钥匙，由 orch 收卡执行。

## 2. 前置核对单（裁决后条件 3 清零的逐条列举）

| bug | 裁决终态 | 清零条件 3 的机制 | 可证伪判据（详见 REV-039 §A） |
|---|---|---|---|
| BUG-0070 | CLOSED | 终态 | 复现 grep 对 `doc/bugs/*.md` 打印零行（已由 9f27476 guard 迁移消解自指命中） |
| BUG-0071 | CLOSED | 终态 | `git log -S fifo_v3 -- coverage-waivers.md` 落点=69cf5a6；勘误存证 REV-035 F1（a12b771） |
| BUG-0073 | ACCEPTED@M5 | 未到期 ACCEPTED（M4<M5，命名 REV-039） | 无 evidence 经该机制假 PASS；解锁=evidence.py 清 MAKEFLAGS 后 tail-N 签名转 PASS |

回填后 active 集 = {}（BUG-0031 CLOSED 有 verify_evidence；KILL-0007 为 KILL 行；
BUG-0044/45/46 未到期 ACCEPTED@M5）。

## 3. 人核抽查（rev，rubric #5–#9）

### #5 覆盖闭合 ≠ 风险闭合 + UNOWNED=∅ + KILL 完备（核心新出口）

- **UNOWNED=∅ 四面对账 PASS**（REV-039 §B-1）：以 v0.4.35 sweep §2.3（132 格）为
  真值，30 个 <90% 格逐格核 `milestone_restructure.md §6.3` 22×6 底板 token——全部
  落 CW-001~014（b）/ BUG-0044 债务（c）/ §6.1 DV-A~G·重测-1/2 backlog（d）之一或
  组合，无空白格。**关键**：sweep 自身非权威声明（其 §8 列 9 UNOWNED、§2.3 的
  `stream_register` 三格未进 §3——即 REV-032 抓到、BUG-0049 登记的漏账）；权威底板
  = §6.3，已把 stream_register 三格由 CW-014（Toggle 含 D1→DV-A）归口。BUG-0049
  闭合链 REV-032→REV-033→§6.3 独立复核自洽。
- **命中 bin 抽查（非偶然命中）**：`M4-EB02.log` `cg_errbp samples=294`、
  `cg_decode_error samples=60 cp_src_port=100% x_route_src_dir=16.67%`——由 EB02
  错误背压场景意图命中，非蹭到（scoreboard `decerr(§4) resp=60 order_violations=0`
  同场景一致）。
- **豁免洞重读**：CW-008（`config_ongoing_i≡1'b0`，`addr_decode.sv:106` 亲验）+ CW-010
  （flush 全 6 例化点 `1'b0`，亲验 spill_register/axi_mux/axi_demux_simple）+ CW-012/
  CW-014-P1/CW-007 共 5 条 Kind-A 论证回源 RTL 全部成立（REV-039 §B-2）。
- **KILL 集完备判断 PASS**（REV-039 §B-3）：功能 oracle 类由 KILL-0001~0005 覆盖
  （M4 标签 0004 OV01 tie-break / 0005 数据完整性），M4 未引入新 SVA 类；docsx 执行器
  高危类专行 KILL-0006/0007，F1-F5 纯分析族以 `test_docsx.py` 提交单测（`make selftest`
  强制重放）承载注伤——**裁定 F1-F5 不需各自 bugs.md KILL 行**（判据 = 注伤是否被机器
  门禁强制，非是否有一行）。

### #6 guard 消费 + 证伪 PASS

`make guards FILES="doc/milestone.md .../M4-coverage-final-sweep.md coverage-waivers.md
bugs.md testplan.md"` → **14 guard(s) matched**（G-0008/0010/0026/0028/0029/0032/0033/
0036/0039/0044/0047/0062/0063/0064）。**实跑证伪一条**（ghost spec-ref 完整性）：注入
`M2-OR02 SPEC-99.9` → `make check` `[FAIL] dangling spec refs: 1`（docs.py exit=1）→
`git checkout` 复原 → `[PASS] dangling spec refs: 0`。guard 见过红、修复复绿。

### #7 spec 债务零或已接受 PASS

active bugs.md 无 OPEN SPEC_ISSUE；BUG-0044/0045/0046 均 ACCEPTED@M5 + 书面接受理由
（REV-019/021/023）。

### #8 接受债务是真债务 PASS

三条 ACCEPTED@M5 均：REV 记录实存、接受理由可证伪、`@M5` 锚未到期（M4<M5，未被
条件 3 列出）、到期须二选一再裁（guard G-0044/G-0039 在位）。逐条可证伪点见 REV-039
§B-4。本轮为 M4 签核、非 M5，三债务尚未到期，无"自动延期"问题。

### #9 chain audit 已答（印本 + 逐 gap 处置）

```
[PASS] dangling spec refs (cited, no such section): 0
[gap] scenarios citing no spec clause: 1 — M0-01
[gap] scenarios in no feature-matrix row: 0
[gap] refs anchored only at a parent section: 14 — (M1-02 SPEC-5.1.2→§5.1 … M4-EB02 SPEC-4.4→§4)
[gap] spec subsections cited by no scenario: 7 — §1.3, §2.2, §2.3, §6.1, §7.1, §7.1.2, §7.4.4
[gap] ✅ evidence without a spec_ref header: 30/30 (convention, not yet enforced)
```

| gap class | 处置 |
|---|---|
| dangling refs = 0 | 无悬空引用（硬门；#6 已证会变红） |
| M0-01 无 spec 子句 | 接受——M0 基建跑上游 smoke tb，非自研判据场景 |
| 14 条锚在父节 | 接受——spec 未细分到该子号（可见性非门，rubric #9） |
| 7 子节无场景引用 | 接受——描述性/复位/ATOP 子类型条款，部分对应 §6.1 backlog 与 M5/M6 范围 |
| 30/30 无 spec_ref 头 | 接受——约定未强制（convention），非门 |

无悬空引用需修复；其余为既有可接受可见性项。

## 4. 残余风险清单

1. **（低）BUG-0073 过渡 guard 未机械化**：其 checklist（"CMD 内嵌 make 用 grep 勿
   tail-N / 勿注册 env-dump 签名"）仍在 `doc/bugs/BUG-0073.md`，未折入 `doc/guards.md`
   结构表——须随 M5 前 fixer 卡（evidence.py 硬化）一并机械化。retention 弱于其余
   教训。
2. **（低）F1-F5 注伤证据非 bugs.md KILL 行**：以 `test_docsx.py` 提交单测承载，被
   `make selftest` 强制重放。若严格读不变量 5"logged as a KILL row"，F1-F5 各欠一
   行——本卡裁为"已权衡的处置、非疏漏"（执行器高危类已专行 KILL-0006/0007）。留作
   记账口径分歧记录，不阻塞。
3. **（既有，非本里程碑新增）Q3 覆盖取证可复现局限**：v0.4.35 sweep §10 全部以
   `sim/out/urgText6/`（`.gitignore` 内、`make regress` 会删）为源，陌生人须在有该
   vdb 的机器上或先按 sweep §0 命令②重生。sweep §10.6 已就地声明，非新增缺口。
4. **（已归口，非缺口）30 个 <90% 格的定向收敛残余**：全部具名归属至 M6 backlog
   （§6.1 DV-A~G / 重测-1/2）或 Kind-A 永久豁免——**六类 ≥90% 百分比达标门属 M6 出口**，
   不在 M4 范围（里程碑重构）。M4 只要求"每格具名归属完成"，已达成。

## 5. 判词

**M4 = APPROVED。** 四出口要件（六类测量基建 · 全闭包三态扫描 22×6 · 每格具名归属
UNOWNED=∅ · KILL 覆盖）经全 rubric 人核 + 机器条件 1/2/4 全绿证成；条件 3 待 orch
按 REV-039 §A 回填 BUG-0070(CLOSED)/0071(CLOSED)/0073(ACCEPTED@M5) 并重跑
`make check MILESTONE=4` 清零（active=0）。**推翻 v0.4.13 REJECTED（旧口径已废）。**
残余四项均低危/已归口/已声明，不阻塞签核。

签核成立以本判词 + orch 机器验证二次钥匙齐备为准。
