// ============================================================
// Problem: Pipeline Stage Register with Stall and Flush
// ============================================================
// Design a parameterized pipeline stage register.
// Module interface:
// module pipe_stage_reg #(
//   parameter DATA_WIDTH = 32,
//   parameter CTRL_WIDTH = 8
// )(
//   input  logic                  clk,
//   input  logic                  rst_n,
//   input  logic                  stall,
//   input  logic                  flush,
//   input  logic [DATA_WIDTH-1:0] data_in,
//   input  logic [CTRL_WIDTH-1:0] ctrl_in,
//   input  logic                  valid_in,
//   output logic [DATA_WIDTH-1:0] data_out,
//   output logic [CTRL_WIDTH-1:0] ctrl_out,
//   output logic                  valid_out
// );
// Requirements:
// 1. Implement a pipeline register between two pipeline stages.
// 2. The register should store:
//    - data payload
//    - control signals
//    - valid bit
// 3. Parameters:
//    - DATA_WIDTH controls the width of the data path.
//    - CTRL_WIDTH controls the width of the control path.
// 4. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, data_out should be cleared to 0.
//    - On reset, ctrl_out should be cleared to 0.
//    - On reset, valid_out should be cleared to 0.
// 5. Normal propagation:
//    - When stall is low and flush is low, inputs should be captured on the rising clock edge.
//    - data_out should receive data_in.
//    - ctrl_out should receive ctrl_in.
//    - valid_out should receive valid_in.
// 6. Stall behavior:
//    - When stall is high and flush is low, the pipeline register should hold its current values.
//    - data_out, ctrl_out, and valid_out should not change during stall.
// 7. Flush behavior:
//    - When flush is high, the pipeline register should inject a bubble/NOP.
//    - data_out should be cleared to 0.
//    - ctrl_out should be cleared to 0.
//    - valid_out should be cleared to 0.
// 8. Priority:
//    - Reset has highest priority.
//    - Flush has priority over stall.
//    - Stall only holds the current values when flush is not asserted.
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use nonblocking assignments for registers.
//    - The design should be synthesizable.
// 10. Assumptions:
//    - DATA_WIDTH is positive.
//    - CTRL_WIDTH is positive.
//    - A flushed pipeline entry is represented by valid_out = 0.
// ============================================================

`default_nettype none

module pipe_stage_reg #(
  parameter DATA_WIDTH = 32,
  parameter CTRL_WIDTH = 8
)(
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  stall,
  input  logic                  flush,
  input  logic [DATA_WIDTH-1:0] data_in,
  input  logic [CTRL_WIDTH-1:0] ctrl_in,
  input  logic                  valid_in,
  output logic [DATA_WIDTH-1:0] data_out,
  output logic [CTRL_WIDTH-1:0] ctrl_out,
  output logic                  valid_out
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            data_out <= '0;
            ctrl_out <= '0;
            valid_out <= 0;
        end else begin
            if (!stall) begin
                data_out <= data_in;
                ctrl_out <= ctrl_in;
                valid_out <= valid_in;
            end
        end
    end
endmodule