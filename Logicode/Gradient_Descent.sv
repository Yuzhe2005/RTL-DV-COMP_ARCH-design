// ============================================================
// Problem: Gradient Descent Weight Update
// ============================================================
// Design a parameterized gradient descent update module.
//
// The module should compute one gradient descent weight update:
//
//   updated_weight = current_weight - learning_rate * gradient
//
// Because learning_rate is represented as a fixed-point value, the product
// should be scaled down by FRAC_BITS:
//
//   scaled_update = (gradient * learning_rate) >>> FRAC_BITS
//
// Therefore:
//
//   updated_weight = current_weight - scaled_update
//
// Module interface:
// module gradient_descent #(
//   parameter DATA_WIDTH = 16,
//   parameter LR_WIDTH   = 8,
//   parameter FRAC_BITS  = 8
// )(
//   input  logic                          clk,
//   input  logic                          rst,
//   input  logic                          enable,
//
//   input  logic signed [DATA_WIDTH-1:0]  gradient,
//   input  logic        [LR_WIDTH-1:0]    learning_rate,
//   input  logic signed [DATA_WIDTH-1:0]  current_weight,
//
//   output logic signed [DATA_WIDTH-1:0]  updated_weight
// );
//
// Requirements:
// 1. The module should implement one gradient descent update step with:
//    - signed DATA_WIDTH-bit gradient input;
//    - unsigned LR_WIDTH-bit learning_rate input;
//    - signed DATA_WIDTH-bit current_weight input;
//    - signed DATA_WIDTH-bit registered updated_weight output.
//
// 2. Gradient descent behavior:
//    - When enable is asserted, the module should compute:
//
//        updated_weight = current_weight - scaled_update
//
//    - scaled_update should be derived from:
//
//        gradient * learning_rate
//
//    - A positive gradient should decrease the weight.
//    - A negative gradient should increase the weight.
//
// 3. Fixed-point learning rate behavior:
//    - learning_rate is treated as a non-negative fixed-point scaling factor.
//    - FRAC_BITS specifies how many fractional bits are used.
//    - The raw product should be shifted right by FRAC_BITS to produce the
//      scaled update.
//
//    Conceptually:
//
//        scaled_update = (gradient * learning_rate) / 2^FRAC_BITS
//
//    In hardware, use arithmetic right shift:
//
//        scaled_update = product >>> FRAC_BITS
//
// 4. Multiplication behavior:
//    - The multiplication result should have width:
//
//        DATA_WIDTH + LR_WIDTH
//
//    - This provides enough bits to hold the raw product of gradient and
//      learning_rate before scaling.
//    - Since gradient is signed, the product should preserve the sign of
//      gradient.
//    - learning_rate is unsigned and should be interpreted as a non-negative
//      magnitude.
//
// 5. Scaling behavior:
//    - After multiplication, shift the product right by FRAC_BITS.
//    - The shift should be arithmetic so that negative products remain negative.
//    - The scaled result should then be used as the update amount.
//
// 6. Output update behavior:
//    - updated_weight is a registered output.
//    - On each rising edge of clk:
//        - if rst is asserted, updated_weight should be cleared to 0;
//        - else if enable is asserted, updated_weight should capture the newly
//          computed weight;
//        - else updated_weight should hold its previous value.
//
// 7. Reset behavior:
//    - rst is synchronous active-high.
//    - On posedge clk, if rst is 1:
//        - updated_weight should be cleared to 0.
//
// 8. Enable behavior:
//    - enable controls whether a new update is accepted.
//    - If enable is 1, updated_weight should update using the current inputs.
//    - If enable is 0, updated_weight should not change.
//
// 9. Timing behavior:
//    - The multiply, scale, and subtract logic may be combinational.
//    - The final updated_weight should be captured on the rising edge of clk
//      when enable is asserted.
//    - Therefore, current_weight, gradient, and learning_rate should be stable
//      before the clock edge where enable is asserted.
//
// 10. Overflow and saturation behavior:
//    - Saturation is not required.
//    - Overflow detection is not required.
//    - If the computed value exceeds DATA_WIDTH, normal fixed-width truncation
//      behavior may occur.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use signed arithmetic for gradient, product, scaled update, and output.
//    - Use always_ff for the registered output.
//    - Use nonblocking assignment in sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 12. Assumptions:
//    - DATA_WIDTH is at least 1.
//    - LR_WIDTH is at least 1.
//    - FRAC_BITS is less than or equal to DATA_WIDTH + LR_WIDTH.
//    - learning_rate is non-negative.
//    - This module performs one update when enable is asserted.
//    - The module does not internally store current_weight, gradient, or
//      learning_rate.
// ============================================================

`default_nettype none

module gradient_descent #(
  parameter DATA_WIDTH = 16,
  parameter LR_WIDTH   = 8,
  parameter FRAC_BITS  = 8
)(
  input  logic                          clk,
  input  logic                          rst,
  input  logic                          enable,

  input  logic signed [DATA_WIDTH-1:0]  gradient,
  input  logic        [LR_WIDTH-1:0]    learning_rate,
  input  logic signed [DATA_WIDTH-1:0]  current_weight,

  output logic signed [DATA_WIDTH-1:0]  updated_weight
);
    localparam int MULT_WIDTH = DATA_WIDTH + LR_WIDTH;

    logic signed [MULT_WIDTH-1:0] lr_times_grad;
    assign lr_times_grad = gradient * learning_rate;

    logic signed [DATA_WIDTH-1:0] scaled_update;
    assign scaled_update = lr_times_grad >>> FRAC_BITS;

    logic signed [DATA_WIDTH-1:0] new_weight;
    assign new_weight = current_weight - scaled_update;

    always_ff @(posedge clk) begin
        if (rst) 
            updated_weight <= '0;
        else if (enable)
            updated_weight <= new_weight;
    end
endmodule