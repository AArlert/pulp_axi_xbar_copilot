# Bugs

States: OPEN/FIXING/FIX_READY/VERIFYING/CLOSED/TB_BUG/SPEC_CHANGED/WONTFIX. Debug stories longer than one line get a detail page doc/bugs/<ID>.md — contract: workflow/schema/failure_record.md.

| id | status | suspect | summary | min_repro | root_cause | fix_commit | verify_evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BUG-0004 | SPEC_CHANGED | SPEC | spec 缺口（arch 蒸馏 P-c）：`PipelineStages` 外部延迟语义仅 axi_pkg.sv 注释可溯源；基线配置即 PipelineStages=1，M1 smoke 时序预期需此条款落地 | -（spec 歧义，非仿真失败） | SPEC_ISSUE 确认（REV-001 裁决）：采延迟不敏感原则。v0 已补 §2.1/§7.4：PipelineStages 为延迟不敏感插桩（改延迟不改功能/吞吐），精确周期数未定义、latency checker 不得断言固定拍数；M1 功能 checker 须延迟不敏感，基线 PipelineStages=1 不阻塞；cycle-accurate 需求另行上游确认（§7.4.4） | - | - |
| BUG-0005 | SPEC_CHANGED | SPEC | spec 缺口（arch 蒸馏 P-d，低）：`NoAddrRules` 最小值口径不一致（xbar.md "地址表至少一条" vs axi_pkg 注释 "每 master 端口至少一条"），影响不可达 mst 端口配置合法性判定 | -（spec 歧义，非仿真失败） | SPEC_ISSUE（源间冲突）确认（REV-001 裁决）：采信主文档 xbar.md 口径——全表 ≥1 条即可，无"每 master 端口 ≥1"硬性要求（axi_pkg 的 should 为软性建议）；无 rule 指向的 master 端口为合法配置。v0 已统一 §2.1/§3.1 措辞 | - | - |
