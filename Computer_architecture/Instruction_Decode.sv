// ============================================================
// Problem: Simple RISC-V Instruction Decoder
// ============================================================
// Design a combinational instruction decoder for a simplified 32-bit
// RISC-V-like CPU.
//
// The module receives a 32-bit instruction and extracts register fields,
// immediate values, opcode/funct fields, and main control signals.
//
// Module interface:
// module instr_decode (
//   input  logic [31:0] instr,
//   output logic [4:0]  rs1,
//   output logic [4:0]  rs2,
//   output logic [4:0]  rd,
//   output logic [31:0] imm,
//   output logic [6:0]  opcode,
//   output logic [6:0]  funct7,
//   output logic [2:0]  funct3,
//   output logic        reg_write,
//   output logic        mem_read,
//   output logic        mem_write,
//   output logic        branch,
//   output logic        alu_src,
//   output logic        jump,
//   output logic        mem_to_reg,
//   output logic        illegal_instruction,
//   output logic [3:0]  alu_op
// );
//
// Requirements:
// 1. The decoder should be purely combinational.
//    - No clock is required.
//    - No reset is required.
//    - Outputs should update immediately when instr changes.
//
// 2. Field extraction:
//    - opcode = instr[6:0]
//    - rd     = instr[11:7]
//    - funct3 = instr[14:12]
//    - rs1    = instr[19:15]
//    - rs2    = instr[24:20]
//    - funct7 = instr[31:25]
//
// 3. Immediate generation:
//    The decoder should generate a 32-bit sign-extended or shifted
//    immediate based on the instruction type.
//
//    I-type immediate:
//      - Used by I-type ALU instructions, loads, and JALR.
//      - imm = sign_extend(instr[31:20])
//
//    S-type immediate:
//      - Used by stores.
//      - imm = sign_extend({instr[31:25], instr[11:7]})
//
//    B-type immediate:
//      - Used by branches.
//      - imm = sign_extend({instr[31], instr[7], instr[30:25],
//                           instr[11:8], 1'b0})
//
//    U-type immediate:
//      - Used by LUI and AUIPC.
//      - imm = {instr[31:12], 12'b0}
//
//    J-type immediate:
//      - Used by JAL.
//      - imm = sign_extend({instr[31], instr[19:12], instr[20],
//                           instr[30:21], 1'b0})
//
//    Unsupported opcodes should produce imm = 0.
//
// 4. Supported opcode types:
//    - 7'b0110011: R-type ALU instruction
//    - 7'b0010011: I-type ALU instruction
//    - 7'b0000011: Load instruction
//    - 7'b0100011: Store instruction
//    - 7'b1100011: Branch instruction
//    - 7'b1101111: JAL
//    - 7'b1100111: JALR
//    - 7'b0110111: LUI
//    - 7'b0010111: AUIPC
//
// 5. Default control behavior:
//    Before decoding opcode, all control outputs should default to 0:
//      - reg_write = 0
//      - mem_read = 0
//      - mem_write = 0
//      - branch = 0
//      - alu_src = 0
//      - jump = 0
//      - mem_to_reg = 0
//      - illegal_instruction = 0
//      - alu_op = 0
//
// 6. R-type behavior:
//    - reg_write should be asserted.
//    - alu_src should be 0, because both ALU operands come from registers.
//    - Decode funct3/funct7 to generate alu_op.
//
//    Simplified ALU operation mapping:
//      - funct3 = 3'b000:
//          funct7[5] = 0 -> ADD, alu_op = 4'd0
//          funct7[5] = 1 -> SUB, alu_op = 4'd1
//      - funct3 = 3'b111:
//          AND, alu_op = 4'd2
//      - funct3 = 3'b110:
//          OR, alu_op = 4'd3
//      - Other funct3 values may default to ADD.
//
// 7. I-type ALU behavior:
//    - reg_write should be asserted.
//    - alu_src should be asserted, because the second ALU operand is imm.
//    - alu_op may default to ADD for this simplified decoder.
//
// 8. Load behavior:
//    - reg_write should be asserted.
//    - mem_read should be asserted.
//    - alu_src should be asserted to compute address using rs1 + imm.
//    - mem_to_reg should be asserted because writeback data comes from memory.
//    - alu_op should select ADD for address calculation.
//
// 9. Store behavior:
//    - mem_write should be asserted.
//    - alu_src should be asserted to compute address using rs1 + imm.
//    - alu_op should select ADD for address calculation.
//    - reg_write should remain 0.
//
// 10. Branch behavior:
//    - branch should be asserted.
//    - alu_op may select SUB or compare-related operation.
//    - reg_write should remain 0.
//    - mem_read and mem_write should remain 0.
//
// 11. Jump behavior:
//    - For JAL and JALR, jump should be asserted.
//    - reg_write should be asserted because the return address is written
//      to rd.
//    - JALR should use an I-type immediate.
//    - JAL should use a J-type immediate.
//
// 12. LUI/AUIPC behavior:
//    - reg_write should be asserted.
//    - alu_src may be asserted because the instruction uses an immediate.
//    - LUI/AUIPC immediate should use U-type immediate format.
//
// 13. Illegal instruction behavior:
//    - If opcode is not one of the supported opcodes, assert
//      illegal_instruction.
//    - For illegal instructions, all other control signals should remain
//      at their default 0 values.
//
// 14. Output behavior:
//    - All outputs should be combinational.
//    - The decoder should provide default assignments to avoid latches.
//    - The design should be synthesizable.
//
// 15. Assumptions:
//    - instr is a 32-bit RISC-V-like instruction.
//    - Register indices are 5 bits wide.
//    - This is a simplified decoder, not a full RV32I decoder.
//    - More detailed funct3/funct7 checking may be handled elsewhere.
//    - Branch comparison and branch target calculation are handled by
//      separate modules.
//    - Actual ALU datapath muxes and writeback muxes are handled elsewhere.
// ============================================================

`default_nettype none

module instr_decode (
  input  logic [31:0] instr,
  output logic [4:0]  rs1,
  output logic [4:0]  rs2,
  output logic [4:0]  rd,
  output logic [31:0] imm,
  output logic [6:0]  opcode,
  output logic [6:0]  funct7,
  output logic [2:0]  funct3,
  output logic        reg_write,
  output logic        mem_read,
  output logic        mem_write,
  output logic        branch,
  output logic        alu_src,
  output logic        jump,
  output logic        mem_to_reg,
  output logic        illegal_instruction,
  output logic [3:0]  alu_op
);
    assign opcode = instr[6:0];
    assign rd = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1 = instr[19:15];
    assign rs2 - instr[24:20];
    assign funct7 = ins[31:25];

    always_comb begin
        case (opcode)

        // I-type immediate
        // Used by:
        //   7'b0010011: I-type ALU instructions, e.g. ADDI, ANDI, ORI
        //   7'b0000011: Load instructions, e.g. LW, LB, LH
        //   7'b1100111: JALR
        //
        // Immediate format:
        //   imm[11:0] = instr[31:20]
        //
        // Sign-extend 12-bit immediate to 32 bits.
        7'b0010011,
        7'b0000011,
        7'b1100111: imm = {{20{instr[31]}}, instr[31:20]};


        // S-type immediate
        // Used by:
        //   7'b0100011: Store instructions, e.g. SW, SB, SH
        //
        // Immediate format:
        //   imm[11:5] = instr[31:25]
        //   imm[4:0]  = instr[11:7]
        //
        // Sign-extend 12-bit immediate to 32 bits.
        7'b0100011: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};


        // B-type immediate
        // Used by:
        //   7'b1100011: Branch instructions, e.g. BEQ, BNE, BLT, BGE
        //
        // Immediate format:
        //   imm[12]   = instr[31]
        //   imm[11]   = instr[7]
        //   imm[10:5] = instr[30:25]
        //   imm[4:1]  = instr[11:8]
        //   imm[0]    = 1'b0
        //
        // Branch offsets are 2-byte aligned, so imm[0] is always 0.
        // Sign-extend 13-bit immediate to 32 bits.
        7'b1100011: imm = {{19{instr[31]}}, instr[31], instr[7],
                            instr[30:25], instr[11:8], 1'b0};


        // U-type immediate
        // Used by:
        //   7'b0110111: LUI
        //   7'b0010111: AUIPC
        //
        // Immediate format:
        //   imm[31:12] = instr[31:12]
        //   imm[11:0]  = 12'b0
        //
        // U-type immediate occupies the upper 20 bits.
        7'b0110111,
        7'b0010111: imm = {instr[31:12], 12'b0};


        // J-type immediate
        // Used by:
        //   7'b1101111: JAL
        //
        // Immediate format:
        //   imm[20]    = instr[31]
        //   imm[19:12] = instr[19:12]
        //   imm[11]    = instr[20]
        //   imm[10:1]  = instr[30:21]
        //   imm[0]     = 1'b0
        //
        // JAL offsets are 2-byte aligned, so imm[0] is always 0.
        // Sign-extend 21-bit immediate to 32 bits.
        7'b1101111: imm = {{11{instr[31]}}, instr[31], instr[19:12],
                            instr[20], instr[30:21], 1'b0};


        // Unsupported opcode
        // If the instruction type is not supported by this simplified decoder,
        // output immediate as 0.
        default: imm = 32'b0;

        endcase
    end

    always_comb begin
        reg_write           = 1'b0;
        mem_read            = 1'b0;
        mem_write           = 1'b0;
        branch              = 1'b0;
        alu_src             = 1'b0; // rs2 是reg 还是 immediate
        jump                = 1'b0;
        mem_to_reg          = 1'b0;
        illegal_instruction = 1'b0;
        alu_op              = 4'd0;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                alu_src   = 1'b0;
                case (funct3)
                3'b000: alu_op = funct7[5] ? 4'd1 : 4'd0;
                3'b111: alu_op = 4'd2;
                3'b110: alu_op = 4'd3;
                default: alu_op = 4'd0;
                endcase
            end

             7'b0010011: begin // I-type ALU
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'd0;
            end

            7'b0000011: begin // Load
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 4'd0;
            end

            7'b0100011: begin // Store
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'd0;
            end

            7'b1100011: begin // Branch
                branch = 1'b1;
                alu_op = 4'd1;
            end

            7'b1101111,
            7'b1100111: begin // JAL/JALR
                jump      = 1'b1;
                reg_write = 1'b1;
                alu_src   = 1'b1;
            end

            7'b0110111,
            7'b0010111: begin // LUI/AUIPC
                reg_write = 1'b1;
                alu_src   = 1'b1;
            end

            default: begin
                illegal_instruction = 1'b1;
            end
        endcase
    end
endmodule