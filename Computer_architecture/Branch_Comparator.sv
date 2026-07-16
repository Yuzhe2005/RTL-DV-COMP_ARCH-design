// ============================================================
// Problem: Branch Comparator
// ============================================================
// Design a combinational branch comparison unit for a simple CPU.
//
// The module receives two W-bit operands and a 3-bit funct3 field, then
// determines whether a branch should be taken.
//
// Module interface:
// module branch_cmp #(
//   parameter W = 32
// )(
//   input  logic [W-1:0] a,
//   input  logic [W-1:0] b,
//   input  logic [2:0]   funct3,
//   output logic         take_branch
// );
//
// Requirements:
// 1. The module should compare operands a and b according to funct3.
//
// 2. funct3 encoding:
//    - 3'b000: BEQ
//        take_branch = 1 if a == b
//
//    - 3'b001: BNE
//        take_branch = 1 if a != b
//
//    - 3'b100: BLT
//        take_branch = 1 if signed(a) < signed(b)
//
//    - 3'b101: BGE
//        take_branch = 1 if signed(a) >= signed(b)
//
//    - 3'b110: BLTU
//        take_branch = 1 if unsigned(a) < unsigned(b)
//
//    - 3'b111: BGEU
//        take_branch = 1 if unsigned(a) >= unsigned(b)
//
// 3. Signed comparison:
//    - BLT and BGE should treat a and b as signed two's-complement values.
//    - Use signed comparison for funct3 values 3'b100 and 3'b101.
//
// 4. Unsigned comparison:
//    - BLTU and BGEU should treat a and b as unsigned values.
//    - Use unsigned comparison for funct3 values 3'b110 and 3'b111.
//
// 5. Equality comparison:
//    - BEQ and BNE only compare bit patterns.
//    - Signedness does not matter for equality and inequality.
//
// 6. Invalid funct3 behavior:
//    - For unsupported funct3 values, take_branch should be 0.
//
// 7. Output behavior:
//    - take_branch should be purely combinational.
//    - take_branch should update immediately when a, b, or funct3 changes.
//    - No clock or reset is needed.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_comb or equivalent combinational logic.
//    - Provide a default assignment or default case to avoid latches.
//    - Do not use sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - W is at least 1.
//    - a and b are W-bit operands.
//    - funct3 follows a RISC-V-like branch encoding.
//    - This module only decides whether the branch condition is true;
//      branch target address calculation is handled elsewhere.
// ============================================================

`default_nettype none

module branch_cmp #(
  parameter W = 32
)(
  input  logic [W-1:0] a,
  input  logic [W-1:0] b,
  input  logic [2:0]   funct3,
  output logic         take_branch
);
    always_comb begin
        case (funct3)
            3'b000: take_branch = (a==b);
            3'b001: take_branch = (a!=b);
            3'b100: take_branch = ($signed(a) < $signed(b));
            3'b101: take_branch = ($signed(a) >= $signed(b));
            3'b110: take_branch = (a < b);
            3'b111: take_branch = (a >= b);
            default: take_branch = 0;
        endcase
    end
endmodule