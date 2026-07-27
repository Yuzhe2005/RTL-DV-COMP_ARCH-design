// ============================================================
// Problem: Sliding Window Median Filter
// ============================================================
// Design a parameterized sliding-window median filter.
//
// The module should maintain a window of the most recent WIN input samples.
// Once the window is full, each valid input should produce the median value
// of the current window.
//
// The reference implementation uses:
//   - a shift-register window to store recent samples;
//   - a saturating fill counter to track when the window is full;
//   - a combinational bubble sort to sort the window values;
//   - the middle sorted value as the median.
//
// Module interface:
// module sliding_window_median #(
//   parameter DATA_W = 8,
//   parameter WIN    = 5
// )(
//   input  logic                 clk,
//   input  logic                 resetn,
//   input  logic                 valid_in,
//   input  logic [DATA_W-1:0]    data_in,
//   output logic                 valid_out,
//   output logic [DATA_W-1:0]    median_out
// );
//
// Requirements:
// 1. The module should implement a sliding-window median filter with:
//    - WIN samples in the window;
//    - DATA_W bits per sample;
//    - one input sample data_in;
//    - one input valid signal valid_in;
//    - one output median value median_out;
//    - one output valid signal valid_out.
//
// 2. Window storage behavior:
//    - Use an internal shift register window to store the most recent WIN
//      input samples.
//    - window[0] should hold the newest sample.
//    - window[WIN-1] should hold the oldest sample.
//    - When valid_in is asserted on a rising clock edge:
//        - data_in should be written into window[0];
//        - old window[0] should move to window[1];
//        - old window[1] should move to window[2];
//        - and so on;
//        - old window[WIN-2] should move to window[WIN-1].
//
// 3. Behavior when valid_in is low:
//    - No new sample should be accepted.
//    - The window contents should hold their previous values.
//    - valid_out should be deasserted to 0.
//    - median_out may continue to reflect the median of the stored window,
//      but it should not be considered valid unless valid_out is 1.
//
// 4. Fill counter behavior:
//    - Use an internal fill_count to track how many valid samples have been
//      accepted so far.
//    - fill_count should start at 0 after reset.
//    - Each time valid_in is asserted, fill_count should increment by 1 until
//      it reaches WIN.
//    - Once fill_count reaches WIN, it should saturate and remain at WIN.
//    - fill_count should not increment when valid_in is 0.
//
// 5. valid_out behavior:
//    - valid_out should be asserted only when the window contains enough valid
//      samples to compute a full-window median.
//    - Before WIN valid samples have been accepted, valid_out should be 0.
//    - On the clock edge that accepts the WIN-th valid sample, valid_out should
//      become 1 after that edge.
//    - After the window is full, each cycle with valid_in asserted should
//      produce valid_out asserted.
//    - If valid_in is 0, valid_out should be 0.
//
// 6. Median computation behavior:
//    - The module should sort the current window contents in ascending order.
//    - The median should be selected as:
//
//        sorted[WIN/2]
//
//    - For the default WIN = 5:
//
//        sorted[0] = smallest value
//        sorted[1] = second smallest value
//        sorted[2] = median value
//        sorted[3] = second largest value
//        sorted[4] = largest value
//
//      Therefore:
//
//        median_out = sorted[2]
//
// 7. Sorting behavior:
//    - Use combinational logic to copy the window contents into a temporary
//      sorted array.
//    - Sort the temporary array in ascending order.
//    - The internal window itself does not need to be stored in sorted order.
//    - Sorting should not modify the window shift register directly.
//
// 8. Timing behavior:
//    - On a clock edge where valid_in is 1:
//        - the new data_in is shifted into the window;
//        - fill_count updates;
//        - valid_out updates based on whether the window is full after this
//          accepted sample.
//    - After the clock edge, median_out should reflect the median of the
//      updated window contents.
//    - median_out is combinational with respect to the stored window.
//
// 9. Reset behavior:
//    - Reset is synchronous active-low.
//    - On posedge clk, if resetn is 0:
//        - all window entries should be cleared to 0;
//        - fill_count should be cleared to 0;
//        - valid_out should be cleared to 0.
//    - median_out may become 0 as a result of the cleared window.
//
// 10. Data comparison behavior:
//    - Samples are treated as unsigned values.
//    - Sorting comparisons should use unsigned ordering.
//    - The median is the middle value after unsigned ascending sort.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use an internal shift register for the sliding window.
//    - Use always_ff for sequential state updates.
//    - Use always_comb for combinational sorting and median selection.
//    - Use nonblocking assignments in sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 12. Assumptions:
//    - WIN is at least 1.
//    - The default intended use is WIN = 5.
//    - WIN is preferably odd, so sorted[WIN/2] is the true middle element.
//    - For even WIN, sorted[WIN/2] selects the upper-middle element.
//    - There is no ready/backpressure signal.
//    - The module accepts at most one valid input sample per cycle.
// ============================================================

`default_nettype none

module sliding_window_median #(
  parameter DATA_W = 8,
  parameter WIN    = 5
)(
  input  logic                 clk,
  input  logic                 resetn,
  input  logic                 valid_in,
  input  logic [DATA_W-1:0]    data_in,
  output logic                 valid_out,
  output logic [DATA_W-1:0]    median_out
);
    logic [DATA_W-1:0] window [WIN];
    localparam int CNT_W = $clog2(WIN);
    logic [CNT_W-1:0] count;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            for (int i = 0; i < WIN; i++) window[i] <= '0;
            count <= '0;
            valid_out <= 0;
        end else begin
            if (valid_in) begin
                count <= (count == WIN-1) ? count : count+1;
                valid_out <= (count >= WIN-1);
                for (int i = 0; i < WIN-1; i++)
                    window[i] <= window[i+1];
                window[WIN-1] <= data_in;
            end else 
                valid_out <= 0;
        end
    end

    logic [DATA_W-1:0] sorted [WIN];

    assign median_out = sorted[WIN/2];

    always_comb begin
        for (int i = 0; i < WIN; i++)
            sorted[i] = window[i];
        for (int i= 0; i < WIN; i++) begin
            for (int j = 0; j < WIN-1; j++) begin
                if (sorted[j] > sorted[j+1])
                    {sorted[j], sorted[j+1]} = {sorted[j+1], sorted[j]};
            end
        end
    end
endmodule