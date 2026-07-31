// ============================================================
// Problem: Wallace Tree Adder / Carry-Save Adder for Three Inputs
// ============================================================
// Design a parameterized bit-parallel carry-save adder for three N-bit
// operands.
//
// The module should take three unsigned N-bit inputs:
//
//   a, b, c
//
// and produce:
//   - sum_bits:   bitwise partial-sum bits;
//   - carry_bits: bitwise carry bits;
//   - sum:        exact arithmetic result a + b + c.
//
// This is the basic 3:2 compressor / carry-save adder structure used inside
// Wallace tree multipliers.
//
// Module interface:
// module wallace_tree_adder #(
//   parameter N = 8
// )(
//   input  logic [N-1:0] a,
//   input  logic [N-1:0] b,
//   input  logic [N-1:0] c,
//   output logic [N-1:0] sum_bits,
//   output logic [N-1:0] carry_bits,
//   output logic [N+1:0] sum
// );
//
// Requirements:
// 1. The module should implement a parameterized 3-input carry-save adder with:
//    - three N-bit input operands;
//    - one N-bit partial sum output;
//    - one N-bit carry output;
//    - one N+2-bit exact arithmetic sum output.
//
// 2. sum_bits behavior:
//    - sum_bits should be the bitwise XOR of the three inputs.
//    - For each bit position i:
//
//        sum_bits[i] = a[i] ^ b[i] ^ c[i]
//
//    - This represents the partial sum bit produced by a full adder at each
//      bit position.
//
// 3. carry_bits behavior:
//    - carry_bits should indicate whether at least two of the three input bits
//      are 1 at each bit position.
//    - For each bit position i:
//
//        carry_bits[i] = majority(a[i], b[i], c[i])
//
//    - Equivalently:
//
//        carry_bits[i] = (a[i] & b[i]) |
//                        (b[i] & c[i]) |
//                        (a[i] & c[i])
//
//    - This represents the carry-out produced by a full adder at each bit
//      position.
//
// 4. Carry-save representation:
//    - sum_bits and carry_bits together represent the value of a + b + c.
//    - The carry bits should be interpreted as shifted left by one bit.
//    - The required invariant is:
//
//        a + b + c = sum_bits + (carry_bits << 1)
//
//    - carry_bits itself is not shifted in the output port;
//      the shift is conceptual when reconstructing the full sum.
//
// 5. Exact sum behavior:
//    - sum should output the exact arithmetic result:
//
//        sum = a + b + c
//
//    - The output width should be N+2 bits.
//    - N+2 bits are enough because the maximum value is:
//
//        3 * (2^N - 1)
//
//      which fits within N+2 bits.
//
// 6. Arithmetic interpretation:
//    - Inputs a, b, and c should be treated as unsigned values.
//    - sum_bits and carry_bits are bit-level carry-save outputs.
//    - sum is the unsigned arithmetic sum of a, b, and c.
//
// 7. Timing behavior:
//    - The module should be purely combinational.
//    - There should be no clock.
//    - There should be no reset.
//    - Outputs should update immediately when inputs change.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use continuous assignments or always_comb.
//    - Do not use always_ff.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - N is at least 2.
//    - N is intended to be in a small range such as 2 to 16.
//    - This module only compresses three operands into carry-save form and
//      also provides the final exact sum for checking or direct output.
//    - A larger Wallace tree would use multiple such 3:2 compressor stages.
// ============================================================

`default_nettype none

module wallace_tree_adder #(
  parameter N = 8
)(
  input  logic [N-1:0] a,
  input  logic [N-1:0] b,
  input  logic [N-1:0] c,
  output logic [N-1:0] sum_bits,
  output logic [N-1:0] carry_bits,
  output logic [N+1:0] sum
);
    assign sum_bits = a^b^c;
    assign carry_bits = (a&b) | (b&c) | (a&c);
    assign sum = a+b+c;
endmodule

