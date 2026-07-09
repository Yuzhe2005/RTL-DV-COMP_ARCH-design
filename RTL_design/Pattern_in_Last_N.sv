// ============================================================
// Problem: Pattern Search Within a Sliding Bit Window
// ============================================================
// Design a module that stores the most recent N serial input bits
// in a shift-register window and checks whether a K-bit pattern
// appears anywhere inside that window.
//
// Module interface:
// module pattern_in_window #(
//   parameter N       = 8,
//   parameter K       = 5,
//   parameter PATTERN = 5'b10110
// )(
//   input  logic clk,
//   input  logic rst_n,
//   input  logic bit_in,
//   output logic found
// );
//
// Requirements:
// 1. The module receives one serial input bit per clock cycle through
//    bit_in.
//
// 2. Maintain an N-bit sliding window containing the most recent N bits.
//
// 3. On every rising edge of clk:
//    - shift the previous window contents by one bit;
//    - insert the newest bit_in into the window;
//    - discard the oldest bit.
//
// 4. In this specification, the newest bit should enter at the MSB side
//    of the window.
//    Example:
//      window <= {bit_in, window[N-1:1]};
//
// 5. The module should check whether the K-bit constant PATTERN appears
//    anywhere inside the current N-bit window.
//
// 6. The output found should be combinational.
//    - found should be 1 if any K-bit slice of window equals PATTERN.
//    - found should be 0 if no K-bit slice matches PATTERN.
//
// 7. The search should examine every possible K-bit slice inside window.
//    - Valid starting positions are 0 through N-K.
//    - For each position i, compare window[i +: K] against PATTERN.
//
// 8. If multiple slices match PATTERN at the same time, found should
//    still simply be 1.
//    - The module does not need to report how many matches exist.
//    - The module does not need to report the matching index.
//
// 9. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low, window should reset to 0.
//    - After reset, found should reflect the reset window contents.
//
// 10. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for the shift register.
//    - Use always_comb for the pattern comparison logic.
//    - Do not infer latches.
//    - Do not use simulation delays or initial blocks for normal operation.
//    - The design should be synthesizable.
//
// 11. Parameter behavior:
//    - N controls the total sliding window size.
//    - K controls the pattern length.
//    - PATTERN is the K-bit value to search for.
//    - The design should work for different legal N and K values.
//
// 12. Assumptions:
//    - N >= K.
//    - K >= 1.
//    - bit_in is synchronous to clk.
//    - This module only detects whether PATTERN exists in the current
//      window; it does not generate a one-cycle pulse per new match.
// ============================================================

`default_nettype none

module pattern_in_window #(
  parameter N       = 8,
  parameter K       = 5,
  parameter PATTERN = 5'b10110
)(
  input  logic clk,
  input  logic rst_n,
  input  logic bit_in,
  output logic found
);  
    logic [N-1:0] slide;

    function automatic logic found_pattern(input logic [N-1:0] slide);
        found_pattern = 0;
        for (int i = K-1; i < N; i++) begin
            // if (slide[i:i-K+1] == PATTERN)
            // slide[i:i-K+1] 逻辑上想法对，但普通 part-select 不允许 variable range；
            // slide[i -: K] 是 SystemVerilog 专门为“变量起点 + 固定宽度”设计的写法。
            if (slide[i-:K] == PATTERN)
                found_pattern = 1;
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slide <= '0;
        end else begin
            slide <= {bit_in, slide[N-1:1]};
        end
    end

    assign found = found_pattern(.slide(slide));
endmodule