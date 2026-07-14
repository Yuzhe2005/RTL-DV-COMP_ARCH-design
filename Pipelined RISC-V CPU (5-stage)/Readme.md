
# Pipelined RISC-V CPU (5-stage)

## What You're Building

A **5-stage pipelined RISC-V RV32I processor** split across multiple files, mirroring real RTL project structure.

## File Structure

- **riscv_pkg.sv** — Shared constants: opcodes, ALU op codes, ctrl_t struct, forwarding selects
- **regfile.sv** — 32×32-bit register file (sync write, combo read, x0=0)
- **alu.sv** — All RV32I integer ops, purely combinational
- **hazard_unit.sv** — Load-use stall detection + EX/MEM forwarding mux selects
- **riscv_pipeline.sv** — Top level: 5 stages, pipeline registers, wired together
- **riscv_pipeline_tb.sv** — Self-checking testbench with hand-assembled RV32I program

## The Five Pipeline Stages

**IF** — Reads instruction from IMEM at PC. PC normally advances PC+4.

**ID** — Decodes opcode, generates immediate, produces ctrl_t control word, reads rs1/rs2 from register file.

**EX** — Runs the ALU. Resolves branches (condition + target). On taken branch, flushes IF/ID and ID/EX.

**MEM** — Performs LW/SW via data memory interface. Other instructions pass through.

**WB** — Selects ALU result or loaded data, writes back to register file.

## Data Hazards and Forwarding

The hazard_unit outputs fwd_a/fwd_b 2-bit mux selects routing results from EX/MEM or MEM/WB directly to the ALU inputs, bypassing the register file.

**EX→EX forward** (one instruction apart): result from EX/MEM pipeline register.

**MEM→EX forward** (two instructions apart): result from MEM/WB pipeline register.

**Load-use hazard** — LW result is only available after MEM. The hazard_unit freezes PC and IF/ID for one cycle and injects a NOP bubble into ID/EX.

## Control Hazards

Branch is resolved in EX. The two wrong-path instructions (in IF and ID) are flushed by writing NOPs into IF/ID and ID/EX on the cycle after branch_taken asserts.
