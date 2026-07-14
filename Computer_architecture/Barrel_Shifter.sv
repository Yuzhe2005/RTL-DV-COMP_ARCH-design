// ============================================================
// Problem: Parameterized Barrel Shifter
// ============================================================
// Design a parameterized combinational barrel shifter.
//
// The module takes an input data word, a shift amount, and a shift type,
// then outputs the shifted result.
//
// Module interface:
// module barrel_shifter #(
//   parameter W = 32
// )(
//   input  logic [W-1:0]         data_in,
//   input  logic [$clog2(W)-1:0] shamt,
//   input  logic [1:0]           shift_type,
//   output logic [W-1:0]         data_out
// );
//
// Requirements:
// 1. The module should be purely combinational.
//    - data_out should update whenever data_in, shamt, or shift_type changes.
//    - Do not use clk or reset.
//    - Use always_comb.
//
// 2. The module should support three shift operations:
//
//    shift_type = 2'b00:
//      - Logical left shift.
//      - data_out = data_in << shamt.
//      - Zeros are shifted into the low bits.
//
//    shift_type = 2'b01:
//      - Logical right shift.
//      - data_out = data_in >> shamt.
//      - Zeros are shifted into the high bits.
//
//    shift_type = 2'b10:
//      - Arithmetic right shift.
//      - data_out = signed(data_in) >>> shamt.
//      - The sign bit, data_in[W-1], is shifted into the high bits.
//
//    default:
//      - data_out = data_in.
//      - No shift is performed.
//
// 3. Shift amount:
//    - shamt determines how many bit positions to shift.
//    - shamt is $clog2(W) bits wide.
//    - For W = 32, shamt is 5 bits and can represent shifts from 0 to 31.
//
// 4. Logical left shift behavior:
//    Example for W = 8:
//      data_in = 8'b0001_1010
//      shamt   = 2
//      data_out = 8'b0110_1000
//
// 5. Logical right shift behavior:
//    Example for W = 8:
//      data_in = 8'b1001_1010
//      shamt   = 2
//      data_out = 8'b0010_0110
//
// 6. Arithmetic right shift behavior:
//    Example for W = 8:
//      data_in = 8'b1001_1010
//      shamt   = 2
//      data_out = 8'b1110_0110
//
//    Since data_in[7] is 1, the shifted-in high bits are filled with 1s.
//
// 7. Output behavior:
//    - data_out should always be W bits.
//    - If shamt is 0, data_out should equal data_in for all shift types.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_comb.
//    - Use a case statement on shift_type.
//    - Provide a default case to avoid latches.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - W is at least 2.
//    - W is normally a power of 2, such as 8, 16, 32, or 64.
//    - shamt is already limited to a legal shift amount by its width.
// ============================================================

`default_nettype none

module barrel_shifter #(
  parameter W = 32
)(
  input  logic [W-1:0]         data_in,
  input  logic [$clog2(W)-1:0] shamt,
  input  logic [1:0]           shift_type,
  output logic [W-1:0]         data_out
);
    always_comb begin
        case (shift_type)
            2'b00: data_out = data_in << shamt;
            2'b01: data_out = data_in >> shamt;
            2'b10: data_out = $signed(data_in) >>> shamt;
            default: data_out = '0;
        endcase
    end
endmodule