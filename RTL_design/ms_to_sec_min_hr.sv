// ============================================================
// Problem: Timebase Pulse Generator
// ============================================================
// Design a timebase generator that receives a 1ms tick pulse and
// generates one-cycle pulses for 1 second, 1 minute, and 1 hour.
//
// Module interface:
// module timebase (
//   input  logic clk,
//   input  logic rst_n,
//   input  logic tick_1ms,
//   output logic sec_pulse,
//   output logic min_pulse,
//   output logic hour_pulse
// );
//
// Requirements:
// 1. The module receives tick_1ms as an input pulse.
//    - tick_1ms is asserted for one clk cycle every 1 millisecond.
//    - The module should only advance the millisecond counter when
//      tick_1ms is 1.
//
// 2. Generate sec_pulse:
//    - Count 1000 tick_1ms pulses.
//    - After 1000 valid millisecond ticks, assert sec_pulse for one
//      clk cycle.
//    - The millisecond counter should count from 0 to 999.
//    - When the counter reaches 999 and tick_1ms is asserted:
//        - reset the millisecond counter to 0;
//        - assert sec_pulse for one clk cycle.
//
// 3. Generate min_pulse:
//    - Count 60 sec_pulse events.
//    - After 60 second pulses, assert min_pulse for one clk cycle.
//    - The second counter should count from 0 to 59.
//    - When the counter reaches 59 and sec_pulse is observed:
//        - reset the second counter to 0;
//        - assert min_pulse for one clk cycle.
//
// 4. Generate hour_pulse:
//    - Count 60 min_pulse events.
//    - After 60 minute pulses, assert hour_pulse for one clk cycle.
//    - The minute counter should count from 0 to 59.
//    - When the counter reaches 59 and min_pulse is observed:
//        - reset the minute counter to 0;
//        - assert hour_pulse for one clk cycle.
//
// 5. Pulse behavior:
//    - sec_pulse should be a registered one-cycle pulse.
//    - min_pulse should be a registered one-cycle pulse.
//    - hour_pulse should be a registered one-cycle pulse.
//    - Each pulse should be cleared to 0 by default every clock cycle,
//      and only asserted when its corresponding counter rolls over.
//
// 6. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low:
//        - clear the millisecond counter;
//        - clear the second counter;
//        - clear the minute counter;
//        - deassert sec_pulse;
//        - deassert min_pulse;
//        - deassert hour_pulse.
//
// 7. Counter widths:
//    - ms_cnt should be wide enough to count 0 through 999.
//    - sec_cnt should be wide enough to count 0 through 59.
//    - min_cnt should be wide enough to count 0 through 59.
//
// 8. Output timing:
//    - All pulse outputs are synchronous to clk.
//    - Pulses are generated from registered counters.
//    - The design may cascade registered pulses from one stage to the
//      next stage:
//        tick_1ms   -> sec_pulse
//        sec_pulse  -> min_pulse
//        min_pulse  -> hour_pulse
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential counters and registered pulses.
//    - Use nonblocking assignments for registers.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 10. Assumptions:
//    - tick_1ms is synchronous to clk.
//    - tick_1ms is a one-cycle pulse.
//    - The module only generates pulses; it does not output the current
//      second, minute, or hour count.
// ============================================================

`default_nettype none

module timebase (
  input  logic clk,
  input  logic rst_n,
  input  logic tick_1ms,
  output logic sec_pulse,
  output logic min_pulse,
  output logic hour_pulse
);
    localparam int MSCNT_W = $clog2(1000);
    localparam int CNT_W = $clog2(60);

    logic [MSCNT_W-1:0] ms_cnt;
    logic [CNT_W-1:0] sec_cnt, min_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ms_cnt <= '0;
            sec_pulse <= 0;
        end else begin
            sec_pulse <= 0;
            if (tick_1ms) begin
                if (ms_cnt == 999) begin
                    ms_cnt <= '0;
                    sec_pulse <= 1;
                end else begin
                    ms_cnt <= ms_cnt+1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec_cnt <= '0;
            min_pulse <= 0;
        end else begin
            min_pulse <= 0;
            if (sec_pulse) begin
                if (sec_cnt == 59) begin
                    sec_cnt <= '0;
                    min_pulse <= 1;
                end else begin
                    sec_cnt <= sec_cnt+1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            min_cnt <= '0;
            hour_pulse <= 0;
        end else begin
            hour_pulse <= 0;
            if (hour_pulse) begin
                if (min_cnt ==  59) begin
                    min_cnt <= '0;
                    hour_pulse <= 1;
                end else begin
                    min_cnt <= min_cnt+1;
                end
            end
        end
    end
endmodule