// ============================================================
// Problem: Sliding Window Min/Max Tracker
// ============================================================
// Design a hardware module that tracks the minimum and maximum values
// inside the most recent WINDOW_SIZE valid input samples.
//
// Module interface:
// module sliding_window_minmax #(
//   parameter WINDOW_SIZE = 4,
//   parameter DATA_WIDTH  = 8
// )(
//   input  logic                   clk,
//   input  logic                   rst_n,
//   input  logic                   in_valid,
//   input  logic [DATA_WIDTH-1:0]  in_data,
//   output logic [DATA_WIDTH-1:0]  min_out,
//   output logic [DATA_WIDTH-1:0]  max_out,
//   output logic                   out_valid
// );
//
// Requirements:
// 1. The module receives a stream of unsigned input values through in_data.
//
// 2. A new input value should only be accepted when in_valid is 1.
//    - If in_valid is 0, the internal window should hold its previous
//      contents.
//    - No new sample should be inserted when in_valid is 0.
//
// 3. The module should maintain a sliding window containing the most recent
//    WINDOW_SIZE valid samples.
//
// 4. Once fewer than WINDOW_SIZE valid samples have been received:
//    - out_valid should be 0.
//    - min_out and max_out do not need to represent a complete valid window.
//
// 5. Once at least WINDOW_SIZE valid samples have been received:
//    - out_valid should be 1.
//    - min_out should be the minimum value among the most recent WINDOW_SIZE
//      valid samples.
//    - max_out should be the maximum value among the most recent WINDOW_SIZE
//      valid samples.
//
// 6. When the window is full and a new valid sample arrives:
//    - Insert the new sample into the window.
//    - Remove or overwrite the oldest sample.
//    - Recompute min_out and max_out over the updated WINDOW_SIZE samples.
//
// 7. The storage structure may be implemented as a circular buffer.
//    - Use a write pointer to indicate which entry will be overwritten next.
//    - After writing the last entry, the write pointer should wrap back to 0.
//
// 8. Keep track of how many valid samples have been received so far.
//    - The count should increase while the window is not full.
//    - Once the count reaches WINDOW_SIZE, it should remain saturated or be
//      treated as full.
//
// 9. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low:
//        - clear the internal window entries to 0;
//        - clear the write pointer;
//        - clear the fill count;
//        - deassert out_valid.
//
// 10. Min/max behavior:
//    - min_out should be computed by comparing all WINDOW_SIZE entries in
//      the current window.
//    - max_out should be computed by comparing all WINDOW_SIZE entries in
//      the current window.
//    - The comparison treats data as unsigned.
//
// 11. Output timing:
//    - out_valid should assert once the module has accepted enough valid
//      samples to fill the window.
//    - After the window becomes full, out_valid should remain asserted
//      unless reset occurs.
//
// 12. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential state updates.
//    - Use always_comb for combinational min/max comparison.
//    - Use loops to support parameterized WINDOW_SIZE.
//    - Do not use simulation delays or initial blocks for normal operation.
//    - The design should be synthesizable.
//
// 13. Assumptions:
//    - WINDOW_SIZE is at least 1.
//    - DATA_WIDTH is at least 1.
//    - in_data is unsigned.
//    - Only valid input samples contribute to the sliding window.
// ============================================================

`default_nettype none

module sliding_window_minmax #(
  parameter WINDOW_SIZE = 4,
  parameter DATA_WIDTH  = 8
)(
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic                   in_valid,
  input  logic [DATA_WIDTH-1:0]  in_data,
  output logic [DATA_WIDTH-1:0]  min_out,
  output logic [DATA_WIDTH-1:0]  max_out,
  output logic                   out_valid
);
    logic [DATA_WIDTH-1:0] window [WINDOW_SIZE];
    localparam int CNT_W = $clog2(WINDOW_SIZE);
    logic [CNT_W:0] count;

    assign out_valid = (count == WINDOW_SIZE);

    always_comb begin
        min_out = window[0];
        max_out = window[0];
        for (int i = 1; i < WINDOW_SIZE; i++) begin
            if (window[i] > max_out)
                max_out = window[i];
            if (window[i] < min_out)
                min_out = window[i];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
            for (int i = 0; i < WINDOW_SIZE; i++)
                window[i] <= '0;
        end else if (in_valid) begin
            for (int i = 1; i < WINDOW_SIZE; i++)
                window[i-1] <= window[i];
            window[WINDOW_SIZE-1] <= in_data;
            // count <= count+1;
            if (count < WINDOW_SIZE)
                count <= count+1;
        end
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:
// 我觉得更高效，因为不用整体shift window values, 只需要 track 一个wr_ptr 来
// 覆盖 oldest value

module sliding_window_minmax #(
  parameter WINDOW_SIZE = 4,
  parameter DATA_WIDTH  = 8
)(
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic                   in_valid,
  input  logic [DATA_WIDTH-1:0]  in_data,
  output logic [DATA_WIDTH-1:0]  min_out,
  output logic [DATA_WIDTH-1:0]  max_out,
  output logic                    out_valid
);
  logic [DATA_WIDTH-1:0] window [WINDOW_SIZE];
  logic [$clog2(WINDOW_SIZE):0] fill_cnt;
  logic [$clog2(WINDOW_SIZE)-1:0] wr_ptr;

  // Shift register buffer
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fill_cnt  <= '0;
      wr_ptr    <= '0;
      out_valid <= 0;
      for (int i = 0; i < WINDOW_SIZE; i++) window[i] <= '0;
    end else if (in_valid) begin
      window[wr_ptr] <= in_data;
      wr_ptr         <= (wr_ptr == WINDOW_SIZE - 1) ? '0 : wr_ptr + 1;
      if (fill_cnt < WINDOW_SIZE) fill_cnt <= fill_cnt + 1;
      out_valid      <= (fill_cnt == WINDOW_SIZE - 1) || (fill_cnt == WINDOW_SIZE);
    end
  end

  // Combinational min/max over entire window
  always_comb begin
    min_out = window[0];
    max_out = window[0];
    for (int i = 1; i < WINDOW_SIZE; i++) begin
      if (window[i] < min_out) min_out = window[i];
      if (window[i] > max_out) max_out = window[i];
    end
  end
endmodule