// ============================================================
// Problem: Modular Exponentiation
// ============================================================
// Design a combinational module that computes:
//
//   y = (a ** b) mod m
//
// where a, b, and m are unsigned 4-bit inputs, and y is an unsigned 4-bit
// output.
//
// Module interface:
// module mod_exp (
//   input  logic [3:0] a,
//   input  logic [3:0] b,
//   input  logic [3:0] m,
//   output logic [3:0] y
// );
//
// Requirements:
// 1. The module should compute modular exponentiation:
//
//      y = a^b mod m
//
// 2. Inputs:
//    - a is the base.
//    - b is the exponent.
//    - m is the modulus.
//    - All inputs are unsigned 4-bit values.
//
// 3. Output:
//    - y is the result of a^b mod m.
//    - y should be a 4-bit unsigned value.
//
// 4. Special case:
//    - If m == 0, modulo operation is undefined.
//    - For this problem, output y should be 0 when m == 0.
//
// 5. Normal behavior:
//    - If m != 0, compute a^b modulo m.
//    - If b == 0, the mathematical result is:
//
//        a^0 mod m = 1 mod m
//
//      Therefore:
//        if m == 1, y = 0;
//        otherwise, y = 1.
//
// 6. Implementation style:
//    - The design should be purely combinational.
//    - No clock or reset is required.
//    - Use SystemVerilog combinational logic.
//    - Intermediate multiplication should use enough bits to avoid losing
//      product bits before modulo reduction.
//    - The design should be synthesizable.
//
// 7. Suggested algorithm:
//    - Since b is 4 bits, b can be decomposed into bits b[0], b[1], b[2],
//      and b[3].
//    - Precompute:
//        a^1 mod m
//        a^2 mod m
//        a^4 mod m
//        a^8 mod m
//    - If b[i] is 1, include the corresponding power in the final product.
//    - Reduce intermediate products modulo m.
//
// 8. Assumptions:
//    - Inputs are treated as unsigned values.
//    - The modulus m is variable, not a constant.
//    - The problem is small enough that a fully combinational solution is
//      acceptable.
// ============================================================

`default_nettype none

module mod_exp (
  input  logic [3:0] a,
  input  logic [3:0] b,
  input  logic [3:0] m,
  output logic [3:0] y
);
  logic [3:0] base1, sq1, sq2, sq3;
  logic [3:0] p0, p1, p2, p3;
  logic [7:0] mul;
  logic [3:0] t0, t1;
  logic one_mod;

  always_comb begin
    base1 = '0;
    sq1 = '0;
    sq2 = '0;
    sq3 = '0;
    p0 = '0;
    p1 = '0;
    p2 = '0;
    p3 = '0;
    mul = '0;
    t0 = '0;
    t1 = '0;
    one_mod = 1'b1;
    y = '0;

    if (m == '0)
      y = '0;
    else begin
      base1 = a % m;
      mul = base1 * base1;
      sq1 = mul % m;
      mul = sq1 * sq1;
      sq2 = mul % m;
      mul = sq2 * sq2;
      sq3 = mul % m;

      one_mod = (m != 1);

      p0 = b[0] ? base1 : one_mod;
      p1 = b[1] ? sq1 : one_mod;
      p2 = b[2] ? sq2 : one_mod;
      p3 = b[3] ? sq3 : one_mod;

      mul = p0 * p1;
      t0 = mul % m;

      mul = p2 * p3;
      t1 = mul % m;

      mul = t0 * t1;
      y = mul % m;
    end
  end
endmodule