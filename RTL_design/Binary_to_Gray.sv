// ============================================================
// Problem: Binary Counter with Gray Code Output
// ============================================================
// Design a parameterized counter that maintains a binary count and also
// outputs the Gray-code representation of that binary count.
//
// Module interface:
// module bin_to_gray_counter #(
//   parameter W = 4
// )(
//   input  logic        clk,
//   input  logic        rst_n,
//   input  logic        enable,
//   output logic [W-1:0] bin_count,
//   output logic [W-1:0] gray_count
// );
//
// Requirements:
// 1. The module should contain a W-bit binary counter.
//
// 2. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low, bin_count should reset to 0.
//
// 3. Counting behavior:
//    - On each rising edge of clk:
//        - if enable is 1, bin_count should increment by 1.
//        - if enable is 0, bin_count should hold its current value.
//
// 4. Counter wraparound:
//    - bin_count is W bits wide.
//    - When bin_count reaches its maximum value, the next increment should
//      naturally wrap around to 0.
//
//    Example for W = 4:
//      1111 + 1 -> 0000
//
// 5. Gray-code output:
//    - gray_count should always be the Gray-code representation of the
//      current bin_count.
//    - gray_count should be computed combinationally from bin_count.
//
// 6. Binary-to-Gray conversion formula:
//      gray_count = bin_count ^ (bin_count >> 1)
//
// 7. Output behavior:
//    - bin_count is a registered output.
//    - gray_count is a combinational output derived from bin_count.
//    - When enable is 0, both bin_count and gray_count should hold
//      effectively the same values because bin_count does not change.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for the binary counter register.
//    - Use a continuous assign or always_comb for Gray-code generation.
//    - Use nonblocking assignment for bin_count.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - W is at least 1.
//    - enable is synchronous to clk.
//    - gray_count is not stored separately; it is directly derived from
//      bin_count.
// ============================================================

`default_nettype none

module bin_to_gray_counter #(
  parameter W = 4
)(
  input  logic        clk,
  input  logic        rst_n,
  input  logic        enable,
  output logic [W-1:0] bin_count,
  output logic [W-1:0] gray_count
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_count <= '0;
        end else if (enable) begin
            bin_count <= bin_count+1;
        end
    end
    assign gray_count = bin_count ^ (bin_count >> 1);
endmodule