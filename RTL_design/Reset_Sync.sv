// ============================================================
// Problem: Asynchronous Reset Synchronizer
// ============================================================
// Design a reset synchronizer that takes an active-low asynchronous
// reset input and generates a reset signal that asserts asynchronously
// but deasserts synchronously to clk.
//
// Module interface:
// module reset_sync (
//   input  logic clk,
//   input  logic async_rst_n,
//   output logic rst_n_sync
// );
//
// Requirements:
// 1. The input async_rst_n is an active-low asynchronous reset.
//    - When async_rst_n is 0, the reset is asserted.
//    - When async_rst_n is 1, the reset is released.
//
// 2. The output rst_n_sync should also be active-low.
//    - rst_n_sync = 0 means reset is asserted.
//    - rst_n_sync = 1 means reset is deasserted.
//
// 3. Reset assertion should be asynchronous.
//    - As soon as async_rst_n goes low, the internal synchronizer
//      registers should clear to 0.
//    - rst_n_sync should go low without waiting for a clock edge.
//
// 4. Reset deassertion should be synchronous.
//    - When async_rst_n goes high, rst_n_sync should not immediately
//      go high.
//    - Instead, reset release should pass through two flip-flops clocked
//      by clk.
//    - rst_n_sync should go high only after the synchronized release
//      has propagated through the two flip-flop chain.
//
// 5. Internal synchronizer behavior:
//    - Use two flip-flops in the clk domain.
//    - On asynchronous reset assertion, both flip-flops clear to 0.
//    - After async_rst_n is released, the first flip-flop captures 1.
//    - The second flip-flop captures the first flip-flop on the next
//      clk edge.
//    - rst_n_sync is driven by the second flip-flop.
//
// 6. Purpose:
//    - This design prevents reset deassertion from happening too close
//      to a clk edge across the design.
//    - It reduces metastability risk during reset release.
//    - It allows all downstream logic in the clk domain to leave reset
//      in a clean, clock-aligned way.
//
// 7. Reset timing behavior:
//    - async_rst_n low:
//        rst_n_sync should be low.
//    - async_rst_n rises high:
//        rst_n_sync should remain low for synchronization cycles.
//    - After the synchronizer pipeline fills with 1s:
//        rst_n_sync should become high.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff.
//    - Use an asynchronous active-low reset in the sensitivity list.
//    - Do not use simulation delays such as # statements.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - clk is a free-running clock.
//    - async_rst_n may assert asynchronously.
//    - rst_n_sync is intended to be used only in the clk domain.
// ============================================================

`default_nettype none

module reset_sync (
  input  logic clk,
  input  logic async_rst_n,
  output logic rst_n_sync
);
    logic sync1_rst_n;

    always_ff @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync1_rst_n <= 0;
            rst_n_sync <= 0;
        end else begin
            sync1_rst_n <= async_rst_n;
            rst_n_sync <= sync1_rst_n;
        end
    end
endmodule