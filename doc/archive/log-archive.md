# Work log archive
## [0.0.2] 2026-07-27 DV 复验闭环：M0-01 ✅ + BUG-0001/0006 CLOSED

**Done**
- DV 复验卡（全新实例，closer≠fixer）：`make compile`（clean rebuild）0×Error-[NCE]、`make smoke TEST=upstream_sanity SEED=1` 自然终止零 mismatch（178296/178296，SVA 3198 assertions 0 failures）、`make regress` 1/1 PASS
- 三条 evidence 经 `make evidence` 机械登记：BUG-0001、BUG-0006、M0-01（均落 `doc/evidence/v0.0.1/`，line 1 replay + 生成戳）
- BUG-0001 FIX_READY → CLOSED；BUG-0006 FIX_READY → CLOSED；testplan M0-01 ❌ → ✅（状态格由 evidence.py 回填，非手改）
- `sim/result_summary.txt` 拷入 `doc/evidence/v0.0.1/`，`make signoff-check` 机器条件 1~3 全 PASS
- CLAUDE.md §2 新增原则"小步快跑"（Small closed loops, then stop）：长任务切小块闭环，完成即推送并等待用户指令

**Not done**
- M0 里程碑未收官：rev signoff 卡未派（`signoff-M0*.md` 缺失，`make signoff-check` 卡在人工抽检 4~6 项）
- FB-1~FB5 回流框架仓库未做

**Next**
- 派 rev 里程碑签核卡（覆盖闭合抽检 + guard falsification + SPEC_ISSUE 清单）→ signoff-M0 记录 → `make bump-minor` → tag v0.1.0
- FB 批量回流 iverif-workflow

**How verified**
- `make docs-check` / `make fw-check` 全绿；`make signoff-check` 机器条件 1~3 PASS（4~6 待 rev）；见 `doc/evidence/v0.0.1/{BUG-0001,BUG-0006,M0-01,result_summary}`

## [0.0.1] 2026-07-27 M0 基建首循环：vendor pin + 编译排雷 + spec v0

**Done**
- iverif-workflow 0.2.0 首次实战接入（copilot/en，正文中文约定见 CLAUDE.md §6）；fw-feedback.md 台账建立并登记 FB-1~FB-5
- vendor pin：axi v0.39.9 + 三依赖库（SHA 见 vendor/VENDOR.md），上游 tb/doc 按同 tag 补拉
- sim 基建：flist 三件套（floo 已验证 Bender 序）+ sim/Makefile（VCS-2018 workaround + SIM_OPTS_2018）
- 编译排雷：BUG-0001（P-001，$sformatf/genvar NCE，@1a15627）与 BUG-0006（P-002，struct 成员端口位宽 NCE 共 3 处，@8062976）均 FIX_READY，make compile 全过（simv 生成）
- spec v0：arch 蒸馏 → REV-001 评审（条件通过，C1~C5）→ 修订应用 → 重 pin（@cbd2b09）；四 spec 缺口（BUG-0002~0005）经 rev 裁决 SPEC_CHANGED（环境约束/延迟不敏感/采信主文档）

**Not done**
- M0-01 仍 ❌：DV 复验未跑（编译已通，仿真 + evidence 未执行——本循环按"小步快跑"在此暂停）
- BUG-0001/0006 未 CLOSED（等 DV 复验闭环，closer ≠ fixer）
- regress/result_summary 归档、rev 签核、M0 里程碑完成均未开始
- fw-feedback 回流框架仓库未做（FB-1~FB-5 全部 open）

**Next**
- 派 DV 复验卡：重跑 M0-01（make smoke）→ make evidence SCEN=M0-01 → make evidence BUG=0001/0006 闭环 → regress + result_summary 归档（顺带实证 FB-3 的 Summary 行悬案）
- 之后：rev 签核卡（含 P-001/P-002 补丁评审回填 VENDOR.md review 列）+ signoff-check + bump-minor → v0.1.0 tag；FB 批量回流 iverif-workflow

**How verified**
- make docs-check / fw-check 全绿（本块提交前复跑）；make compile 结论见 BUG-0006 root_cause 实证（out/simv 生成、comp.log 0×NCE）；spec pin=2637206e…（提交 cbd2b09）

## [0.0.0] 2026-07-27 scaffolded

**Done**
- fwsync --init (framework snapshot + doc seeds)

**Not done**
- everything else

**Next**
- M0 bring-up: vendor/flists/sim Makefile, spec v0

**How verified**
- make docs-check

