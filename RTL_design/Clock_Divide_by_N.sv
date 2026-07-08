// ============================================================
// Problem: Parameterized Clock Divider by N
// ============================================================
// Design a parameterized clock divider that generates a divided
// clock with output period N input-clock cycles.
//
// Module interface:
// module clk_divN #(
//   parameter N = 4
// )(
//   input  logic clk,
//   input  logic rst_n,
//   output logic clk_divN
// );
//
// Requirements:
// 1. Implement a clock divider that divides the input clock by N.
// 2. The output clk_divN should have a period equal to N cycles of clk.
// 3. The design should support both even and odd N values.
// 4. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, internal counters should clear to 0.
//    - The divided clock output should reset to 0.
// 5. Even N behavior:
//    - For even N, generate a divided clock using the positive edge of clk.
//    - The output should be high for N/2 input cycles.
//    - The output should be low for N/2 input cycles.
//    - This produces a 50% duty-cycle divided clock.
// 6. Odd N behavior:
//    - For odd N, a true 50% duty cycle cannot be generated using only
//      positive-edge logic.
//    - Use both positive-edge and negative-edge clocked logic to improve
//      the duty cycle.
//    - Combine the positive-edge and negative-edge generated waveforms
//      to produce the final divided clock.
// 7. Counter behavior:
//    - Internal counters should count from 0 to N-1.
//    - After reaching N-1, the counter should wrap back to 0.
//    - The counter width should be large enough to represent values
//      from 0 to N-1.
// 8. Output behavior:
//    - The divided clock should be derived from the counter values.
//    - For even N, the output may directly use the positive-edge waveform.
//    - For odd N, the output should be generated from both positive-edge
//      and negative-edge waveforms.
// 9. Parameter behavior:
//    - N determines the divide ratio.
//    - HALF may be computed as N/2 using integer division.
//    - ODD may be computed from the least significant bit of N.
// 10. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for clocked counter/output logic.
//    - Use a generate block to choose between even-N and odd-N logic.
//    - The design should be synthesizable.
// 11. Assumptions:
//    - N is greater than 1.
//    - The input clock is free-running.
//    - This module only generates a divided clock; it does not include
//      clock gating cells, clock-domain crossing logic, or glitch filtering.
// ============================================================

`default_nettype none

module clk_divN #(
  parameter N = 4
)(
  input  logic clk,
  input  logic rst_n,
  output logic clk_divN
);
    localparam int HALF = N/2;
    localparam int ODD = N[0];
    localparam int CNT_W = (N <= 1) ? 1 : $clog2(N);
    // localparam int CNT_W = $clog2(N);

    logic [CNT_W-1:0] pos_cnt, neg_cnt;
    logic pos_mark, neg_mark;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pos_cnt <= '0;
            pos_mark <= 0;
        end else begin
            pos_cnt <= (pos_cnt == N-1) ? '0 : pos_cnt+1;
            // 简化：pos_mark <= (pos_cnt < HALF);
            // neg_mark 同理
            if (pos_cnt < HALF)
                pos_mark <= 1;
            else
                pos_mark <= 0; // 第一遍忘了
        end
    end

    always_ff @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            neg_cnt <= '0;
            neg_mark <= 0;
        end else begin
            neg_cnt <= (neg_cnt == N-1) ? '0 : neg_cnt+1;
            if (neg_cnt < HALF)
                neg_mark <= 1;
            else
                neg_mark <= 0; // 第一遍忘了
        end
    end

    always_comb begin
        if (ODD)
            clk_divN = neg_mark | pos_mark;
        else
            clk_divN = pos_mark;
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:

module clk_divN #(
  parameter N = 4
)(
  input  logic clk,
  input  logic rst_n,
  output logic clk_divN
);
  localparam HALF = N / 2;
  localparam ODD  = N[0];   // 1 if N is odd

  logic [$clog2(N)-1:0] cnt_pos;
  logic                   pos_out;

  // Posedge counter
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt_pos <= 0;
      pos_out <= 0;
    end else begin
      if (cnt_pos == N - 1) cnt_pos <= 0;
      else cnt_pos <= cnt_pos + 1;
      pos_out <= (cnt_pos < HALF);
    end
  end

  // For even N: use posedge output directly (50% duty)
  // For odd N: also generate negedge version and OR them
  generate
    if (ODD) begin : gen_odd
      logic [$clog2(N)-1:0] cnt_neg;
      logic                   neg_out;

      always_ff @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
          cnt_neg <= 0;
          neg_out <= 0;
        end else begin
          if (cnt_neg == N - 1) cnt_neg <= 0;
          else cnt_neg <= cnt_neg + 1;
          neg_out <= (cnt_neg < HALF);
        end
      end

      assign clk_divN = pos_out & neg_out;
    end else begin : gen_even
      assign clk_divN = pos_out;
    end
  endgenerate
endmodule