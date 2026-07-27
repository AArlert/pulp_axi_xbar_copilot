<!-- Rendered by fwsync from iverif-workflow/templates/CLAUDE.project.copilot.md
     (framework 0.3.0). Project-specific sections are marked
     TODO; the framework-owned sections should not be edited here. -->

# pulp_axi_xbar_copilot — CLAUDE.md

Profile: **copilot** (see `workflow/profiles.md`). The workflow rules
live in the `workflow/` snapshot — read them there (offline-safe); do not
restate or fork them here.

> **Read first, every session: `workflow/discipline.md`** — execution
> discipline (think before coding · simplicity first · surgical changes ·
> goal-driven execution · small closed loops). It binds orch and every
> dispatched role, and it outranks convenience: prefer it over the faster
> path. It sits below the core invariants and the isolation rules in §0 —
> those are hard gates, discipline is how you behave between them. Every
> role file repeats the pointer; the text itself lives only in the
> snapshot, so it can never drift here.

## §0 Roles and isolation (hard rules)

- **orch (main session, you)**: pure dispatcher — assembles cards
  (`/dispatch` skill), collects deliveries against each role's fixed report
  format, applies rev-approved spec edits + re-pin, maintains the memory
  system via the make targets. **orch produces no technical artifacts**: no
  RTL, no TB, no design-prompts, no spec content of its own.
- **arch / de / dv / rev** (subagents, rendered from the framework — see
  `.claude/agents/`, regenerated on every `fwsync --pull`): architecture,
  RTL, verification, review. Their boundaries live in their own files.
- Instance isolation: fresh instance per card; DE and DV never share an
  instance for the same module; arch and rev never share an instance;
  closer ≠ fixer; DV never reads DE reasoning (only file paths, section
  numbers, row ids travel in cards). Common-mode errors are the enemy.

Core invariants (framework): no sim log no ✅ · replay command on line 1 ·
closer ≠ fixer · spec pinned by sha256.

## §1 Memory system

Rolling files, read at session start via `make handover` (never re-derive
state from chat history):
- `doc/status.jsonl` — one JSON line per closeout, newest first.
- `doc/log.md` — capped block count; each block answers: done / not done /
  next / how verified.
- `doc/testplan.md` — the scenario truth table (contract:
  `workflow/schema/testplan_entry.md`).
Archives live in `doc/archive/` and are not read by default.

## §2 The work loop

```
make handover           # where am I
make next               # mechanically derived actions
<assemble card>         # /dispatch: pick tier, isolation self-check
<dispatch arch|de|dv|rev>
<collect against the fixed report format>
make evidence SCEN=<id> TEST=<t> SEED=<n>   # dv runs it; PASS only
make docs-check         # before closing any card
<closeout via /closeout at cycle end>
```

Failures: never registered as evidence. Triage with
`workflow/dispatch/*.md`, file in `doc/bugs.md`
(contract: `workflow/schema/failure_record.md`).

**Registration is unconditional** — the rule itself now lives in canon
(`workflow/taxonomy/failure_taxonomy.md`, opening paragraph, framework
0.2.1) and in every role's delivery-report format; read it there rather
than from a local restatement that can drift. Why this repo learned it the
hard way: the M1-01 VCS-2018 `bind`→direct-instantiation workaround
initially landed only in code comments + review records, not `doc/bugs.md`
(retro-registered as BUG-0007; this repo's FB-7 to the framework).

**Execution discipline**: `workflow/discipline.md` (framework 0.3.0) — the
five rules bind orch and every dispatched role. This repo's 小步快跑 became
its rule 5; the rest arrived with it. Local ritual only: a chunk "lands"
here when the gates are green **and** `/closeout` is done — then `git push`
and wait for the next instruction.

## §3 Gate order (dispatch preconditions)

- No DE new-feature card before its design-prompt passed the rev gate
  (behavior-leak check).
- No bug card before the bugs.md row exists (no verbal dispatch).
- No milestone close before `make signoff-check` machine conditions AND the
  rev signoff record (`doc/evidence/v*/signoff-M<n>.md`).

## §4 Environment

- Simulation runs in the VM (Ubuntu 22.04, VCS/Verdi O-2018). Known tool
  workarounds: `scripts/make/vcs-2018.mk` header. The xverif toolkit
  (`xdebug`/`xcov`/`xsva`/`xloc`) is NOT on PATH: entry
  `$XVERIF_ROOT/tools/` (default `/home/open_tools/xverif`, exported by
  `scripts/make/vcs-2018.mk`); export VERDI_HOME first; probe with
  `test -x $XVERIF_ROOT/tools/xcov`, never `command -v`.
- This repo is developed on the host and cloned into the VM; line endings
  are pinned by `.gitattributes` — do not fight it.
- VCS-2018.09-SP2 rejects `bind <interface> <module>`（`Error-[IIM]`）——挂接
  协议/时序 SVA 一律走宿主模块（`tb_top` 等）generate 循环内直接例化，见
  `doc/design-prompt/sva_bind.md` C1.1、`doc/review/REV-003.md`。

## §5 Git

- Conventional commits. Evidence lands in the same commit as the code it
  certifies. Push after closeout.
- Hooks: `git config core.hooksPath .githooks` once per clone.
- `scripts/`, `workflow/`, and `.claude/skills/` are a hash-pinned
  framework snapshot (`make fw-check`); `.claude/agents/` is regenerated on
  every pull. Improvements flow to the framework repo first:
  <https://github.com/AArlert/iverif-workflow>

## §6 Project specifics

- **DUT**：pulp-platform/axi v0.39.9 的 `axi_xbar`（AXI4+ATOP 全连接
  crossbar：每 slave 端口一个 `axi_demux` × 每 master 端口一个
  `axi_mux`）。只读 vendor 快照于 `vendor/`，SHA 锁定见
  `vendor/VENDOR.md`。本仓库**无 `rtl/`**：DE 卡仅用于 vendor 工具兼容
  补丁（P-xxx 登记 + rev 评审）；疑似 DUT 行为错误一律走 DUT_BUG 失败
  记录 + 上游 issue，绝不本地改行为。
- **spec 来源清单**（arch 蒸馏 `doc/spec.md` 的唯一许可来源）：
  `vendor/axi/doc/axi_xbar.md`（+ `axi_demux.md`、`axi_mux.md`）、
  `vendor/axi/src/axi_pkg.sv`（`xbar_cfg_t`/`xbar_latency_e`/
  `xbar_rule_*_t`）、`vendor/axi/src/axi_xbar.sv` 头注释。仅有 RTL 来源
  的条款须标注"（来源：RTL——上游文档未载）"。
- **DV 唯一可读参数定义文件**：`vendor/axi/src/axi_pkg.sv`。
- **flist 布局**：`sim/flist/vendor.f`（tech_cells_generic →
  common_cells → common_verification，Bender 序）/ `dut.f`（axi 全库，
  `axi_pkg.sv` 起）/ `tb_upstream.f`（上游 tb_axi_xbar，M0 sanity）/
  `tb.f`（M1+ UVM env）。仿真入口 `sim/Makefile`（VCS-MX O-2018，
  license 覆盖值 `27000@icarray-virtual-machine`）。
- **tb 架构（M1+ 草图）**：`tb_top` 例化单 `axi_xbar` + N 主 M 从接口；
  UVM env = 多 master agent + 多 slave agent + 由 spec 推导的地址路由
  参考模型记分板；协议/时序 SVA 在 `tb/sva/` 经 `bind` 挂接。基线配置
  取上游 tb 默认（6 主 × 8 从），多配置矩阵见 spec §0。
- **里程碑**（版本 0.M.P）：M0 基建+sanity+spec v0 → M1 UVM env+smoke
  （并评估 v0.39.10 升级）→ M2 功能场景+SVA+功能覆盖 → M3 多配置回归+
  错误路径 → M4 六类覆盖 ≥90% 收敛 → v1.0.0。
- **文档语言**：表头/机制英文（columns_preset=en），spec/log/testplan
  描述等正文中文（与人工学习仓库 `pulp_axi_xbar` 的阅读习惯一致）。
- **框架反馈**：任何 iverif-workflow 摩擦当场登记
  `doc/fw-feedback.md`，回流节奏与仪式见该文件头注；本仓库是框架首次
  实战应用，回馈是硬性交付物之一。
