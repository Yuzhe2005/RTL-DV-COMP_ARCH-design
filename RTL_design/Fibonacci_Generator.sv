// ============================================================
// Problem: Fibonacci Number Generator
// ============================================================
// Design a parameterized Fibonacci sequence generator.
//
// Module interface:
// module fib_gen #(
//   parameter W = 16
// )(
//   input  logic          clk,
//   input  logic          rst_n,
//   input  logic          enable,
//   output logic [W-1:0]  fib_out
// );
//
// Requirements:
// 1. The module should generate Fibonacci numbers in sequence:
//
//      0, 1, 1, 2, 3, 5, 8, 13, ...
//
// 2. The output fib_out should reflect the current Fibonacci number.
//
// 3. The generator should maintain two internal W-bit registers.
//    - One register holds the current Fibonacci value.
//    - One register holds the next Fibonacci value.
//
// 4. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low:
//        - the current value should reset to 0;
//        - the next value should reset to 1;
//        - fib_out should therefore be 0 after reset.
//
// 5. Enable behavior:
//    - When enable is 1, the generator should advance to the next
//      Fibonacci number on the rising edge of clk.
//    - When enable is 0, the internal state should hold its current value.
//    - fib_out should also hold its current value when enable is 0.
//
// 6. Sequence update behavior:
//    - On each enabled cycle, update the internal state so that the
//      current value becomes the previous next value, and the next value
//      becomes the sum of the previous current and previous next values.
//
// 7. Width behavior:
//    - W controls the width of the Fibonacci values.
//    - Arithmetic is W-bit arithmetic.
//    - If the Fibonacci value exceeds W bits, it may wrap around naturally
//      due to fixed-width overflow.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential state updates.
//    - Use nonblocking assignments for registers.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - clk is a free-running clock.
//    - enable is synchronous to clk.
//    - The module only generates the Fibonacci sequence; it does not
//      include start/done handshaking or overflow detection.
// ============================================================

`default_nettype none

module fib_gen #(
  parameter W = 16
)(
  input  logic          clk,
  input  logic          rst_n,
  input  logic          enable,
  output logic [W-1:0]  fib_out
);
    logic [W-1:0] fib1, fib2;
    // fib1 当前 fib value
    // fib2 下一个 fib value
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fib1 <= '0;
            fib2 <= 1;
            // fib_out <= '0;
        end else if (enable) begin
            // fib_out <= fib1+fib2;
            // fib1 <= fib2;
            // fib2 <= fib_out;
            fib1 <= fib2;
            fib2 <= fib1+fib2;
        end
    end
    assign fib_out = fib1;
endmodule