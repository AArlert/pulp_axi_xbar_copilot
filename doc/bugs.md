# Bugs

States: OPEN/FIXING/FIX_READY/VERIFYING/CLOSED/TB_BUG/SPEC_CHANGED/WONTFIX. Debug stories longer than one line get a detail page doc/bugs/<ID>.md — contract: workflow/schema/failure_record.md.

| id | status | suspect | summary | min_repro | root_cause | fix_commit | verify_evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BUG-0001 | FIXING | TB | VCS-2018 编译上游 tb_axi_xbar 报 2×Error-[NCE]：generate 环内 `$sformatf(...,i)` 作 axi_chan_logger 参数 LoggerName 覆盖被判非常量（vendor/axi/test/tb_axi_xbar.sv:301/337），M0-01 smoke 无法编译；详情 doc/bugs/BUG-0001.md | `cd sim && make smoke TEST=upstream_sanity SEED=1`（compile 阶段即失败，与 SEED 无关） | TOOL_ENV：VCS-MX O-2018 不支持含 genvar 的 $sformatf 作参数覆盖常量（工具能力缺口，非 DUT 行为） | - | - |
| BUG-0006 | OPEN | TB | VCS-2018 编译报 6×Error-[NCE]：`(NoAddrRules - 1)` 作端口位宽（xbar_cfg_t struct 成员参数选择）无法常量折叠，vendor/axi/src/axi_xbar.sv:84（module axi_xbar）与 :190（module axi_xbar_intf），经 tb 的 axi_xbar_intf 实例弹性触发；原被 BUG-0001 的先序错误掩盖，P-001 后浮出 | `cd sim && make compile`（elaboration 阶段确定性错误） | TOOL_ENV：VCS-MX O-2018 struct-member-in-port-width 折叠缺陷（同类先例：floo_axi_chimney P-001 的 TCF 类，localparam 中转可解），非 DUT 行为 | - | - |
| BUG-0002 | OPEN | SPEC | spec 缺口（arch 蒸馏 P-a，高优先）：`Connectivity[i][j]=0` 时命中该路由的事务响应行为上游文档未载，M3/M4 稀疏矩阵维度 checker 无法推导期望值；待 rev 裁决补 spec 途径（上游确认，非抄实现） | -（spec 歧义，非仿真失败） | SPEC_ISSUE：许可来源无该条款 | - | - |
| BUG-0003 | OPEN | SPEC | spec 缺口（arch 蒸馏 P-b）：`ATOPs=0` 配置下收到 ATOP 事务的行为未定义，影响配置矩阵 ATOPs{0} 维度 checker | -（spec 歧义，非仿真失败） | SPEC_ISSUE：许可来源无该条款 | - | - |
| BUG-0004 | OPEN | SPEC | spec 缺口（arch 蒸馏 P-c）：`PipelineStages` 外部延迟语义仅 axi_pkg.sv 注释可溯源；基线配置即 PipelineStages=1，M1 smoke 时序预期需此条款落地 | -（spec 歧义，非仿真失败） | SPEC_ISSUE：来源仅 RTL 注释 | - | - |
| BUG-0005 | OPEN | SPEC | spec 缺口（arch 蒸馏 P-d，低）：`NoAddrRules` 最小值口径不一致（xbar.md "地址表至少一条" vs axi_pkg 注释 "每 master 端口至少一条"），影响不可达 mst 端口配置合法性判定 | -（spec 歧义，非仿真失败） | SPEC_ISSUE：来源间口径冲突 | - | - |
