# Work log archive
## [0.1.2] 2026-07-27 框架 0.2.0 → 0.3.0 两轮回流闭环 + BUG-0008 补登

**Done**
- FB 首轮回流闭环：FB-1~FB-7 全部落入框架 0.2.1，本仓库 `fwsync --pull`
  两次（0.2.1 → 0.3.0），`doc/fw-feedback.md` 七行 `open` → `fixed@0.2.1`
  并加头注。实质拿回来的变化：`evidence.py` 非 UVM tb 摘要窗口 2 → 20 行
  + 关键行正则增补（FB-6）；`.claude/agents/de.md` 修复交付改置 FIXING，
  fix_commit 与 FIX_READY 归 orch 提交后回填（FB-5，绕行作废）；四角色
  交付报告新增强制字段"本卡是否命中 taxonomy 异常（含已绕过的）"
  + taxonomy 正典补"登记无条件"段（FB-7）；`vcs-2018.mk` 的
  `LM_LICENSE_FILE` 注释挑明是必须覆盖的占位值（FB-2）。
- 框架 0.3.0 带来 `workflow/discipline.md`（执行纪律五条，优先级高于便利、
  低于核心不变量与角色隔离），CLAUDE.md 与四个角色文件都指向它。本仓库
  自产的"小步快跑"被上收为正典 rule 5。
- 反漂移清理两处本地重述：CLAUDE.md §2 的 taxonomy 登记表述、以及那段
  自产"执行纪律"三条，都收成指向正典的指针，只保留本仓库特有的内容
  （M1-01 案例、落地判据含 `/closeout` 的本地仪式）。
- **BUG-0008 补登**（TOOL_ENV，OPEN）：`doc/evidence/v0.0.1/` 三条 M0 证据
  的 `## Key check lines` 段为空。此事 signoff-M0 抽检 R1 就发现了，却只
  进了 `doc/fw-feedback.md` FB-6 和评审记录，`doc/bugs.md` 一直没有行——
  与 BUG-0007 同一形状的可追溯性缺口，按"登记无条件"补上。

**Not done**
- 存量三条 M0 证据未重新生成。`doc/evidence/v0.0.1/` 是 signoff-M0 已签核
  指向的产物，用新抽取器覆写会改动被签核对象而签核记录无法同步重签；
  权衡后判定"摘要不全"轻于"签核指向的证据在签核后被改过"。是否重生成
  属 rev 裁决，orch 不自行 WONTFIX（路径写在 BUG-0008 的 `## rerun`）。
- M1-02 未动（scoreboard_refmodel / sva_bind 两行仍非 ✅）。

**Next**
- 派 rev 卡：① 裁决 BUG-0008 存量是否重生成；② 复核本轮两处本地重述收编
  是否有语义丢失。
- 派 DV 卡推进 M1-02。

**How verified**
- 每轮 pull 后 `make fw-check` + `make docs-check` 双绿（当前
  framework 0.3.0，26 个 pin 文件）；BUG-0008 行与详情页加入后 docs-check
  仍绿（FL 详情页非终态可部分填写，本页已按 schema 八段写全）。
- 框架侧 48 例自测全过（新增一例钉住 discipline.md 到位且两种 profile 下
  每个角色文件都指向它），framework master 与两个标签已推送。
- FB-6 的修复在框架侧有保险丝：还原窗口与正则后 48 例中恰好只有
  `test_plain_nonuvm_verdict_line_captured` 失败。

## [0.1.1] 2026-07-27 M1 首个场景：UVM env 骨架落地 + M1-01 smoke ✅

**Done**
- arch 设计输入卡：`doc/design-prompt/{tb_top,uvm_env,scoreboard_refmodel,sva_bind}.md`（每约束引 spec 章节）+ feature-matrix `F-M1-01~04` + testplan `M1-01`/`M1-02`（🔲）+ vendor 升级评估 `doc/vendor-upgrade-v0.39.10.md`（结论 Defer：v0.39.9→v0.39.10 对 axi_xbar 全部 spec 蒸馏来源逐字节相同，唯一差异为非行为的冗余 elaboration 断言删除 #407）
- rev 交付门 `REV-002`：M1 design-prompt 集放行（cleared for DV），未见 behavior-leak；`sva_bind.md` 两处引用瑕疵（PASS-with-notes，非阻塞）；vendor 升级 memo 结论逐条实测证实
- DV 卡：`tb/` UVM env 骨架（tb_top + slave/master agent + 地址路由/ID 前缀参考模型记分板 + SVA）落地，`sim/flist/tb.f` + `sim/Makefile`（按 TEST 名切换 M0 上游 tb / M1 UVM tb_top，M0-01 复现命令不变）；M1-01 smoke 通过（scoreboard route/resp 48/48 match、SVA 2119 assertions 0 failures、UVM_ERROR 0、自然终止），evidence 登记 `doc/evidence/v0.1.0/M1-01.log`；`sva_bind.md` 两处引用瑕疵随手订正
- 工具偏离处理：VCS-2018.09-SP2 拒绝 `bind <interface> <module>`（`Error-[IIM]`），DV 改直接例化挂 SVA；rev 独立复核 `REV-003`（含最小探针复现该报错签名）确认行为等价、放行，`sva_bind.md` C1.1 补订正说明，CLAUDE.md §4 补记该工具限制供后续卡参考
- 附带完成（同周期、独立提交推送）：README 新增"DUT 模块层级"小节（grep 例化关系逐级追至叶子/common_cells 基础单元）+ "数据流概览"讲解 + `doc/attach/axi_xbar_dataflow.svg` 示意图

**Not done**
- `M1-02`（ID 前缀响应路由 smoke）未做，仍 🔲；`scoreboard_refmodel.md` 里为 M1-02 预留的判决路径仍是 stub
- M1 里程碑未收官（尚缺 M1-02 + 里程碑签核）
- `FB-1~FB-6` 批量回流 iverif-workflow 框架仓库仍未做——里程碑边界约定时点已过一个版本周期，欠账中

**Next**
- 派 DV 卡实现 `M1-02`
- `FB-1~FB-6` 批量回流 iverif-workflow（已逾期一个周期，优先级提高）
- M1 里程碑收官（M1-02 完成后）

**How verified**
- 独立重跑 `make compile`（0 error/0×NCE）+ `make run TEST=m1_01_smoke_test SEED=1`（scoreboard 48/48 match、SVA 0 failures、UVM_ERROR 0，与 DV 交付报告一致）+ `make run TEST=upstream_sanity SEED=1`（M0-01 回归不变，Tests Failed 0）；`make docs-check`/`make fw-check` 全绿；`REV-002`/`REV-003` 见 `doc/review/`

## [0.1.0] 2026-07-27 M0 里程碑签核 PASS：基建+sanity+spec v0 收官，转入 M1

**Done**
- rev 全新实例（非本里程碑任何 review/fix 当事人）执行 M0 里程碑签核：机器条件 3×PASS 自跑复核 + 3 项人工抽查（抽查 4 覆盖闭合 N/A 但按精神等价核验目标机制命中；抽查 5 守卫证伪——一次性废弃分支 revert BUG-0006 修复、`make compile` 复现原 6×NCE 签名、清理分支；抽查 6 spec 债务清零核对 REV-001 §5 逐条裁决）
- 签核记录 `doc/evidence/v0.0.2/signoff-M0.md`：总体裁决 **PASS**，2 项非阻塞残留风险（R1 证据摘要窗口未捕获非 UVM 记分板判决行；R2 末拍在飞断言，良性）
- R1 回流 `doc/fw-feedback.md` FB-6（kernel/evidence.py，annoyance）
- `make signoff-check` 全绿（含 signoff 文件识别）；`make bump-minor` 0.0.2→0.1.0

**Not done**
- M1（UVM env + smoke，评估 v0.39.10 升级）未开始
- FB-1~FB-6 回流框架仓库（iverif-workflow）未做——里程碑边界批量回流的约定时点已到，尚待执行
- R1（evidence.py 摘要窗口）本身未修——按框架红线本仓库不改 scripts/，需上游修复

**Next**
- FB-1~FB-6 批量回流 iverif-workflow（里程碑边界回流仪式，见 CLAUDE.md §5）
- 派 arch 设计输入卡：M1 UVM env 骨架（tb_top + 多 master/slave agent + 地址路由参考模型记分板）+ 评估 v0.39.10 升级影响
- `git tag v0.1.0`

**How verified**
- `make signoff-check` 全绿（机器条件 3×PASS + signoff 文件 `[yes]`）；`make docs-check` / `make fw-check` 全绿；签核记录见 `doc/evidence/v0.0.2/signoff-M0.md` §5 裁决

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

