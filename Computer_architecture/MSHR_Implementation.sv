// ============================================================
// Problem: MSHR - Miss Status Holding Register
// ============================================================
// Design a simplified MSHR for a cache controller.
//
// An MSHR tracks outstanding cache misses. If multiple requesters miss
// to the same cache line while the first miss is still outstanding, the
// later requests should merge into the existing MSHR entry instead of
// issuing another memory request.
//
// Module interface:
// module mshr #(
//   parameter ENTRIES  = 4,
//   parameter ADDR_W   = 32,
//   parameter REQS     = 4,
//   parameter OFFSET_W = 4
// )(
//   input  logic                          clk,
//   input  logic                          rst_n,
//   input  logic                          alloc_req,
//   input  logic                          refill_done,
//   input  logic [ADDR_W-1:0]             alloc_addr,
//   input  logic [$clog2(REQS)-1:0]       requester_id,
//   input  logic [$clog2(ENTRIES)-1:0]    refill_entry,
//   output logic                          full,
//   output logic                          hit,
//   output logic                          issue_mem_req,
//   output logic [$clog2(ENTRIES)-1:0]    alloc_entry,
//   output logic [$clog2(ENTRIES)-1:0]    hit_entry,
//   output logic [REQS-1:0]               merged_waiters
// );
//
// Requirements:
// 1. The module should contain ENTRIES MSHR entries.
//
// 2. Each MSHR entry should track:
//    - whether the entry is valid;
//    - the outstanding cache line address;
//    - a bitmask of requesters waiting for this line.
//
// 3. Cache line address:
//    - alloc_addr is a byte address.
//    - The MSHR should compare cache-line addresses, not byte offsets.
//    - The cache line address is alloc_addr[ADDR_W-1:OFFSET_W].
//    - Requests with the same line address but different byte offsets
//      should be treated as the same outstanding miss.
//
// 4. Hit detection:
//    - hit should be 1 when alloc_addr's line address matches any valid
//      MSHR entry.
//    - hit_entry should indicate the matching entry index.
//    - If multiple entries somehow match, choose the lowest-index match.
//
// 5. Full detection:
//    - full should be 1 when all MSHR entries are valid.
//    - full should be 0 when at least one entry is free.
//    - alloc_entry should indicate the lowest-index free entry.
//
// 6. Memory request issue:
//    - issue_mem_req should assert when:
//        - alloc_req is 1;
//        - the requested line is not already in the MSHR;
//        - the MSHR is not full.
//    - If the request hits an existing MSHR entry, do not issue a new
//      memory request.
//    - If the MSHR is full and there is no hit, do not issue a new memory
//      request.
//
// 7. Allocation behavior:
//    - On a clock edge, when alloc_req is 1 and hit is 0 and full is 0:
//        - allocate the entry indicated by alloc_entry;
//        - mark that entry valid;
//        - store the requested line address;
//        - clear the waiters bitmask;
//        - set the bit corresponding to requester_id.
//
// 8. Merge behavior:
//    - On a clock edge, when alloc_req is 1 and hit is 1:
//        - do not allocate a new entry;
//        - do not issue another memory request;
//        - set waiters[hit_entry][requester_id] to 1.
//    - This records that requester_id is waiting for the same outstanding
//      cache line refill.
//
// 9. Full and miss behavior:
//    - When alloc_req is 1, hit is 0, and full is 1:
//        - no entry should be allocated;
//        - no waiter should be added;
//        - issue_mem_req should be 0.
//
// 10. Refill completion behavior:
//    - refill_done indicates that the memory refill for refill_entry has
//      completed.
//    - On refill_done:
//        - clear valid for refill_entry;
//        - clear its waiter bitmask;
//        - the entry becomes available for future allocations.
//
// 11. merged_waiters output:
//    - merged_waiters should output the waiter bitmask of refill_entry.
//    - This tells the cache/controller which requesters were waiting for
//      the completed refill.
//
// 12. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset:
//        - all MSHR entries should become invalid;
//        - all stored line addresses should clear to 0;
//        - all waiter bitmasks should clear to 0.
//
// 13. Combinational behavior:
//    - hit, hit_entry, full, and alloc_entry should be computed
//      combinationally from the current MSHR state and alloc_addr.
//    - issue_mem_req should also be combinational.
//
// 14. Sequential behavior:
//    - Allocation, merge, and refill clearing should happen on the rising
//      edge of clk.
//    - Use nonblocking assignments for registered state.
//
// 15. Assumptions:
//    - ENTRIES is at least 1.
//    - REQS is at least 1.
//    - ADDR_W is greater than OFFSET_W.
//    - requester_id is a valid requester index.
//    - refill_entry is a valid MSHR entry index.
//    - The design is a simplified MSHR and does not store per-request
//      byte offsets, load/store types, data masks, or replay metadata.
// ============================================================

`default_nettype none

module mshr #(
  parameter ENTRIES  = 4,
  parameter ADDR_W   = 32,
  parameter REQS     = 4,
  parameter OFFSET_W = 4
)(
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic                          alloc_req,
  input  logic                          refill_done,
  input  logic [ADDR_W-1:0]             alloc_addr,
  input  logic [$clog2(REQS)-1:0]       requester_id,
  input  logic [$clog2(ENTRIES)-1:0]    refill_entry,
  output logic                          full,
  output logic                          hit,
  output logic                          issue_mem_req,
  output logic [$clog2(ENTRIES)-1:0]    alloc_entry,
  output logic [$clog2(ENTRIES)-1:0]    hit_entry,
  output logic [REQS-1:0]               merged_waiters
); 
    logic [ENTRIES-1:0] valid_vec;
    logic [ADDR_W-1-OFFSET_W:0] cache_line [ENTRIES];
    logic [REQS-1:0] waiters [ENTRIES];

    logic [ADDR_W-1-OFFSET_W:0] alloc_line;
    assign alloc_line = alloc_addr[ADDR_W-1:OFFSET_W];

    assign merged_waiters = waiters[refill_entry];
    assign full = (valid_vec == '1);

    always_comb begin
        hit_entry = '0;
        alloc_entry = '0;
        hit = 0; // 第一遍忘了
        if (alloc_req) begin // 不需要
            for (int i = 0; i < ENTRIES; i++) begin
                if (valid_vec[i] && cache_line[i] == alloc_line) begin
                    hit = 1;
                    hit_entry = i[$clog2(ENTRIES)-1:0];
                    break;
                end
            end 
            
            for (int i = 0; i < ENTRIES; i++) begin
                if (!valid_vec[i]) begin
                    alloc_entry = i[$clog2(ENTRIES)-1:0]; 
                    break;
                end
            end
        end
    end

    assign issue_mem_req = alloc_req && !hit && !full; // 第一遍不知道

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_vec <= '0;
            for (int i = 0; i < ENTRIES; i++) begin
                cache_line[i] <= '0;
                waiters[i] <= '0;
            end 
        end else begin
            if (alloc_req) begin
                if (hit) begin
                    // cache_line[hit_entry] <= alloc_line; // 没有必要，本来就hit了
                    waiters[hit_entry][requester_id] <= 1'b1;
                end else if (!full) begin // 这里应该 !full，什么都做不了
                    cache_line[alloc_entry] <= alloc_line;
                    valid_vec[alloc_entry] <= 1;
                    waiters[alloc_entry] <= '0;
                    waiters[alloc_entry][requester_id] <= 1;
                end
                
                // 这个不应该出现在 alloc_req 的条件下
                // if (refill_done) begin
                //     valid_vec[refill_entry] <= 0;
                //     waiters[refill_done] <= '0;
                // end
            end

            if (refill_done) begin
                valid_vec[refill_entry] <= 0;
                waiters[refill_entry] <= '0;
            end
        end
    end
endmodule

//--------------------------------------------------------------------------------------------------------------------------

// sample solution:

module mshr #(
  parameter ENTRIES  = 4,
  parameter ADDR_W   = 32,
  parameter REQS     = 4,
  parameter OFFSET_W = 4
)(
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic                          alloc_req,
  input  logic                          refill_done,
  input  logic [ADDR_W-1:0]             alloc_addr,
  input  logic [$clog2(REQS)-1:0]       requester_id,
  input  logic [$clog2(ENTRIES)-1:0]    refill_entry,
  output logic                          full,
  output logic                          hit,
  output logic                          issue_mem_req,
  output logic [$clog2(ENTRIES)-1:0]    alloc_entry,
  output logic [$clog2(ENTRIES)-1:0]    hit_entry,
  output logic [REQS-1:0]               merged_waiters
);
  // Use packed valid bitvector for Verilator comb sensitivity
  logic [ENTRIES-1:0]              valid_vec;
  logic [ADDR_W-OFFSET_W-1:0]     line    [ENTRIES];
  logic [REQS-1:0]                waiters [ENTRIES];
  logic [ADDR_W-OFFSET_W-1:0]     alloc_line;

  assign alloc_line     = alloc_addr[ADDR_W-1:OFFSET_W];
  assign merged_waiters = waiters[refill_entry];

  always_comb begin
    hit         = 1'b0;
    hit_entry   = '0;
    full        = 1'b1;
    alloc_entry = '0;

    for (int i = 0; i < ENTRIES; i++) begin
      if (valid_vec[i] && (line[i] == alloc_line) && !hit) begin
        hit       = 1'b1;
        hit_entry = i[$clog2(ENTRIES)-1:0];
      end
    end

    for (int i = 0; i < ENTRIES; i++) begin
      if (!valid_vec[i] && full) begin
        full        = 1'b0;
        alloc_entry = i[$clog2(ENTRIES)-1:0];
      end
    end
  end

  assign issue_mem_req = alloc_req && !hit && !full;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_vec <= '0;
      for (int i = 0; i < ENTRIES; i++) begin
        line[i]    <= '0;
        waiters[i] <= '0;
      end
    end else begin
      if (alloc_req) begin
        if (hit) begin
          waiters[hit_entry][requester_id] <= 1'b1;
        end else if (!full) begin
          valid_vec[alloc_entry]               <= 1'b1;
          line[alloc_entry]                    <= alloc_line;
          waiters[alloc_entry]                 <= '0;
          waiters[alloc_entry][requester_id]   <= 1'b1;
        end
      end

      if (refill_done) begin
        valid_vec[refill_entry]   <= 1'b0;
        waiters[refill_entry]     <= '0;
      end
    end
  end
endmodule

