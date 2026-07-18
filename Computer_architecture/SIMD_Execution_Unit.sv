// ============================================================
// Problem: Masked SIMD ALU
// ============================================================
// Design a parameterized SIMD-style ALU.
//
// The module contains multiple independent lanes. Each lane receives its
// own operands a[i] and b[i], performs the selected ALU operation, and
// produces result[i]. A per-lane mask controls whether each lane is active.
//
// Module interface:
// module simd_alu #(
//   parameter LANES = 4,
//   parameter W     = 32
// )(
//   input  logic [W-1:0]     a      [LANES],
//   input  logic [W-1:0]     b      [LANES],
//   input  logic [LANES-1:0] mask,
//   input  logic [2:0]       op,
//   output logic [W-1:0]     result [LANES]
// );
//
// Requirements:
// 1. The module should implement a SIMD ALU with LANES parallel lanes.
//
// 2. Each lane should operate independently:
//      result[i] depends only on a[i], b[i], mask[i], and op.
//
// 3. Lane mask behavior:
//    - If mask[i] is 0, lane i is inactive.
//    - An inactive lane should output 0.
//    - If mask[i] is 1, lane i should perform the selected operation.
//
// 4. Supported operations:
//    - op = 3'd0:
//        result[i] = a[i] + b[i]
//
//    - op = 3'd1:
//        result[i] = a[i] - b[i]
//
//    - op = 3'd2:
//        result[i] = a[i] & b[i]
//
//    - op = 3'd3:
//        result[i] = a[i] | b[i]
//
//    - op = 3'd4:
//        result[i] = a[i] ^ b[i]
//
//    - default:
//        result[i] = 0
//
// 5. Output behavior:
//    - result should be purely combinational.
//    - result should update immediately when a, b, mask, or op changes.
//    - No clock or reset is needed.
//
// 6. Parallel lane behavior:
//    - All lanes should compute in parallel.
//    - The operation selected by op is shared by all lanes.
//    - The mask is per-lane, so some lanes may be active while others are
//      inactive.
//
// 7. Implementation style:
//    - Use SystemVerilog.
//    - Use generate-for or equivalent structure to create LANES copies of
//      the lane ALU logic.
//    - Use always_comb for each lane's combinational logic.
//    - Provide default behavior to avoid latches.
//    - Do not use sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 8. Assumptions:
//    - LANES is at least 1.
//    - W is at least 1.
//    - Operands are treated as unsigned bit vectors for add/sub.
//    - Overflow/carry flags are not required.
//    - This module only computes lane results; instruction scheduling,
//      register reads, and writeback are handled elsewhere.
// ============================================================

`default_nettype none

module simd_alu #(
  parameter LANES = 4,
  parameter W     = 32
)(
  input  logic [W-1:0]     a      [LANES],
  input  logic [W-1:0]     b      [LANES],
  input  logic [LANES-1:0] mask,
  input  logic [2:0]       op,
  output logic [W-1:0]     result [LANES]
);
    always_comb begin
        for (int i = 0; i < LANES; i++) begin
            result[i] = '0;
            if (mask[i]) begin
                case (op)
                    3'b000: result[i] = a[i]+b[i];
                    3'b001: result[i] = a[i]-b[i];
                    3'b010: result[i] = a[i]&b[i];
                    3'b011: result[i] = a[i]|b[i];
                    3'b100: result[i] = a[i]^b[i];
                    default: result[i] = '0;
                endcase
            end
        end
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:

module simd_alu #(
  parameter LANES = 4,
  parameter W     = 32
)(
  input  logic [W-1:0]     a      [LANES],
  input  logic [W-1:0]     b      [LANES],
  input  logic [LANES-1:0] mask,
  input  logic [2:0]        op,
  output logic [W-1:0]     result [LANES]
);
  genvar i;
  generate
    for (i = 0; i < LANES; i++) begin : lane
      always_comb begin
        if (!mask[i]) begin
          result[i] = '0;
        end else begin
          case (op)
            3'd0: result[i] = a[i] + b[i];
            3'd1: result[i] = a[i] - b[i];
            3'd2: result[i] = a[i] & b[i];
            3'd3: result[i] = a[i] | b[i];
            3'd4: result[i] = a[i] ^ b[i];
            default: result[i] = '0;
          endcase
        end
      end
    end
  endgenerate
endmodule