/**
 * alu.sv — RV32I ALU
 * ─────────────────────────────────────────────────────────────────────────────
 * Purely combinational. Performs all integer operations required by RV32I.
 * The operation is selected by the 4-bit alu_op code defined in riscv_pkg.
 *
 * Shift amount (shamt) is always the lower 5 bits of operand b, matching the
 * RISC-V spec for both R-type shifts (rs2[4:0]) and I-type shifts (imm[4:0]).
 * ─────────────────────────────────────────────────────────────────────────────
 */

import riscv_pkg::*;

module alu (
  input  logic [31:0] a,       // Operand A (always a register value)
  input  logic [31:0] b,       // Operand B (register or sign-extended immediate)
  input  logic [3:0]  alu_op,  // Operation — see riscv_pkg ALU_* constants
  output logic [31:0] result,
  output logic        zero     // 1 when result == 0 (used for branch conditions)
);

  logic [4:0] shamt;
  assign shamt = b[4:0];

  always_comb begin
    case (alu_op)
      ALU_ADD:  result = a + b;
      ALU_SUB:  result = a - b;
      ALU_AND:  result = a & b;
      ALU_OR:   result = a | b;
      ALU_XOR:  result = a ^ b;
      ALU_SLL:  result = a << shamt;
      ALU_SRL:  result = a >> shamt;
      ALU_SRA:  result = $signed(a) >>> shamt;
      ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
      ALU_SLTU: result = (a < b)                   ? 32'd1 : 32'd0;
      default:  result = 32'd0;
    endcase
  end

  assign zero = (result == 32'd0);

endmodule
