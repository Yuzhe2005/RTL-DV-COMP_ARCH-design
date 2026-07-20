// ============================================================
// Problem: Simple Reorder Buffer
// ============================================================
// Design a simplified reorder buffer for an out-of-order CPU pipeline.
//
// A reorder buffer, or ROB, stores dispatched instructions in program order,
// tracks when their execution results are ready, and allows completed
// instructions to commit in program order from the head of the buffer.
//
// Module interface:
// module rob #(
//   parameter ENTRIES = 8,
//   parameter W       = 32
// )(
//   input  logic                          clk,
//   input  logic                          rst_n,
//   input  logic                          dispatch,
//   input  logic                          writeback,
//   input  logic                          commit,
//   input  logic                          flush,
//   input  logic [$clog2(ENTRIES)-1:0]    wb_id,
//   input  logic [$clog2(ENTRIES)-1:0]    flush_tail,
//   input  logic [4:0]                    dest_arch,
//   input  logic [W-1:0]                  wb_value,
//   output logic                          full,
//   output logic                          empty,
//   output logic                          commit_valid,
//   output logic [4:0]                    commit_arch,
//   output logic [W-1:0]                  commit_value,
//   output logic [$clog2(ENTRIES)-1:0]    alloc_id
// );
//
// Requirements:
// 1. The ROB should contain ENTRIES entries.
//
// 2. Each ROB entry should store:
//    - valid bit: whether the entry is currently occupied;
//    - ready bit: whether the instruction has finished execution;
//    - destination architectural register;
//    - writeback value.
//
// 3. The ROB should maintain two pointers:
//    - head: points to the oldest ROB entry;
//    - tail: points to the next free allocation entry.
//
// 4. Empty behavior:
//    - empty should be 1 when head == tail and the head entry is not valid.
//    - empty should be 0 otherwise.
//
// 5. Full behavior:
//    - full should be 1 when head == tail and the head entry is valid.
//    - full should be 0 otherwise.
//
// 6. Allocation behavior:
//    - alloc_id should always equal tail.
//    - When dispatch is asserted and the ROB is not full:
//        - allocate the entry at tail;
//        - set valid[tail] to 1;
//        - set ready[tail] to 0;
//        - store dest_arch into the entry;
//        - increment tail with wrap-around.
//    - If dispatch is asserted while full is 1, no allocation should occur.
//
// 7. Writeback behavior:
//    - When writeback is asserted:
//        - use wb_id to select a ROB entry;
//        - write wb_value into that entry;
//        - set ready[wb_id] to 1.
//    - This marks the instruction as completed, but it does not commit it yet.
//
// 8. Commit behavior:
//    - commit_valid should be 1 when the head entry is both valid and ready.
//    - commit_arch should output the architectural destination register stored
//      in the head entry.
//    - commit_value should output the value stored in the head entry.
//    - When commit is asserted and commit_valid is 1:
//        - clear valid[head];
//        - clear ready[head];
//        - increment head with wrap-around.
//    - If the head entry is not ready, no commit should occur even if later
//      entries are ready.
//
// 9. In-order commit requirement:
//    - Instructions may write back out of order using wb_id.
//    - Instructions must commit in order from head.
//    - A younger ready instruction cannot commit before an older instruction
//      at the head has committed.
//
// 10. Flush behavior:
//    - flush is used to recover from events such as branch misprediction.
//    - flush_tail indicates the new tail pointer after recovery.
//    - On flush:
//        - invalidate entries in the circular range [flush_tail, tail);
//        - clear their valid and ready bits;
//        - set tail to flush_tail.
//    - Entries before flush_tail are preserved.
//    - If flush_tail == tail, no entries need to be invalidated.
//
// 11. Wrap-around behavior:
//    - head and tail are circular pointers.
//    - When head or tail reaches ENTRIES-1, the next value should wrap to 0.
//
// 12. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset:
//        - head should be cleared to 0;
//        - tail should be cleared to 0;
//        - all valid bits should be cleared;
//        - all ready bits should be cleared;
//        - stored destination registers and values should be cleared.
//
// 13. Output behavior:
//    - full, empty, alloc_id, commit_valid, commit_arch, and commit_value
//      should be generated combinationally from the current ROB state.
//    - ROB state should update only on reset or rising edge of clk.
//
// 14. Simplifications:
//    - This ROB stores only destination architectural register and result value.
//    - It does not store opcode, exception status, branch metadata, physical
//      register mappings, memory ordering information, or PC.
//    - It supports at most one dispatch, one writeback, and one commit per cycle.
//    - It assumes wb_id refers to a valid allocated ROB entry.
//    - It assumes flush_tail is a valid ROB pointer.
//
// 15. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential state updates.
//    - Use nonblocking assignments in sequential logic.
//    - Use circular pointer logic for head and tail.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
// ============================================================

·default_nettype none

module rob #(
  parameter ENTRIES = 8,
  parameter W       = 32
)(
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic                          dispatch,
  input  logic                          writeback,
  input  logic                          commit,
  input  logic                          flush,
  input  logic [$clog2(ENTRIES)-1:0]    wb_id,
  input  logic [$clog2(ENTRIES)-1:0]    flush_tail,
  input  logic [4:0]                    dest_arch,
  input  logic [W-1:0]                  wb_value,
  output logic                          full,
  output logic                          empty,
  output logic                          commit_valid,
  output logic [4:0]                    commit_arch,
  output logic [W-1:0]                  commit_value,
  output logic [$clog2(ENTRIES)-1:0]    alloc_id
);
    logic [ENTRIES-1:0] valid, ready;
    logic [4:0] arch_dest [ENTRIES];
    logic [W-1:0] value [ENTRIES];
    logic [$clog2(ENTRIES)-1:0] head, tail;

    assign empty = (head == tail) && !valid[head];
    assign full = (head == tail) && valid[head];
    assign alloc_id = tail;
    assign commit_valid = valid[head] && ready[head];
    assign commit_arch = arch_dest[head];
    assign commit_value = value[head];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= '0;
            tail <= '0;
            valid <= '0;
            ready <= '0;
            for (int i = 0; i < ENTRIES; i++) begin
                arch_dest[i] <= '0;
                valid[i] <= '0;
            end
        end else begin
            if (dispatch && !full) begin
                valid[tail] <= 1'b1;
                ready[tail] <= 1'b0;
                arch_dest[tail] <= dest_arch;
                tail <= (tail == ENTRIES-1) ? '0 : (tail+1'b1);
            end

            if (writeback) begin
                ready[wb_id] <= 1'b1;
                value[wb_id] <= wb_value;
            end

            if (commit_valid && commit) begin
                valid[head] <= 1'b0;
                ready[head] <= 1'b0;
                head <= (head == ENTRIES-1) ? '0 : (head+1'b1);
            end

            if (flush) begin
                if (flush_tail != tail) begin
                    for (int i = 0; i < ENTRIES; i++) begin
                        logic in_flush_range;
                        if (flush_tail < tail)
                            in_flush_range = (i[$clog2(ENTRIES)-1:0] >= flush_tail) &&
                               (i[$clog2(ENTRIES)-1:0] < tail);
                        else
                            in_flush_range = (i[$clog2(ENTRIES)-1:0] >= flush_tail) ||
                               (i[$clog2(ENTRIES)-1:0] < tail);
                        if (in_flush_range) begin
                            valid[i] <= 1'b0;
                            ready[i] <= 1'b0;
                        end
                    end
                end
                tail <= flush_tail;
            end
        end
    end
endmodule