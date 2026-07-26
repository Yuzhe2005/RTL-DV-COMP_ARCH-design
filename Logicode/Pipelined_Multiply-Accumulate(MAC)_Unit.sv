// ============================================================
// Problem: Pipelined Multiply-Accumulate Unit
// ============================================================
// Design a parameterized pipelined multiply-accumulate unit.
//
// The module should multiply two input operands A and B, then accumulate
// the product into an internal/output accumulator.
//
// The design has two pipeline stages:
//   - Stage 1: multiply A and B;
//   - Stage 2: accumulate the registered product into result.
//
// Module interface:
// module pipeline_multiply_accumulate #(
//   parameter DATA_WIDTH = 8,
//   parameter ACC_WIDTH  = 32
// )(
//   input  logic                  clk,
//   input  logic                  rst_n,
//   input  logic                  valid_in,
//   input  logic                  accum_clr,
//   input  logic [DATA_WIDTH-1:0] A,
//   input  logic [DATA_WIDTH-1:0] B,
//   output logic                  valid_out,
//   output logic [ACC_WIDTH-1:0]  result
// );
//
// Requirements:
// 1. The module should implement a pipelined multiply-accumulate datapath with:
//    - two DATA_WIDTH-bit input operands A and B;
//    - one 2*DATA_WIDTH-bit registered product stage;
//    - one ACC_WIDTH-bit accumulator output result;
//    - valid signal pipelining from valid_in to valid_out.
//
// 2. Pipeline stage 1 behavior:
//    - On every rising edge of clk, when not in reset:
//        - product_stage should capture A * B;
//        - valid_pipe should capture valid_in;
//        - clr_pipe should capture accum_clr.
//    - product_stage stores the multiplication result for use by stage 2.
//    - valid_pipe indicates whether product_stage is valid.
//    - clr_pipe carries the clear-control signal aligned with product_stage.
//
// 3. Pipeline stage 2 behavior:
//    - On every rising edge of clk, when not in reset:
//        - valid_out should capture valid_pipe.
//    - If valid_pipe is 1:
//        - If clr_pipe is 1, result should be loaded with product_stage.
//        - If clr_pipe is 0, result should accumulate:
//
//            result <= result + product_stage
//
//    - If valid_pipe is 0:
//        - result should hold its previous value;
//        - valid_out should be 0 after the clock edge.
//
// 4. Accumulation clear behavior:
//    - accum_clr is sampled in stage 1 into clr_pipe.
//    - clr_pipe is used in stage 2 together with the matching product_stage.
//    - This ensures the clear operation is aligned with the product it affects.
//    - When clr_pipe is asserted and valid_pipe is asserted:
//
//        result <= product_stage
//
//      instead of:
//
//        result <= result + product_stage
//
// 5. Valid timing behavior:
//    - valid_in corresponds to the input operands A and B in stage 1.
//    - valid_pipe is valid_in delayed by one cycle.
//    - valid_out is valid_in delayed by two pipeline stages from the input view,
//      but it is asserted when the stage-2 accumulation result is updated.
//
//    Example:
//      Cycle N:
//        valid_in = 1, A and B are sampled into the multiplier stage.
//
//      Cycle N+1:
//        valid_pipe = 1;
//        result is updated using the product from cycle N;
//        valid_out becomes 1 after the clock edge.
//
// 6. Data timing behavior:
//    - A and B are multiplied in stage 1 and stored into product_stage.
//    - The accumulator uses the registered product_stage in the following cycle.
//    - Therefore, the multiply result is accumulated one cycle after A and B
//      are sampled.
//
// 7. Reset behavior:
//    - Reset is synchronous active-low.
//    - On posedge clk, if rst_n is 0:
//        - product_stage should be cleared to 0;
//        - valid_pipe should be cleared to 0;
//        - clr_pipe should be cleared to 0;
//        - result should be cleared to 0;
//        - valid_out should be cleared to 0.
//
// 8. Width behavior:
//    - A and B are DATA_WIDTH bits wide.
//    - The product width should be 2*DATA_WIDTH bits.
//    - result is ACC_WIDTH bits wide.
//    - Before adding product_stage into result, product_stage should be extended
//      or cast to ACC_WIDTH bits.
//    - The design does not need to detect accumulator overflow.
//
// 9. Arithmetic behavior:
//    - The given interface uses unsigned inputs and unsigned result.
//    - Therefore, A * B should be treated as unsigned multiplication.
//    - The accumulation should also be unsigned unless the interface is changed
//      to signed signals.
//
// 10. Behavior when valid_in is low:
//    - Stage 1 may still compute and store A * B, but valid_pipe should be 0.
//    - Since valid_pipe will be 0 in the following cycle, stage 2 should not
//      update result using that product.
//    - valid_out should also be 0 when the corresponding product is invalid.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for both pipeline stages.
//    - Use nonblocking assignments in sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//    - The multiply stage and accumulate stage should be separated by registers.
//
// 12. Assumptions:
//    - DATA_WIDTH is at least 1.
//    - ACC_WIDTH is large enough to hold the desired accumulated result.
//    - valid_in indicates when A, B, and accum_clr should be treated as valid.
//    - There is no ready/backpressure signal.
//    - The module accepts at most one input operation per cycle.
// ============================================================

`default_nettype none

module pipeline_multiply_accumulate #(
  parameter DATA_WIDTH = 8,
  parameter ACC_WIDTH  = 32
)(
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  valid_in,
  input  logic                  accum_clr,
  input  logic [DATA_WIDTH-1:0] A,
  input  logic [DATA_WIDTH-1:0] B,
  output logic                  valid_out,
  output logic [ACC_WIDTH-1:0]  result
);  
    logic [ACC_WIDTH-1:0] product;
    logic valid_pipeline;
    logic clr_pipeline;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            product <= '0;
            valid_pipeline <= 0;
            clr_pipeline <= 0;
        end else begin
            product <= A * B;
            valid_pipeline <= valid_in;
            clr_pipeline <=  accum_clr;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 0;
            result <= '0;
        end else begin
            if (clr_pipeline) result <= product;
            else result <= result+product;
            valid_out <= valid_pipeline;
        end
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:|

module pipeline_multiply_accumulate #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  valid_in,
    input  logic                  accum_clr,
    input  logic [DATA_WIDTH-1:0] A,
    input  logic [DATA_WIDTH-1:0] B,
    output logic                  valid_out,
    output logic [ACC_WIDTH-1:0]  result
);
    // Pipeline stage 1: multiply
    logic [2*DATA_WIDTH-1:0] product_stage;
    logic                    valid_pipe;
    logic                    clr_pipe;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            product_stage <= '0;
            valid_pipe    <= 1'b0;
            clr_pipe      <= 1'b0;
        end else begin
            product_stage <= A * B;
            valid_pipe    <= valid_in;
            clr_pipe      <= accum_clr;
        end
    end

    // Pipeline stage 2: accumulate
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            result    <= '0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_pipe;
            if (valid_pipe) begin
                result <= clr_pipe ? ACC_WIDTH'(product_stage) : result + ACC_WIDTH'(product_stage);
            end
        end
    end
endmodule