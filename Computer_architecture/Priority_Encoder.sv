// ============================================================
// Problem: Parameterized LSB-First Priority Encoder
// ============================================================
// Design a parameterized combinational priority encoder.
//
// The encoder takes an N-bit input vector and outputs the index of the
// highest-priority asserted bit. In this problem, the lowest bit index has
// the highest priority.
//
// Module interface:
// module priority_enc #(
//   parameter N = 8
// )(
//   input  logic [N-1:0]          in,
//   output logic [$clog2(N)-1:0] out,
//   output logic                 valid
// );
//
// Requirements:
// 1. The module should implement an N-input priority encoder.
//
// 2. Priority rule:
//    - LSB-first priority.
//    - Lower index bits have higher priority.
//    - in[0] has the highest priority.
//    - in[N-1] has the lowest priority.
//
// 3. valid behavior:
//    - valid should be 1 if at least one bit of in is 1.
//    - valid should be 0 if in is all zeros.
//
// 4. out behavior:
//    - If valid = 1, out should be the index of the lowest-numbered bit
//      in in that is asserted.
//    - If valid = 0, out should be 0.
//
// 5. Example with N = 8:
//    - in = 8'b0000_0000 -> valid = 0, out = 0
//    - in = 8'b0000_0001 -> valid = 1, out = 0
//    - in = 8'b0000_0010 -> valid = 1, out = 1
//    - in = 8'b0000_0100 -> valid = 1, out = 2
//    - in = 8'b1000_0000 -> valid = 1, out = 7
//
// 6. Priority example:
//    - in = 8'b1010_1000
//    - Asserted bits are in[3], in[5], and in[7].
//    - Since this is LSB-first priority, in[3] wins.
//    - Therefore:
//        valid = 1
//        out   = 3
//
// 7. Implementation style:
//    - The design should be purely combinational.
//    - No clock or reset is required.
//    - Use default assignments to avoid latches.
//    - The design should be parameterized by N.
//    - The design should be synthesizable.
//    - Do not use delays or simulation-only constructs.
//
// 8. Assumptions:
//    - N is at least 2.
//    - out has enough bits to represent indices 0 to N-1.
// ============================================================

`default_nettype none

module priority_enc #(
  parameter N = 8
)(
  input  logic [N-1:0]          in,
  output logic [$clog2(N)-1:0] out,
  output logic                 valid
);
    always_comb begin
        out = '0;
        valid = 0;

        for (int i = 0; i < N; i++) begin
            if (in[i]) begin
                valid = 1'b1;
                out = i[$clog2(N)-1:0];
                break;
            end
        end
    end
endmodule