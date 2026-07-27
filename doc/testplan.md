# Testplan

Scenario truth table — contract: workflow/schema/testplan_entry.md. Register rows BEFORE coding; ✅/evidence/repro are script-owned.

| id | milestone | description | config | status | evidence | repro |
| --- | --- | --- | --- | --- | --- | --- |
| M0-01 | M0 | 上游 tb_axi_xbar sanity：6 主 × 8 从随机读写各 200 笔并发（ATOP 开），tb 自带 FIFO 参考网络校验路由/保序/ID，print_result 零 mismatch，仿真自然结束（当前被 BUG-0001 阻塞：VCS-2018 编译 NCE，见 doc/bugs/BUG-0001.md） | 上游 tb 默认（6×8，SlvIdW 5/用 3，DW 64，AW 32，Pipeline 1） | ✅ | doc/evidence/v0.0.1/M0-01.log | `make run TEST=upstream_sanity SEED=1` |
| M1-01 | M1 | 自研 UVM env happy-path 路由 smoke：6 slave 端口各发命中地址表的写/读 burst，目标覆盖多个 master 端口；scoreboard 参考模型校验路由目标（SPEC-3.1/SPEC-3.2）、master 侧 ID 前缀（SPEC-5.1）、数据完整性（SPEC-1），响应码 OKAY，零 mismatch，env 无 UVM_ERROR、仿真自然结束 | baseline（6×8，Cfg 全 13 字段钉定：MaxMst 10/MaxSlv 6/FallThr 0/CUT_ALL_AX/Pipe 1/SlvIdW 5/Used 3/UniqueIds 0/AW 32/DW 64/Rules 8；ATOPs 1/Conn '1） | ✅ | doc/evidence/v0.1.0/M1-01.log | `make run TEST=m1_01_smoke_test SEED=1` |
| M1-02 | M1 | ID 前缀响应路由 smoke：多 slave 端口发低位相同 slave ID、目标不同 master 端口的事务（构造为不制造同 ID 同向跨端口未决对，避开 SPEC-5.2 stall）；scoreboard 校验每笔 B/R 按 master 侧 ID 高 clog2(NoSlvPorts) 位回送到正确源 slave 端口（SPEC-5.1.2/SPEC-5.1.3），无跨端口错送 | baseline（同 M1-01） | ✅ | doc/evidence/v0.1.2/M1-02.log | `make run TEST=m1_02_id_prefix_test SEED=1` |
