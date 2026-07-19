// ============================================================
// Problem: Parameterized Binary Decoder
// ============================================================
// Design a parameterized combinational binary decoder.
//
// The decoder takes an N-bit binary input and converts it into a one-hot
// output vector of width 2^N. When enable is low, the output should be all
// zeros.
//
// Module interface:
// module decoder #(
//   parameter N = 3
// )(
//   input  logic [N-1:0]       in,
//   input  logic               en,
//   output logic [(1<<N)-1:0]  out
// );
//
// Requirements:
// 1. The module should implement an N-to-2^N decoder.
//
// 2. Output width:
//    - The output width should be 2^N.
//    - For example:
//        N = 2 -> out has 4 bits
//        N = 3 -> out has 8 bits
//        N = 4 -> out has 16 bits
//
// 3. Enable behavior:
//    - If en = 0:
//        out should be all zeros.
//    - If en = 1:
//        exactly one bit of out should be high.
//
// 4. Decode behavior:
//    - When en = 1, out[in] should be 1.
//    - All other bits of out should be 0.
//
// 5. Example with N = 3:
//    - in = 3'b000, en = 1 -> out = 8'b0000_0001
//    - in = 3'b001, en = 1 -> out = 8'b0000_0010
//    - in = 3'b010, en = 1 -> out = 8'b0000_0100
//    - in = 3'b011, en = 1 -> out = 8'b0000_1000
//    - in = 3'b100, en = 1 -> out = 8'b0001_0000
//    - in = 3'b101, en = 1 -> out = 8'b0010_0000
//    - in = 3'b110, en = 1 -> out = 8'b0100_0000
//    - in = 3'b111, en = 1 -> out = 8'b1000_0000
//
// 6. Example when disabled:
//    - in can be any value.
//    - en = 0 -> out = 0.
//
// 7. Implementation style:
//    - The design should be purely combinational.
//    - No clock or reset is required.
//    - The design should be parameterized by N.
//    - The design should be synthesizable.
//    - Do not use delays or simulation-only constructs.
//
// 8. Assumptions:
//    - N is at least 1.
//    - The input in is always within the valid N-bit range.
// ============================================================

`default_nettype none

module decoder #(
  parameter N = 3
)(
  input  logic [N-1:0]       in,
  input  logic               en,
  output logic [(1<<N)-1:0]  out
);
    always_comb begin
        out = '0;
        if (en) out[in] = 1'b1;
    end
endmodule