// ============================================================
// Problem: Integrated Clock Gating Cell
// ============================================================
// Design a simple clock-gating cell that gates an input clock using
// an enable signal while avoiding glitches on the gated clock.
//
// Module interface:
// module icg_cell (
//   input  logic clk_in,
//   input  logic enable,
//   output logic clk_gated
// );
//
// Requirements:
// 1. The module should generate a gated clock output clk_gated.
//
// 2. When enable is 1, clk_gated should follow clk_in.
//
// 3. When enable is 0, clk_gated should stay low.
//
// 4. The enable signal should not be directly ANDed with clk_in.
//    Directly doing:
//
//      assign clk_gated = clk_in & enable;
//
//    can create glitches if enable changes while clk_in is high.
//
// 5. To avoid glitches, latch the enable signal when clk_in is low.
//    - The latch should be transparent when clk_in = 0.
//    - The latch should hold its value when clk_in = 1.
//
// 6. The gated clock should be generated using:
//
//      clk_gated = clk_in & enable_latched;
//
// 7. Because enable_latched only changes while clk_in is low,
//    clk_gated should not glitch during the high phase of clk_in.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_latch for the level-sensitive latch.
//    - Use continuous assignment for clk_gated.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - clk_in is a free-running clock.
//    - enable is stable enough to be sampled during the low phase of clk_in.
//    - No reset is required for this simple ICG cell.
//    - In real ASIC flows, this logic is usually replaced by a standard-cell
//      library ICG cell.
// ============================================================

`default_nettype none

module icg_cell (
  input  logic clk_in,
  input  logic enable,
  output logic clk_gated
);
    logic enable_latched;

    always_latch begin
        if (!clk_in) enable_latched <= enable;
    end

    assign clk_gated = clk_in & enable_latched;
endmodule