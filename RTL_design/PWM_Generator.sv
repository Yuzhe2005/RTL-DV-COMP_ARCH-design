// ============================================================
// Problem: Parameterized PWM Generator
// ============================================================
// Design a parameterized PWM generator.
//
// PWM stands for Pulse Width Modulation. The output pwm_out should be a
// periodic digital waveform. In each period, pwm_out stays high for DUTY
// clock cycles and low for the remaining clock cycles.
//
// Module interface:
// module pwm_gen #(
//   parameter COUNTER_WIDTH = 8,
//   parameter PERIOD        = 100,
//   parameter DUTY          = 50
// )(
//   input  logic clk,
//   input  logic rst_n,
//   output logic pwm_out
// );
//
// Requirements:
// 1. The module should contain a COUNTER_WIDTH-bit counter.
//
// 2. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low, counter should reset to 0.
//
// 3. Counter behavior:
//    - On each rising edge of clk, the counter increments by 1.
//    - When counter reaches PERIOD - 1, it should wrap back to 0.
//    - Therefore, one PWM period lasts PERIOD clock cycles.
//
// 4. PWM output behavior:
//    - pwm_out should be 1 when counter < DUTY.
//    - pwm_out should be 0 when counter >= DUTY.
//    - Therefore, pwm_out is high for DUTY cycles in each PERIOD-cycle
//      interval.
//
// 5. Example:
//    - If PERIOD = 100 and DUTY = 50:
//        - pwm_out is high for 50 cycles;
//        - pwm_out is low for 50 cycles;
//        - duty cycle is 50%.
//
//    - If PERIOD = 100 and DUTY = 25:
//        - pwm_out is high for 25 cycles;
//        - pwm_out is low for 75 cycles;
//        - duty cycle is 25%.
//
// 6. Output timing:
//    - counter is a registered state.
//    - pwm_out may be generated combinationally from counter.
//    - pwm_out should reflect the current counter value.
//
// 7. Edge cases:
//    - If DUTY = 0, pwm_out should always be 0.
//    - If DUTY >= PERIOD, pwm_out should stay high for the entire period.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for the counter register.
//    - Use a continuous assign or always_comb for pwm_out generation.
//    - Use nonblocking assignments for sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - PERIOD is greater than 0.
//    - COUNTER_WIDTH is large enough to represent PERIOD - 1.
//    - DUTY is between 0 and PERIOD for normal PWM operation.
// ============================================================

`default_nettype none

module pwm_gen #(
  parameter COUNTER_WIDTH = 8,
  parameter PERIOD        = 100,
  parameter DUTY          = 50
)(
  input  logic clk,
  input  logic rst_n,
  output logic pwm_out
);
    logic [COUNTER_WIDTH-1:0] counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out <= '0;
            counter <= '0;
        end else begin
            counter <= (counter == PERIOD-1) ? '0 : counter+1;
            pwm_out <= (counter < DUTY);
        end
    end
endmodule