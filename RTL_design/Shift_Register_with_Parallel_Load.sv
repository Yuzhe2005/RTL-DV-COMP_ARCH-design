// ============================================================
// Problem: Shift Register with Parallel Load and Serial Shift Right
// ============================================================
// Design a parameterized shift register.
// Module interface:
// module shift_reg #(
//   parameter WIDTH = 8
// )(
//   input  logic              clk,
//   input  logic              rst_n,
//   input  logic              load,
//   input  logic              shift,
//   input  logic [WIDTH-1:0]  data_in,
//   input  logic              serial_in,
//   output logic [WIDTH-1:0]  parallel_out,
//   output logic              serial_out
// );
// Requirements:
// 1. This is a WIDTH-bit shift register.
//    - The register should update on the rising edge of clk.
//    - The register width is controlled by parameter WIDTH.
//    - The design should support parallel load and serial right shift.
// 2. Reset behavior:
//    - rst_n is an active-low reset.
//    - When rst_n is low, the internal shift register should reset to zero.
//    - serial_out should also reset to zero.
// 3. Parallel load behavior:
//    - When rst_n is high and load is high, load data_in into the shift register.
//    - load has priority over shift.
//    - If load and shift are both high in the same cycle, perform the load operation.
// 4. Shift behavior:
//    - When rst_n is high, load is low, and shift is high,
//      shift the register one bit to the right.
//    - serial_in should enter the most significant bit position.
//    - The previous least significant bit should be shifted out.
// 5. Hold behavior:
//    - When rst_n is high, load is low, and shift is low,
//      the shift register should hold its current value.
//    - serial_out should hold its previous value unless a shift operation occurs.
// 6. parallel_out behavior:
//    - parallel_out should reflect the current value of the internal shift register.
//    - parallel_out may be driven continuously from the internal register.
// 7. serial_out behavior:
//    - serial_out should represent the bit shifted out during a valid shift operation.
//    - For a right shift, the shifted-out bit is the previous least significant bit.
//    - serial_out should be registered so that it is stable after the rising clock edge.
//    - serial_out should update only when an actual shift operation occurs.
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - The design should be synthesizable.
// 9. Assumptions:
//    - WIDTH is positive.
//    - No left shift operation is required.
//    - No separate enable signal is required.
//    - No arithmetic shift behavior is required.
// ============================================================

`default_nettype none

module shift_reg #(
  parameter WIDTH = 8
)(
  input  logic              clk,
  input  logic              rst_n,
  input  logic              load,
  input  logic              shift,
  input  logic [WIDTH-1:0]  data_in,
  input  logic              serial_in,
  output logic [WIDTH-1:0]  parallel_out,
  output logic              serial_out
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_out <= '0;
            serial_out <= 0;
        end else begin
            if (load) parallel_out <= data_in;
            else if (shift) begin
                parallel_out <= {serial_in, parallel_out[WIDTH-1:1]};
                serial_out <= parallel_out[0];
            end
        end
    end
endmodule