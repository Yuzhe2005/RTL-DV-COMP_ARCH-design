// ============================================================
// Problem: Divide-by-3 Clock Divider with ~50% Duty Cycle
// ============================================================
// Design a glitch-free clock divider that divides the input clock
// frequency by 3 and generates an output clock with approximately
// 50% duty cycle.
//
// Module interface:
// module clk_div3_50 (
//   input  logic clk,
//   input  logic rst_n,
//   output logic clk_div3_50
// );
//
// Requirements:
// 1. Divide ratio:
//    - The output clk_div3_50 should have frequency clk / 3.
//    - Equivalently, one full output period should span 3 input
//      clock cycles.
//
// 2. Duty cycle:
//    - The output should be approximately 50% duty cycle.
//    - Since divide-by-3 is an odd divide ratio, the ideal waveform
//      would be high for 1.5 input clock cycles and low for 1.5
//      input clock cycles.
//    - A posedge-only counter cannot naturally generate this half-cycle
//      timing, so both clock edges should be used.
//
// 3. Use both clock edges:
//    - Use positive-edge clocked logic to generate one registered
//      divide-by-3 phase.
//    - Use negative-edge clocked logic to generate another registered
//      phase shifted by half an input clock cycle.
//    - The final output should be derived from these registered phases
//      to achieve the approximate 50% duty cycle.
//
// 4. Counter behavior:
//    - Internal divide-by-3 counters should cycle through three states:
//        0, 1, 2, 0, 1, 2, ...
//    - After reaching the final state, the counter should wrap back
//      to 0.
//    - The counters should be wide enough to represent values 0, 1,
//      and 2.
//
// 5. Glitch-free behavior:
//    - The output must not generate runt pulses.
//    - Output transitions should only occur at intended clock boundaries,
//      such as posedge or negedge of the input clock.
//    - Avoid generating the output from unstable or partially decoded
//      combinational counter logic that could glitch.
//    - The final output should be based on registered signals.
//
// 6. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is asserted low:
//        - all internal counters should reset to 0;
//        - all internal phase/output registers should reset to 0;
//        - clk_div3_50 should be 0.
//    - After reset is released, the divider should settle into a stable
//      divide-by-3 waveform.
//
// 7. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Do not use simulation delays such as # statements.
//    - Do not use initial blocks for normal operation.
//    - The design should be synthesizable.
//
// 8. Assumptions:
//    - clk is a free-running clock.
//    - rst_n may be asserted asynchronously.
//    - The goal is a practical divide-by-3 clock with improved duty cycle,
//      not a purely posedge-only 33% or 66% duty-cycle divider.
// ============================================================

`default_nettype none

module clk_div3_50 (
  input  logic clk,
  input  logic rst_n,
  output logic clk_div3_50
);
    logic [1:0] cnt_pos, cnt_neg;
    logic pos_mark, neg_mark;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_pos <= '0;
            pos_mark <= 0;
        end else begin
            cnt_pos <= (cnt_pos == 2) ? '0 : cnt_pos+1;
            pos_mark <= (cnt_pos < 1);
        end
    end

    always_ff @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_neg <= '0;
            neg_mark <= 0;
        end else begin
            cnt_neg <= (cnt_neg == 2) ? '0 : cnt_neg+1;
            neg_mark <= (cnt_neg < 1);
        end
    end

    assign clk_div3_50 = neg_mark | pos_mark;
endmodule