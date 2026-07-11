// ============================================================
// Problem: Binary Counter with Gray-Code Pointer Output
// ============================================================
// Design a parameterized pointer generator that maintains a binary
// counter and outputs both the binary pointer and its Gray-code version.
//
// Module interface:
// module gray_ptr #(
//   parameter W = 4
// )(
//   input  logic         clk,
//   input  logic         rst_n,
//   input  logic         inc,
//   output logic [W-1:0] bin_ptr,
//   output logic [W-1:0] gray_ptr
// );
//
// Requirements:
// 1. Maintain a W-bit binary pointer register bin_ptr.
//
// 2. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low, bin_ptr should reset to 0.
//    - Therefore, gray_ptr should also become 0.
//
// 3. Increment behavior:
//    - On each rising edge of clk, if inc is 1, increment bin_ptr by 1.
//    - If inc is 0, bin_ptr should hold its current value.
//
// 4. Wraparound behavior:
//    - bin_ptr is W bits wide.
//    - If bin_ptr reaches its maximum W-bit value and inc is asserted,
//      it should naturally wrap around to 0.
//
// 5. Gray-code output:
//    - gray_ptr should be the Gray-code encoding of bin_ptr.
//    - Use the standard binary-to-Gray conversion:
//
//        gray_ptr = bin_ptr ^ (bin_ptr >> 1);
//
// 6. Output behavior:
//    - bin_ptr exposes the current binary counter value.
//    - gray_ptr exposes the current Gray-code version of bin_ptr.
//    - gray_ptr may be generated combinationally from bin_ptr.
//
// 7. Purpose:
//    - Gray-code pointers are commonly used in asynchronous FIFO designs.
//    - In Gray code, only one bit changes between consecutive pointer values,
//      which makes pointer synchronization across clock domains safer.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for the binary pointer register.
//    - Use nonblocking assignment for sequential logic.
//    - Use continuous assignment or always_comb for Gray-code conversion.
//    - Do not use simulation delays or initial blocks for normal operation.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - clk is a free-running clock.
//    - inc is synchronous to clk.
//    - W is at least 1.
// ============================================================

`default_nettype none

module gray_ptr #(
  parameter W = 4
)(
  input  logic         clk,
  input  logic         rst_n,
  input  logic         inc,
  output logic [W-1:0] bin_ptr,
  output logic [W-1:0] gray_ptr
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_ptr <= '0;
        end else if (inc) begin
            bin_ptr <= bin_ptr+1;
        end
    end

    assign gray_ptr = bin_ptr ^ (bin_ptr >> 1);
endmodule