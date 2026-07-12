// ============================================================
// Problem: Rising/Falling/Toggle Edge Detector
// ============================================================
// Design a synchronous edge detector that observes a single-bit input
// signal and generates one-cycle pulses when the signal rises, falls,
// or toggles.
//
// Module interface:
// module edge_toggle_detect (
//   input  logic clk,
//   input  logic rst_n,
//   input  logic sig_in,
//   output logic rise_pulse,
//   output logic fall_pulse,
//   output logic toggle_pulse
// );
//
// Requirements:
// 1. The module should sample sig_in on each rising edge of clk.
//
// 2. Store the previous sampled value of sig_in in an internal register.
//
// 3. Generate rise_pulse:
//    - rise_pulse should assert for one clk cycle when sig_in changes
//      from 0 to 1.
//    - This means the current sig_in is 1 and the previous sampled
//      value was 0.
//
// 4. Generate fall_pulse:
//    - fall_pulse should assert for one clk cycle when sig_in changes
//      from 1 to 0.
//    - This means the current sig_in is 0 and the previous sampled
//      value was 1.
//
// 5. Generate toggle_pulse:
//    - toggle_pulse should assert for one clk cycle whenever sig_in
//      changes value.
//    - It should assert on both rising and falling transitions.
//    - It should be 0 when sig_in stays the same.
//
// 6. Pulse behavior:
//    - All three outputs should be synchronous to clk.
//    - Each pulse should last exactly one clk cycle.
//    - If there is no corresponding transition, the pulse should be 0.
//
// 7. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low:
//        - the previous sampled value should reset to 0;
//        - rise_pulse should reset to 0;
//        - fall_pulse should reset to 0;
//        - toggle_pulse should reset to 0.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use nonblocking assignments for registers.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - sig_in is synchronous to clk or has already been synchronized
//      before entering this module.
//    - This module detects transitions between consecutive clk samples,
//      not asynchronous glitches between clock edges.
// ============================================================

`default_nettype none

module edge_toggle_detect (
  input  logic clk,
  input  logic rst_n,
  input  logic sig_in,
  output logic rise_pulse,
  output logic fall_pulse,
  output logic toggle_pulse
);
    logic prev;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev <= 0;
            rise_pulse <= 0;
            fall_pulse <= 0;
            toggle_pulse <= 0;
        end else begin
            prev <= sig_in;
            rise_pulse <= !prev && sig_in;
            fall_pulse <= prev && !sig_in;
            toggle_pulse <= prev != sig_in;
        end
    end
endmodule