// ============================================================
// Problem: Synchronizer and Simple Debounce Filter
// ============================================================
// Design a module that safely synchronizes an asynchronous input
// into the clk domain, filters short glitches/bounce using consecutive
// samples, and generates a one-cycle rising pulse when the debounced
// level rises.
//
// Module interface:
// module debounce_sync (
//   input  logic clk,
//   input  logic rst_n,
//   input  logic async_in,
//   output logic debounced_level,
//   output logic debounced_rise_pulse
// );
//
// Requirements:
// 1. The input async_in is asynchronous to clk.
//    - It should not be used directly by the debounce logic.
//    - It must first pass through a 2-flop synchronizer.
//
// 2. Synchronizer behavior:
//    - Use two flip-flops, sync1 and sync2, clocked by clk.
//    - sync1 samples async_in.
//    - sync2 samples sync1.
//    - The debounce filter should use sync2 as the synchronized input.
//
// 3. Debounce behavior:
//    - The debounced output level should only change after seeing
//      two consecutive stable samples of the same value.
//    - If sync2 is high for two consecutive clk cycles, set
//      debounced_level to 1.
//    - If sync2 is low for two consecutive clk cycles, set
//      debounced_level to 0.
//    - If the synchronized input is not stable for two consecutive
//      samples, debounced_level should hold its previous value.
//
// 4. Internal previous-sample tracking:
//    - Store the previous synchronized sample in a register.
//    - Compare the current synchronized sample with the previous sample.
//    - This allows the design to detect two consecutive high samples
//      or two consecutive low samples.
//
// 5. Rising pulse generation:
//    - Generate debounced_rise_pulse when debounced_level transitions
//      from 0 to 1.
//    - debounced_rise_pulse should be asserted for exactly one clk cycle.
//    - It should remain 0 otherwise.
//
// 6. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low:
//        - synchronizer registers should reset to 0;
//        - debounce tracking registers should reset to 0;
//        - debounced_level should reset to 0;
//        - debounced_rise_pulse should be 0 after reset.
//
// 7. Output behavior:
//    - debounced_level is a filtered level signal.
//    - debounced_rise_pulse is a one-cycle pulse in the clk domain.
//    - debounced_rise_pulse should be based on the debounced level,
//      not directly on async_in or sync2.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Do not use simulation delays such as # statements.
//    - Do not use initial blocks for normal operation.
//    - The design should be synthesizable.
//    - Avoid combinational logic that directly uses async_in.
//
// 9. Assumptions:
//    - clk is a free-running clock.
//    - async_in may bounce or glitch.
//    - This is a simple debounce filter requiring only 2 consecutive
//      stable samples, not a long programmable debounce counter.
// ============================================================

`default_nettype none

module debounce_sync (
  input  logic clk,
  input  logic rst_n,
  input  logic async_in,
  output logic debounced_level,
  output logic debounced_rise_pulse
);
    logic sync1, sync2, prev;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync1 <= 0;
            sync2 <= 0;
            prev <= 0;
        end else begin
            sync1 <= async_in;
            sync2 <= sync1;
            prev <= sync2;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounced_level <= 0;

            debounced_rise_pulse <= 0;
        end else begin
            if (prev && sync2)
                debounced_level <= 1;
            else if (!prev && !sync2)
                debounced_level <= 0;

            if (prev && sync2 && !debounced_level)
                debounced_rise_pulse <= 1;
            else 
                debounced_rise_pulse <= 0;
        end
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:

module debounce_sync (
  input  logic clk,
  input  logic rst_n,
  input  logic async_in,
  output logic debounced_level,
  output logic debounced_rise_pulse
);
  // 2-flop synchronizer
  logic sync1, sync2;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync1 <= 0;
      sync2 <= 0;
    end else begin
      sync1 <= async_in;
      sync2 <= sync1;
    end
  end

  // Debounce filter: require 2 consecutive high samples
  logic prev;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev             <= 0;
      debounced_level  <= 0;
    end else begin
      prev <= sync2;
      // Accept high only after 2 stable samples
      if (sync2 && prev)  debounced_level <= 1;
      if (!sync2 && !prev) debounced_level <= 0;
    end
  end

  // Rising edge of debounced_level
  logic debounced_prev;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) debounced_prev <= 0;
    else        debounced_prev <= debounced_level;
  end

  assign debounced_rise_pulse = debounced_level & ~debounced_prev;
endmodule