# Bugs archive

| id | status | suspect | summary | min_repro | root_cause | fix_commit | verify_evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BUG-0002 | SPEC_CHANGED | SPEC | spec 缺口（arch 蒸馏 P-a，高优先）：`Connectivity[i][j]=0` 时命中该路由的事务响应行为上游文档未载，M3/M4 稀疏矩阵维度 checker 无法推导期望值 | -（spec 歧义，非仿真失败） | SPEC_ISSUE 确认（REV-001 裁决）：许可来源不定义、禁抄 RTL。v0 已补 §8 构造性环境约束：稀疏配置地址表须构造为不译码到非连通 master 端口（未定义情形构造性不可触发）；M3/M4 稀疏维度在此约束子集上验证不降级；"被禁触发时 DUT 响应"留待上游确认（§8.4，不阻塞） | - | - |
| BUG-0003 | SPEC_CHANGED | SPEC | spec 缺口（arch 蒸馏 P-b）：`ATOPs=0` 配置下收到 ATOP 事务的行为未定义，影响配置矩阵 ATOPs{0} 维度 checker | -（spec 歧义，非仿真失败） | SPEC_ISSUE 确认（REV-001 裁决）：许可来源未定义、禁抄 RTL。v0 已补 §6 环境约束：ATOPs=0 时环境保证不发起 ATOP（aw.atop≡'0），违反即未定义；ATOPs{0} 维度在无-ATOP 约束下验证，不阻塞 M4 | - | - |
