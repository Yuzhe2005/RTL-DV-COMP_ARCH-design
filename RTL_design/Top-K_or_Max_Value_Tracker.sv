// ============================================================
// Problem: Top-K Value Tracker
// ============================================================
// Design a hardware module that tracks the largest K values seen so
// far from a stream of input data.
//
// Module interface:
// module top_k_tracker #(
//   parameter K          = 3,
//   parameter DATA_WIDTH = 8
// )(
//   input  logic                  clk,
//   input  logic                  rst_n,
//   input  logic                  in_valid,
//   input  logic [DATA_WIDTH-1:0] in_data,
//   output logic [DATA_WIDTH-1:0] top_values [K]
// );
//
// Requirements:
// 1. The module receives one input value in_data per clock cycle.
//
// 2. The input value should only be considered when in_valid is 1.
//    - If in_valid is 0, the stored top-K values should hold their
//      previous values.
//
// 3. The module should maintain the largest K values seen so far.
//
// 4. The output top_values should be sorted from largest to smallest:
//      top_values[0]     = largest value seen so far
//      top_values[1]     = second largest value
//      ...
//      top_values[K-1]   = K-th largest value
//
// 5. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low, all entries of top_values should reset to 0.
//
// 6. Insert behavior:
//    - When in_valid is 1, compare in_data against the current top_values.
//    - If in_data is larger than one of the stored top-K values, insert
//      it into the correct sorted position.
//    - Shift smaller values downward to make room.
//    - Drop the previous smallest top-K value if necessary.
//
// 7. If in_data is not large enough to enter the top-K list, top_values
//    should remain unchanged.
//
// 8. Duplicate values are allowed.
//    - If in_data equals an existing value, it may still appear in the
//      top-K list if it is large enough relative to the lower entries.
//    - The module does not need to remove duplicates.
//
// 9. Combinational next-state behavior:
//    - Use combinational logic to compute the next top-K array.
//    - Start by copying current top_values into next_top.
//    - Find the first insertion position where in_data is greater than
//      the current stored value.
//    - Insert in_data there and shift later entries down by one position.
//
// 10. Sequential update behavior:
//    - On each rising edge of clk, update top_values with next_top.
//    - If in_valid is 0, next_top should equal current top_values, so
//      the state holds.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use always_comb for insertion/next-state logic.
//    - Use always_ff for registered top_values state.
//    - Use loops to support parameter K.
//    - Do not use simulation delays or initial blocks for normal operation.
//    - The design should be synthesizable.
//
// 12. Assumptions:
//    - K is at least 1.
//    - DATA_WIDTH is at least 1.
//    - in_data is treated as an unsigned value.
//    - This module only tracks values; it does not track timestamps,
//      indices, or how many inputs have been seen.
// ============================================================

`default_nettype none

module top_k_tracker #(
  parameter K          = 3,
  parameter DATA_WIDTH = 8
)(
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  in_valid,
  input  logic [DATA_WIDTH-1:0] in_data,
  output logic [DATA_WIDTH-1:0] top_values [K]
);
    logic [DATA_WIDTH-1:0] top_values_d [K];

    always_comb begin
        for (int i = 0; i < K ; i++) top_values_d[i] = 0; // 第一遍忘了归零了
        for (int i = 0; i < K; i++) begin
            if (top_values[i] < in_data) begin
                top_values_d[i] = in_data;
                for (int j = i+1; j < K; j++) begin
                    top_values_d[j] = top_values[j-1];
                end
                break;
            end else 
                top_values_d[i] = top_values[i];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < K; k++)
                top_values[k] <= '0;
        end else if (in_valid) begin
            for (int k = 0; k < K; k++)
                top_values[k] <= top_values_d[k];
        end
    end
endmodule