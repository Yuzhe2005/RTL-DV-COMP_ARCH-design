// ============================================================
// Problem: Tree-Based Pseudo-LRU Cache Replacement Controller
// ============================================================
// Design a parameterized pseudo-LRU replacement controller.
// Module interface:
// module cache_plru #(
//   parameter int NUM_SETS = 64,
//   parameter int N_WAYS   = 4
// )(
//   input  logic clk,
//   input  logic rst_n,
//   input  logic access_valid,
//   input  logic [$clog2(NUM_SETS)-1:0] access_set,
//   input  logic [$clog2(N_WAYS)-1:0] access_way,
//   output logic [$clog2(N_WAYS)-1:0] victim_way
// );
// Requirements:
// 1. This module tracks replacement metadata for a set-associative cache.
//    - The cache contains NUM_SETS sets.
//    - Each set contains N_WAYS ways.
//    - The intended replacement policy is tree-based pseudo-LRU.
// 2. Parameters:
//    - NUM_SETS controls the number of cache sets.
//    - N_WAYS controls the number of ways per set.
//    - N_WAYS is assumed to be a power of 2.
// 3. Internal metadata:
//    - Maintain pseudo-LRU state independently for each set.
//    - The metadata should be enough to choose one victim way from each set.
//    - Metadata for one set should not affect metadata for another set.
// 4. Reset behavior:
//    - rst_n is an active-low reset.
//    - On reset, initialize all pseudo-LRU metadata to a known state.
//    - After reset, victim_way should produce a deterministic victim for any selected set.
// 5. Victim selection behavior:
//    - victim_way should be generated from the pseudo-LRU metadata of access_set.
//    - victim_way should indicate the way currently predicted to be least recently used.
//    - Victim selection may be combinational.
//    - Changing access_set may change victim_way.
// 6. Access update behavior:
//    - When access_valid is high, update the pseudo-LRU metadata for access_set.
//    - The update should mark access_way as recently used.
//    - After an access, the same way should become less likely to be selected as victim immediately.
//    - Only the metadata for access_set should update.
// 7. Hold behavior:
//    - When access_valid is low, pseudo-LRU metadata should hold its current value.
//    - victim_way should still reflect the current metadata for access_set.
// 8. Tree-based PLRU behavior:
//    - Use a binary-tree style pseudo-LRU representation.
//    - Each internal tree bit should guide victim selection toward one group of ways.
//    - On an access, update the tree state along the path corresponding to access_way.
//    - The update should point future victim selection away from the recently accessed way.
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use sequential logic for metadata updates.
//    - Use combinational logic for victim selection.
//    - The design should be synthesizable.
// 10. Assumptions:
//    - N_WAYS is positive and power-of-two.
//    - access_set is always within the valid set range.
//    - access_way is always within the valid way range.
//    - No valid-bit checking is required in this module.
//    - This module only handles replacement metadata, not cache data/tag storage.
// ============================================================

`default_nettype none

module cache_plru #(
  parameter int NUM_SETS = 64,
  parameter int N_WAYS   = 4
)(
  input  logic clk,
  input  logic rst_n,
  input  logic access_valid,
  input  logic [$clog2(NUM_SETS)-1:0] access_set,
  input  logic [$clog2(N_WAYS)-1:0] access_way,
  output logic [$clog2(N_WAYS)-1:0] victim_way
);
    localparam int LEVELS = $clog2(N_WAYS);
    localparam int TREE_BITS = N_WAYS-1;

    logic [TREE_BITS-1:0] tree [NUM_SETS];

    always_comb begin
      int node;
      node = 0;
      victim_way = '0;
      for (int l = 0; l < LEVELS; l++) begin
        if (tree[access_set][node] == 1'b0) begin
          node = node * 2 + 1;
          victim_way[LEVELS-1-l] = 0;
        end else begin
          node = node * 2 + 2;
          victim_way[LEVELS-1-l] = 1;
        end
      end
    end

    logic [TREE_BITS-1:0] next_tree;
    always_comb begin
      int node;
      next_tree = tree[access_set];
      node = 0;
      for (int l = 0; l < LEVELS; l++) begin
        if (access_way[LEVELS-1-l] == 1'b0) begin
          next_tree[node] = 1;
          node = node * 2 + 1;
        end else begin
          next_tree[node] = 0;
          node = node * 2 + 2;
        end
      end
    end

    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        for (int i = 0; i < NUM_SETS; i++) begin
          tree[i] <= '0;
        end 
      end else if (access_valid) begin
        tree[access_set] <= next_tree;
      end
    end
endmodule