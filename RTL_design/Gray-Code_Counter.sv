// ============================================================
// Problem: Parameterized Gray-Code Counter
// ============================================================
// Design a parameterized Gray-code counter.
// Module interface:
// module gray_counter #(
//   parameter N = 4
// )(
//   input  logic         clk,
//   input  logic         rst_n,
//   input  logic         enable,
//   output logic [N-1:0] gray_count
// );
// Requirements:
// 1. This is an N-bit Gray-code counter.
//    - The output width is controlled by parameter N.
//    - The counter should advance only when enable is high.
//    - The counter should hold its current value when enable is low.
// 2. Reset behavior:
//    - rst_n is an active-low reset.
//    - When rst_n is low, the internal count state should reset to zero.
//    - After reset, gray_count should represent the Gray-code value for zero.
// 3. Counting behavior:
//    - On each rising edge of clk, if rst_n is high and enable is high,
//      the counter should advance to the next count value.
//    - The count sequence should wrap around naturally after the maximum N-bit value.
// 4. Gray-code output behavior:
//    - gray_count should output the Gray-code encoding of the current count value.
//    - Between consecutive enabled count values, gray_count should change by only one bit.
//    - gray_count may be generated combinationally from the internal count state.
// 5. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for the sequential count state.
//    - Use combinational logic or continuous assignment for Gray-code output generation.
//    - The design should be synthesizable.
// 6. Assumptions:
//    - N is positive.
//    - No load, clear, decrement, or terminal-count output is required.
//    - No separate binary count output is required.
// ============================================================

`default_nettype none

module gray_counter #(
  parameter N = 4
)(
  input  logic         clk,
  input  logic         rst_n,
  input  logic         enable,
  output logic [N-1:0] gray_count
);
    function automatic logic [N-1:0] gray(input logic [N-1:0] bin);
        gray = bin ^ (bin >> 1);
    endfunction

    logic [N-1:0] bin_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_count <= '0;
        end else begin
            if (enable) bin_count <= bin_count+1;
        end
    end

    assign gray_count = gray(bin_count);
endmodule