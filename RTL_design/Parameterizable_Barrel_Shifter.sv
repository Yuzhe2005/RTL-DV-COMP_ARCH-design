// ============================================================
// Problem: Parameterized Barrel Shifter
// ============================================================
// Design a parameterized combinational barrel shifter.
// Module interface:
// module barrel_shifter #(
//   parameter WIDTH = 8
// )(
//   input  logic [WIDTH-1:0]          data_in,
//   input  logic [$clog2(WIDTH)-1:0]  shift_amt,
//   input  logic [1:0]                shift_op,
//   output logic [WIDTH-1:0]          data_out
// );
// Requirements:
// 1. This is a WIDTH-bit combinational barrel shifter.
//    - The input data width is controlled by parameter WIDTH.
//    - The output data width should also be WIDTH bits.
//    - The shift amount is controlled by shift_amt.
// 2. Supported shift operations:
//    - shift_op = 2'b00: logical shift left.
//    - shift_op = 2'b01: logical shift right.
//    - shift_op = 2'b10: arithmetic shift right.
//    - Other shift_op values should produce a safe default behavior.
// 3. Logical shift left behavior:
//    - Shift data_in left by shift_amt bit positions.
//    - Vacated low-order bits should be filled with zeros.
//    - Bits shifted out of the high-order side are discarded.
// 4. Logical shift right behavior:
//    - Shift data_in right by shift_amt bit positions.
//    - Vacated high-order bits should be filled with zeros.
//    - Bits shifted out of the low-order side are discarded.
// 5. Arithmetic shift right behavior:
//    - Shift data_in right by shift_amt bit positions while preserving sign.
//    - The most significant bit of data_in should be treated as the sign bit.
//    - Vacated high-order bits should be filled with the original sign bit.
// 6. Default behavior:
//    - For unsupported shift_op values, data_out should have a defined value.
//    - A reasonable default is to pass data_in through unchanged.
// 7. Implementation style:
//    - Use SystemVerilog.
//    - Use combinational logic.
//    - Use always_comb or equivalent combinational assignment style.
//    - The design should be synthesizable.
// 8. Assumptions:
//    - WIDTH is positive.
//    - shift_amt is within the range representable by $clog2(WIDTH).
//    - No clock or reset is required.
//    - No rotate operation is required.
// ============================================================

`default_nettype none

module barrel_shifter #(
  parameter WIDTH = 8
)(
  input  logic [WIDTH-1:0]          data_in,
  input  logic [$clog2(WIDTH)-1:0]  shift_amt,
  input  logic [1:0]                shift_op,
  output logic [WIDTH-1:0]          data_out
);
    always_comb begin
        case (shift_op)
            2'b00: data_out = data_in << shift_amt;
            2'b01: data_out = data_in >> shift_amt;
            // 2'b10: data_out = $signed(data_in) >> shift_amt;
            2'b10: data_out = $signed(data_in) >>> shift_amt;
            default: data_out = data_in;
        endcase
    end
endmodule