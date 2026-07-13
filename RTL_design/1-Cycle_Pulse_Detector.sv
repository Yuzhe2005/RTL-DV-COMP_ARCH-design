// ============================================================
// Problem: One-Cycle Pulse Detector
// ============================================================
// Design a synchronous detector that asserts an output pulse when the
// input signal sig_in contains a high pulse that lasts exactly one clk
// cycle.
//
// Module interface:
// module one_cycle_pulse (
//   input  logic clk,
//   input  logic rst_n,
//   input  logic sig_in,
//   output logic onecycle_pulse
// );
//
// Requirements:
// 1. The module should sample sig_in on each rising edge of clk.
//
// 2. Detect the input pattern:
//      0 -> 1 -> 0
//    across three consecutive clock samples.
//
// 3. onecycle_pulse should assert when sig_in was high for exactly one
//    clock cycle and then returned low.
//
// 4. onecycle_pulse should be a registered output.
//    - It should update on the rising edge of clk.
//    - It should stay high for exactly one clk cycle when a one-cycle
//      input pulse is detected.
//    - Otherwise, it should be 0.
//
// 5. If sig_in stays high for multiple consecutive cycles, the module
//    should not assert onecycle_pulse.
//    Example:
//      sig_in: 0, 1, 1, 0
//      This is not a one-cycle pulse.
//
// 6. If sig_in stays low, onecycle_pulse should remain 0.
//
// 7. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low:
//        - internal delay registers should reset to 0;
//        - onecycle_pulse should reset to 0.
//
// 8. Implementation hint:
//    - Use delay registers to store previous sampled values of sig_in.
//    - A typical implementation keeps:
//        - d1 = sig_in delayed by 1 cycle;
//        - d2 = sig_in delayed by 2 cycles.
//    - Detect the pattern where:
//        - d2 was 0;
//        - d1 was 1;
//        - current sig_in is 0.
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use nonblocking assignments for registers.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 10. Assumptions:
//    - sig_in is synchronous to clk or has already been synchronized.
//    - This module detects one-clock-wide pulses based on sampled values,
//      not glitches that occur between clock edges.
// ============================================================

`default_nettype none

module one_cycle_pulse (
  input  logic clk,
  input  logic rst_n,
  input  logic sig_in,
  output logic onecycle_pulse
);
    logic prev1, prev2;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev1 <= '0;
            prev2 <= '0;
        end else begin
            prev1 <= prev2;
            prev2 <= sig_in;
        end
    end
    // assign onecycle_pulse = !prev1 && prev2 && !sig_in;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            onecycle_pulse <= 0;
        end else begin
            onecycle_pulse <= !prev1 && prev2 && !sig_in;
        end
    end
endmodule