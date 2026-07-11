// ============================================================
// Problem: Two-Flip-Flop Synchronizer
// ============================================================
// Design a simple 2-flop synchronizer that safely brings an
// asynchronous single-bit signal into a destination clock domain.
//
// Module interface:
// module two_ff_sync (
//   input  logic dst_clk,
//   input  logic dst_rst_n,
//   input  logic async_sig_in,
//   output logic sig_sync
// );
//
// Requirements:
// 1. The input async_sig_in is asynchronous to dst_clk.
//    - It may change at any time relative to dst_clk.
//    - It should not be used directly by downstream logic in the
//      destination clock domain.
//
// 2. Synchronize async_sig_in into the dst_clk domain using two
//    cascaded flip-flops.
//    - The first flip-flop samples async_sig_in.
//    - The second flip-flop samples the output of the first flip-flop.
//    - The synchronized output should come from the second flip-flop.
//
// 3. The purpose of the first flip-flop is to capture the asynchronous
//    signal and absorb possible metastability.
//
// 4. The purpose of the second flip-flop is to provide a more stable
//    synchronized signal for use by dst_clk-domain logic.
//
// 5. Reset behavior:
//    - dst_rst_n is an active-low asynchronous reset.
//    - When dst_rst_n is low:
//        - the first synchronizer flop should reset to 0;
//        - the second synchronizer flop should reset to 0;
//        - sig_sync should be 0.
//    - After reset is released, the synchronizer should begin sampling
//      async_sig_in on rising edges of dst_clk.
//
// 6. Output behavior:
//    - sig_sync should be the output of the second flip-flop.
//    - Changes on async_sig_in should appear on sig_sync after passing
//      through the two-flop synchronization chain.
//    - Therefore, sig_sync will usually reflect async_sig_in with about
//      two dst_clk cycles of latency.
//
// 7. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use nonblocking assignments for flip-flops.
//    - Do not use combinational logic to directly drive sig_sync from
//      async_sig_in.
//    - Do not use simulation delays or initial blocks for normal operation.
//    - The design should be synthesizable.
//
// 8. Assumptions:
//    - async_sig_in is a single-bit level signal.
//    - dst_clk is a free-running destination-domain clock.
//    - This synchronizer is intended for single-bit CDC signals.
//    - Multi-bit data buses require a different CDC scheme, such as
//      handshake, FIFO, or Gray-code synchronization.
// ============================================================

`default_nettype none

module two_ff_sync (
  input  logic dst_clk,
  input  logic dst_rst_n,
  input  logic async_sig_in,
  output logic sig_sync
);
    logic sig_sync1;

    always_ff @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            sig_sync <= 0;
            sig_sync1 <= 0;
        end else begin
            sig_sync1 <= async_sig_in;
            sig_sync <= sig_sync1;
        end
    end
endmodule