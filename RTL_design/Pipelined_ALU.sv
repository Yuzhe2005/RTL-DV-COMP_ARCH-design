// ============================================================
// Problem: 2-Stage Pipelined ALU with RAW Forwarding
// ============================================================
// Design a parameterized pipelined ALU.
// Module interface:
// module pipelined_alu #(
//   parameter WIDTH    = 32,
//   parameter REG_ADDR = 5
// )(
//   input  logic                    clk,
//   input  logic                    rst_n,
//   input  logic                    flush,
//   input  logic                    input_valid,
//   input  logic [3:0]              opcode,
//   input  logic [REG_ADDR-1:0]     src_a_reg,
//   input  logic [REG_ADDR-1:0]     src_b_reg,
//   input  logic [WIDTH-1:0]        src_a_value,
//   input  logic [WIDTH-1:0]        src_b_value,
//   input  logic [REG_ADDR-1:0]     dest_reg,
//   output logic                    wb_valid,
//   output logic [WIDTH-1:0]        wb_result,
//   output logic [REG_ADDR-1:0]     wb_dest
// );
// Requirements:
// 1. This is a simple 2-stage pipelined ALU.
//    - Stage 1 should accept an input operation when input_valid is high.
//    - Stage 2 should produce the writeback result from the previous stage.
//    - The output should include a valid bit, result value, and destination register.
// 2. Parameters:
//    - WIDTH controls the width of ALU operands and results.
//    - REG_ADDR controls the width of register addresses.
// 3. ALU operations:
//    - opcode = 4'd0: addition.
//    - opcode = 4'd1: subtraction.
//    - opcode = 4'd2: bitwise AND.
//    - opcode = 4'd3: bitwise OR.
//    - opcode = 4'd4: bitwise XOR.
//    - Unsupported opcodes should produce a defined safe result.
// 4. Pipeline valid behavior:
//    - input_valid indicates whether the current input operation is valid.
//    - A valid input operation should move through the pipeline.
//    - wb_valid should indicate whether wb_result and wb_dest are valid.
// 5. Destination register behavior:
//    - dest_reg should be carried through the pipeline with the computed result.
//    - wb_dest should identify the destination register for wb_result.
// 6. Reset behavior:
//    - rst_n is an active-low reset.
//    - On reset, all pipeline valid bits should be cleared.
//    - Pipeline result and destination registers should be reset to known values.
// 7. Flush behavior:
//    - flush should clear the pipeline state.
//    - When flush is asserted, pending pipeline operations should be invalidated.
//    - After flush, wb_valid should be low until a new valid operation reaches writeback.
// 8. RAW forwarding behavior:
//    - The design should support simple read-after-write forwarding.
//    - If the current input source register matches a pending destination register,
//      use the pending result instead of the original source value.
//    - Forwarding should be supported for both source operands.
//    - Register zero should not be forwarded if the source register address is zero.
//    - More recent pipeline results should have priority over older visible results.
// 9. Source operand behavior:
//    - src_a_value and src_b_value are the default operand values.
//    - src_a_reg and src_b_reg identify which architectural registers those operands came from.
//    - The effective operands used by the ALU may be forwarded values when a dependency exists.
// 10. Writeback behavior:
//    - wb_result should contain the ALU result after it passes through the pipeline.
//    - wb_dest should contain the corresponding destination register.
//    - wb_valid should be asserted only for valid operations.
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use sequential logic for pipeline registers.
//    - Use combinational logic for ALU computation and forwarding decisions.
//    - The design should be synthesizable.
// 12. Assumptions:
//    - REG_ADDR is positive.
//    - WIDTH is positive.
//    - Register address zero is treated as a non-forwarded zero register.
//    - No stall input is required.
//    - No memory operation, branch operation, or multi-cycle ALU operation is required.
// ============================================================

`default_nettype none

module pipelined_alu #(
  parameter WIDTH    = 32,
  parameter REG_ADDR = 5
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    flush,
  input  logic                    input_valid,
  input  logic [3:0]              opcode,
  input  logic [REG_ADDR-1:0]     src_a_reg,
  input  logic [REG_ADDR-1:0]     src_b_reg,
  input  logic [WIDTH-1:0]        src_a_value,
  input  logic [WIDTH-1:0]        src_b_value,
  input  logic [REG_ADDR-1:0]     dest_reg,
  output logic                    wb_valid,
  output logic [WIDTH-1:0]        wb_result,
  output logic [REG_ADDR-1:0]     wb_dest
);
  logic ex_valid;
  logic [WIDTH-1:0] ex_result;
  logic [REG_ADDR-1:0] ex_dest;

  function automatic logic [WIDTH-1:0] res(
    input logic [WIDTH-1:0] val_a,
    input logic [WIDTH-1:0] val_b,
    input logic [3:0] op
  );
    case (op)
      4'd0: res = val_a+val_b;
      4'd1: res = val_a-val_b;
      4'd2: res = val_a & val_b;
      4'd3: res = val_a | val_b;
      4'd4: res = val_a ^ val_b;
      default: res = '0;
    endcase
  endfunction

  logic [WIDTH-1:0] op_val_a, op_val_b;
  always_comb begin
    op_val_a = src_a_value;
    op_val_b = src_b_value;
    // 下面的input_valid condition中可以不用添加，因为 input_valid 会pass到 ex_valid
    if (input_valid && (ex_dest == src_a_reg) && ex_valid && (src_a_reg != '0)) begin
      op_val_a = ex_result;
    end else if (input_valid && (wb_dest == src_a_reg) && wb_valid && (src_a_reg != '0)) begin
      op_val_a = wb_result;
    end

    if (input_valid && (ex_dest == src_b_reg) && ex_valid && (src_b_reg != '0)) begin
      op_val_b = ex_result;
    end else if (input_valid && (wb_dest == src_b_reg) && wb_valid && (src_b_reg != '0)) begin
      op_val_b = wb_result;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || flush) begin
      ex_valid <= 0;
      ex_result <= '0;
      ex_dest <= '0;
    end else begin
      ex_valid <= input_valid;
      // ex_result <=  res(.val_a(src_a_value), .val_b(src_b_value), .op(opcode));
      ex_result <= res(.val_a(op_val_a), .val_b(op_val_b), .op(opcode));
      ex_dest <= dest_reg;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || flush) begin
      wb_valid <= 0;
      wb_result <= '0;
      wb_dest <= '0;
    end else begin
      wb_valid <= ex_valid;
      wb_result <= ex_result;
      wb_dest <= ex_dest;
    end
  end
endmodule