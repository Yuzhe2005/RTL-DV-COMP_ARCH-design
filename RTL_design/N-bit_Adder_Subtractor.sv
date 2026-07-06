// ============================================================
// Problem: Parameterized Adder/Subtractor with Carry and Overflow
// ============================================================
// Design a parameterized combinational adder/subtractor.
// Module interface:
// module adder_sub #(
//   parameter WIDTH = 32
// )(
//   input  logic [WIDTH-1:0] a,
//   input  logic [WIDTH-1:0] b,
//   input  logic             sub,
//   output logic [WIDTH-1:0] result,
//   output logic             carry_out,
//   output logic             overflow
// );
// Requirements:
// 1. Implement a combinational arithmetic unit that can perform addition or subtraction.
// 2. When sub = 0:
//    - Compute result = a + b.
// 3. When sub = 1:
//    - Compute result = a - b.
//    - Use two's complement subtraction internally.
//    - This means a - b should be implemented as a + (~b) + 1.
// 4. result should contain the lower WIDTH bits of the arithmetic result.
// 5. carry_out should contain the carry out from the WIDTH-bit addition.
//    - For addition, carry_out is the normal unsigned carry out.
//    - For subtraction using a + (~b) + 1, carry_out is the carry out of that operation.
// 6. overflow should indicate signed overflow.
// 7. For addition:
//    - overflow occurs when a and b have the same sign,
//      but result has a different sign.
// 8. For subtraction:
//    - overflow occurs when a and b have different signs,
//      but result has a different sign from a.
// 9. The design should be parameterized by WIDTH.
// 10. The design should be purely combinational.
// 11. Use SystemVerilog.
// 12. The design should be synthesizable.
// 13. Assumptions:
//    - WIDTH is positive.
//    - Inputs are interpreted as two's complement values for overflow detection.
//    - No registered output is required.
// ============================================================

`default_nettype none

module adder_sub #(
  parameter WIDTH = 32
)(
  input  logic [WIDTH-1:0] a,
  input  logic [WIDTH-1:0] b,
  input  logic             sub,
  output logic [WIDTH-1:0] result,
  output logic             carry_out,
  output logic             overflow
);
    logic [WIDTH:0] res_with_high;
    always_comb begin
        result = '0;
        carry_out = 0;
        overflow = 0;

        // if (sub) res_with_high = a + (~b) + 1;
        // else res_with_high= a + b;
        // 没有考虑a and b的bit number, 可能会导致bit num截断

        if (sub) res_with_high = {1'b0, a} + {1'b0, ~b} + 1'b1;
        else res_with_high = {1'b0, a} + {1'b0, b};

        result = res_with_high[WIDTH-1:0];
        carry_out = res_with_high[WIDTH];

        if (!sub) begin
            if (a[WIDTH-1] == b[WIDTH-1] && b[WIDTH-1] != result[WIDTH-1]) overflow = 1;
        end else begin
            if (a[WIDTH-1] != b[WIDTH-1] && a[WIDTH-1] != result[WIDTH-1]) overflow = 1;
        end
    end
endmodule