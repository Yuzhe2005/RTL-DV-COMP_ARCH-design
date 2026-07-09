// ============================================================
// Problem: Cache Dirty Bit Tracker with Writeback Request
// ============================================================
// Design a dirty-bit tracking module for a set-associative write-back
// cache. The module records which cache lines are dirty and generates
// a writeback request when a dirty line is being evicted.
//
// Module interface:
// module cache_dirty #(
//   parameter NUM_SETS = 64,
//   parameter N_WAYS   = 4,
//   parameter TAG_W    = 20
// )(
//   input  logic                         clk,
//   input  logic                         rst_n,
//   input  logic                         write_hit,
//   input  logic                         refill_done,
//   input  logic                         write_alloc_fill,
//   input  logic                         evict_valid,
//   input  logic                         wb_done,
//   input  logic [$clog2(NUM_SETS)-1:0]  hit_set,
//   input  logic [$clog2(NUM_SETS)-1:0]  refill_set,
//   input  logic [$clog2(NUM_SETS)-1:0]  evict_set,
//   input  logic [$clog2(N_WAYS)-1:0]    hit_way,
//   input  logic [$clog2(N_WAYS)-1:0]    refill_way,
//   input  logic [$clog2(N_WAYS)-1:0]    evict_way,
//   input  logic [TAG_W-1:0]             evict_tag,
//   output logic                         evict_dirty,
//   output logic                         writeback_req,
//   output logic [TAG_W+$clog2(NUM_SETS)-1:0] writeback_addr
// );
//
// Requirements:
// 1. Maintain one dirty bit for every cache line.
//    - Total number of dirty bits is NUM_SETS * N_WAYS.
//    - Each dirty bit corresponds to one set/way cache line.
//
// 2. Dirty bit indexing:
//    - A cache line may be indexed using:
//        index = set * N_WAYS + way
//    - hit_set/hit_way identify the cache line hit by a write.
//    - refill_set/refill_way identify the cache line filled by refill.
//    - evict_set/evict_way identify the cache line selected for eviction.
//
// 3. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, all dirty bits should clear to 0.
//    - After reset, no cache line should be considered dirty.
//
// 4. Write-hit behavior:
//    - When write_hit is asserted, set the dirty bit for
//      hit_set/hit_way to 1.
//    - This represents a write-back cache line being modified by the CPU.
//
// 5. Refill behavior:
//    - When refill_done is asserted, update the dirty bit for
//      refill_set/refill_way.
//    - If write_alloc_fill is 1, the newly filled line should become dirty.
//    - If write_alloc_fill is 0, the newly filled line should be clean.
//    - Therefore:
//        dirty[refill_set, refill_way] <= write_alloc_fill;
//
// 6. Writeback completion behavior:
//    - When wb_done is asserted, clear the dirty bit for evict_set/evict_way.
//    - This means the dirty cache line has been written back to memory
//      and is no longer dirty.
//
// 7. Eviction dirty status:
//    - evict_dirty should indicate whether the currently selected eviction
//      line is dirty.
//    - evict_dirty should be combinationally derived from the dirty bit
//      at evict_set/evict_way.
//
// 8. Writeback request behavior:
//    - writeback_req should assert when:
//        evict_valid is 1, and
//        the selected eviction line is dirty.
//    - If evict_valid is 0, writeback_req should be 0 even if the indexed
//      dirty bit is 1.
//    - If the selected eviction line is clean, writeback_req should be 0.
//
// 9. Writeback address behavior:
//    - writeback_addr should be formed from the evicted line's tag and set.
//    - The address should contain:
//        {evict_tag, evict_set}
//    - This module does not include byte offset bits.
//
// 10. Update priority:
//    - Multiple input events may occur in the same clock cycle.
//    - If the same dirty bit is written by multiple conditions in the same
//      always_ff block, later assignments in the block take priority.
//    - A typical priority order is:
//        write_hit update,
//        refill_done update,
//        wb_done clear.
//    - Therefore, if wb_done targets the same line as another update in
//      the same cycle, the final dirty bit should be cleared.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for dirty-bit state updates.
//    - Use continuous assignments or always_comb for combinational outputs.
//    - Do not infer latches.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 12. Parameter behavior:
//    - NUM_SETS controls the number of cache sets.
//    - N_WAYS controls the associativity.
//    - TAG_W controls the width of the cache tag.
//    - The design should work for different legal parameter values.
//
// 13. Assumptions:
//    - NUM_SETS >= 1.
//    - N_WAYS >= 1.
//    - Input set and way indices are valid.
//    - This module only tracks dirty metadata; it does not store cache
//      data, tags, valid bits, or replacement state.
// ============================================================

`default_nettype none

module cache_dirty #(
  parameter NUM_SETS = 64,
  parameter N_WAYS   = 4,
  parameter TAG_W    = 20
)(
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         write_hit,
  input  logic                         refill_done,
  input  logic                         write_alloc_fill,
  input  logic                         evict_valid,
  input  logic                         wb_done,
  input  logic [$clog2(NUM_SETS)-1:0]  hit_set,
  input  logic [$clog2(NUM_SETS)-1:0]  refill_set,
  input  logic [$clog2(NUM_SETS)-1:0]  evict_set,
  input  logic [$clog2(N_WAYS)-1:0]    hit_way,
  input  logic [$clog2(N_WAYS)-1:0]    refill_way,
  input  logic [$clog2(N_WAYS)-1:0]    evict_way,
  input  logic [TAG_W-1:0]             evict_tag,
  output logic                         evict_dirty,
  output logic                         writeback_req,
  output logic [TAG_W+$clog2(NUM_SETS)-1:0] writeback_addr
);
    logic [NUM_SETS * N_WAYS-1:0] dirty;
    
    assign writeback_addr = {evict_tag, evict_set};
    assign evict_dirty = dirty[evict_set*N_WAYS+evict_way];

    assign writeback_req = evict_valid && evict_dirty; // 第一遍不会


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dirty <= '0;
        end else begin
            // 三个独立的if condition, 因为可能同时进行
            if (write_hit)
                dirty[hit_set*N_WAYS+hit_way] <= 1;
            // else if (refill_done)
            if (refill_done)
                dirty[refill_set*N_WAYS+refill_way] <= write_alloc_fill;
            // else if (wb_done)
            if (wb_done)
                dirty[evict_set*N_WAYS+evict_way] <= 0;
        end
    end
endmodule