// ============================================================
// Problem: Register Scoreboard
// ============================================================
// Design a simple scoreboard for tracking whether architectural registers
// are currently waiting for a pending writeback.
//
// The scoreboard marks a destination register as busy when an instruction
// is issued, and clears that register when the instruction writes back.
//
// Module interface:
// module scoreboard #(
//   parameter REGS = 32
// )(
//   input  logic       clk,
//   input  logic       rst_n,
//   input  logic       issue_valid,
//   input  logic       wb_valid,
//   input  logic [4:0] issue_rd,
//   input  logic [4:0] wb_rd,
//   input  logic [4:0] check_rs1,
//   input  logic [4:0] check_rs2,
//   output logic       rs1_busy,
//   output logic       rs2_busy
// );
//
// Requirements:
// 1. The module should maintain one busy bit per register.
//    - busy[r] = 1 means register r has a pending result that has not
//      written back yet.
//    - busy[r] = 0 means register r is ready to be read.
//
// 2. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low, all busy bits should be cleared to 0.
//    - After reset, all registers are considered ready.
//
// 3. Issue behavior:
//    - When issue_valid is asserted, the instruction being issued has a
//      destination register issue_rd.
//    - If issue_rd is not register 0, busy[issue_rd] should be set to 1
//      on the rising edge of clk.
//    - This means the destination register is now waiting for a future
//      writeback.
//
// 4. Writeback behavior:
//    - When wb_valid is asserted, the instruction writing back has
//      destination register wb_rd.
//    - If wb_rd is not register 0, busy[wb_rd] should be cleared to 0
//      on the rising edge of clk.
//    - This means the register value is now available.
//
// 5. Register zero behavior:
//    - Register 0 should never be treated as busy.
//    - issue_rd == 0 should not set any busy bit.
//    - wb_rd == 0 should not affect the scoreboard.
//    - check_rs1 == 0 should make rs1_busy output 0.
//    - check_rs2 == 0 should make rs2_busy output 0.
//
// 6. Source check behavior:
//    - check_rs1 is a source register index to check.
//    - check_rs2 is another source register index to check.
//    - rs1_busy should be asserted if check_rs1 is nonzero and its busy bit
//      is set.
//    - rs2_busy should be asserted if check_rs2 is nonzero and its busy bit
//      is set.
//
// 7. Output behavior:
//    - rs1_busy and rs2_busy should be combinational outputs.
//    - They should reflect the current busy table contents immediately.
//
// 8. Same-cycle issue and writeback behavior:
//    - If issue_valid and wb_valid are both asserted in the same cycle,
//      both updates may occur.
//    - If issue_rd and wb_rd are different registers, one register is marked
//      busy while another is cleared.
//    - If issue_rd and wb_rd are the same nonzero register, the later
//      assignment in the sequential block determines the final value.
//      In the provided behavior, writeback clear has priority because it is
//      written after issue set.
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use a packed bit vector for the busy bits.
//    - Use always_ff for sequential updates.
//    - Use nonblocking assignments for busy bit updates.
//    - Use continuous assignments or always_comb for source busy checks.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 10. Assumptions:
//    - REGS is 32 for a RISC-V-style register file.
//    - Register indices are 5 bits wide.
//    - This scoreboard only tracks whether registers are waiting for
//      writeback.
//    - It does not track physical registers, operand values, instruction
//      age, ROB entries, or multiple pending writers to the same register.
// ============================================================

`default_nettype none

module scoreboard #(
  parameter REGS = 32
)(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       issue_valid,
  input  logic       wb_valid,
  input  logic [4:0] issue_rd,
  input  logic [4:0] wb_rd,
  input  logic [4:0] check_rs1,
  input  logic [4:0] check_rs2,
  output logic       rs1_busy,
  output logic       rs2_busy
);
    logic [REGS-1:0] busy;

    // assign rs1_busy = busy[check_rs1];
    // assign rs2_busy = busy[check_rs2];
    assign rs1_busy = (check_rs1 != '0) && busy[check_rs1];
    assign rs2_busy = (check_rs2 != '0) && busy[check_rs2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= '0;
        end else begin
            if (issue_valid && issue_rd != '0)
                busy[issue_rd] <= 1'b1;
            if (wb_valid && wb_rd != '0)
                busy[wb_rd] <= 1'b0;
        end
    end
endmodule