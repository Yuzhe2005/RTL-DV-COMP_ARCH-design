// ============================================================
// Problem: Forwarding Unit
// ============================================================
// Design a combinational forwarding unit for a simple pipelined CPU.
//
// The module should decide whether the operands used by the instruction
// currently in the EX stage should come directly from the ID/EX pipeline
// register, from the EX/MEM stage, or from the MEM/WB stage.
//
// Module interface:
// module forwarding_unit (
//   input  logic [4:0] id_ex_rs1,
//   input  logic [4:0] id_ex_rs2,
//   input  logic [4:0] ex_mem_rd,
//   input  logic [4:0] mem_wb_rd,
//   input  logic       ex_mem_reg_write,
//   input  logic       mem_wb_reg_write,
//   output logic [1:0] fwd_a,
//   output logic [1:0] fwd_b
// );
//
// Requirements:
// 1. The module should generate forwarding control signals for two ALU
//    source operands.
//
// 2. Register fields:
//    - id_ex_rs1 is the first source register of the instruction currently
//      in the EX stage.
//    - id_ex_rs2 is the second source register of the instruction currently
//      in the EX stage.
//    - ex_mem_rd is the destination register of the instruction currently
//      in the EX/MEM pipeline stage.
//    - mem_wb_rd is the destination register of the instruction currently
//      in the MEM/WB pipeline stage.
//
// 3. Write-enable signals:
//    - ex_mem_reg_write indicates whether the EX/MEM stage instruction
//      will write back to a register.
//    - mem_wb_reg_write indicates whether the MEM/WB stage instruction
//      will write back to a register.
//
// 4. Forwarding control encoding:
//    - 2'b00: no forwarding.
//             Use the value already stored in the ID/EX pipeline register.
//
//    - 2'b01: forward from MEM/WB.
//             Use the writeback-stage result.
//
//    - 2'b10: forward from EX/MEM.
//             Use the result from the previous instruction.
//
// 5. Operand A forwarding:
//    - fwd_a controls the source for the ALU operand corresponding to
//      id_ex_rs1.
//    - If ex_mem_rd matches id_ex_rs1 and EX/MEM will write a register,
//      fwd_a should be 2'b10.
//    - Else, if mem_wb_rd matches id_ex_rs1 and MEM/WB will write a register,
//      fwd_a should be 2'b01.
//    - Otherwise, fwd_a should be 2'b00.
//
// 6. Operand B forwarding:
//    - fwd_b controls the source for the ALU operand corresponding to
//      id_ex_rs2.
//    - If ex_mem_rd matches id_ex_rs2 and EX/MEM will write a register,
//      fwd_b should be 2'b10.
//    - Else, if mem_wb_rd matches id_ex_rs2 and MEM/WB will write a register,
//      fwd_b should be 2'b01.
//    - Otherwise, fwd_b should be 2'b00.
//
// 7. Priority rule:
//    - EX/MEM forwarding has higher priority than MEM/WB forwarding.
//    - If both EX/MEM and MEM/WB match the same source register, select
//      EX/MEM forwarding.
//    - This is because EX/MEM contains the newer result.
//
// 8. x0 behavior:
//    - Register x0 is hardwired to zero.
//    - If ex_mem_rd is 0, it should not trigger forwarding.
//    - If mem_wb_rd is 0, it should not trigger forwarding.
//
// 9. Output behavior:
//    - fwd_a and fwd_b should be purely combinational.
//    - They should update immediately when any input changes.
//    - No clock or reset is needed.
//
// 10. Example cases:
//    - add x5, x1, x2
//      sub x6, x5, x3
//      The sub instruction needs x5 from the previous instruction.
//      If the add result is in EX/MEM, fwd_a should be 2'b10.
//
//    - add x5, x1, x2
//      nop
//      sub x6, x5, x3
//      The sub instruction needs x5 from MEM/WB.
//      fwd_a should be 2'b01.
//
//    - add x0, x1, x2
//      sub x6, x0, x3
//      Since x0 is always zero, no forwarding should occur.
//      fwd_a should be 2'b00.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use combinational logic.
//    - Use always_comb or equivalent continuous combinational logic.
//    - Provide default assignments to avoid latches.
//    - Do not use sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 12. Assumptions:
//    - Register indices are 5 bits wide.
//    - Register 0 represents x0.
//    - This module only generates forwarding select signals.
//    - The actual muxes that select ALU operands are implemented elsewhere.
//    - Load-use hazards that cannot be solved by forwarding are handled by
//      a separate hazard detection unit.
// ============================================================

`default_nettype none

module forwarding_unit (
  input  logic [4:0] id_ex_rs1,
  input  logic [4:0] id_ex_rs2,
  input  logic [4:0] ex_mem_rd,
  input  logic [4:0] mem_wb_rd,
  input  logic       ex_mem_reg_write,
  input  logic       mem_wb_reg_write,
  output logic [1:0] fwd_a,
  output logic [1:0] fwd_b
);
    always_comb begin
        fwd_a = 2'b00;
        fwd_b = 2'b00;
        
        if (mem_wb_reg_write && mem_wb_rd != '0 && mem_wb_rd == id_ex_rs1)
            fwd_a = 2'b01;
        if (mem_wb_reg_write && mem_wb_rd != '0 && mem_wb_rd == id_ex_rs2)
            fwd_b = 2'b01;
        if (ex_mem_reg_write && ex_mem_rd != '0 && ex_mem_rd == id_ex_rs1)
            fwd_a = 2'b10;
        if (ex_mem_reg_write && ex_mem_rd != '0 && ex_mem_rd == id_ex_rs2)
            fwd_b = 2'b10;
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:

module forwarding_unit (
  input  logic [4:0] id_ex_rs1,
  input  logic [4:0] id_ex_rs2,
  input  logic [4:0] ex_mem_rd,
  input  logic [4:0] mem_wb_rd,
  input  logic       ex_mem_reg_write,
  input  logic       mem_wb_reg_write,
  output logic [1:0] fwd_a,
  output logic [1:0] fwd_b
);
  // Encoding: 00=no forward, 01=MEM/WB, 10=EX/MEM
  always_comb begin
    fwd_a = 2'b00;
    fwd_b = 2'b00;
    // EX-stage forwarding (higher priority) => 10
    if (ex_mem_reg_write && ex_mem_rd != 0 && ex_mem_rd == id_ex_rs1)
      fwd_a = 2'b10;
    else if (mem_wb_reg_write && mem_wb_rd != 0 && mem_wb_rd == id_ex_rs1)
      fwd_a = 2'b01;
    if (ex_mem_reg_write && ex_mem_rd != 0 && ex_mem_rd == id_ex_rs2)
      fwd_b = 2'b10;
    else if (mem_wb_reg_write && mem_wb_rd != 0 && mem_wb_rd == id_ex_rs2)
      fwd_b = 2'b01;
  end
endmodule