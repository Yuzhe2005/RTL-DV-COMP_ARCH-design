// ============================================================
// Problem: Add/Sub Carry and Signed Overflow Detector
// ============================================================
// Design a parameterized combinational module that detects carry and
// signed overflow for addition or subtraction.
//
// Module interface:
// module overflow_detect #(
//   parameter W = 32
// )(
//   input  logic [W-1:0] a,
//   input  logic [W-1:0] b,
//   input  logic [W-1:0] result,
//   input  logic         is_sub,
//   output logic         overflow,
//   output logic         carry
// );
//
// Requirements:
// 1. The module should be purely combinational.
//    - Do not use clk or reset.
//    - Outputs should update whenever inputs change.
//
// 2. The module should support both addition and subtraction.
//
// 3. Operation select:
//    - If is_sub = 0:
//        operation is addition:
//        result is assumed to be a + b.
//
//    - If is_sub = 1:
//        operation is subtraction:
//        result is assumed to be a - b.
//
// 4. Carry output:
//    - Internally compute the add/sub operation using W+1 bits.
//    - For addition:
//        ext = {1'b0, a} + {1'b0, b}
//    - For subtraction:
//        ext = {1'b0, a} - {1'b0, b}
//    - carry should be ext[W], the extra upper bit of the W+1-bit result.
//
// 5. Carry interpretation:
//    - For addition, carry = 1 means the unsigned addition produced a
//      carry out of bit W-1.
//    - For subtraction in this implementation, carry = ext[W] comes from
//      the W+1-bit subtraction result.
//    - Different ISAs may define subtraction carry/borrow differently;
//      this module simply exposes ext[W].
//
// 6. Signed overflow output:
//    - overflow should indicate signed two's-complement overflow.
//    - overflow is only about signed arithmetic correctness.
//    - It is different from carry.
//
// 7. Addition overflow rule:
//    - For a + b, overflow occurs when:
//        a and b have the same sign,
//        but result has a different sign.
//    - In logic:
//        overflow = (a[W-1] == b[W-1]) &&
//                   (result[W-1] != a[W-1])
//
// 8. Subtraction overflow rule:
//    - For a - b, overflow occurs when:
//        a and b have different signs,
//        and result has a different sign from a.
//    - In logic:
//        overflow = (a[W-1] != b[W-1]) &&
//                   (result[W-1] != a[W-1])
//
// 9. Inputs:
//    - a and b are W-bit operands.
//    - result is the W-bit arithmetic result produced elsewhere.
//    - This module does not compute the final result output itself;
//      it only uses result's sign bit to detect signed overflow.
//
// 10. Output behavior:
//    - carry is derived from a W+1-bit recomputation of a+b or a-b.
//    - overflow is derived from sign-bit relationships among a, b,
//      and result.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Continuous assignments are sufficient.
//    - The design should be synthesizable.
//    - No delays, initial blocks, or simulation-only constructs.
//
// 12. Assumptions:
//    - W is at least 1.
//    - a, b, and result are interpreted as two's-complement values for
//      overflow detection.
//    - carry is interpreted as an unsigned arithmetic flag, not as a
//      signed overflow flag.
// ============================================================

`default_nettype none

module overflow_detect #(
  parameter W = 32
)(
  input  logic [W-1:0] a,
  input  logic [W-1:0] b,
  input  logic [W-1:0] result,
  input  logic         is_sub,
  output logic         overflow,
  output logic         carry
);
    always_comb begin
        overflow = 0;
        if (is_sub) overflow = (a[W-1] != b[W-1]) && (a[W-1] != result[W-1]);
        else overflow = (a[W-1] == b[W-1]) && (a[W-1] != result[W-1]);
    end

    logic [W:0] result_calc;
    assign result_calc = (is_sub) ? {1'b0, a}-{1'b0, b} : {1'b0, a}+{1'b0, b};
    assign carry = result_calc[W];
endmodule