// ============================================================
// Problem: GF(2^8) Multiplier
// ============================================================
// Design a combinational multiplier over GF(2^8).
//
// The module should multiply two 8-bit operands a and b in the finite field
// GF(2^8), using the AES irreducible polynomial:
//
//   x^8 + x^4 + x^3 + x + 1
//
// This polynomial is represented as:
//
//   POLY = 9'h11B
//
// During reduction, when the shifted value overflows past bit 7, reduce by
// XORing with 8'h1B.
//
// Module interface:
// module gf_multiplier #(
//   parameter POLY = 9'h11B
// )(
//   input  logic [7:0] a,
//   input  logic [7:0] b,
//   output logic [7:0] product
// );
//
// Requirements:
// 1. The module should implement multiplication in GF(2^8) with:
//    - 8-bit input operand a;
//    - 8-bit input operand b;
//    - 8-bit output product.
//
// 2. Arithmetic field behavior:
//    - Addition in GF(2^8) should be XOR.
//    - Multiplication should be polynomial multiplication followed by modular
//      reduction using the irreducible polynomial.
//
// 3. Algorithm behavior:
//    - Use the Russian peasant multiplication algorithm.
//    - The algorithm should process each bit of b from bit 0 to bit 7.
//    - Maintain:
//        - a running multiplicand value;
//        - an accumulated result.
//
// 4. Accumulation behavior:
//    - Initialize the accumulated result to 0.
//    - For each bit i of b:
//        - if b[i] is 1, XOR the current multiplicand into the result;
//        - if b[i] is 0, leave the result unchanged.
//
//    Conceptually:
//
//      if (b[i])
//          result = result ^ current_a;
//
// 5. Multiplicand update behavior:
//    - After each iteration except the last, multiply the current multiplicand
//      by x in GF(2^8).
//    - This is done by left shifting by 1 bit.
//    - If the old MSB was 0:
//
//        next_a = {current_a[6:0], 1'b0}
//
//    - If the old MSB was 1, the shift overflows the 8-bit field and must be
//      reduced:
//
//        next_a = ({current_a[6:0], 1'b0} ^ 8'h1B)
//
// 6. Polynomial reduction behavior:
//    - POLY = 9'h11B represents the AES reduction polynomial.
//    - Since the x^8 term is removed during 8-bit reduction, the reduction
//      constant used after overflow is:
//
//        8'h1B
//
//    - Equivalently, this is POLY[7:0].
//
// 7. Output behavior:
//    - product should be the final accumulated result after processing all
//      8 bits of b.
//    - product should be 8 bits wide.
//
// 8. Timing behavior:
//    - The module should be purely combinational.
//    - There should be no clock.
//    - There should be no reset.
//    - product should update whenever a or b changes.
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use continuous assignments or always_comb.
//    - Do not use always_ff.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//    - The 8 iterations may be written as an unrolled datapath or as a
//      combinational loop.
//
// 10. Assumptions:
//    - a and b are interpreted as elements of GF(2^8), not normal integers.
//    - XOR is used for field addition.
//    - No signed arithmetic is involved.
//    - The intended default polynomial is AES polynomial 9'h11B.
// ============================================================\

`default_nettype none

module gf_multiplier #(
  parameter POLY = 9'h11B
)(
  input  logic [7:0] a,
  input  logic [7:0] b,
  output logic [7:0] product
);
    logic [7:0] a0, a1, a2, a3, a4, a5, a6, a7;
    logic [7:0] r0, r1, r2, r3, r4, r5, r6, r7;

    // Iteration 0 (bit 0 of b)
    assign a0 = a;
    assign r0 = 8'h00;
    assign r1 = b[0] ? (r0 ^ a0) : r0;
    assign a1 = a0[7] ? ({a0[6:0], 1'b0} ^ 8'h1B) : {a0[6:0], 1'b0};

    // Iteration 1 (bit 1 of b)
    assign r2 = b[1] ? (r1 ^ a1) : r1;
    assign a2 = a1[7] ? ({a1[6:0], 1'b0} ^ 8'h1B) : {a1[6:0], 1'b0};

    // Iteration 2 (bit 2 of b)
    assign r3 = b[2] ? (r2 ^ a2) : r2;
    assign a3 = a2[7] ? ({a2[6:0], 1'b0} ^ 8'h1B) : {a2[6:0], 1'b0};

    // Iteration 3 (bit 3 of b)
    assign r4 = b[3] ? (r3 ^ a3) : r3;
    assign a4 = a3[7] ? ({a3[6:0], 1'b0} ^ 8'h1B) : {a3[6:0], 1'b0};

    // Iteration 4 (bit 4 of b)
    assign r5 = b[4] ? (r4 ^ a4) : r4;
    assign a5 = a4[7] ? ({a4[6:0], 1'b0} ^ 8'h1B) : {a4[6:0], 1'b0};

    // Iteration 5 (bit 5 of b)
    assign r6 = b[5] ? (r5 ^ a5) : r5;
    assign a6 = a5[7] ? ({a5[6:0], 1'b0} ^ 8'h1B) : {a5[6:0], 1'b0};

    // Iteration 6 (bit 6 of b)
    assign r7 = b[6] ? (r6 ^ a6) : r6;
    assign a7 = a6[7] ? ({a6[6:0], 1'b0} ^ 8'h1B) : {a6[6:0], 1'b0};

    // Iteration 7 (bit 7 of b) — no need to update 'a' after the last step
    assign product = b[7] ? (r7 ^ a7) : r7;
endmodule