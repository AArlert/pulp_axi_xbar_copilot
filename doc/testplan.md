# Testplan

Scenario truth table — contract: workflow/schema/testplan_entry.md. Register rows BEFORE coding; ✅/evidence/repro are script-owned.

| id | milestone | description | config | status | evidence | repro |
| --- | --- | --- | --- | --- | --- | --- |
| M0-01 | M0 | 上游 tb_axi_xbar sanity：6 主 × 8 从随机读写各 200 笔并发（ATOP 开），tb 自带 FIFO 参考网络校验路由/保序/ID，print_result 零 mismatch，仿真自然结束（当前被 BUG-0001 阻塞：VCS-2018 编译 NCE，见 doc/bugs/BUG-0001.md） | 上游 tb 默认（6×8，SlvIdW 5/用 3，DW 64，AW 32，Pipeline 1） | ✅ | doc/evidence/v0.0.1/M0-01.log | `make run TEST=upstream_sanity SEED=1` |
