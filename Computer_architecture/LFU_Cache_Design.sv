// ============================================================
// Problem: Cache LFU Replacement Controller
// ============================================================
// Design a parameterized LFU replacement controller for a set-associative cache.
// LFU means Least Frequently Used: when replacement is needed, choose the valid
// way with the smallest access frequency counter.
//
// Module interface:
// module cache_lfu #(
//   parameter NUM_SETS = 64,
//   parameter N_WAYS   = 4,
//   parameter CNT_W    = 4
// )(
//   input  logic                         clk,
//   input  logic                         rst_n,
//   input  logic                         req_valid,
//   input  logic                         hit,
//   input  logic                         refill,
//   input  logic [$clog2(NUM_SETS)-1:0]  req_set,
//   input  logic [$clog2(N_WAYS)-1:0]    hit_way,
//   input  logic [$clog2(N_WAYS)-1:0]    refill_way,
//   input  logic [N_WAYS-1:0]            way_valid,
//   output logic [$clog2(N_WAYS)-1:0]    victim_way
// );
//
// Requirements:
// 1. Implement a cache replacement helper that tracks frequency counters
//    for every set and way.
// 2. There should be one CNT_W-bit frequency counter for each cache line:
//    - total counters = NUM_SETS * N_WAYS.
// 3. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, all frequency counters should be cleared to 0.
// 4. Victim selection behavior:
//    - victim_way should be combinationally selected for req_set.
//    - If any way in the selected set is invalid, choose the first invalid way.
//    - Invalid ways have higher priority than LFU replacement.
//    - If all ways are valid, choose the way with the smallest frequency counter.
//    - If multiple ways have the same minimum frequency, choose the lowest-indexed way.
// 5. Hit update behavior:
//    - When req_valid && hit is true, increment the frequency counter for hit_way
//      in req_set.
//    - The counter should saturate at its maximum value instead of wrapping.
// 6. Refill update behavior:
//    - When req_valid && refill is true, initialize the frequency counter for
//      refill_way in req_set to 1.
//    - This marks the newly filled line as recently/frequently used once.
// 7. Counter max behavior:
//    - The maximum counter value is all 1s: {CNT_W{1'b1}}.
//    - A hit should not increment a counter past this value.
// 8. Addressing behavior:
//    - The counter index for a given set and way may be computed as:
//      base = req_set * N_WAYS;
//      counter index = base + way.
// 9. Request gating:
//    - Frequency counters should update only when req_valid is high.
//    - If req_valid is low, all counters should hold their current values.
// 10. Implementation style:
//    - Use SystemVerilog.
//    - Use always_comb for victim_way selection.
//    - Use always_ff for frequency counter updates.
//    - The design should be synthesizable.
// 11. Assumptions:
//    - way_valid corresponds to the selected req_set.
//    - hit_way is meaningful when hit is high.
//    - refill_way is meaningful when refill is high.
//    - This module only chooses a victim and maintains LFU metadata;
//      it does not store cache tags or data.
// ============================================================

`default_nettype none

module cache_lfu #(
  parameter NUM_SETS = 64,
  parameter N_WAYS   = 4,
  parameter CNT_W    = 4
)(
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         req_valid,
  input  logic                         hit,
  input  logic                         refill,
  input  logic [$clog2(NUM_SETS)-1:0]  req_set,
  input  logic [$clog2(N_WAYS)-1:0]    hit_way,
  input  logic [$clog2(N_WAYS)-1:0]    refill_way,
  input  logic [N_WAYS-1:0]            way_valid,
  output logic [$clog2(N_WAYS)-1:0]    victim_way
);
    logic [CNT_W-1:0] freq [NUM_SETS * N_WAYS];
    localparam logic [CNT_W-1:0] max_val = {CNT_W{1'b1}};
    
    logic [CNT_W-1:0] low_freq;
    
    logic [$clog2(NUM_SETS*N_WAYS)-1:0] base;
    assign base = req_set * N_WAYS;

    always_comb begin
        logic found;
        found = 0;
        low_freq = max_val;
        victim_way = '0; // 第一遍忘了
        for (int w = 0; w < N_WAYS; w++) begin
            if (!found && !way_valid[w]) begin
                found = 1;
                victim_way = w[$clog2(N_WAYS)-1:0];
            end
        end
        if (!found) begin
            for (int w = N_WAYS-1; w >= 0; w--) begin
                if (freq[base + w] <= low_freq) begin
                    victim_way = w[$clog2(N_WAYS)-1:0];
                    low_freq = freq[base+w];
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SETS; s++) begin
                for (int w = 0; w < N_WAYS; w++) begin
                    freq[s*N_WAYS+w] <= '0;
                end
            end
        end else if (req_valid) begin
            if (hit) begin
                if (freq[base+hit_way] < max_val)
                    freq[base+hit_way] <= freq[base+hit_way]+1;
            end 
            if (refill) begin
                // freq[req_set][hit_way] <= 1;
                freq[base+refill_way] <= 1;
            end
        end
    end
endmodule