# Pipelined RISC-V CPU (5-stage) 项目讲解

本文假设你没有计算机体系结构背景，从前置概念开始，逐步解释这个项目在做什么、每个文件负责什么、5-stage pipeline 如何工作，以及当前 RTL 里需要注意的限制。

## 1. 这个项目是什么

这个 folder 实现的是一个简化版 **5-stage pipelined RISC-V RV32I CPU**。

简单说，它是一个可以执行一部分 RISC-V 指令的处理器 RTL 设计。RTL 用 SystemVerilog 写成，描述的是硬件电路，而不是普通软件程序。

这个 CPU 的目标结构是经典五级流水线：

```text
IF -> ID -> EX -> MEM -> WB
```

这五级分别表示：

| Stage | 全称 | 作用 |
| --- | --- | --- |
| IF | Instruction Fetch | 根据 PC 从 instruction memory 取指令 |
| ID | Instruction Decode | 解析指令、读寄存器、生成控制信号 |
| EX | Execute | ALU 运算、地址计算、branch 判断 |
| MEM | Memory Access | load/store 访问 data memory |
| WB | Write Back | 把结果写回 register file |

注意：虽然叫 5-stage，但代码里会看到：

```text
IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
```

这里真正的 stage 只有 `IF/ID/EX/MEM/WB` 五个。中间的 `IF/ID`、`ID/EX`、`EX/MEM`、`MEM/WB` 是 **pipeline register**，不是新的 stage。它们负责把一个 stage 的结果保存一拍，再交给下一个 stage。

## 2. 必要前置知识

### 2.1 CPU 执行指令的基本过程

CPU 执行一条指令，通常需要做这些事情：

1. 找到下一条指令的地址，也就是 `PC`。
2. 从 instruction memory 取出 instruction。
3. 解析 instruction 的字段，例如 opcode、rs1、rs2、rd、immediate。
4. 从 register file 读取源寄存器。
5. 用 ALU 做计算。
6. 如果是 load/store，就访问 data memory。
7. 如果有结果，就写回 register file。

单周期 CPU 会在一个超长 clock cycle 内完成所有步骤。流水线 CPU 把这些步骤拆成多个 stage，让多条指令重叠执行。

### 2.2 什么是 PC

`PC` = Program Counter。

它保存当前要取的 instruction 地址。RISC-V 普通 32-bit 指令长度是 4 bytes，所以正常情况下：

```text
PC_next = PC + 4
```

如果遇到 branch 或 jump，PC 就不再是 `PC + 4`，而是跳到目标地址。

### 2.3 什么是 register file

RISC-V 有 32 个通用寄存器：

```text
x0, x1, x2, ..., x31
```

其中 `x0` 永远是 0。写入 `x0` 的结果会被忽略。

register file 通常有：

- 两个读端口：同时读 `rs1` 和 `rs2`
- 一个写端口：写回 `rd`

例如：

```assembly
add x3, x1, x2
```

意思是：

```text
x3 = x1 + x2
```

这里：

- `rs1 = x1`
- `rs2 = x2`
- `rd = x3`

### 2.4 什么是 ALU

`ALU` = Arithmetic Logic Unit，算术逻辑单元。

它负责执行：

- 加法：`ADD`
- 减法：`SUB`
- 与：`AND`
- 或：`OR`
- 异或：`XOR`
- 移位：`SLL/SRL/SRA`
- 比较：`SLT/SLTU`

在这个项目里，ALU 是组合逻辑，输入变化后结果立即由组合电路算出。

### 2.5 什么是 opcode、funct3、funct7

RISC-V 指令是 32-bit 编码。CPU 需要从 instruction 的不同 bit 字段里读出含义。

常见字段包括：

| 字段 | 位置 | 作用 |
| --- | --- | --- |
| opcode | `inst[6:0]` | 判断指令大类 |
| rd | `inst[11:7]` | 目标寄存器 |
| funct3 | `inst[14:12]` | 进一步区分指令 |
| rs1 | `inst[19:15]` | 源寄存器 1 |
| rs2 | `inst[24:20]` | 源寄存器 2 |
| funct7 | `inst[31:25]` | 进一步区分 R-type 指令 |

例如 `ADD` 和 `SUB` 的 opcode、funct3 相同，主要靠 `funct7` 区分。

### 2.6 什么是 immediate

`immediate` 是 instruction 里直接编码的常数。

例如：

```assembly
addi x1, x0, 5
```

意思是：

```text
x1 = x0 + 5
```

这里 `5` 就是 immediate。

不同指令格式的 immediate 分布在 instruction 的不同 bit 位置，所以 ID 阶段需要根据 opcode 生成正确的 `id_imm`。

## 3. 为什么需要流水线

如果每条指令都完整执行完，再执行下一条，吞吐率会很低。

流水线的思想是：把一条指令的执行拆成多个 stage，让不同指令同时处在不同 stage。

例如：

```text
cycle 1: inst1 IF
cycle 2: inst1 ID   inst2 IF
cycle 3: inst1 EX   inst2 ID   inst3 IF
cycle 4: inst1 MEM  inst2 EX   inst3 ID   inst4 IF
cycle 5: inst1 WB   inst2 MEM  inst3 EX   inst4 ID   inst5 IF
```

理想情况下，流水线填满后，每个 cycle 都能完成一条指令。

## 4. 为什么需要 pipeline register

每个 stage 都在同一个 clock cycle 内同时工作。为了不让不同指令的数据混在一起，stage 之间必须用寄存器隔开。

这个项目有四组 pipeline register：

| Pipeline register | 保存什么 | 给谁用 |
| --- | --- | --- |
| IF/ID | IF 取到的 PC 和 instruction | ID stage |
| ID/EX | ID 解码后的寄存器值、immediate、控制信号 | EX stage |
| EX/MEM | EX 的 ALU 结果、store data、控制信号 | MEM stage |
| MEM/WB | MEM 的读数据、ALU 结果、写回控制信号 | WB stage |

所以：

```text
5 个功能 stage + 4 组 stage 之间的 pipeline register
```

不是 9 个 stage。

## 5. 项目文件结构

这个 folder 主要有这些文件：

| 文件 | 作用 |
| --- | --- |
| `riscv_pkg.sv` | 公共常量、opcode、ALU op、control word、forwarding select |
| `regfile.sv` | 32 x 32-bit register file |
| `alu.sv` | RV32I 基础整数 ALU |
| `hazard_unit.sv` | 数据冒险检测、stall、forwarding 控制 |
| `riscv_pipeline.sv` | CPU 顶层，连接五级流水线 |
| `riscv_pipeline_tb.sv` | testbench，用来仿真验证 |

本文重点解释 RTL 设计本身，也就是前五个文件。

## 6. riscv_pkg.sv

`riscv_pkg.sv` 是一个 SystemVerilog package。package 可以理解为一个公共命名空间，用来放多个模块都要用的常量和类型。

其他文件通过：

```systemverilog
import riscv_pkg::*;
```

使用里面定义的名字。

### 6.1 RISC-V opcode

这些 `OP_*` 是 instruction 的最低 7 bit，也就是 `inst[6:0]`。

| 名字 | 含义 |
| --- | --- |
| `OP_R` | R-type ALU 指令，例如 ADD、SUB、AND、OR |
| `OP_I_ALU` | I-type ALU 指令，例如 ADDI、ANDI、ORI |
| `OP_LOAD` | load 指令，例如 LW |
| `OP_STORE` | store 指令，例如 SW |
| `OP_BRANCH` | branch 指令，例如 BEQ、BNE、BLT |
| `OP_JAL` | Jump And Link |
| `OP_JALR` | Jump And Link Register |
| `OP_LUI` | Load Upper Immediate |
| `OP_AUIPC` | Add Upper Immediate to PC |

这个 package 覆盖了 RV32I 里常见的基础指令类别，但不是完整 RISC-V。它没有完整覆盖 system、CSR、exception、interrupt、fence，以及各种扩展指令。

### 6.2 ALU operation code

这些 `ALU_*` 是 CPU 内部给 ALU 用的控制码，不是 RISC-V instruction opcode。

| 名字 | ALU 动作 |
| --- | --- |
| `ALU_ADD` | 加法 |
| `ALU_SUB` | 减法 |
| `ALU_AND` | 按位与 |
| `ALU_OR` | 按位或 |
| `ALU_XOR` | 按位异或 |
| `ALU_SLL` | 逻辑左移 |
| `ALU_SRL` | 逻辑右移 |
| `ALU_SRA` | 算术右移 |
| `ALU_SLT` | signed less-than |
| `ALU_SLTU` | unsigned less-than |

### 6.3 Pipeline control word

`ctrl_t` 是一个 packed struct，用来把一条指令的控制信号打包。

```systemverilog
typedef struct packed {
  logic       mem_re;
  logic       mem_we;
  logic       reg_we;
  logic       alu_src;
  logic       branch;
  logic       jal;
  logic       jalr;
  logic       lui;
  logic       auipc;
  logic [3:0] alu_op;
  logic [2:0] funct3;
} ctrl_t;
```

可以把 control word 理解成“这条指令的操作说明书”。它会随着指令一起流过 pipeline。

| 字段 | 作用 |
| --- | --- |
| `mem_re` | 是否读 data memory |
| `mem_we` | 是否写 data memory |
| `reg_we` | 是否写 register file |
| `alu_src` | ALU B 输入是否来自 immediate |
| `branch` | 是否是条件分支 |
| `jal` | 是否是 JAL |
| `jalr` | 是否是 JALR |
| `lui` | 是否是 LUI |
| `auipc` | 是否是 AUIPC |
| `alu_op` | ALU 要执行的操作 |
| `funct3` | branch 条件或 memory width 信息 |

### 6.4 Forwarding select

`FWD_*` 用来告诉 EX stage 的 ALU 输入从哪里来。

| 名字 | 含义 |
| --- | --- |
| `FWD_NONE` | 不转发，使用 ID/EX 里保存的寄存器值 |
| `FWD_EX` | 从 EX/MEM 转发 |
| `FWD_MEM` | 从 MEM/WB 转发 |

forwarding 是为了解决数据还没写回 register file，但下一条指令已经要用它的问题。

## 7. regfile.sv

`regfile.sv` 实现 RISC-V 的 32 个通用寄存器。

核心特性：

1. `x0` 永远读出 0。
2. 写入 `x0` 会被忽略。
3. 写入发生在 clock 上升沿。
4. 读取是组合逻辑。

接口概念：

| 信号 | 作用 |
| --- | --- |
| `rs1_addr` | 要读的第一个源寄存器地址 |
| `rs1_data` | 第一个源寄存器读出的数据 |
| `rs2_addr` | 要读的第二个源寄存器地址 |
| `rs2_data` | 第二个源寄存器读出的数据 |
| `we` | 是否写寄存器 |
| `rd_addr` | 要写的目标寄存器地址 |
| `rd_data` | 要写入的数据 |

例子：

```assembly
add x3, x1, x2
```

register file 会读 `x1` 和 `x2`，最后 WB 阶段写 `x3`。

## 8. alu.sv

`alu.sv` 是组合逻辑模块。

输入：

- `a`：ALU operand A
- `b`：ALU operand B
- `alu_op`：选择做哪种运算

输出：

- `result`：运算结果
- `zero`：结果是否为 0

它支持基础 RV32I ALU 操作，包括加减、逻辑运算、移位和比较。

移位时只使用 `b[4:0]` 作为 shift amount，这是 RV32I 的规则，因为 32-bit 数据最多只需要 5 bit 表示移位数量。

## 9. hazard_unit.sv

pipeline 会带来 hazard，也就是冒险。

这个项目主要处理两类数据冒险：

1. load-use hazard
2. 普通 ALU 数据相关，通过 forwarding 解决

### 9.1 Load-use stall

例子：

```assembly
lw  x3, 0(x1)
add x4, x3, x5
```

`lw` 的数据要到 MEM stage 才能拿到，但下一条 `add` 在 EX stage 就要用 `x3`。这时 forwarding 也来不及，所以必须暂停一拍。

代码逻辑：

```systemverilog
assign stall = id_ex_mem_re &&
               (id_ex_rd != 5'd0) &&
               ((id_ex_rd == id_rs1_addr) || (id_ex_rd == id_rs2_addr));
```

含义：

1. 当前 EX 指令是 load。
2. load 的目标寄存器不是 x0。
3. 当前 ID 指令要读这个目标寄存器。

如果都满足，就 `stall = 1`。

### 9.2 Forwarding

例子：

```assembly
add x3, x1, x2
sub x4, x3, x5
```

`add` 的结果还没有写回 register file，但结果已经在 EX/MEM 里了。`sub` 需要用 `x3`，所以可以直接从 EX/MEM 把结果送回 EX stage。

这就是 forwarding。

forwarding unit 产生：

- `fwd_a`：控制 ALU operand A
- `fwd_b`：控制 ALU operand B

优先级是：

```text
EX/MEM 优先于 MEM/WB
```

因为 EX/MEM 里的结果更新。

## 10. riscv_pipeline.sv 顶层结构

`riscv_pipeline.sv` 是 CPU 顶层，把所有东西连起来。

### 10.1 Module interface

顶层接口包括：

| 信号 | 方向 | 作用 |
| --- | --- | --- |
| `clk` | input | 时钟 |
| `rst_n` | input | 低有效 reset |
| `imem_addr` | output | instruction memory 地址 |
| `imem_data` | input | instruction memory 返回的指令 |
| `dmem_req` | output | data memory 请求有效 |
| `dmem_we` | output | data memory 写使能 |
| `dmem_addr` | output | data memory 地址 |
| `dmem_wdata` | output | 写入 data memory 的数据 |
| `dmem_rdata` | input | data memory 读出的数据 |

### 10.2 PC / IF

PC 逻辑：

```systemverilog
if (!rst_n)
  pc <= 32'd0;
else if (!stall)
  pc <= branch_taken ? branch_target : pc + 4;
```

含义：

- reset 时从地址 0 开始。
- 正常情况每次加 4。
- branch 或 jump taken 时跳到目标地址。
- stall 时 PC 保持不变。

### 10.3 IF/ID

IF/ID register 保存：

- `if_id_pc`
- `if_id_inst`

如果 branch taken，就把 IF/ID 清成 NOP，避免错误路径上的指令继续执行。

### 10.4 ID

ID stage 做三件事：

1. 拆 instruction 字段。
2. 生成 immediate。
3. 生成 control word。

拆字段：

```systemverilog
id_opcode   = if_id_inst[6:0];
id_rd_addr  = if_id_inst[11:7];
id_funct3   = if_id_inst[14:12];
id_rs1_addr = if_id_inst[19:15];
id_rs2_addr = if_id_inst[24:20];
id_funct7   = if_id_inst[31:25];
```

control decode 根据 opcode 判断这条指令是什么类型，然后设置 `id_ctrl`。

例如 load：

```systemverilog
OP_LOAD: begin
  id_ctrl.mem_re  = 1;
  id_ctrl.reg_we  = 1;
  id_ctrl.alu_src = 1;
end
```

表示 load 要读 memory、写 register，并且用 immediate 参与地址计算。

### 10.5 ID/EX

ID/EX register 保存 ID stage 的输出：

- PC
- rs1 data
- rs2 data
- immediate
- rd/rs1/rs2 地址
- control word

stall 或 branch taken 时，ID/EX 被清空，相当于插入 bubble。

### 10.6 EX

EX stage 做：

1. forwarding mux 选择最新操作数。
2. ALU 运算。
3. branch 条件判断。
4. jump/branch target 计算。

ALU B 输入选择：

```systemverilog
ex_alu_b = id_ex_ctrl.alu_src ? id_ex_imm : ex_rs2_raw;
```

如果是 immediate 指令，B 输入来自 immediate；否则来自 rs2。

branch 判断：

| funct3 | branch |
| --- | --- |
| `000` | BEQ |
| `001` | BNE |
| `100` | BLT |
| `101` | BGE |
| `110` | BLTU |
| `111` | BGEU |

如果 branch taken 或 jump，就产生：

```systemverilog
branch_taken = 1
```

然后 PC 会跳到 `branch_target`。

### 10.7 EX/MEM

EX/MEM register 保存：

- ALU result
- store data
- rd
- `reg_we`
- `mem_re`
- `mem_we`
- `funct3`

这些信息给 MEM stage 使用。

### 10.8 MEM

MEM stage 产生 data memory 接口：

```systemverilog
dmem_req   = ex_mem_mem_re || ex_mem_mem_we;
dmem_we    = ex_mem_mem_we;
dmem_addr  = ex_mem_alu_res;
dmem_wdata = ex_mem_rs2;
```

load 和 store 的地址都来自 EX stage 算出的 ALU result。

### 10.9 MEM/WB

MEM/WB register 保存：

- ALU result
- data memory 读出的数据
- rd
- 是否写回
- 是否是 load

### 10.10 WB

WB stage 选择写回数据：

```systemverilog
mem_wb_result = mem_wb_mem_re ? mem_wb_dmem : mem_wb_alu_res;
```

如果是 load，写回 memory 数据；否则写回 ALU result。

然后通过 register file 写端口写回：

```systemverilog
wb_reg_we
wb_rd_addr
wb_rd_data
```

## 11. 一条 ADD 指令如何流过 pipeline

以：

```assembly
add x3, x1, x2
```

为例。

| Stage | 动作 |
| --- | --- |
| IF | 根据 PC 取出 `add` 指令 |
| ID | 解析出 `rs1=x1`、`rs2=x2`、`rd=x3`，读 x1/x2 |
| EX | ALU 计算 `x1 + x2` |
| MEM | 不访问 memory，只把结果往后传 |
| WB | 把 ALU result 写回 x3 |

## 12. 一条 LW 指令如何流过 pipeline

以：

```assembly
lw x4, 0(x1)
```

为例。

| Stage | 动作 |
| --- | --- |
| IF | 取出 `lw` 指令 |
| ID | 读 base register `x1`，生成 offset immediate |
| EX | ALU 计算地址 `x1 + 0` |
| MEM | 从 data memory 读取该地址的数据 |
| WB | 把读出的数据写回 x4 |

## 13. 一条 SW 指令如何流过 pipeline

以：

```assembly
sw x3, 0(x1)
```

为例。

| Stage | 动作 |
| --- | --- |
| IF | 取出 `sw` 指令 |
| ID | 读 base register `x1` 和 store data `x3` |
| EX | ALU 计算地址 `x1 + 0` |
| MEM | 把 x3 的值写入 data memory |
| WB | 不写寄存器，只是经过 |

## 14. 一条 BEQ 指令如何流过 pipeline

以：

```assembly
beq x1, x2, label
```

为例。

| Stage | 动作 |
| --- | --- |
| IF | 取出 `beq` 指令 |
| ID | 读 x1/x2，生成 branch immediate |
| EX | 比较 x1 和 x2，计算 branch target |
| MEM | 不访问 memory |
| WB | 不写寄存器 |

这个项目在 EX stage 才知道 branch 是否 taken。如果 taken，需要 flush IF/ID 和 ID/EX，因为那里面可能已经有错误路径上的指令。

## 15. 当前 RTL 设计的主要限制

不看 testbench，只看 RTL，当前设计还有这些限制：

1. `riscv_pipeline.sv` 里 instruction memory 接口注释写同步 1-cycle latency，但 IF/ID 逻辑更像组合 instruction memory。
2. `riscv_pipeline.sv` 里 data memory load 的时序假设比较强，要求 `dmem_rdata` 在 MEM/WB 采样时已经有效。
3. `hazard_unit.sv` 的 load-use 检测无条件比较 `rs2`，即使某些指令不使用 `rs2`，可能产生多余 stall。
4. `regfile.sv` 没有 same-cycle write/read bypass；WB 同周期写一个寄存器、ID 同周期读同一个寄存器时，读到新值还是旧值不够明确。
5. load/store 数据通路目前主要像支持 `LW/SW`，没有完整 byte enable，也没有 `LB/LH/LBU/LHU/SB/SH` 的 sign extension 或 byte lane 处理。
6. package 覆盖的是简化 RV32I 常见指令类别，不是完整 RISC-V 系统级实现。

## 16. 总结

这个项目是一个清晰的 5-stage RISC-V pipeline 教学骨架。

它已经具备：

- PC 更新
- IF/ID/EX/MEM/WB 五级结构
- pipeline registers
- register file
- ALU
- immediate generation
- control decode
- branch/jump 基础处理
- load/store 基础接口
- forwarding
- load-use stall

但它还不是完整商用品质 CPU，也不是完整 RISC-V 实现。它更适合作为理解流水线 CPU 的学习项目。后续如果要增强，优先应该处理 memory timing、register file bypass、load/store byte width、更多指令覆盖和更完整验证。
