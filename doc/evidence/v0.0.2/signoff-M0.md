# signoff-M0 — 里程碑 M0 签核记录

- 签核人：rev（独立实例；非本里程碑任何 review/fix 的当事人）
- 日期：2026-07-27
- 版本：v0.0.2（HEAD 80f6c3c）
- 判据来源：`workflow/signoff/rubric.md`（机器条件 ×3 + 人工抽查 ×3）、
  `workflow/signoff/six_questions.md`
- 引用的过程评审：`doc/review/REV-001.md`（spec v0 蒸馏评审 + BUG-0002~0005
  SPEC_ISSUE 仲裁）——本记录**引用不复述**（rubric L38–41）
- **总体裁决：PASS**（带 2 项非阻塞残留风险，见 §残留风险）

---

## 1. 机器条件（`make signoff-check` 自跑输出，未采信卡片粘贴）

```
[PASS] 1. all M0 scenarios ✅
[PASS] 2. regress summary registered as evidence (result_summary.txt in doc/evidence/v0.0.*)
[PASS] 3. all bugs terminal, closures evidenced
[not yet] signoff file (signoff-M0*.md) in doc/evidence/v0.0.*
```

- 条件 1：唯一 M0 行 `M0-01` 状态 ✅（`doc/testplan.md:7`）。
- 条件 2：`doc/evidence/v0.0.1/result_summary.txt` = `passed=1/1` / `PASS
  upstream_sanity SEED=1`；回归清单 `sim/regress/regress.list` 含
  `upstream_sanity 1`（唯一守卫用例）。
- 条件 3：BUG-0001/0006 = CLOSED（fix_commit + verify_evidence 齐备）；
  BUG-0002~0005 = SPEC_CHANGED（终态）。`fl_schema_enforce=true`
  （`iverif.json:10`）下机器检查通过。
- `[not yet] signoff file` 即本文件，写入后满足 `docs.py --next` 的里程碑
  完成判定。

机器条件均 PASS。以下人工抽查由签核人独立执行，非机器可判。

---

## 2. 人工抽查

### 抽查 4 — 覆盖闭合 ≠ 风险闭合

**M0 尚无功能覆盖采集**（覆盖率六类从 M2/M4 起，见 CLAUDE.md §6 里程碑路线
图）。故 rubric L23–26 的"抽 2–3 个命中 bin 核验其由目标场景命中、复读 1 个
豁免洞"在 M0 无对应 covergroup/waiver 客体——**不适用，显式声明而非静默跳
过**。

按该抽查的**精神**（"通过是否由目标机制达成、而非偶然/空跑")对 M0-01 的唯一
证据做等价核验：

- 目标机制（`doc/testplan.md:7`）：上游 tb 自带 FIFO 参考网络校验路由/保序/
  ID，`print_result` 零 mismatch，仿真自然结束。
- 独立核验源日志 `sim/out/upstream_sanity_1.log`（`make run TEST=
  upstream_sanity SEED=1` 复跑重生，非仅采信蒸馏证据）尾部：
  `Simulation has ended!` → `Tests Expected: 178296` / `Tests Conducted:
  178296` / `Tests Failed: 0` → `tb_axi_xbar.sv, 261 : $stop()`（`end_of_sim`
  自然收敛）→ `Summary: 3198 assertions, 1924 with attempts, 0 with
  failures`。
- **反"空跑通过"守卫已在 tb 内建**：`tb_axi_xbar_pkg.sv:500-501`
  `if(tests_conducted == 0) $error("...did not conduct any tests!")`——即
  "0 事务的假通过"会被 tb 自身判红。本次 Conducted=178296=Expected，证明通过
  是由 6×8 全连接、读写各 200 笔并发（ATOP 开）的**目标激励实打实命中**，非
  偶然/空跑。此为 M0 层面"well-hit 由目标场景命中"的等价证据。

**结论：M0-01 的通过由目标机制达成，可信。**

### 抽查 5 — 守卫证伪（Guard falsification）

选 **BUG-0006**（min_repro `make compile`，elaboration 确定性错误，无 SEED
依赖，最适合证伪）。

实际操作（一次性废弃分支，绝不合并/推送）：

1. `git checkout -b signoff-throwaway-bug0006`（自 HEAD 80f6c3c）。
2. `git revert --no-edit 8062976`（撤销 P-002 修复；改动 3 文件：
   `axi_xbar.sv` / `tb_axi_xbar_pkg.sv` / `VENDOR.md`）。核验回退生效：
   `axi_xbar.sv:84/190` 端口位宽复原为 `input rule_t [Cfg.NoAddrRules-1:0]`
   （`localparam AddrMapMsb` 中转已撤）。
3. `make -C sim clean && make -C sim compile` → **守卫如期转红**：
   `sim/out/comp.log` 报 `6 × Error-[NCE] Non-constant expression`，
   `Expression: (NoAddrRules - 1)`，`6 errors`，`make: *** [compile] 错误
   255`——与 `doc/archive/bugs-archive.md` BUG-0006 记录的 `6×Error-[NCE]`、
   表达式 `NoAddrRules-1` 签名逐条吻合（含 root_cause 所述"先序错误掩盖后由
   `Cfg.NoAddrRules-1` 变 `NoAddrRules-1`"的实证形态）。
4. `git checkout master && git branch -D signoff-throwaway-bug0006 && make -C
   sim clean`。核验：回到 master、工作树干净、修复复位
   （`axi_xbar.sv:67/86/187/194` 的 `localparam AddrMapMsb` 在位）、无残留
   throwaway 分支。

**守卫为真**：`upstream_sanity 1` 作为回归守卫用例，其 `compile`（`run` 的前
置依赖）在 P-002 修复缺席时确定性失败——该守卫**已亲眼见红**，非仅假设。
（附注：BUG-0001 的 P-001 守卫本轮未证伪，但 BUG-0006 与之同为
VCS-2018 NCE 编译类、共享同一 `make compile` 守卫路径；本次证伪已覆盖该守卫
路径的红/绿两态。）

### 抽查 6 — spec 债务为零或已受理

开放 SPEC_ISSUE 清单：BUG-0002~0005，均已置 `SPEC_CHANGED`（终态），且每条
在 `doc/bugs.md` / `doc/archive/bugs-archive.md` 的 `root_cause` 列有书面受理
理由，与 `doc/review/REV-001.md` §5 逐条裁决一致：

- BUG-0002（Connectivity[i][j]=0 响应未载，高）→ REV-001 §5 裁决：许可来源不
  定义、禁抄 RTL；v0 补 §8 构造性环境约束（地址表不译码到非连通 master 端
  口）。受理，不阻塞 M3/M4。
- BUG-0003（ATOPs=0 收 ATOP 未定义）→ v0 补 §6 环境约束（ATOPs=0 时环境保证
  `aw.atop≡'0`）。受理，不阻塞 M4。
- BUG-0004（PipelineStages 外部时序仅 RTL 注释）→ 采延迟不敏感原则；v0 补
  §2.1/§7.4（精确周期数未定义、latency checker 不得断言固定拍数）。受理，基
  线 PipelineStages=1 不阻塞 M1。
- BUG-0005（NoAddrRules 最小值源间冲突，低）→ 采主文档 xbar.md 口径（全表 ≥1
  条即可）；v0 统一 §2.1/§3.1 措辞。受理。

两项挂起的**上游确认项**（BUG-0002"被禁触发时 DUT 响应"、BUG-0004
"cycle-accurate 时序"）经 REV-001 判为不阻塞后续里程碑，作为长期追踪项，非
M0 债务。

**结论：M0 无未受理的 spec 债务。**

---

## 3. 残留风险（均非阻塞）

| # | 风险 | 严重度 | 依据 | 处置建议 |
| --- | --- | --- | --- | --- |
| R1 | 已提交证据 `doc/evidence/v0.0.1/M0-01.log`（及 BUG-0001/0006.log，三者字节相同）的 `## Key check lines` 段为**空**，未捕获上游 tb 记分板判决行 `Tests Failed: 0 / Conducted 178296`——该行位于 `PLAIN_MARK` 摘要窗口（`V C S Simulation Report` 上 2 行内）之上、且不匹配 `evidence.py` 的 `KEY_LINE_RE`（pass\|match\|compare ok\|check ok\|running test）。故仅凭已提交证据无法直接看到功能记分板结果，只见 SVA 摘要（3198 断言 0 失败）。 | 中 | `scripts/evidence.py:27-37,66-77`；源日志 `sim/out/upstream_sanity_1.log` 尾部 | 不阻塞：①`svacheck.judge` 判决为**两腿制且 fail-closed**（VCS 完成 banner 在场 + SVA 独立零失败；FAIL/NOSUMMARY 直接拒登），✅ 判定本身稳健；②签核人已独立复跑源日志确认 178296/178296、0 failed；③line-1 复现命令自洽。建议登记 `doc/fw-feedback.md`：非 UVM tb 记分板判决行落在 `PLAIN_MARK` 窗口上沿之外，`evidence.py` 宜上扩窗口或为非 UVM tb 增补 `Tests Failed`/`ended`/`mismatch` 关键行模式。 |
| R2 | 源仿真日志尾部与 SVA 摘要含一条 `axi_demux_simple.sv:624 ... cnt_underflow: started at 4098920000ps not finished` —— 一条在 `$stop` 时刻仍在飞的断言 attempt。 | 低 | `sim/out/upstream_sanity_1.log` 尾部；三份 `.log` 证据 `## Report Summary` 段 | 良性：`$stop` 于 `end_of_sim` 自然收敛点触发，末拍握手中的断言 attempt 未及闭合属正常仿真终止形态，非断言失败（`0 with failures` 已独立佐证）。仅记录备查，无需动作。 |

**非风险的观察（备查，不计入残留风险）**：BUG-0006 的 `root_cause` 行较长
（多子句），逼近"调试故事 > 一行即建详情页"的边界，但 `fl_schema_enforce`
机器检查已通过；是否补 `doc/bugs/BUG-0006.md` 为记录质量偏好，非签核阻塞项。

---

## 4. 六问框架收敛（本里程碑证据整体）

1. **Origin**：M0-01 溯 `doc/testplan.md:7`（上游 tb sanity）；spec v0 条款可
   溯性经 REV-001 §3.1 抽查通过。达标。
2. **Falsifiability**：功能面由上游 FIFO 参考网络 + `tests_conducted==0`
   守卫（tb 内建反空跑）+ 3198 SVA 保证可红；BUG-0006 守卫经抽查 5 亲验见红。
   达标。
3. **Replayability**：三证据 line-1 均为 `make run TEST=upstream_sanity
   SEED=1`，evidence.py 生成、与源日志自洽，证据随代码同 commit（closeout
   24d16ce）。达标（证据摘要完整度见 R1）。
4. **Attribution**：BUG-0001/0006 失败记录含 first_anomaly/taxonomy
   (TOOL_ENV)/rca/fix_commit/rerun/守卫；closer≠fixer 由框架实例隔离保证。
   达标。
5. **Judgment**：机器条件 3×PASS + 抽查 4/5/6 通过；证据支持"M0 风险已退
   役"，缺口仅 R1/R2（非阻塞）。达标。
6. **Retention**：教训落 bugs.md 行 + VENDOR.md（P-001/P-002）+ REV-001 +
   regress.list 守卫 + 本签核；R1 建议回流 fw-feedback。达标。

---

## 5. 裁决

**M0 里程碑签核：PASS。**

M0（基建 + 上游 sanity + spec v0）的风险已退役：唯一功能场景 M0-01 由目标激励
实打实通过（178296 事务 0 失败、3198 断言 0 失败、自然收敛），两条 VCS-2018
NCE 编译障碍（BUG-0001/0006）已修复、闭环并具亲验守卫，四条 spec 缺口
（BUG-0002~0005）经 REV-001 仲裁受理入 spec v0 并 SPEC_CHANGED。残留 R1（证据
摘要未捕获非 UVM 记分板判决行）与 R2（末拍在飞断言）均非阻塞，R1 建议回流框
架反馈。可进入 M1（UVM env + smoke，并评估 v0.39.10 升级）。

> 本签核仅执行只读机器检查 + 人工抽查（含一次性废弃分支的守卫证伪，已丢
> 弃），未改 rtl/tb/vendor 行为、未改 spec、未改代码；产出仅本签核记录。
