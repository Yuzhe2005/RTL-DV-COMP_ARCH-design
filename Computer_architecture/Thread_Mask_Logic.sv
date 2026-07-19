// ============================================================
// Problem: Thread Active Mask Control with Simple Divergence Stack
// ============================================================
// Design a thread active-mask controller for a SIMD/SIMT-style execution
// unit.
//
// The module tracks which threads are currently active during conditional
// control flow such as if/else regions. It supports entering an if-path,
// switching to an else-path, and exiting the conditional region.
//
// Module interface:
// module thread_mask #(
//   parameter THREADS = 32,
//   parameter STACK_D = 4
// )(
//   input  logic [THREADS-1:0] predicate,
//   input  logic               clk,
//   input  logic               rst_n,
//   input  logic               enter_if,
//   input  logic               enter_else,
//   input  logic               exit_if,
//   output logic [THREADS-1:0] active_mask
// );
//
// Requirements:
// 1. The module should maintain an active thread mask.
//    - active_mask[i] = 1 means thread i is currently active.
//    - active_mask[i] = 0 means thread i is currently inactive.
//
// 2. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset:
//        - active_mask should be set to all 1s;
//        - stack pointer sp should be cleared to 0;
//        - all stack entries should be cleared to 0.
//    - This means all threads are initially active.
//
// 3. Predicate behavior:
//    - predicate[i] indicates whether thread i takes the if-branch.
//    - If predicate[i] = 1, thread i belongs to the if-path.
//    - If predicate[i] = 0, thread i belongs to the else-path.
//
// 4. Stack behavior:
//    - The module should contain a stack of active masks.
//    - The stack is used to remember the parent active_mask before entering
//      a divergent if/else region.
//    - sp points to the next free stack entry.
//    - The maximum stack depth is STACK_D.
//
// 5. enter_if behavior:
//    - When enter_if is asserted and the stack is not full:
//        - push the current active_mask onto stack[sp];
//        - increment sp;
//        - update active_mask to active_mask & predicate.
//    - This activates only the threads that are currently active and whose
//      predicate bit is 1.
//
// 6. enter_else behavior:
//    - When enter_else is asserted and sp is not 0:
//        - active_mask should become stack[sp-1] & ~predicate.
//    - This activates the else-path threads from the saved parent mask.
//    - enter_else should not pop the stack.
//    - The saved parent mask must remain available for exit_if.
//
// 7. exit_if behavior:
//    - When exit_if is asserted and sp is not 0:
//        - restore active_mask from stack[sp-1];
//        - decrement sp.
//    - This exits the if/else region and restores the parent active mask.
//
// 8. Priority behavior:
//    - If multiple control signals are asserted in the same cycle, use this
//      priority:
//        enter_if > enter_else > exit_if
//    - This matches an if / else-if / else-if implementation style.
//
// 9. Stack full behavior:
//    - If enter_if is asserted while sp == STACK_D, no push should occur.
//    - active_mask and sp should remain unchanged for that enter_if request.
//
// 10. Stack empty behavior:
//    - If enter_else or exit_if is asserted while sp == 0, no restore should
//      occur.
//    - active_mask and sp should remain unchanged.
//
// 11. Output behavior:
//    - active_mask should be registered.
//    - active_mask changes only on reset or on the rising edge of clk.
//
// 12. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential state updates.
//    - Use nonblocking assignments.
//    - Use a stack array to store previous active masks.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 13. Assumptions:
//    - THREADS is the number of SIMD/SIMT threads or lanes.
//    - STACK_D is the maximum supported nested divergence depth.
//    - predicate is stable when enter_if or enter_else is asserted.
//    - This is a simplified divergence-mask controller.
//    - It does not store separate reconvergence PCs or branch targets.
// ============================================================

`default_nettype none

module thread_mask #(
  parameter THREADS = 32,
  parameter STACK_D = 4
)(
  input  logic [THREADS-1:0] predicate,
  input  logic               clk,
  input  logic               rst_n,
  input  logic               enter_if,
  input  logic               enter_else,
  input  logic               exit_if,
  output logic [THREADS-1:0] active_mask
);
    localparam int SP_W = $clog2(STACK_D);
    logic [THREADS-1:0] stack [STACK_D];
    logic [SP_W:0] sp;

    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        // active_mask <= '0;
        active_mask <= '1;
        sp <= '0;
        for (int i = 0; i < STACK_D; i++) stack[i] <= '0;
      end else begin
        if (enter_if && sp < STACK_D) begin
          active_mask <= active_mask & predicate;
          stack[sp] <= active_mask;
          sp <= sp+1;
        end else if (enter_else && sp != 0) begin
          active_mask <= stack[sp-1] & (~predicate);
        end else if (exit_if && sp != 0) begin
          active_mask <= stack[sp-1];
          sp <= sp-1;
        end
      end
    end
endmodule