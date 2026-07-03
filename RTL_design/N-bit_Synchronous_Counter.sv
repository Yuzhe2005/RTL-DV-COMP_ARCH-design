// ============================================================
// Problem: Parameterized Synchronous Counter
// ============================================================
// Design a parameterized synchronous counter.
// Module interface:
// module sync_counter #(
//   parameter N           = 4,
//   parameter RESET_VALUE = 0
// )(
//   input  logic         clk,
//   input  logic         rst_n,
//   input  logic         enable,
//   output logic [N-1:0] count
// );
// Requirements:
// 1. This is an N-bit synchronous counter.
//    - The counter updates on the rising edge of clk.
//    - The counter output width is controlled by parameter N.
//    - The counter should use sequential logic.
// 2. Reset behavior:
//    - rst_n is an active-low reset.
//    - When rst_n is low, count should be reset immediately.
//    - The reset value is controlled by parameter RESET_VALUE.
//    - RESET_VALUE should be cast or truncated to fit N bits.
// 3. Enable behavior:
//    - When rst_n is high and enable is high, count should increment by 1
//      on each rising edge of clk.
//    - When rst_n is high and enable is low, count should hold its current value.
// 4. Overflow behavior:
//    - Since count is N bits wide, it should naturally wrap around after
//      reaching the maximum N-bit value.
//    - No separate overflow output is required.
// 5. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - The design should be synthesizable.
// 6. Assumptions:
//    - N is positive.
//    - RESET_VALUE is an integer parameter.
//    - No load, decrement, clear, or terminal-count output is required.
// ============================================================

`default_nettype none

module sync_counter #(
  parameter N           = 4,
  parameter RESET_VALUE = 0
)(
  input  logic         clk,
  input  logic         rst_n,
  input  logic         enable,
  output logic [N-1:0] count
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= N'(RESET_VALUE);
        end else begin
            if (enable) count <= count+1;
        end
    end
endmodule