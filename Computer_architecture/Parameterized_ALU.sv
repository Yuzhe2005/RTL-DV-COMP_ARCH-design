// ============================================================
// Problem: Parameterized Combinational ALU
// ============================================================
// Design a parameterized combinational ALU that supports arithmetic,
// logic, comparison, and shift operations.
//
// Module interface:
// module alu #(
//   parameter W = 32
// )(
//   input  logic [W-1:0] a,
//   input  logic [W-1:0] b,
//   input  logic [3:0]   op,
//   output logic [W-1:0] result,
//   output logic         zero,
//   output logic         carry,
//   output logic         overflow,
//   output logic         negative
// );
//
// Requirements:
// 1. The ALU should be purely combinational.
//    - Outputs should update whenever inputs change.
//    - Do not use clk or reset.
//    - Use always_comb.
//
// 2. The ALU should support the following operations:
//
//      op = 4'd0:
//        result = a + b
//
//      op = 4'd1:
//        result = a - b
//
//      op = 4'd2:
//        result = a & b
//
//      op = 4'd3:
//        result = a | b
//
//      op = 4'd4:
//        result = a ^ b
//
//      op = 4'd5:
//        signed less-than comparison
//        result = 1 if signed(a) < signed(b)
//        result = 0 otherwise
//
//      op = 4'd6:
//        logical left shift
//        result = a << shift_amount
//
//      op = 4'd7:
//        logical right shift
//        result = a >> shift_amount
//
//      op = 4'd8:
//        arithmetic right shift
//        result = signed(a) >>> shift_amount
//
//      default:
//        result = 0
//
// 3. Shift amount:
//    - Use the low $clog2(W) bits of b as the shift amount.
//    - For example, if W = 32, use b[4:0].
//
// 4. Carry behavior:
//    - For add/sub operations, compute the operation using W+1 bits.
//    - carry should be the MSB of the W+1-bit temporary result.
//    - For non-arithmetic operations, carry should be 0.
//
// 5. Overflow behavior:
//    - overflow should indicate signed overflow for addition and subtraction.
//    - For addition:
//        overflow = 1 when a and b have the same sign,
//        but result has a different sign.
//
//    - For subtraction:
//        overflow = 1 when a and b have different signs,
//        and result has a different sign from a.
//
//    - For all other operations, overflow should be 0.
//
// 6. Zero flag:
//    - zero should be 1 when result is all zeros.
//    - Otherwise zero should be 0.
//
// 7. Negative flag:
//    - negative should equal the MSB of result.
//    - For signed interpretation, this indicates whether result is negative.
//
// 8. Result width:
//    - result should always be W bits.
//    - Arithmetic should use a W+1-bit temporary internally to preserve
//      carry information.
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use always_comb.
//    - Use a case statement on op.
//    - Provide default assignments to avoid latches.
//    - The design should be synthesizable.
//
// 10. Assumptions:
//    - W is at least 2.
//    - a and b are treated as unsigned for logic and shift operations.
//    - a and b are treated as signed only for signed less-than and
//      arithmetic right shift.
// ============================================================

`default_nettype none

module alu #(
  parameter W = 32
)(
  input  logic [W-1:0] a,
  input  logic [W-1:0] b,
  input  logic [3:0]   op,
  output logic [W-1:0] result,
  output logic         zero,
  output logic         carry,
  output logic         overflow,
  output logic         negative
);
    logic [W:0] result_calc;
    assign result = result_calc[W-1:0];
    logic [$clog2(W)-1:0] shamt;
    assign shamt = b[$clog2(W)-1:0];

    always_comb begin
        case (op)
            4'd0: result_calc = a+b;
            4'd1: result_calc = a-b;
            4'd2: result_calc = {1'b0, a&b};
            4'd3: result_calc = {1'b0, a|b};
            4'd4: result_calc = {1'b0, a^b};
            4'd5: result_calc = {{(W-1){1'b0}}, $signed(a) < $signed(b)};
            4'd6: result_calc = {1'b0, a << shamt};
            4'd7: result_calc = {1'b0, a >> shamt};
            4'd8: result_calc = {1'b0, $signed(a) >>> shamt};
            default: result_calc = '0;
        endcase
    end

    assign carry = result_calc[W];
    assign zero = (result == '0);
    assign negative = result[W-1];

    always_comb begin
        overflow = 0;
        // if ((op == 4'd0 && a[W-1] && b[W-1] && !result[W-1]) ||
        //     (op == 4'd1 && !a[W-1] && b[W-1] && result[W-1])) // 第一遍写错了
        if ((a[W-1] == b[W-1]) && (result[W-1] != a[W-1]) || 
            (a[W-1] != b[W-1]) && (result[W-1] != a[W-1]))
            overflow = 1;
    end
endmodule