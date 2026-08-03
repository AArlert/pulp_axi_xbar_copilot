# Bugs

任何验证失败都无条件登记于此（不因已绕过/不阻塞而豁免）。每条 bug 一行总表
概览 + 一页详细记录（`doc/bugs/<id>.md`：现象、复现、分诊、RCA、修复、复验）。
编号顺延历史（历史台账见 `git show v0.5.3-pre-reset:doc/bugs.md` 及其归档），
下一个可用编号 **BUG-0080**。

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
| BUG-0075 | TB_BUG | OPEN | 共享译码 oracle `decode_mst_port` 未实现 spec §3.2.3 `end_addr=='0` 哨兵语义（休眠：现行地址表构造性不可触发，非阻塞；M6 处置，修 oracle+场景或走环境约束条款，二选一） | - | doc/bugs/BUG-0075.md |
| BUG-0076 | TB_BUG | CLOSED | M5-AT03 激励缺 atomicload 阶段（cp_atop_subtype 3/4 bins，行判据声称 4/4；FCOV_SUMMARY 恰不印该 coverpoint 掩盖缺口）——修复：seq Phase D + 补印 cp_subtype | doc/evidence/v0.5.15/BUG-0076.log | doc/bugs/BUG-0076.md |
| BUG-0077 | TB_BUG | CLOSED | M5 soak 层无未命中激励，M5-SK03"命中与未命中均覆盖"证据实为 decerr resp=0——修复：xbar_soak_seq 增加 decode-miss leg（region NO_ADDR_RULES，atop='0，§4.7 宽读合规） | doc/evidence/v0.5.15/BUG-0077.log | doc/bugs/BUG-0077.md |
| BUG-0078 | TB_BUG | CLOSED | fall-through cover 结构性恒 0（RN03 与基准 M4-FT01 均 samples=0，"显著高于"不成立；驱动器串行 AW→W 呈现使四信号同拍不可达）——修复：aw_w_decoupled 旋钮复用 EB01 解耦 fork，cfgE 专属子类启用 | doc/evidence/v0.5.15/BUG-0078.log | doc/bugs/BUG-0078.md |
| BUG-0079 | TB_BUG | CLOSED | M5-RN02"探及连通域边界"must-reach 结构性未兑现（cfgd 随机轮固定偏移只探区间内部，种子无关）——修复：确定性边界探针（start_addr / end_addr-8，§3.2 含起不含终；rev 收口评审补登，与 BUG-0077/0078 同型） | doc/evidence/v0.6.0/BUG-0079.log | doc/bugs/BUG-0079.md |
