// ============================================================
// Problem: Pipeline Register with Stall and Flush
// ============================================================
// Design a parameterized pipeline register.
//
// The module stores a W-bit data value and updates it on the rising edge
// of clk. It supports both stall and flush control signals, which are
// commonly used in pipelined CPU/datapath designs.
//
// Module interface:
// module pipe_reg #(
//   parameter W = 64
// )(
//   input  logic          clk,
//   input  logic          rst_n,
//   input  logic          stall,
//   input  logic          flush,
//   input  logic [W-1:0]  d,
//   output logic [W-1:0]  q
// );
//
// Requirements:
// 1. The module should implement a W-bit pipeline register.
//
// 2. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low, q should be cleared to 0.
//
// 3. Normal update behavior:
//    - On each rising edge of clk, if the register is not stalled and not
//      flushed, q should capture d.
//
// 4. Stall behavior:
//    - If stall is asserted, the pipeline register should hold its current
//      value.
//    - While stalled, q should not capture d.
//
// 5. Flush behavior:
//    - If flush is asserted, q should be cleared to 0.
//    - Flush represents inserting a bubble into the pipeline.
//
// 6. Priority:
//    - Reset has the highest priority.
//    - Flush has higher priority than stall.
//    - Normal data capture happens only when flush is 0 and stall is 0.
//
//    Priority order:
//      reset > flush > stall/hold > normal capture
//
// 7. Example behavior:
//    - rst_n = 0:
//        q becomes 0 immediately.
//    - rst_n = 1, flush = 1:
//        q becomes 0 on the next rising edge of clk.
//    - rst_n = 1, flush = 0, stall = 1:
//        q keeps its previous value.
//    - rst_n = 1, flush = 0, stall = 0:
//        q captures d on the next rising edge of clk.
//
// 8. Output behavior:
//    - q should be a registered output.
//    - q should only change on reset or on the rising edge of clk.
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use nonblocking assignments.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 10. Assumptions:
//    - W is at least 1.
//    - stall and flush are synchronous control signals.
//    - The flush value is 0, representing a pipeline bubble.
// ============================================================

`default_nettype none

module pipe_reg #(
  parameter W = 64
)(
  input  logic          clk,
  input  logic          rst_n,
  input  logic          stall,
  input  logic          flush,
  input  logic [W-1:0]  d,
  output logic [W-1:0]  q
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= '0;
        end else begin
            if (flush) q <= '0;
            else if (!stall) q <= d;
        end
    end
endmodule