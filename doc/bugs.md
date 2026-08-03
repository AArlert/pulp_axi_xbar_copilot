# Bugs

任何验证失败都无条件登记于此（不因已绕过/不阻塞而豁免）。每条 bug 一行总表
概览 + 一页详细记录（`doc/bugs/<id>.md`：现象、复现、分诊、RCA、修复、复验）。
编号顺延历史（历史台账见 `git show v0.5.3-pre-reset:doc/bugs.md` 及其归档），
下一个可用编号 **BUG-0075**。

**五类分诊速查**（按此顺序排查；DUT_BUG 之前先排掉前四类）：

| class | 一行判据 |
|---|---|
| TOOL_ENV | 结果随种子/机器/构建漂移而激励未变；命中已知工具缺陷（VCS O-2018 特性见 `scripts/make/vcs-2018.mk` 头注）；陈旧构建产物 |
| TB_BUG | driver 违反协议时序；monitor 采错沿；scoreboard 期望推导错——或期望**抄了 RTL 而非 spec** |
| CONSTRAINT_BUG | 随机约束产生非法/越界激励，或把想测的空间约束没了 |
| SPEC_ISSUE | spec 与上游文档矛盾、或行为根本未定义，DUT 与 TB 各有一种站得住的读法 → 补 spec 条款，绝不"就地解释" |
| DUT_BUG | 波形显示 DUT 输出违反 spec 明文条款，且有独立激励路径可复现 → vendor 快照走上游 issue，**绝不本地改行为** |

状态：`OPEN → FIXING → CLOSED`，或终态改判 `TB_BUG / SPEC_CHANGED / WONTFIX`。
关闭须复验证据（`make evidence BUG=<id> ...`，脚本回填 evidence 列）。

| id | class | status | summary | evidence | link |
| --- | --- | --- | --- | --- | --- |
| BUG-0044 | SPEC_ISSUE | CLOSED | spec §6 补齐 ATOP 子类型应答义务（SPEC-6.6/6.7/6.8）+ scoreboard oracle 天然支持 + M5-AT03 定向测试 PASS | doc/evidence/v0.5.12/M5-AT03.log | doc/bugs/BUG-0044.md |
