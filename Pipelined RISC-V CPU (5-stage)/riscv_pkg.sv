/**
 * riscv_pkg.sv — Shared types and opcodes for the RISC-V pipeline
 * ─────────────────────────────────────────────────────────────────────────────
 * Import with: import riscv_pkg::*;
 * ─────────────────────────────────────────────────────────────────────────────
 */

package riscv_pkg;

  // ── RV32I opcode map ──────────────────────────────────────────────────────
  localparam logic [6:0]
    OP_R      = 7'b0110011,   // R-type  (ADD SUB AND OR XOR SLL SRL SRA SLT SLTU)
    OP_I_ALU  = 7'b0010011,   // I-type  (ADDI ANDI ORI XORI SLLI SRLI SRAI SLTI)
    OP_LOAD   = 7'b0000011,   // I-type  (LW LH LB …)
    OP_STORE  = 7'b0100011,   // S-type  (SW SH SB)
    OP_BRANCH = 7'b1100011,   // B-type  (BEQ BNE BLT BGE BLTU BGEU)
    OP_JAL    = 7'b1101111,   // J-type
    OP_JALR   = 7'b1100111,   // I-type
    OP_LUI    = 7'b0110111,   // U-type
    OP_AUIPC  = 7'b0010111;   // U-type

  // ── ALU operation codes ───────────────────────────────────────────────────
  localparam logic [3:0]
    ALU_ADD  = 4'd0,
    ALU_SUB  = 4'd1,
    ALU_AND  = 4'd2,
    ALU_OR   = 4'd3,
    ALU_XOR  = 4'd4,
    ALU_SLL  = 4'd5,
    ALU_SRL  = 4'd6,
    ALU_SRA  = 4'd7,
    ALU_SLT  = 4'd8,
    ALU_SLTU = 4'd9;

  // ── Pipeline control word ─────────────────────────────────────────────────
  typedef struct packed {
    logic       mem_re;    // Memory read (load)
    logic       mem_we;    // Memory write (store)
    logic       reg_we;    // Register file write-back
    logic       alu_src;   // 1 = ALU B operand from immediate
    logic       branch;    // Branch instruction
    logic       jal;       // JAL
    logic       jalr;      // JALR
    logic       lui;       // LUI
    logic       auipc;     // AUIPC
    logic [3:0] alu_op;    // ALU operation code
    logic [2:0] funct3;    // For branch condition / mem width
  } ctrl_t;

  // ── Forwarding select ─────────────────────────────────────────────────────
  localparam logic [1:0]
    FWD_NONE = 2'b00,   // Use register file value
    FWD_MEM  = 2'b01,   // Forward from MEM/WB
    FWD_EX   = 2'b10;   // Forward from EX/MEM

endpackage
