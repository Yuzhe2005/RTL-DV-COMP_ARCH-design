// ============================================================
// Problem: Simplified Register Renaming Unit
// ============================================================
// Design a simplified register renaming unit for an out-of-order CPU.
//
// The module maps architectural registers to physical registers. When a
// destination architectural register is renamed, the unit allocates a free
// physical register and updates the map table.
//
// Module interface:
// module reg_rename #(
//   parameter ARCH = 32,
//   parameter PHYS = 64
// )(
//   input  logic                         clk,
//   input  logic                         rst_n,
//   input  logic                         rename_req,
//   input  logic                         checkpoint_save,
//   input  logic                         flush,
//   input  logic                         commit_free,
//   input  logic [$clog2(ARCH)-1:0]      src1_arch,
//   input  logic [$clog2(ARCH)-1:0]      src2_arch,
//   input  logic [$clog2(ARCH)-1:0]      dst_arch,
//   input  logic [$clog2(PHYS)-1:0]      free_preg,
//   output logic [$clog2(PHYS)-1:0]      src1_preg,
//   output logic [$clog2(PHYS)-1:0]      src2_preg,
//   output logic [$clog2(PHYS)-1:0]      new_preg,
//   output logic [$clog2(PHYS)-1:0]      old_preg,
//   output logic                         rename_grant,
//   output logic                         stall
// );
//
// Requirements:
// 1. The module should maintain a map table:
//      map_table[arch_reg] = current physical register for arch_reg
//
// 2. Source register lookup:
//    - src1_preg should be the current physical register mapped to src1_arch.
//    - src2_preg should be the current physical register mapped to src2_arch.
//    - These lookups should be combinational.
//
// 3. Destination old mapping:
//    - old_preg should be the current physical register mapped to dst_arch.
//    - This is the old physical register that used to represent dst_arch.
//    - The old physical register may be freed later when the instruction
//      commits.
//
// 4. Free list:
//    - The module should keep a free_list bit vector.
//    - free_list[p] = 1 means physical register p is free.
//    - free_list[p] = 0 means physical register p is currently allocated.
//
// 5. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset:
//        - architectural register a should initially map to physical register a;
//        - physical registers 0 to ARCH-1 should be marked used;
//        - physical registers ARCH to PHYS-1 should be marked free;
//        - checkpoint_table should also be initialized to the same mapping.
//
// 6. Stall behavior:
//    - stall should be asserted when no physical register is free.
//    - stall = 1 when free_list has no bits set.
//    - If stall is asserted, rename should not be granted.
//
// 7. Rename grant behavior:
//    - rename_grant should be asserted when rename_req is asserted and the
//      free list is not empty.
//    - rename_grant = rename_req && !stall.
//
// 8. New physical register allocation:
//    - new_preg should be selected from the free list.
//    - The lowest-index free physical register may be selected.
//    - If no physical register is free, new_preg may be 0, but rename_grant
//      should be 0.
//
// 9. Rename behavior:
//    - When rename_req is asserted and stall is 0:
//        - allocate new_preg;
//        - update map_table[dst_arch] to new_preg;
//        - mark new_preg as used in free_list.
//    - The source physical registers and old_preg should reflect the map
//      table before this rename update.
//
// 10. Commit free behavior:
//    - When commit_free is asserted, free_preg should be marked free.
//    - This represents freeing an old physical register after the instruction
//      that replaced it has safely committed.
//
// 11. Checkpoint behavior:
//    - When checkpoint_save is asserted, copy the current map_table into
//      checkpoint_table.
//    - This checkpoint can later be used to recover from a branch
//      misprediction or flush event.
//
// 12. Flush behavior:
//    - When flush is asserted:
//        - restore map_table from checkpoint_table;
//        - rebuild free_list based on the physical registers used by the
//          checkpointed map table.
//    - Physical registers referenced by checkpoint_table should be marked
//      used.
//    - All other physical registers should be marked free.
//
// 13. Priority behavior:
//    - Reset has highest priority.
//    - Flush should take priority over normal rename and commit-free updates.
//    - When flush is asserted, the module should recover to the checkpointed
//      rename state.
//
// 14. Output behavior:
//    - src1_preg, src2_preg, old_preg, stall, and rename_grant should be
//      combinational outputs.
//    - map_table, checkpoint_table, and free_list should be registered state.
//    - new_preg may be computed combinationally from the current free_list.
//
// 15. Simplifications:
//    - Only one rename request is handled per cycle.
//    - Only one physical register can be freed per cycle.
//    - Only one checkpoint is stored.
//    - This module does not track physical register readiness.
//    - This module does not implement a ROB.
//    - This module does not handle multiple branch checkpoints.
//
// 16. Assumptions:
//    - PHYS is greater than or equal to ARCH.
//    - free_preg is provided by external commit/ROB logic.
//    - The external logic should not free a physical register that is still
//      needed by the architectural or speculative state.
//    - checkpoint_save and flush are not expected to represent two different
//      recovery actions in the same cycle.
//    - If rename and commit_free occur in the same cycle, they should refer
//      to different physical registers.
// ============================================================

`default_nettype none

module reg_rename #(
  parameter ARCH = 32,
  parameter PHYS = 64
)(
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         rename_req,
  input  logic                         checkpoint_save,
  input  logic                         flush,
  input  logic                         commit_free,
  input  logic [$clog2(ARCH)-1:0]      src1_arch,
  input  logic [$clog2(ARCH)-1:0]      src2_arch,
  input  logic [$clog2(ARCH)-1:0]      dst_arch,
  input  logic [$clog2(PHYS)-1:0]      free_preg,
  output logic [$clog2(PHYS)-1:0]      src1_preg,
  output logic [$clog2(PHYS)-1:0]      src2_preg,
  output logic [$clog2(PHYS)-1:0]      new_preg,
  output logic [$clog2(PHYS)-1:0]      old_preg,
  output logic                         rename_grant,
  output logic                         stall
);
    logic [$clog2(PHYS)-1:0] map_table [ARCH];
    logic [$clog2(PHYS)-1:0] checkpoint_table [ARCH];
    logic [PHYS-1:0] free_list;

    assign src1_preg = map_table[src1_arch];
    assign src2_preg = map_table[src2_arch];
    assign old_preg = map_table[dst_arch];

    always_comb begin
        new_preg = '0;
        for (int i = 0; i < PHYS; i++) begin
            if (free_list[i]) begin
                new_preg = i[$clog2(PHYS)-1:0];
                break;
            end
        end
    end

    assign stall = (free_list == '0);
    assign rename_grant = rename_req && !stall;

    logic [PHYS-1:0] rebuild_free_list;

    always_comb begin
        rebuild_free_list = '1;
        for (int i = 0; i < ARCH; i++) begin
            rebuild_free_list[checkpoint_table[i]] = 1'b0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < ARCH; i++) begin
                // map_table[i] <= '0;
                // checkpoint_table[i] <= '0;
                map_table[i] <= i[$clog2(PHYS)-1:0];
                checkpoint_table[i] <= i[$clog2(PHYS)-1:0];
            end
            free_list <= {{(PHYS-ARCH){1'b1}}, {(ARCH){1'b0}}};
        end else begin
            if (checkpoint_save) begin
                for (int i = 0; i < ARCH; i++)
                    checkpoint_table[i] <= map_table[i];
            end

            if (flush) begin
                for (int i = 0; i < ARCH; i++)
                    map_table[i] <= checkpoint_table[i];
                free_list <= rebuild_free_list;
            end else begin
                if (commit_free)
                    free_list[free_preg] <= 1'b1;

                // 这里第一遍忘写了
                if (rename_req && !stall) begin
                    map_table[dst_arch] <= new_preg;
                    free_list[new_preg] <= 1'b0;
                end
            end
        end
    end
endmodule