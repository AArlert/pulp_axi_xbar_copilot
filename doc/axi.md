# AXI 基础：从零读懂本项目的 DUT

> **这份文档是什么**：给人看的 AXI4 入门读物，逐层递进，最后落到本仓库的 DUT
> （`axi_xbar`）上。目标是让一个没碰过 AXI 的人读完能看懂 `doc/spec.md` 和
> 那张数据流图。
>
> **这份文档不是什么**：**它不是规格，不得作为 checker 期望值的来源。**
> 本仓库的期望值只有一个来源——sha256 钉住的 `doc/spec.md`（见 `CLAUDE.md`
> 不变量 4）。本文里凡涉及 DUT 行为处一律给出 spec 章节号，请以 spec 为准；
> 本文与 spec 冲突时，spec 赢，并请提 issue 修本文。
>
> 阅读顺序建议：§0 → §6 是协议本身，任何 AXI 项目都通用；§7 起是本项目专属。

### 怎么读这份文档

光讲协议是悬空的——AXI 的很多规则要看到那行 Verilog 才会"啊原来如此"。所以：

- **每节末尾有 `📎 对照代码`**，给出 `vendor/` 里的确切文件与行号。`vendor/`
  是 SHA 锁定的只读快照（`vendor/VENDOR.md`），行号稳定，可以直接跳。
- **[§8](#8-跟着代码走一遍s2-写-m5) 是一次完整的代码走读**：跟一笔写事务从
  S2 走到 M5 再走回来，八站，每站贴真实 RTL。前面所有抽象概念都在那里落地。
  只想快速上手的话，可以 §0 → §8 → 回头补细节。

> ⚠️ 读代码是为了**理解原理**，不是为了**取期望值**。本仓库的红线：checker 的
> 期望值只准从 `doc/spec.md` 推导，**永不从 RTL 抄**（`CLAUDE.md` 不变量 4）。
> 看懂实现之后回到 spec 找条款，这个顺序不能反。

---

## 目录

- [§0 先把命名钉死：M 接 S，永远如此](#0-先把命名钉死m-接-s永远如此)
- [§1 五个通道：AXI 的骨架](#1-五个通道axi-的骨架)
- [§2 VALID/READY 握手：三条铁律](#2-validready-握手三条铁律)
- [§3 一笔事务从头走到尾](#3-一笔事务从头走到尾)
- [§4 Burst 描述符：地址只发一次](#4-burst-描述符地址只发一次)
- [§5 ID 与保序：AXI 最容易搞错的部分](#5-id-与保序axi-最容易搞错的部分)
- [§6 通道间的依赖关系](#6-通道间的依赖关系)
- [§7 映射回本项目的 DUT](#7-映射回本项目的-dut)
- [§8 跟着代码走一遍：S2 写 M5](#8-跟着代码走一遍s2-写-m5)
- [§9 常见误解清单](#9-常见误解清单)
- [附录 A 术语表](#附录-a-术语表)
- [附录 B 继续往下读](#附录-b-继续往下读)

---

## §0 先把命名钉死：M 接 S，永远如此

AXI 是**点对点**协议，一条链路只有两端：

- **master**：发起事务的一端（驱动地址）
- **slave**：接收事务、返回响应的一端

角色由**谁发起**定义，**与数据流方向无关**。读事务里数据是从 slave 流向
master 的，但发起方依然是 master——这一点务必先想清楚，后面所有信号方向都由
它推出来。

因此**一条 AXI 链路的接法永远是 master 接口 ↔ slave 接口**。M 接 M、S 接 S 是
接不上的：valid/ready 的驱动方向整个反了。

### 互连的端口为什么"看起来是反的"

互连（interconnect / crossbar）夹在中间，两侧必须扮演**相反**角色：

| xbar port | xbar's role here | So the other side must be | Signals |
| --- | --- | --- | --- |
| **slave 端口** S0..S5 | slave（收地址、回响应） | 外部 AXI **master**（CPU/DMA） | `slv_ports_req_i` / `slv_ports_resp_o` |
| **master 端口** M0..M7 | master（发地址） | 外部 AXI **slave**（DRAM/外设） | `mst_ports_req_o` / `mst_ports_resp_i` |

**端口名描述的是 xbar 自己在那个端口上扮演的角色，不是"接了谁"。**

```
  外部 CPU/DMA                    axi_xbar                     外部 DRAM/外设
  ┌──────────┐            ┌────────────────────┐            ┌─────────┐
  │AXI master│ ─── AXI ──>│ slave 端口 S0..S5  │            │AXI slave│
  └──────────┘            │        ↓ 交叉矩阵  │            └─────────┘
                          │ master 端口 M0..M7 │ ─── AXI ──>     ↑
                          └────────────────────┘
```

一个立刻能自查的推论：`mst_ports_req_o` 是 **out**、`mst_ports_resp_i` 是
**in**——因为在 master 端口上，请求由 xbar 发出、响应由外部 slave 送回。slave
端口正好相反。**方向永远跟着"谁发起"走**（spec §2.3 端口表）。

本仓库基线：`NoSlvPorts=6`（6 个外部 master）、`NoMstPorts=8`（8 个外部
slave），全部钉定值见 spec §0 行 2。

---

## §1 五个通道：AXI 的骨架

AXI 把一笔事务拆成 **5 条彼此独立**的通道，每条通道自带一对 VALID/READY：

| Channel | Full name | Direction | Payload |
| --- | --- | --- | --- |
| **AW** | Write Address | M → S | 写事务的地址与描述符 |
| **W** | Write Data | M → S | 写数据 beats（含字节使能） |
| **B** | Write Response | S → M | 整笔写的响应（每笔**一拍**） |
| **AR** | Read Address | M → S | 读事务的地址与描述符 |
| **R** | Read Data | S → M | 读数据 beats（**每拍**带响应码） |

"独立"是 AXI 性能的来源：AW 可以连发 10 笔而不等任何 B 回来，R 可以在 AR 还在
发的时候就开始回。这也是它比 AHB/APB 复杂的根本原因——**不能再用"一笔做完再做
下一笔"的心智模型去理解它**。

### 主要字段

AW 与 AR 结构同构，合称 `Ax`：

| Signal | Width | Meaning |
| --- | --- | --- |
| `AxID` | 可配 | 事务 ID —— 保序的唯一依据，见 §5 |
| `AxADDR` | 32 / 64 | burst 的**起始**地址 |
| `AxLEN` | 8 (AXI4) | beat 数 **− 1**（`LEN=0` 表示 1 拍） |
| `AxSIZE` | 3 | 每 beat 字节数 = `2^AxSIZE`，不得超过总线宽度 |
| `AxBURST` | 2 | `FIXED` / `INCR` / `WRAP` |
| `AxCACHE` / `AxPROT` / `AxQOS` / `AxREGION` | — | 属性、权限、QoS、区域提示 |
| `AxLOCK` | 1 | 独占访问（crossbar 不做独占监视，本项目 spec 未涉及） |

数据与响应通道：

- **W**：`WDATA` / `WSTRB`（每字节一位使能）/ `WLAST`（burst 末拍标记）
- **R**：`RDATA` / `RID` / `RRESP`（**每拍都有**）/ `RLAST`
- **B**：`BID` / `BRESP`，**整笔只有一拍**

请特别记住这个**不对称**：

> **读的响应码在每个 beat 上，写的响应码只在最后那一拍 B 上。**

spec §4.3 里 decode error 那句"读出齐 `AxLEN+1` 拍、末拍 `RLAST=1`；写在收齐
W burst 后回单拍 B"说的就是这个不对称——不是 spec 在啰嗦，是协议本身如此。

### 📎 对照代码：五个通道在 RTL 里长什么样

上面那张表不是抽象概念，它就是一组 struct。`vendor/axi/include/axi/typedef.svh`
用宏把五个通道定死：

```systemverilog
// vendor/axi/include/axi/typedef.svh:34   AW 通道 —— 和 §1 的字段表逐项对应
`define AXI_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t, id_t, user_t)  \
  typedef struct packed {                                       \
    id_t              id;                                       \
    addr_t            addr;                                     \
    axi_pkg::len_t    len;      // 8 位 = beat 数 − 1            \
    axi_pkg::size_t   size;     // 3 位 = log2(每 beat 字节数)   \
    axi_pkg::burst_t  burst;    // FIXED / INCR / WRAP           \
    logic             lock;                                     \
    axi_pkg::cache_t  cache;                                    \
    axi_pkg::prot_t   prot;                                     \
    axi_pkg::qos_t    qos;                                      \
    axi_pkg::region_t region;                                   \
    axi_pkg::atop_t   atop;     // ← AXI5 原子操作，见 §7        \
    user_t            user;                                     \
  } aw_chan_t;
```

关键在于**请求与响应是怎么打包的**——这解释了为什么本项目的信号叫
`slv_ports_req_i` / `slv_ports_resp_o` 而不是逐通道的一大把线：

```systemverilog
// vendor/axi/include/axi/typedef.svh:84
`define AXI_TYPEDEF_REQ_T(req_t, aw_chan_t, w_chan_t, ar_chan_t)  \
  typedef struct packed {                                         \
    aw_chan_t aw;  logic aw_valid;   // M → S 的三条通道：payload + VALID
    w_chan_t  w;   logic w_valid;                                 \
    logic     b_ready;               // ← B 是 S → M，所以这边只出 READY
    ar_chan_t ar;  logic ar_valid;                                \
    logic     r_ready;               // ← R 同理                  \
  } req_t;

// vendor/axi/include/axi/typedef.svh:95
`define AXI_TYPEDEF_RESP_T(resp_t, b_chan_t, r_chan_t)  \
  typedef struct packed {                               \
    logic     aw_ready;  logic ar_ready;  logic w_ready;  // ← 三条请求通道的 READY
    b_chan_t  b;  logic b_valid;                        \
    r_chan_t  r;  logic r_valid;                        \
  } resp_t;
```

看这两个 struct 就能把 §0 的方向规则彻底钉死：**`req_t` 装的是"M 往 S 送的
东西"**——三条 M→S 通道的 payload+VALID，加上两条 S→M 通道的 READY。`resp_t`
正好互补。所以：

- 在 xbar 的 **slave 端口**上，`req` 是 **输入**（`slv_ports_req_i`）
- 在 xbar 的 **master 端口**上，`req` 是 **输出**（`mst_ports_req_o`）

同一个 `req_t` 类型，方向由端口角色决定——这就是 §0 那句"方向永远跟着谁发起走"
在代码里的样子（spec §2.3）。

其余通道：`W` 在 `:49`、`B` 在 `:56`、`AR` 在 `:62`、`R` 在 `:76`。翻一眼就能
确认 §1 说的不对称——`b_chan_t` 里没有 `last`，`r_chan_t` 里有 `resp` 也有
`last`。

---

## §2 VALID/READY 握手：三条铁律

每条通道都用同一套握手。**在时钟上升沿，VALID 与 READY 同时为高时，一拍数据
完成传输。**

```
        ┌─┐ ┌─┐ ┌─┐ ┌─┐
clk   ──┘ └─┘ └─┘ └─┘ └──
VALID ____╱‾‾‾‾‾‾‾‾‾╲____
READY ________╱‾‾‾╲______
                ↑
              握手发生在这一拍
```

三条不能违反的规则：

1. **VALID 不得等 READY。** 源端一旦准备好数据就必须拉高 VALID，不许"先看看
   对方 ready 不 ready 再决定"。READY 反过来**可以**等 VALID，也可以提前拉高。
   这条规则的意义是**防止两端互相等待形成死锁**。
2. **VALID 一旦拉高，必须保持到握手完成**，中途不许撤回。
3. **VALID 期间 payload 必须稳定**，不许改数据/地址。

绝大多数 AXI 协议 checker 的第一批断言就是这三条。本仓库的协议 SVA 放在
`tb/sva/`。

> 工具限制备忘：VCS-2018.09-SP2 拒绝 `bind <interface> <module>`，本仓库的协议
> SVA 一律走宿主模块 generate 循环内直接例化，见
> `doc/design-prompt/sva_bind.md` C1.1。

### 📎 对照代码：铁律 1 为什么能防死锁

`spill_register` 是整个设计里出现最多的部件（demux 里 7 个、每个 `axi_cut` 里
5 个），它就是"**在不违反铁律 1 的前提下把时序路径切开**"的标准答案。核心只有
三行：

```systemverilog
// vendor/common_cells/src/spill_register_flushable.sv:90
  // 只要两级寄存器里还有空位就收 —— READY 完全不看 valid_i
  assign ready_o = !a_full_q || !b_full_q;

// :93
  // 只要有货就发 —— VALID 完全不看 ready_i
  assign valid_o = a_full_q | b_full_q;

// :96
  assign data_o  = b_full_q ? b_data_q : a_data_q;
```

请注意 `ready_o` 的表达式里**没有 `valid_i`**，`valid_o` 的表达式里**没有
`ready_i`**——上下游被彻底切断，这正是铁律 1 要的效果。用两级寄存器（A/B）而
不是一级，是为了在切断组合路径的同时**不损吞吐**：一级寄存器一旦下游 stall
就必须让 `ready_o` 拉低，两级则还能再吞一拍。

代价是延迟：每过一个 spill_register 就多一拍。这就是 spec §7 `LatencyMode` 在
配置的东西，也是 spec §7.4「延迟不敏感原则」存在的原因——**同一个功能，换个
`LatencyMode` 拍数就全变，所以 checker 不准数拍**。

---

## §3 一笔事务从头走到尾

### 写事务

```
M ──AW(addr, len=3, id=5)──> S      地址与描述符
M ──W(data0)───────────────> S      ┐
M ──W(data1)───────────────> S      │ 4 个 beat
M ──W(data2)───────────────> S      │
M ──W(data3, WLAST=1)──────> S      ┘
M <───────B(id=5, OKAY)───── S      整笔一个响应
```

### 读事务

```
M ──AR(addr, len=3, id=7)──> S
M <──R(data0, id=7, OKAY)─── S      ┐
M <──R(data1, id=7, OKAY)─── S      │ 4 个 beat
M <──R(data2, id=7, OKAY)─── S      │ 每拍都有 RRESP
M <──R(data3, id=7, OKAY, RLAST=1)─ S ┘
```

注意 `len=3` 是 **4 拍**——`AxLEN` 是 beat 数减一。这是最常见的低级错误之一。

---

## §4 Burst 描述符：地址只发一次

burst 内每个 beat 的地址由 `AxADDR + AxBURST + AxSIZE` 推出来，**不再逐拍传
地址**。这是 AXI 带宽效率的来源。

### 三种 burst 类型

| Type | Address behavior | Typical use |
| --- | --- | --- |
| `INCR` | 逐 beat 递增 `2^AxSIZE` | 内存访问，最常用 |
| `FIXED` | 地址不变，反复打同一地址 | FIFO / 外设寄存器 |
| `WRAP` | 递增到边界后回绕，长度只能是 2/4/8/16 | cache line fill |

### 两条硬约束

**① 一个 burst 不得跨越 4KB 边界。**

这条约束是为了保证一个 burst 不会跨到另一个 slave 的地址空间去。它**直接决定
了本项目的路由模型**：地址译码只用起始地址 `AxADDR` 查一次表（spec §3），如果
允许跨 4KB，一笔 burst 的后半程可能属于另一个 master 端口，整套"一笔事务对应
一条路径"的参考模型就崩了。

**② burst 长度上限随类型不同。**

- `INCR` 最长 **256** beats（`AxLEN` 8 位）
- `FIXED` / `WRAP` 最长 **16** beats
- AXI3 时代 `AxLEN` 只有 4 位，所有类型上限都是 16

另外 `AxSIZE` 决定每 beat 的字节数（`2^AxSIZE`，1..128 字节），且**不得超过
总线数据宽度**。基线 `AxiDataWidth=64` 位 = 8 字节，故 `AxSIZE ≤ 3`。

---

## §5 ID 与保序：AXI 最容易搞错的部分

这是 AXI 的精华，也是本项目验证的核心难点。

### 5.1 三条基本规则

1. **同 ID、同方向**的事务，响应**必须按发起顺序返回**。
2. **不同 ID** 之间**没有任何顺序保证**——slave 可以随意乱序完成，R beats 可以
   在不同 ID 之间交织。
3. **读与写之间没有顺序保证**。想要顺序，得靠 master 自己等。

所以要建立正确的心智模型：

> **ID 不是"事务编号"，而是"顺序域标签"。**
> 同一个 ID 是一条有序队列；不同 ID 之间完全解耦。
> master 想要并行性就用不同 ID，想要顺序就复用同一个 ID。

一个 AXI4 特有的点：**AXI4 取消了 `WID`，不允许写数据交织。** 所以 master 发出
的 W burst 必须严格按它发出 AW 的顺序排队，一个 burst 发完才能发下一个。AXI3
有 `WID` 且允许交织。spec §5.5.1 记的就是这条性质。

### 5.2 响应怎么找到回家的路：ID 前缀机制

crossbar 进去的时候**不记路**——它靠 ID。事务从 slave 端口 `i` 出去时，`i` 被
拼进事务 ID 的**高位**（spec §5.1）：

```
slave 端口侧 ID:  [   5 位原始 ID   ]                  (AxiIdWidthSlvPorts = 5)
master 端口侧 ID: [ 3 位端口号 i ][ 5 位原始 ID ]      (5 + ⌈log₂6⌉ = 8 位)
                    ↑
                  回家的钥匙
```

响应回来时 `axi_mux` 剥出高位就知道该送回哪个 slave 端口。这同时保证了不同
slave 端口在 master 端口侧的 ID 空间**互不相交**——否则两个 CPU 都用 ID=3，
响应就分不清是谁的了。

master 端口 ID 宽度因此**必须**是
`AxiIdWidthSlvPorts + $clog2(NoSlvPorts)`（spec §5.1.1）。

#### 📎 对照代码：整套机制就是两行 Verilog

**出去时拼前缀**——`axi_mux` 为每个 slave 端口例化一个 `axi_id_prepend`：

```systemverilog
// vendor/axi/src/axi_id_prepend.sv:89
  mst_aw_chans_o[i].id = {pre_id_i, slv_aw_chans_i[i].id[AxiIdWidthSlvPort-1:0]};
  mst_ar_chans_o[i].id = {pre_id_i, slv_ar_chans_i[i].id[AxiIdWidthSlvPort-1:0]};
```

`pre_id_i` 从哪来？就是 generate 循环的下标：

```systemverilog
// vendor/axi/src/axi_mux.sv:227
        .pre_id_i ( switch_id_t'(i) ),   // i = 源 slave 端口号
```

**回来时剥前缀**——B 通道：

```systemverilog
// vendor/axi/src/axi_mux.sv:387
    assign slv_b_chans  = {NoSlvPorts{mst_b_chan}};              // 广播给所有端口
    assign switch_b_id  = mst_b_chan.id[SlvAxiIDWidth+:MstIdxBits];  // 剥出高位
    assign slv_b_valids = (mst_b_valid) ? (1 << switch_b_id) : '0;   // 只给一个端口拉 VALID
```

R 通道一模一样（`:445`，只是把 `b` 换成 `r`）。

**这三行就是"响应怎么找到回家的路"的全部**。payload 广播给所有 slave 端口，
`1 << switch_b_id` 让只有一个端口看到 VALID——所以"路由"在这里根本不是查表，
而是**一次移位**。ID 高位就是端口号，剥出来直接当 one-hot 的移位量用。

顺带解释了 spec §5.1.4 那句"ID 前缀使不同 slave 端口拥有互不相交的 ID 空间"
为什么是**必须**的：如果两个 slave 端口能产出同样的高位，`1 << switch_b_id`
就会把响应送错人，而且**错得悄无声息**——没有任何校验能发现。

### 5.3 为什么会 stall

这个 crossbar **没有 reorder buffer**（spec §5.2.3）。所以当同一个 slave 端口
先后发出两笔**同 ID、同方向、但目标是不同 master 端口**的事务时，第二笔必须等
第一笔完成——否则两个下游 slave 各自按自己节奏回，响应到达 slave 端口时就乱序
了，违反 §5.1 规则 1。

### 5.4 一个必须知道的坑：假冲突

判定"同 ID"时**只比较低 `AxiIdUsedSlvPorts` 位**（基线 3 位，而 ID 有 5 位）。
于是 `ID=0b00011` 和 `ID=0b01011` 会被当成同一个 ID 桶，产生**假冲突 stall**
（spec §5.2.2）。

这只损失性能、**不影响正确性**，是拿面积换来的。基线配置故意设成 `3 < 5`，
就是为了让这条路径被测到。

---

## §6 通道间的依赖关系

AXI4 刻意把依赖砍到最少，**只有这三条**：

- **B 必须晚于 AW 和 WLAST 的握手**（写完了才能回响应）
- **R 必须晚于 AR 的握手**
- **AW 与 W 之间没有顺序要求**——W 可以先于 AW 到达。很多 slave 内部还是要等
  AW 才能处理，但协议层面不许**要求**这个顺序。

**没有依赖的地方绝不能加断言。** 这直接关系到本仓库的一条纪律：spec §7.4 的
「延迟不敏感原则」——checker 只准断言"发生了什么、顺序如何"，不准断言"第几拍
发生"。`LatencyMode` 一改拍数就全变了，但功能正确性不变。

一个具体后果（spec §5.2.1、BUG-0013 裁决）：基线 `LatencyMode=CUT_ALL_AX` 在
核心判决逻辑**之前**放了 `SpillAw`/`SpillAr` 弹性缓冲，所以"第二笔被 stall"这
件事在外部边界上**看不到即时的握手拒绝**。判决必须锚定**完成序**，不能断言
"第二笔的 AW 握手迟于第一笔完成"。

---

## §7 映射回本项目的 DUT

现在再看这张图就通了：

![axi_xbar 请求/响应数据流](attach/axi_xbar_dataflow.svg)

图里几处需要对上号的地方：

- **最左一列 S0..S5** 是外部 AXI **master**，接在 xbar 的 **slave 端口**上
  （§0 那条命名规则）。
- **最下一排 M0..M7** 是外部 AXI **slave**，接在 xbar 的 **master 端口**上。
- **紫色虚线框内的绿格**才是交叉矩阵，`NoSlvPorts × NoMstPorts = 48` 格，
  每格 `[i][j]` 是 slave 端口 `i` 与 master 端口 `j` 之间那条唯一路径。
- **右侧红色虚线框里的红列不属于交叉矩阵**——它是 `axi_demux` 多出的第
  `NoMstPorts` 路，接本 slave 端口专属的 decode error 从机。事务在那里终结，
  没有对应的 master 端口。

### 概念对照表

| AXI concept | In `axi_xbar` | spec |
| --- | --- | --- |
| 地址 → 选中哪个 slave | `addr_decode` 查 `addr_map_i`（每 slave 端口 AW/AR 各一个） | §3 |
| 地址查不到 | 路由到本端口的 `axi_err_slv`，回 `DECERR` | §4 |
| 一个 master 的请求分给多个 slave | `axi_demux`（`NoMstPorts+1` 路，多出的那路给 err_slv） | — |
| 多个 master 抢同一个 slave | `axi_mux` 里的 `rr_arb_tree` 轮询仲裁 | §5.5 |
| 响应怎么找回发起者 | ID 高位前缀 = 源 slave 端口号 | §5.1 |
| 同 ID 保序 | 无 reorder buffer → stall | §5.2 |
| 在飞事务上限 | 按（ID 桶 × 方向）分桶计数 | §5.4 |
| 流水线深度 / 时序 | `LatencyMode` + `PipelineStages` | §7 |
| 稀疏连接 | `Connectivity[i][j]` | §8 |
| AXI5 原子操作 | `aw.atop != '0`，原子读要求 B 和 R 都回 | §6 |

### 响应码：四种

| `xRESP` | Name | Meaning |
| --- | --- | --- |
| `2'b00` | `OKAY` | 正常完成 |
| `2'b01` | `EXOKAY` | 独占访问成功（仅独占事务用） |
| `2'b10` | `SLVERR` | slave 收到了但出错了 |
| `2'b11` | `DECERR` | **地址译码失败**——没有任何 slave 认领这个地址 |

`DECERR` 通常由**互连**产生，不是 slave 产生的——因为压根没有 slave 被选中。
这正是本项目 `axi_err_slv` 的角色：AXI 不允许请求悬空不应答，所以地址查不到时
必须有个部件把事务吞掉并回一个合法的 `DECERR`（spec §4）。

设计上"错误也要有个终点"是这么来的：

- **地址查不到** → 每个 slave 端口专属的 decode error 从机（图中红列）
- **这条路没修**（`Connectivity[i][j]=0`）→ 该格改例化一个 `axi_err_slv`

两者是同一类部件（只差 `MaxTrans` 参数），但**期望的响应形态只有前者在 spec
里有定义**；未连通格的应答行为许可来源未定义（spec §8.2），本项目不写 checker，
而是用环境约束让"译码到非连通 master 端口"根本不可发生（spec §8.3）。

---

## §8 跟着代码走一遍：S2 写 M5

前面全是概念。这一节跟一笔写事务从 S2 出发、经交叉矩阵格 `[2][5]` 到达 M5、
再原路走回来，**每站贴真实 RTL**——就是图上那条蓝线加橙线。

读之前先记住这张分工图：

```
axi_xbar.sv                     顶层：把 unmuxed 的输出按列喂给 mux
├─ axi_xbar_unmuxed.sv          译码 + 分流 + 交叉矩阵
│  ├─ addr_decode.sv              第 1 站：地址 → master 端口号
│  ├─ axi_demux.sv                第 2-3 站：选路 + 保序 stall
│  ├─ axi_multicut.sv             第 4 站：流水线切割
│  └─ axi_err_slv.sv              岔路：地址查不到时的终点
└─ axi_mux.sv                   第 5-6 站：仲裁 + 拼 ID + 回程分流
```

---

### 第 1 站 `addr_decode`：地址怎么变成端口号

事务刚进 S2，第一件事是查地址表。整个译码就是一个 `always_comb` 里的循环：

```systemverilog
// vendor/common_cells/src/addr_decode_dync.sv:101
  always_comb begin
    // 默认值：没使能 default port 就直接是 decode error
    dec_valid_o = 1'b0;
    dec_error_o = (en_default_idx_i) ? 1'b0 : 1'b1;
    idx_o       = (en_default_idx_i) ? default_idx_i : '0;

    for (int unsigned i = 0; i < NoRules; i++) begin
      if (!Napot && (addr_i >= addr_map_i[i].start_addr) &&
          ((addr_i < addr_map_i[i].end_addr) || (addr_map_i[i].end_addr == '0))) begin
        dec_valid_o = 1'b1;
        dec_error_o = 1'b0;
        idx_o       = idx_t'(addr_map_i[i].idx);   // ← 命中的 rule 指向哪个 master 端口
      end
    end
  end
```

三个能立刻确认的事实（都是 spec §3 的条款）：

1. **区间是左闭右开**：`>= start_addr` 且 `< end_addr`。`end_addr == '0` 是
   特例，表示"一直到地址空间末尾"。
2. **循环不 break**：多条 rule 同时命中时，**下标最大的那条赢**。所以地址表
   重叠不是语法错误，是**静默的优先级**。
3. **`en_default_idx_i` 一开，`dec_error_o` 恒 0**——default master port 使能
   后就不可能有 decode error 了。这正是 spec §3.3 / §4.2 那句"且该端口未使能
   default master port"的由来。

还有一条前面埋过的伏笔在这里收口：**译码只看 `addr_i` 一个地址**，也就是
burst 的起始地址。这就是为什么 §4 那条"burst 不得跨 4KB 边界"对本项目是**结构
性前提**——不是风格建议。

📎 `addr_decode.sv:92` 是外壳，实际逻辑全在 `addr_decode_dync.sv`。

---

### 第 2 站 select：decode error 怎么变成"第 8 路"

译码结果要变成 demux 的选择信号。这两行是整张图右侧红列的**全部来历**：

```systemverilog
// vendor/axi/src/axi_xbar_unmuxed.sv:131
    assign slv_aw_select = (dec_aw_error) ?
        mst_port_idx_t'(Cfg.NoMstPorts) : mst_port_idx_t'(dec_aw);
    assign slv_ar_select = (dec_ar_error) ?
        mst_port_idx_t'(Cfg.NoMstPorts) : mst_port_idx_t'(dec_ar);
```

译码失败时 select 被赋成 `Cfg.NoMstPorts`（基线 = 8）——一个**比任何真实
master 端口号都大 1** 的值。而 demux 恰好被例化成 `NoMstPorts + 1` 路：

```systemverilog
// vendor/axi/src/axi_xbar_unmuxed.sv:174
      .NoMstPorts ( Cfg.NoMstPorts + 1 ),
// :209   第 NoMstPorts 路接给本端口专属的错误从机
      .slv_req_i  ( slv_reqs[i][Cfg.NoMstPorts]  ),
      .slv_resp_o ( slv_resps[i][cfg_NoMstPorts] ),
```

所以"decode error"在硬件里**不是一个特殊的错误分支，而就是多出来的一个普通
出口**。图上那个红列画在矩阵框外，理由就是这段代码——它在
`gen_slv_port_demux` 循环里，而交叉矩阵是另一对循环
`gen_xbar_slv_cross` / `gen_xbar_mst_cross`（`:215`），`j` 只跑到
`NoMstPorts-1`。

---

### 第 3 站 `axi_demux`：扇出很无聊，stall 才是重点

扇出本身平淡无奇——一个 for 循环，只给选中那路拉 VALID：

```systemverilog
// vendor/axi/src/axi_demux_simple.sv:417
      mst_reqs_o = '0;
      for (int unsigned i = 0; i < NoMstPorts; i++) begin
        mst_reqs_o[i].aw       = slv_req_i.aw;   // payload 广播给所有出口
        mst_reqs_o[i].aw_valid = 1'b0;
        if (aw_valid && (slv_aw_select_i == i)) begin
          mst_reqs_o[i].aw_valid = 1'b1;         // 只有选中的那路 VALID
        end
      end
```

跟 §5.2 回程那段 `1 << switch_b_id` 是同一个套路：**payload 广播、VALID 独热**。

真正值得读的是**这个 AW 什么时候才被允许放行**。§5.3 讲了半天的"保序
stall"，落到代码就是一个 `if` 的三个条件：

```systemverilog
// vendor/axi/src/axi_demux_simple.sv:168
        // 条件 A：ID 计数器和 W 计数器都没满
        if (!aw_id_cnt_full && (w_open != {IdCounterWidth{1'b1}}) &&
            (!(ar_id_cnt_full && slv_req_i.aw.atop[axi_pkg::ATOP_R_RESP]) || !AtopSupport)) begin
          if (slv_req_i.aw_valid &&
                // 条件 B：还有 W 没发完时，新 AW 不许换出口
                ((w_open == '0) || (w_select == slv_aw_select_i)) &&
                // 条件 C：同 ID 桶已经绑定了出口时，新 AW 必须去同一个出口
                (!aw_select_occupied || (slv_aw_select_i == lookup_aw_select))) begin
            aw_valid = 1'b1;   // ← 放行
```

**条件 C 就是 spec §5.2 的全部。** "同 ID、同方向、目标不同 master 端口的第二
笔要等第一笔完成"——`aw_select_occupied` 表示这个 ID 桶当前绑着一个出口，
`lookup_aw_select` 是绑的哪个。目标一样就放行，不一样就卡住。这个 crossbar
**没有 reorder buffer**，只能靠这一行防止响应乱序。

**条件 B 是另一件事，很多人会跟条件 C 搞混**：它防的是 **W 通道死锁**。因为
AXI4 的 W 通道**没有 ID**（§5.1 那条"AXI4 取消了 WID"），W beats 只能按 AW 的
顺序走。所以只要还有 AW 的 W 没发完（`w_open != 0`），新 AW 就不能指向别的
出口——否则后面来的 W 会被送到错误的下游。

> **这就是"结合代码才看得懂原理"的典型例子**：光看协议文档，"AXI4 取消 WID"
> 像是一条无关痛痒的版本差异；看到条件 B 才明白它直接约束了 crossbar 什么时候
> 能换向。

至于"同 ID"到底怎么判，看 `lookup` 用了几位就知道：`AxiLookBits` 参数由
`Cfg.AxiIdUsedSlvPorts` 喂进来（`axi_xbar_unmuxed.sv:176`），基线只有 3 位而
ID 有 5 位——§5.4 说的**假冲突**就是从这里来的。

---

### 第 4 站 `axi_multicut`：最无聊的一站

格 `[2][5]` 里是什么？如果 `Connectivity[2][5]=1`（基线全连通），就是纯粹的
流水线：

```systemverilog
// vendor/axi/src/axi_multicut.sv:43
  if (NoCuts == '0) begin : gen_no_cut
    assign mst_req_o = slv_req_i;     // 直通，一根线
  end else begin : gen_axi_cut
    for (genvar i = 0; i < NoCuts; i++) begin : gen_axi_cuts
      axi_cut #( ... )                // 每级 = 5 个 spill_register
```

而 `axi_cut` 就是把 §2 那个 spill_register 在五条通道上各放一个
（`axi_cut.sv:49/63/77/91/105`）。

**只加延迟，不改数据**——这一站不改变任何功能行为，只改拍数。也正因如此，
spec §7.4 才敢说"周期数未定义、checker 必须延迟不敏感"。

---

### 第 5 站 `axi_mux`：仲裁、拼 ID、W 跟随

矩阵第 5 列的 6 个格子（`[0][5]`..`[5][5]`）汇进 `axi_mux 5`。它干三件事：

**① 轮询仲裁**——AW 和 AR 各一个 `rr_arb_tree`（`axi_mux.sv:264` / `:409`），
决定这一拍放哪个 slave 端口走。

**② 拼 ID**——见 §5.2 的 `axi_id_prepend`。

**③ 让 W 跟上 AW**——这是最容易被忽略的一环。AW 仲裁完了，后面的 W beats 怎么
知道该跟谁走？靠一个 FIFO 记住每次 AW 的胜者：

```systemverilog
// vendor/axi/src/axi_mux.sv:317
    fifo_v3 #(
      .DEPTH ( MaxWTrans   ),
      .dtype ( switch_id_t )     // 只存一个端口号
    ) i_aw_fifo (
      // :329  AW 握手时把"赢家的端口号"推进去
      .data_i ( mst_aw_chan.id[SlvAxiIDWidth+:MstIdxBits] ),
```

注意它存的东西：**从刚拼好的 ID 里再把高位剥出来**。同一个"端口号"信息在这里
被用了三次——拼进 ID（找回家的路）、推进 FIFO（让 W 跟上）、回程时移位
（分流响应）。

> 这就解答了 spec §5.4.2 那条容易踩的坑：`MaxSlvTrans` 经 `axi_xbar.sv:141`
> 映射成的 `MaxWTrans`，**是这个 FIFO 的深度**，不是什么"每 ID 在飞上限"。
> 看一眼 `.DEPTH ( MaxWTrans )` 就一目了然——mux 侧根本不存在按 ID 分桶的计数
> 机制。这条结论是 BUG-0016 / REV-007 查出来的。

---

### 第 6 站 回程：B 沿原路走回 S2

M5 回一个 B。`axi_mux` 剥 ID 高位 → 得到 `2` → `1 << 2` → 只有 S2 那路看到
VALID（代码见 §5.2 的 `📎`）。B 一路退回格 `[2][5]`、退回 demux，demux 侧用
`rr_arb_tree` 在 `NoMstPorts+1` 路回程中仲裁（`axi_demux_simple.sv:265`），
最后从 S2 吐给外部 master。

**全程原路返回，不重新查地址表**——因为路由信息已经藏在 ID 里了。

---

### 岔路：如果地址根本查不到

那么第 2 站的 select 会是 8，事务进入本端口的 `axi_err_slv`，在那里终结。它怎
么造出"`AxLEN+1` 拍、末拍 `RLAST=1`"？

先在 AR 握手时把 ID 和长度存进 FIFO：

```systemverilog
// vendor/axi/src/axi_err_slv.sv:158
  assign r_fifo_push       = err_req.ar_valid & ~r_fifo_full;
  assign err_resp.ar_ready = ~r_fifo_full;      // ← 只要 FIFO 没满就照单全收
  assign r_fifo_inp.id     = err_req.ar.id;
  assign r_fifo_inp.len    = err_req.ar.len;    // ← 记住要回几拍
```

然后用一个倒数计数器逐拍吐 R：

```systemverilog
// vendor/axi/src/axi_err_slv.sv:183
  always_comb begin : proc_r_channel
    err_resp.r.id   = r_fifo_data.id;      // ID 原样返回
    err_resp.r.data = RespData;
    err_resp.r.resp = Resp;                // ← 例化时钉成 RESP_DECERR
    if (r_busy_q) begin
      err_resp.r_valid = 1'b1;
      err_resp.r.last  = (r_current_beat == '0);   // 倒数到 0 就是末拍
      ...
```

`err_resp.ar_ready = ~r_fifo_full` 那行就是 spec §4.3 说的 **absorb**——错误
从机不是"拒收"，而是**照单全收再回错误**。AXI 不允许请求悬空不应答，这是唯一
合法的做法。

> ⚠️ **一个必须知道的坑，正好说明为什么期望值不能从 RTL 抄。**
> 上面代码里的 `RespData` 是参数，`axi_err_slv.sv:24-25` 的默认值是
> `RespWidth = 64` / `RespData = 64'hCA11AB1EBADCAB1E`，而 `axi_xbar_unmuxed`
> 例化时**没有覆盖它**。但上游文档 `vendor/axi/doc/axi_xbar.md` 和据此蒸馏的
> spec §4.4 都写的是 `32'hBADCAB1E` 零扩展/截断。
>
> **文档与 RTL 在这里对不上。** 本仓库的规矩很清楚：期望值只从 spec 推导，
> M3 的 DE01 场景跑起来若失配，按 `DUT_BUG` 分诊、走上游 issue——**而不是回头
> 把 spec 改成 RTL 的样子**（`CLAUDE.md` 不变量 4、`workflow/bugs.md`）。
> 如果当初"结合代码写 spec"，这个缺陷就被永久掩盖了。

---

### 代码路线图

想自己再走一遍时的索引：

| File | 负责什么 | 先看哪几行 |
| --- | --- | --- |
| `vendor/axi/include/axi/typedef.svh` | 五通道 struct 定义 | `34` / `84` / `95` |
| `vendor/axi/src/axi_xbar.sv` | 顶层，unmuxed 输出按列喂 mux | `141`（`MaxSlvTrans`→`MaxWTrans`） |
| `vendor/axi/src/axi_xbar_unmuxed.sv` | 译码 + demux + 交叉矩阵 | `131`（select）· `215`（矩阵 generate） |
| `vendor/common_cells/src/addr_decode_dync.sv` | 地址匹配 | `101`（整个 always_comb） |
| `vendor/axi/src/axi_demux_simple.sv` | 选路 + 保序 stall | `168`（三个条件）· `417`（扇出） |
| `vendor/axi/src/axi_mux.sv` | 仲裁 + 拼 ID + 回程 | `227` · `317` · `387` · `445` |
| `vendor/axi/src/axi_id_prepend.sv` | ID 拼接 | `89` |
| `vendor/axi/src/axi_err_slv.sv` | 错误应答 | `158` · `183` |
| `vendor/common_cells/src/spill_register_flushable.sv` | 握手切割 | `90` |

---

## §9 常见误解清单

先记下来，能省掉大量 debug 时间：

| ❌ 错误理解 | ✅ 正确理解 |
| --- | --- |
| xbar 的 master 端口接外部 master | 反了。端口名说的是 **xbar 自己**的角色 |
| ID 是事务编号，得唯一 | ID 是**顺序域标签**；复用 ID 恰恰是要求顺序的手段 |
| `AxLEN=4` 表示 4 拍 | 是 **5 拍**，`AxLEN` 是 beat 数**减一** |
| 写完 W 就算完成 | 没收到 **B** 就不算完成 |
| R 只在最后一拍有响应码 | 反了。**R 每拍都有 RRESP，B 才是整笔一拍** |
| VALID 要等对面 READY | 违反握手第一定律，会**死锁** |
| burst 可以随便跨地址 | **不得跨 4KB 边界** |
| 不同 ID 的响应会按发起顺序回 | 不同 ID 之间**无任何顺序保证** |
| `MaxMstTrans=10` 就是在飞上限 10 | 是计数器**定宽**参数，有效上限 = `2^⌈log₂10⌉−1 = 15`（spec §5.4.1） |

---

## 附录 A 术语表

| Term | 含义 |
| --- | --- |
| **beat** | 一次 VALID/READY 握手传输的一拍数据 |
| **burst** | 一笔事务包含的连续 beats（`AxLEN+1` 拍） |
| **transaction / 事务** | 一笔完整的读或写，从 `Ax` 发出到响应收齐 |
| **in-flight / 在飞** | 已发出但响应尚未收齐的事务 |
| **outstanding** | 同「在飞」，强调可以同时有多笔未完成 |
| **interleaving / 交织** | 不同事务的 beats 在通道上交错出现（AXI4 的 R 允许，W 不允许） |
| **decode error** | 地址不匹配任何 rule 且未使能 default master port，回 `DECERR` |
| **ATOP** | AXI5 原子操作，由 `aw.atop != '0` 的 AW 发起（spec §6） |
| **spill register** | 一种全握手的一拍缓冲，用来切时序路径且不损吞吐 |
| **round-robin** | 轮询仲裁；本项目**只准断言无饿死，不准断言具体授权序**（spec §5.5.4） |

---

## 附录 B 继续往下读

按由浅入深排：

1. **本文 §0–§6** —— 协议本身，任何 AXI 项目通用
2. **`README.md` 的「数据流概览」小节** —— 请求/响应四步走 + 设计动机
3. **`README.md` 的「DUT 模块层级」小节** —— 从 `axi_xbar` 一路追到
   `common_cells` 叶子的例化树
4. **`doc/spec.md`** —— 本项目钉死的行为规格（sha256 pin）。其中
   **§5（ID 与保序）** 和 **§7.4（延迟不敏感）** 是这个 DUT 最难的两节，值得
   逐条读
5. **`doc/testplan.md`** —— 场景真值表，看 spec 的每一条是怎么变成可跑场景的
6. **`vendor/axi/doc/axi_xbar.md`**（以及 `axi_demux.md` / `axi_mux.md`）——
   上游原文，spec 的许可来源
7. **ARM IHI 0022 AXI Protocol Specification** —— 协议原始文本，前面所有关于
   协议本身的说法最终都以它为准
