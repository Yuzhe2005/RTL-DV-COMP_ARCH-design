// ============================================================
// Problem: 4-Way Cache LRU Replacement Controller
// ============================================================
// Design a parameterized cache replacement controller that tracks
// least-recently-used information for each cache set.
// Module interface:
// module cache_lru4 #(
//   parameter NUM_SETS  = 64,
//   parameter WAY_COUNT = 4
// )(
//   input  logic                          clk,
//   input  logic                          rst_n,
//   input  logic                          req_valid,
//   input  logic                          hit,
//   input  logic                          refill,
//   input  logic [$clog2(NUM_SETS)-1:0]  req_set,
//   input  logic [$clog2(WAY_COUNT)-1:0] hit_way,
//   input  logic [$clog2(WAY_COUNT)-1:0] refill_way,
//   input  logic [WAY_COUNT-1:0]         way_valid,
//   output logic                          victim_valid,
//   output logic [$clog2(WAY_COUNT)-1:0] victim_way
// );
// Requirements:
// 1. This module implements cache replacement metadata.
//    - The cache has NUM_SETS sets.
//    - Each set has WAY_COUNT ways.
//    - The default target configuration is 4-way set associative.
//    - The module should decide which way should be selected as victim.
// 2. Request behavior:
//    - req_valid indicates that the current request is valid.
//    - req_set selects which cache set is being accessed.
//    - hit indicates that the request hit in the cache.
//    - refill indicates that a cache refill/allocation is happening.
//    - hit_way is meaningful when hit is high.
//    - refill_way is meaningful when refill is high.
// 3. LRU tracking:
//    - Maintain per-set replacement state.
//    - Each set should track relative recency among all ways.
//    - On reset, initialize the replacement state to a deterministic value.
//    - On a valid hit, update the accessed hit way as the most recently used way.
//    - On a valid refill, update the refill way as the most recently used way.
//    - Other ways in the same set should be updated consistently so that future
//      victim selection reflects least-recently-used behavior.
//    - Sets not selected by req_set should not have their LRU state changed.
// 4. Access selection:
//    - When req_valid is high and hit is high, the accessed way is hit_way.
//    - When req_valid is high and refill is high, the accessed way is refill_way.
//    - If both hit and refill are low, no LRU update is required.
//    - You may assume hit and refill are not both asserted for the same request.
// 5. Victim selection:
//    - victim_valid should indicate whether victim_way is meaningful.
//    - If req_valid is low, victim_valid should be low.
//    - If req_valid is high, victim_valid should be high.
//    - Victim selection should be based on the selected req_set.
//    - Invalid ways have priority over LRU replacement.
//    - If at least one way in the selected set is invalid, select an invalid way.
//    - If all ways are valid, select the least-recently-used way.
//    - If multiple ways satisfy the same priority condition, choose the lowest-index way.
// 6. way_valid behavior:
//    - way_valid is a per-way valid mask for the selected set.
//    - way_valid[i] == 1 means way i currently contains valid cache data.
//    - way_valid[i] == 0 means way i is available for allocation.
//    - Invalid ways should be selected before evicting a valid LRU way.
// 7. Timing behavior:
//    - LRU state updates should happen on the rising edge of clk.
//    - Reset is active-low asynchronous reset: rst_n.
//    - Victim selection may be combinational based on current request and stored LRU state.
//    - The design should avoid race-prone behavior between input valid mask and victim selection.
// 8. Reset behavior:
//    - When rst_n is low:
//        all per-set replacement metadata should be initialized.
//        victim output behavior should be safe after reset.
//    - The initial LRU ordering does not need to reflect real accesses.
//    - The initial LRU ordering only needs to be deterministic.
// 9. Output behavior:
//    - victim_valid should be 0 when req_valid is 0.
//    - victim_valid should be 1 when req_valid is 1.
//    - victim_way should point to the selected replacement way.
//    - victim_way should prefer an invalid way over any valid way.
//    - victim_way should select the LRU way only when all ways are valid.
// 10. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential LRU state updates.
//    - Use always_comb for combinational victim selection and access decode.
//    - The design should be synthesizable.
//    - The implementation may use per-way ranks, counters, bits, or any equivalent
//      replacement-state encoding.
// 11. Assumptions:
//    - WAY_COUNT is expected to be 4 for the main test configuration.
//    - NUM_SETS is positive.
//    - way_valid corresponds to the currently requested set.
//    - hit_way and refill_way are valid way indices when their corresponding
//      control signals are asserted.
//    - This problem only requires LRU victim selection and update.
// ============================================================

`default_nettype none

module cache_lru4 #(
  parameter NUM_SETS  = 64,
  parameter WAY_COUNT = 4
)(
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic                          req_valid,
  input  logic                          hit,
  input  logic                          refill,
  input  logic [$clog2(NUM_SETS)-1:0]  req_set,
  input  logic [$clog2(WAY_COUNT)-1:0] hit_way,
  input  logic [$clog2(WAY_COUNT)-1:0] refill_way,
  input  logic [WAY_COUNT-1:0]         way_valid,
  output logic                          victim_valid,
  output logic [$clog2(WAY_COUNT)-1:0] victim_way
);
    
    logic [1:0] rank [NUM_SETS][WAY_COUNT];
    logic [1:0] old_rank;
    logic [$clog2(WAY_COUNT)-1:0] access;
    logic valid;
    
    assign valid = (req_valid) && (hit || refill);

    always_comb begin
        access = '0;
        if (valid) access = (hit) ? hit_way : refill_way;
    end

    assign old_rank = rank[req_set][access];

    logic [WAY_COUNT-1:0] way_valid_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) way_valid_q <= '1;
        else way_valid_q <= way_valid;
    end

    assign victim_valid = req_valid;

    logic found;
    always_comb begin
        victim_way = '0;
        found = 0;
        if (req_valid) begin
            for (int i = 0; i < WAY_COUNT; i++) begin
                if (!found && !way_valid_q[i]) begin
                    victim_way = i[$clog2(WAY_COUNT)-1:0];
                    found = 1;
                end
            end
            if (!found) begin
                for (int i = 0; i < WAY_COUNT; i++) begin
                    if (!found && (rank[req_set][i] == 0)) begin
                        victim_way = i[$clog2(WAY_COUNT)-1:0];
                        found = 1;
                    end
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SETS; s++) begin
                for (int w = 0; w < WAY_COUNT; w++) begin
                    rank[s][w] <= w[1:0];
                end
            end
        end else if (valid) begin
            for (int w = 0; w < WAY_COUNT; w++) begin
                if (w[1:0] == access) begin
                    rank[req_set][w] <= 2'd3;
                end else if (rank[req_set][w] > old_rank) begin
                    rank[req_set][w] <= rank[req_set][w]-1;
                end
            end
        end
    end
endmodule


//------------------------------------------------------------------------------
// better solution (sample solution):

module cache_lru4 #(
  parameter NUM_SETS  = 64,
  parameter WAY_COUNT = 4
)(
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic                          req_valid,
  input  logic                          hit,
  input  logic                          refill,
  input  logic [$clog2(NUM_SETS)-1:0]  req_set,
  input  logic [$clog2(WAY_COUNT)-1:0] hit_way,
  input  logic [$clog2(WAY_COUNT)-1:0] refill_way,
  input  logic [WAY_COUNT-1:0]         way_valid,
  output logic                          victim_valid,
  output logic [$clog2(WAY_COUNT)-1:0] victim_way
);

  // -----------------------------
  // LRU state (0 = LRU, 3 = MRU)
  // -----------------------------
  logic [1:0] rank [NUM_SETS][WAY_COUNT];

  // -----------------------------
  // Register inputs (FIX timing bug)
  // -----------------------------
  logic [WAY_COUNT-1:0] way_valid_q;
  logic [$clog2(WAY_COUNT)-1:0] acc;
  logic [1:0] old_r;

  // Latch inputs to avoid race
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      way_valid_q <= '1;
    else
      way_valid_q <= way_valid;
  end

  // -----------------------------
  // Access decode
  // -----------------------------
  always_comb begin
    acc = '0;
    if (req_valid && (hit || refill))
      acc = hit ? hit_way : refill_way;
  end

  always_comb begin
    old_r = rank[req_set][acc];
  end

  // -----------------------------
  // Victim selection (FIXED priority)
  // -----------------------------
  always_comb begin
    victim_valid = req_valid;
    victim_way   = '0;

    if (!req_valid) begin
      victim_valid = 0;
    end
    else begin
      logic found;

      found = 0;

      // -------------------------
      // PRIORITY 1: invalid ways
      // -------------------------
      for (int i = 0; i < WAY_COUNT; i++) begin
        if (!found && !way_valid_q[i]) begin
          victim_way = i;
          found = 1;
        end
      end

      // -------------------------
      // PRIORITY 2: true LRU
      // -------------------------
      if (!found) begin
        for (int i = 0; i < WAY_COUNT; i++) begin
          if (!found && rank[req_set][i] == 0) begin
            victim_way = i;
            found = 1;
          end
        end
      end
    end
  end

  // -----------------------------
  // LRU update logic
  // -----------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int s = 0; s < NUM_SETS; s++) begin
        for (int w = 0; w < WAY_COUNT; w++) begin
          rank[s][w] <= w; 
        end
      end
    end
    else if (req_valid && (hit || refill)) begin
      for (int w = 0; w < WAY_COUNT; w++) begin
        if (w == acc)
          rank[req_set][w] <= 2'd3; // MRU
        else if (rank[req_set][w] > old_r)
          rank[req_set][w] <= rank[req_set][w] - 1;
      end
    end
  end

endmodule
