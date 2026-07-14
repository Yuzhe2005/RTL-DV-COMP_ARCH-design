// ============================================================
// Problem: Rising/Falling Edge Detector
// ============================================================
// Design a synchronous edge detector for a single-bit input signal.
//
// Module interface:
// module edge_detector (
//   input  logic clk,
//   input  logic rst_n,
//   input  logic sig_in,
//   output logic rise_pulse,
//   output logic fall_pulse
// );
//
// Requirements:
// 1. The module should sample sig_in on each rising edge of clk.
//
// 2. Store the previous sampled value of sig_in in an internal register.
//
// 3. Generate rise_pulse:
//    - rise_pulse should assert for one clock cycle when sig_in changes
//      from 0 to 1.
//    - This means the current sig_in is 1 and the previous sampled value
//      was 0.
//
// 4. Generate fall_pulse:
//    - fall_pulse should assert for one clock cycle when sig_in changes
//      from 1 to 0.
//    - This means the current sig_in is 0 and the previous sampled value
//      was 1.
//
// 5. If sig_in does not change between two consecutive clock samples:
//    - rise_pulse should be 0.
//    - fall_pulse should be 0.
//
// 6. Pulse timing:
//    - rise_pulse and fall_pulse should be registered outputs.
//    - Each pulse should last exactly one clock cycle.
//    - The pulse should be generated on the clock edge where the transition
//      is observed.
//
// 7. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low:
//        - clear the previous sampled value to 0;
//        - clear rise_pulse to 0;
//        - clear fall_pulse to 0.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use nonblocking assignments for registers.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - sig_in is synchronous to clk or has already been synchronized before
//      entering this module.
//    - This module detects transitions between consecutive clock samples,
//      not glitches that happen between clock edges.
// ============================================================

`default_nettype none

module edge_detector (
  input  logic clk,
  input  logic rst_n,
  input  logic sig_in,
  output logic rise_pulse,
  output logic fall_pulse
);
    logic prev;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev <= 0;
            rise_pulse <= 0;
            fall_pulse <= 0;
        end else begin
            prev <= sig_in;
            rise_pulse <= !prev && sig_in;
            fall_pulse <= prev && !sig_in;
        end
    end
endmodule