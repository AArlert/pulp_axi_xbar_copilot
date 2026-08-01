CMD: python3 -c "import re;G={};M=open(\"sim/out/urgText6/modlist.txt\",encoding=\"utf-8\",errors=\"replace\").read().split(chr(10));[G.setdefault(l.split()[7],l.split()[1:7]) for l in M if len(l.split())==8 and re.fullmatch(r\"\d+[.]\d\d\",l.split()[0]) and l.index(l.split()[0])<=1];S=open(\"doc/design-prompt/milestone_restructure.md\",encoding=\"utf-8\").read().split(\"### 6.3\")[1].split(\"## 7.\")[0];R=[[x.strip() for x in r.strip().strip(\"|\").split(\"|\")] for r in S.split(chr(10)) if r.startswith(\"|\") and \"---\" not in r];O={};[O.setdefault(re.match(r\"[a-z0-9_]+\",c[0]).group(0),c[2:8]) for c in R if len(c)>=8 and re.match(r\"[a-z0-9_]+\",c[0])];D=\"axi_xbar axi_xbar_unmuxed addr_decode addr_decode_dync axi_demux axi_demux_simple axi_demux_id_counters counter delta_counter axi_err_slv axi_atop_filter stream_register axi_mux axi_id_prepend rr_arb_tree lzc fifo_v3 axi_multicut axi_cut spill_register spill_register_flushable axi_pkg\".split();C=[(d,i,G[d][i]) for d in D for i in range(6)];L=[x for x in C if x[2]!=\"--\" and float(x[2])<90];U=[x for x in L if not re.search(r\"CW-\d|BUG-\d|DV-[A-G]\",O[x[0]][x[1]])];print(\"RESULT CELLS=%d LT90=%d UNOWNED=%d\"%(len(C),len(L),len(U)),U)"

EXPECT: `RESULT CELLS=132 LT90=30 UNOWNED=0`

# BUG-0049 关闭复验证据（closer 复算，v0.4.37）

**性质**：非仿真类缺陷的实质复验记录。评审记录（scope→verdict→guidance→overall）
在 `doc/review/REV-034.md`，**本文件不是它的副本**——这里只放"我实际跑了什么、
机器吐了什么"，判断与裁量在 REV-034。

> **与 `doc/evidence/v0.4.37/BUG-0049.log` 的分工（两份都不多余，别删任何一份）**
>
> | 文件 | 谁生成 | 在证据链里的角色 |
> | --- | --- | --- |
> | `BUG-0049.log` | **机器**：`scripts/evidence.py`（`make evidence BUG=BUG-0049 CMD=… EXPECT=…`）真的执行了本文件首行那条 CMD、校验 exit code=0 与 EXPECT 签名命中，然后**自己**把 `doc/bugs.md` 的 `status` 翻成 `CLOSED`、`verify_evidence` 指向它自己 | **形式件 / 机器背书**：`verify_evidence` 列的唯一合法载体（`scripts/docs.py:224-244` 只认 `doc/evidence/` 下实有文件）。它证明的是"这条判据当场可重放并通过"，**不含任何人的判断**。状态由脚本翻而非手改，兑现 `workflow/bugs.md` L134「The fixer never sets CLOSED」 |
> | `BUG-0049-closure.md`（本文件） | **人**：closer 手写 | **实质件 / 复验记录**：BUG-0029 guard 明写非仿真类缺陷的 `verify_evidence` 「对这类 bug 是形式件」，须另有实质复验位置——本文件即该位置的数据面：四路复算命令与原始输出、30 格集合差、闭包重建、CW-014 逐 bin 回源、机核门证伪 |
>
> 一句话：**`.log` 是判据的执行回执，本文件是判据本身的推导过程**；判断与 verdict
> 两份都不含，在 `doc/review/REV-034.md`。删掉 `.log` 则 `verify_evidence` 失载体
> （docs-check 红）；删掉本文件则 BUG-0029 guard 要求的实质复验只剩 root_cause 列
> 里的一句转述，30 格集合差底板丢失。

- 复验者：REV-034 的 rev 实例（closer）。**不是** REV-032 / REV-033 / 提案 arch /
  应用 fix 的 orch ⇒ 不变量 3（closer ≠ fixer）。
- **数据源只有两类原始事实**：`sim/out/urgText6/{modlist,modinfo}.txt`（上一张卡
  现场重生的 urg 文本报告，本卡只读）与 `vendor/` RTL 原文。**未采信**
  `M4-coverage-final-sweep.md` §3/§5/§8、`REV-031/032/033` 任何汇总清单——
  BUG-0049 的根因之一正是以汇总清单为输入。
- 未跑任何 sim、未 `make clean`、未触碰任何 `cov.vdb`。

---

## 1. 环境与前置事实

```
$ python3 -c "import sys;sys.path.insert(0,'scripts');import evidence,iverif_config;\
evidence.CFG=iverif_config.load_config();print(evidence.read_version())"
0.4.37

$ sha256sum doc/spec.md ; cat doc/spec.sha256
dad62e082a2be71329954d3daf3f62ac76351ca0e8125ed33121d1d00d5620a2  doc/spec.md
dad62e082a2be71329954d3daf3f62ac76351ca0e8125ed33121d1d00d5620a2
                              # spec pin 相符 ⇒ §0#4 判据口径可用（不变量 4）

$ head -n 20 sim/out/urgText6/dashboard.txt | grep -E "Number of tests|Command line"
Command line: urg -full64 -dir out/cov.vdb -format text -report out/urgText6 \
              -metric line+cond+fsm+tgl+branch+assert
Number of tests: 24
                              # = final-sweep 命令② 的产物，24 基线拓扑场景
```

## 2. 复算命令与输出（逐条实跑）

### ① 首行 CMD —— UNOWNED=∅ 一条命令判据（本文件首行，可原样粘贴）

作用：从原始 urg 报告重建 22×6 全格三态，把每个 <90% 格拿去 `milestone_restructure.md`
§6.3 对照表查归属 token，报差集。退出码 0 且签名行出现即判据成立。

```
RESULT CELLS=132 LT90=30 UNOWNED=0 []
```

尾部 `[]` = 差集为空列表（若非空会逐个打印 `(模块, 类型下标, 实测值)`）。

### ② 三态普查（独立于 ①，只读 modlist，不看任何归属表）

```
$ awk 'index($0,$1)<=2&&$1~/^[0-9]+\.[0-9][0-9]$/&&NF==8&&$NF~/^(axi_xbar|axi_xbar_unmuxed|\
addr_decode|addr_decode_dync|axi_demux|axi_demux_simple|axi_demux_id_counters|counter|\
delta_counter|axi_err_slv|axi_atop_filter|stream_register|axi_mux|axi_id_prepend|rr_arb_tree|\
lzc|fifo_v3|axi_multicut|axi_cut|spill_register|spill_register_flushable|axi_pkg)$/\
{m++;for(i=2;i<=7;i++){c++;if($i=="--")na++;else if($i+0>=90)ok++;else lt++}}\
END{printf "MODULES=%d CELLS=%d NA=%d PASS=%d LT90=%d\n",m,c,na,ok,lt}' \
  sim/out/urgText6/modlist.txt

MODULES=22 CELLS=132 NA=59 PASS=43 LT90=30
```

与 ① 的 `CELLS=132 LT90=30` 互相独立地对上。

### ③ 例化闭包完备性 + 子树限定（spec §0#4 末两句）

```
$ python3 -c "<见下方注*>"
DUT modules with a page: 22   instances outside i_xbar_dut subtree: 0
instance counts: [('addr_decode',12), ('addr_decode_dync',12), ('axi_atop_filter',6),
 ('axi_cut',48), ('axi_demux',6), ('axi_demux_id_counters',12), ('axi_demux_simple',6),
 ('axi_err_slv',6), ('axi_id_prepend',48), ('axi_multicut',48), ('axi_mux',8),
 ('axi_pkg',0), ('axi_xbar',1), ('axi_xbar_unmuxed',1), ('counter',12),
 ('delta_counter',108), ('fifo_v3',26), ('lzc',56), ('rr_arb_tree',28),
 ('spill_register',322), ('spill_register_flushable',322), ('stream_register',6)]
```

\* 脚本逻辑：遍历 `modinfo.txt` 的每个 `Module : X` 段，取其 `Module self-instances :`
清单，统计条数并断言每条实例路径以 `tb_top.i_xbar_dut` 开头。

`modlist.txt` 首部 `Total modules in report: 35`；上表 22 个 DUT 模块页 + 13 个 tb
侧模块页（`tb_top`/`mstport_if`/`slvport_if`/`xbar_cfg_if`/`uvm_pkg`/
`rand_verif_pkg`/`uvm_custom_install_verdi_recording`/6 个 `*_sva`）= 35 逐位对上。

**RTL 侧独立重建闭包**（`grep` 例化点，仅取结构事实）：
`axi_xbar.sv:99/125` → {axi_xbar_unmuxed, axi_mux}；`axi_xbar_unmuxed.sv:101/116/164/195/218/238`
→ {addr_decode×2, axi_demux, axi_err_slv×2, axi_multicut}；`axi_demux.sv:89-189`
→ {spill_register×7, axi_demux_simple}；`axi_demux_simple.sv:210/236/265/355/383/599`
→ {axi_demux_id_counters×2, counter, rr_arb_tree×2, delta_counter}；
`axi_mux.sv:73-451` → {spill_register, axi_id_prepend, rr_arb_tree×2, fifo_v3}；
`axi_err_slv.sv:46/90/123/165/231` → {axi_atop_filter, fifo_v3×3, counter}；
`axi_atop_filter.sv:348` → {stream_register}；`axi_multicut.sv:58` → {axi_cut}；
`axi_cut.sv:49-105` → {spill_register×5}；`addr_decode.sv:92` → {addr_decode_dync}；
`rr_arb_tree.sv:202/211` → {lzc×2}；`counter.sv:28` → {delta_counter}；
`spill_register.sv:31` → {spill_register_flushable}。
**并集 = 21 个被例化模块 + `axi_pkg`（package，仅 1 条内嵌 assert 留痕）= 22**，
与 urg 模块页集合逐个相等 ⇒ **无闭包成员遗漏**（BUG-0049 的"成员蒸发"无第二例）。

### ④ 30 个 <90% 格 → 归属 token 逐格打印（① 的展开形式）

```
$ awk 'FNR==NR{if($0~/^### 6\.3/)f=1; if($0~/^## 7\./)f=0;
   if(f&&$0~/^\|/&&$0!~/---/){n=split($0,c,"|"); if(n>=9){m=c[2]; gsub(/[^a-z0-9_]/,"",m);
   for(i=1;i<=6;i++){v=c[3+i]; gsub(/^[ \t]+|[ \t]+$/,"",v); own[m"#"i]=v}}} next}
   index($0,$1)<=2&&$1~/^[0-9]+\.[0-9][0-9]$/&&NF==8&&$NF~/^(<22 模块名>)$/{
   split("Line Cond Toggle FSM Branch Assert",t," ");
   for(i=2;i<=7;i++){cells++; if($i=="--"||$i+0>=90)continue; lt++;
     o=own[$NF"#"(i-1)];
     if(o!~/CW-[0-9]|BUG-[0-9]|DV-[A-G]/){un++; print "UNOWNED " $NF " " t[i-1] " " $i}
     else print "OWNED " $NF " " t[i-1] " " $i " -> " o}}
   END{printf "RESULT CELLS=%d LT90=%d UNOWNED=%d\n",cells,lt,un+0}' \
  doc/design-prompt/milestone_restructure.md sim/out/urgText6/modlist.txt
```

输出（按 modlist 出现序，30 行 + 结果行；`UNOWNED` 行零条）：

```
OWNED counter                  Toggle 43.48 -> **CW-013+DV-A/DV-G**(43.48)
OWNED stream_register          Line   75.00 -> **CW-014**(75.00)
OWNED stream_register          Toggle 22.00 -> **CW-014+DV-A(D1)**(22.00)
OWNED stream_register          Branch 50.00 -> **CW-014**(50.00)
OWNED axi_atop_filter          Line   48.18 -> **CW-001**(48.18)
OWNED axi_atop_filter          Cond   41.94 -> **CW-001**(41.94)
OWNED axi_atop_filter          Toggle 65.19 -> **CW-001**(65.19)
OWNED axi_atop_filter          FSM    14.29 -> **CW-001**(14.29)
OWNED axi_atop_filter          Branch 41.30 -> **CW-001**(41.30)
OWNED spill_register_flushable Cond   82.49 -> **CW-010+重测-2**(82.49)
OWNED spill_register_flushable Toggle 79.76 -> **CW-010+DV-A/B+重测-2**(79.76)
OWNED spill_register_flushable Assert  0.00 -> **CW-010**(0.00,vacuous)
OWNED delta_counter            Toggle 41.20 -> **CW-013+DV-A/DV-G**(41.20)
OWNED lzc                      Toggle 42.59 -> **CW-011**(42.59)
OWNED axi_demux_id_counters    Line   73.91 -> **DV-G**(73.91)
OWNED axi_demux_id_counters    Toggle 74.06 -> **DV-G**(74.06)
OWNED axi_demux_id_counters    Branch 79.49 -> **DV-G**(79.49)
OWNED fifo_v3                  Cond   80.19 -> **CW-010+重测-1**(80.19)
OWNED fifo_v3                  Toggle 82.09 -> **CW-010+DV-A/B+重测-1**(82.09)
OWNED fifo_v3                  Branch 78.43 -> **CW-010+重测-1**(78.43)
OWNED spill_register           Toggle 88.51 -> **DV-A/B 阴影**(88.51)
OWNED rr_arb_tree              Line   80.00 -> **CW-010**(80.00)
OWNED rr_arb_tree              Toggle 77.45 -> **CW-007/010+DV-A+DV-F**(77.45)
OWNED axi_cut                  Toggle 89.22 -> **DV-A/B 阴影**(89.22)
OWNED axi_id_prepend           Toggle 78.26 -> **CW-012+DV-C**(78.26)
OWNED axi_demux_simple         Cond   82.76 -> **CW-009+DV-E**(82.76)
OWNED axi_err_slv              Toggle 70.22 -> **CW-002/003/004/005/006/007+BUG-0044+DV-A+DV-D**(70.22)
OWNED axi_multicut             Toggle 89.22 -> **DV-A/B 阴影**(89.22)
OWNED addr_decode_dync         Branch 83.33 -> **CW-008**(83.33)
OWNED axi_mux                  Toggle 89.34 -> **CW-002/006/007+BUG-0044+DV-A/B/C**(89.34)
RESULT CELLS=132 LT90=30 UNOWNED=0
```

### ⑤ 归属 token 可解析性（无悬空引用）

§6.3 用到的 20 个 token 逐个回查登记面：`CW-001~014` 均在
`doc/coverage-waivers.md` 表内实有行；`BUG-0044` 在 `doc/bugs.md` L11；
`DV-A~G` 与 `重测-1/2` 均在 `milestone_restructure.md` §6.1 L370–378 有条目。
**MISSING 计 0。**

### ⑥ §6.3 底板反向核对（防凭空格 / 错格 / 张冠李戴）

逐格拿 §6.3 的 token 与括号回抄值去比原始 urg：

```
6.3 rows parsed: 22
closure members missing from 6.3: []
6.3 rows not in closure: []
problems: 0                # STATE MISMATCH 0 处 + VALUE MISMATCH 0 处
```

判据：urg 为 `--` 的格 §6.3 必写 `N/A ⁿ`；≥90 必写 `PASS`；<90 必写 CW/BUG/DV
token；括号回抄的百分比必与 urg 逐位相同。

### ⑦ CW-014 逐 bin 事实回源（`modinfo.txt` L2611–2775）

```
Module : stream_register            SCORE 49.00  LINE 75.00  COND --  TOGGLE 22.00  FSM --  BRANCH 50.00  ASSERT --
Module self-instances : 6 例，全部形如
  tb_top.i_xbar_dut.i_xbar_unmuxed.gen_slv_port_demux[0..5].i_axi_err_slv.genblk1.i_atop_filter.r_resp_cmd

Line   : TOTAL 12/9 = 75.00 ；未覆盖恰 3 行 = 37.9 (valid_o<=0 @clr_i)、38.9 (data_o<=0 @clr_i)、38.11 (data_o<=data_i @reg_ena)
Branch : Branches 8/4 = 50.00 ；L37 [0 1 -] Not Covered、L37 [0 0 0] Not Covered、L38 [0 1 -] Not Covered、L38 [0 0 1] Not Covered
Toggle : Total Bits 50 / Covered 11 = 22.00
         已覆盖 11 = clk_i(2) + rst_ni 0->1(1) + data_i.len[3:0](8)
         未覆盖 39 = clr_i(2)+testmode_i(2) | rst_ni 1->0(1) | valid_i(2)+ready_o(2)+valid_o(2)
                     +ready_i(2)+data_o.len[7:0](16)+reg_ena(2) | data_i.len[7:4](8)
         Condition 节不存在 ⇒ Cond = N/A（无 bin）
```

**账平**：11 + 39 = 50；39 = P1(4) + P3(1) + P2(26) + D1(8)，与 CW-014 的
31 bit Kind-A + 8 bit 定向拆分逐位对上，**无残余未归因位**。

### ⑧ CW-014 引用的 RTL 事实亲验（只读结构，不推期望值）

```
axi_atop_filter.sv:353     .clr_i      (1'b0),          <- P1 tie-off
axi_atop_filter.sv:354     .testmode_i (1'b0),          <- P1 tie-off
axi_atop_filter.sv:143     if (slv_req_i.aw.atop[axi_pkg::ATOP_R_RESP]) begin
axi_atop_filter.sv:147       r_resp_cmd_push_valid = 1'b1;     <- P2 push 门唯一置位点
axi_atop_filter.sv:362     assign r_resp_cmd_push.len = slv_req_i.aw.len;  <- D1 组合馈通
axi_pkg.sv:447             localparam ATOP_R_RESP = 32'd5;
axi_err_slv.sv:45-58       if (ATOPs) begin axi_atop_filter ... i_atop_filter ( ... );
stream_register.sv:34      assign ready_o = ready_i | ~valid_o;
stream_register.sv:35      assign reg_ena = valid_i & ready_o;
doc/spec.md §4 clause 7 (L172-173)  M3 与 M4 全部场景不向译码未命中地址发起任何 ATOP
                                    （送往未命中地址的 AW 恒 aw.atop ≡ '0）
```

⇒ P2 链（`valid_i≡0 → valid_o≡0 → ready_o≡1 → reg_ena≡0`）成立；
⇒ D1 成立：clause 7 只约束 `aw.atop`、对 `aw.len` 无任何限制（全文 L163–197 亲读）。

### ⑨ 机核门证伪（证明关闭证据这道门确实会红）

```
$ python3 -c "import sys;sys.path.insert(0,'scripts');import docs,iverif_config;\
docs.CFG=iverif_config.load_config();\
[ (lambda e: print(repr(c),'->', e or 'ACCEPTED'))([]) or None for c in [] ]"
# 实际调用 docs.check_evidence(候选值, 'BUG-0049 closure', errs)：
'doc/review/REV-034.md'                           -> ['... evidence does not point into doc/evidence/']
'doc/evidence/v0.4.37/BUG-0049-closure.md'        -> ['... evidence file missing: ...']   （写入本文件之前）
'doc/evidence/v0.4.35/M4-coverage-final-sweep.md' -> ACCEPTED
'doc/evidence/v0.4.6/BUG-0040.log'                -> ACCEPTED
```

### ⑩ 机器状态（复验时刻）

```
$ make check
docs-check passed ；chain audit 无新增 gap 形状

$ make check MILESTONE=4
[PASS] 1. all M4 scenarios ✅
[PASS] 2. regress summary registered as evidence
[FAIL] 3. all bugs terminal or ACCEPTED-unexpired — active: BUG-0049, BUG-0048
[PASS] 4. kill coverage: >=1 KILL row tagged M4 (KILL-0005, KILL-0004)
```

---

## 3. 结论

**UNOWNED = ∅ 经独立复算成立**（②④⑥ 三条互相独立的路径同得 `CELLS=132
LT90=30 UNOWNED=0`），闭包 22 成员完备且全部限定在 `i_xbar_dut` 子树内（③），
BUG-0049 点名的 `stream_register` 三格现由 CW-014（Line/Branch 全格 + Toggle
31 bit）与 M6 backlog DV-A(D1)（Toggle 8 bit）具名承接，逐 bin 账平（⑦）、
其引用的 RTL 事实逐条回源无误（⑧）。

⇒ **BUG-0049 的缺陷面（归属丢失）已消除，满足 CLOSED 的实质条件。**

判断、逐项 verdict、guidance 与非阻塞发现（I1–I5）见 `doc/review/REV-034.md`；
关闭应用前置（`fix_commit` 必填 / `verify_evidence` 指向本文件 / BUG-0029 guard
要求的实质复验指针）见该记录 §Overall verdict 的 A1–A4。
