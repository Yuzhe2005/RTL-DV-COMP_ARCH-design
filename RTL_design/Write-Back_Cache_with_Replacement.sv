// ============================================================
// Problem: 4-Way Set-Associative Write-Back Cache with LRU
// ============================================================
// Design a parameterized set-associative cache.
// Module interface:
// module wb_cache #(
//   parameter NUM_SETS   = 4,
//   parameter NUM_WAYS   = 4,
//   parameter TAG_BITS   = 4,
//   parameter DATA_WIDTH = 8
// )(
//   input  logic                   clk,
//   input  logic                   rst_n,
//   input  logic                   access,
//   input  logic                   write_en,
//   input  logic [TAG_BITS-1:0]   addr_tag,
//   input  logic [$clog2(NUM_SETS)-1:0] addr_set,
//   input  logic [DATA_WIDTH-1:0]  write_data,
//   output logic [DATA_WIDTH-1:0]  read_data,
//   output logic                    hit,
//   output logic                    miss,
//   output logic                    wb_req,
//   output logic [TAG_BITS-1:0]    wb_tag,
//   output logic [$clog2(NUM_SETS)-1:0] wb_set,
//   output logic [DATA_WIDTH-1:0]  wb_data
// );
// Requirements:
// 1. This is a set-associative cache.
//    - The cache contains NUM_SETS sets.
//    - Each set contains NUM_WAYS ways.
//    - For the intended configuration, NUM_WAYS is 4.
//    - The address is already decomposed into addr_tag and addr_set.
// 2. Internal storage:
//    - Each cache entry should store a valid bit.
//    - Each cache entry should store a dirty bit.
//    - Each cache entry should store a tag.
//    - Each cache entry should store one data word.
//    - Each cache entry should also maintain replacement metadata for LRU.
// 3. Reset behavior:
//    - On reset, all cache lines should become invalid.
//    - On reset, all dirty bits should be cleared.
//    - LRU metadata should be initialized to a known state.
//    - Data and tag contents do not need to be meaningful when valid is low.
// 4. Hit and miss detection:
//    - When access is high, compare addr_tag against all valid ways in addr_set.
//    - A hit occurs if any valid way in the selected set has a matching tag.
//    - A miss occurs when access is high and no matching valid way is found.
//    - When access is low, both hit and miss should be low.
// 5. Read behavior:
//    - A read access occurs when access is high and write_en is low.
//    - On a read hit, read_data should return the data from the matching way.
//    - On a read miss, the cache should select a victim way for replacement.
//    - This simplified problem does not include an external memory refill input.
// 6. Write behavior:
//    - A write access occurs when access is high and write_en is high.
//    - This cache uses write-back behavior.
//    - On a write hit, update the matching cache line with write_data.
//    - On a write hit, set the dirty bit of that cache line.
//    - A write hit should not immediately write to memory.
// 7. Write miss behavior:
//    - On a write miss, select a victim way in the selected set.
//    - Fill the victim way with the new tag and write_data.
//    - Mark the victim way valid.
//    - Set the dirty bit according to the write operation.
//    - Update replacement metadata for the filled way.
// 8. Victim selection:
//    - Prefer an invalid way in the selected set if one exists.
//    - If all ways in the selected set are valid, choose a way based on LRU.
//    - The selected victim way is used for replacement on a miss.
// 9. LRU behavior:
//    - Track relative usage order of ways within each set.
//    - After every hit, the accessed way should become the most recently used way.
//    - After every miss fill, the filled victim way should become the most recently used way.
//    - Other ways in the same set should update their LRU state consistently.
//    - LRU state in other sets should not change.
// 10. Write-back behavior:
//    - Because this is a write-back cache, modified data may exist only in cache.
//    - A dirty bit indicates that a valid cache line has been modified but not written back.
//    - On a miss, if the selected victim line is valid and dirty,
//      the cache should request a write-back.
//    - wb_req should indicate that the evicted victim line must be written back.
//    - wb_tag should report the tag of the victim line.
//    - wb_set should report the selected set.
//    - wb_data should report the data stored in the victim line.
// 11. Clean eviction behavior:
//    - If the selected victim line is invalid, no write-back is required.
//    - If the selected victim line is valid but not dirty, no write-back is required.
//    - Only valid and dirty victim lines require write-back.
// 12. Output behavior:
//    - hit and miss may be combinational outputs.
//    - read_data may reflect the data from the hit way.
//    - wb_req, wb_tag, wb_set, and wb_data may be combinational outputs based on the selected victim.
// 13. Implementation style:
//    - Use SystemVerilog.
//    - Use sequential logic for cache state updates.
//    - Use combinational logic for hit detection, victim selection, and write-back output generation.
//    - The design should be synthesizable.
// 14. Assumptions:
//    - NUM_SETS and NUM_WAYS are positive.
//    - The intended LRU ranking is for a 4-way cache.
//    - addr_set is always within the valid set range.
//    - This simplified model stores one data word per cache line.
//    - No byte enable is required.
//    - No refill data input from memory is required in this simplified version.
//    - No ready/valid handshake or multi-cycle miss handling is required.
// ============================================================

`default_nettype  none

module wb_cache #(
  parameter NUM_SETS   = 4,
  parameter NUM_WAYS   = 4,
  parameter TAG_BITS   = 4,
  parameter DATA_WIDTH = 8
)(
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic                   access,
  input  logic                   write_en,
  input  logic [TAG_BITS-1:0]   addr_tag,
  input  logic [$clog2(NUM_SETS)-1:0] addr_set,
  input  logic [DATA_WIDTH-1:0]  write_data,
  output logic [DATA_WIDTH-1:0]  read_data,
  output logic                    hit,
  output logic                    miss,
  output logic                    wb_req,
  output logic [TAG_BITS-1:0]    wb_tag,
  output logic [$clog2(NUM_SETS)-1:0] wb_set,
  output logic [DATA_WIDTH-1:0]  wb_data
);
    localparam int WAY_W = $clog2(NUM_WAYS);

    logic [WAY_W-1:0] rank [NUM_SETS][NUM_WAYS];
    logic dirty [NUM_SETS][NUM_WAYS];
    logic valid [NUM_SETS][NUM_WAYS];
    logic [DATA_WIDTH-1:0] data [NUM_SETS][NUM_WAYS];
    logic [TAG_BITS-1:0] tag [NUM_SETS][NUM_WAYS];

    logic [WAY_W-1:0] hit_way, victim_way;
    logic any_hit;

    always_comb begin
        hit_way = '0;
        any_hit = 0;
        for (int w = 0; w < NUM_WAYS; w++) begin
            if (valid[addr_set][w] && tag[addr_set][w] == addr_tag) begin
                hit_way = w[WAY_W-1:0];
                any_hit = 1;
            end
        end
    end

    logic found;
    always_comb begin
        victim_way = '0;
        found = 0;
        for (int w = 0; w < NUM_WAYS; w++) begin
            if (!found && !valid[addr_set][w]) begin
                found = 1;
                victim_way = w[WAY_W-1:0];
            end
        end
        if (!found) begin
            for (int w = 0; w < NUM_WAYS; w++) begin
                if (!found && (rank[addr_set][w] == '0)) begin
                    found = 1;
                    victim_way = w[WAY_W-1:0];
                end
            end
        end
    end

    assign read_data = data[addr_set][hit_way];
    assign hit = access && any_hit;
    assign miss = access && !hit;
    assign wb_req = miss && dirty[addr_set][victim_way] && valid[addr_set][victim_way];
    // assign wb_tag = addr_tag;
    assign wb_tag = tag[addr_set][victim_way];
    assign wb_set = addr_set;
    assign wb_data = data[addr_set][victim_way];

    logic [WAY_W-1:0] old_rank, old_way;
    assign old_way = (hit) ? hit_way : victim_way;
    assign old_rank = rank[addr_set][old_way];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SETS; s++) begin
                for (int w = 0; w < NUM_WAYS; w++) begin
                    rank[s][w] <= w[WAY_W-1:0];
                    dirty[s][w] <= 0;
                    valid[s][w] <= 0;
                    data[s][w] <= '0;
                    tag[s][w] <= '0;
                end
            end
        end else if (hit) begin
            if (write_en) begin
                dirty[addr_set][hit_way] <= 1;
                valid[addr_set][hit_way] <= 1;
                data[addr_set][hit_way] <= write_data;
            end
            for (int w = 0; w < NUM_WAYS; w++) begin
                if (rank[addr_set][w] == old_rank) begin
                    rank[addr_set][w] <= '1;
                end else if (rank[addr_set][w] > old_rank) begin
                    rank[addr_set][w] <= rank[addr_set][w]-1;
                end
            end
        end else if (miss) begin
            valid[addr_set][victim_way] <= 1;
            dirty[addr_set][victim_way] <= write_en;
            data[addr_set][victim_way] <= write_data;
            tag[addr_set][victim_way] <= addr_tag;
            for (int w = 0; w < NUM_WAYS; w++) begin
                    if (rank[addr_set][w] == old_rank) begin
                        rank[addr_set][w] <= '1;
                    end else if (rank[addr_set][w] > old_rank) begin
                        rank[addr_set][w] <= rank[addr_set][w]-1;
                    end
                end
        end
    end
endmodule

//-------------------------------------------------------------------------------------------------------------------
//sample solutoin:

// 4-way set-associative write-back cache with LRU replacement
module wb_cache #(
  parameter NUM_SETS   = 4,
  parameter NUM_WAYS   = 4,
  parameter TAG_BITS   = 4,
  parameter DATA_WIDTH = 8
)(
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic                   access,
  input  logic                   write_en,
  input  logic [TAG_BITS-1:0]   addr_tag,
  input  logic [$clog2(NUM_SETS)-1:0] addr_set,
  input  logic [DATA_WIDTH-1:0]  write_data,
  output logic [DATA_WIDTH-1:0]  read_data,
  output logic                    hit,
  output logic                    miss,
  // Writeback interface
  output logic                    wb_req,
  output logic [TAG_BITS-1:0]    wb_tag,
  output logic [$clog2(NUM_SETS)-1:0] wb_set,
  output logic [DATA_WIDTH-1:0]  wb_data
);
  logic                  valid [NUM_SETS][NUM_WAYS];
  logic                  dirty [NUM_SETS][NUM_WAYS];
  logic [TAG_BITS-1:0]   tags  [NUM_SETS][NUM_WAYS];
  logic [DATA_WIDTH-1:0] data  [NUM_SETS][NUM_WAYS];
  logic [1:0]            lru   [NUM_SETS][NUM_WAYS]; // LRU rank: 3=MRU, 0=LRU

  logic [$clog2(NUM_WAYS)-1:0] hit_way;
  logic [$clog2(NUM_WAYS)-1:0] victim_way;
  logic                         any_hit;

  // Hit detection
  always_comb begin
    any_hit  = 0;
    hit_way  = '0;
    for (int w = 0; w < NUM_WAYS; w++) begin
      if (valid[addr_set][w] && tags[addr_set][w] == addr_tag) begin
        any_hit = 1;
        hit_way = w[$clog2(NUM_WAYS)-1:0];
      end
    end
  end

  // LRU victim selection
  always_comb begin
    victim_way = '0;
    // First prefer invalid way
    for (int w = NUM_WAYS-1; w >= 0; w--) begin
      if (!valid[addr_set][w]) victim_way = w[$clog2(NUM_WAYS)-1:0];
    end
    // If all valid, pick LRU (rank == 0)
    if (&{valid[addr_set][0], valid[addr_set][1], valid[addr_set][2], valid[addr_set][3]}) begin
      for (int w = 0; w < NUM_WAYS; w++) begin
        if (lru[addr_set][w] == 2'd0) victim_way = w[$clog2(NUM_WAYS)-1:0];
      end
    end
  end

  assign hit      = access && any_hit;
  assign miss     = access && !any_hit;
  assign read_data = data[addr_set][hit_way];
  assign wb_req   = miss && valid[addr_set][victim_way] && dirty[addr_set][victim_way];
  assign wb_tag   = tags[addr_set][victim_way];
  assign wb_set   = addr_set;
  assign wb_data  = data[addr_set][victim_way];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int s = 0; s < NUM_SETS; s++) begin
        for (int w = 0; w < NUM_WAYS; w++) begin
          valid[s][w] <= 0;
          dirty[s][w] <= 0;
          lru[s][w]   <= w[1:0];
        end
      end
    end else if (access) begin
      if (any_hit) begin
        // Hit: update data on write, always update LRU
        if (write_en) begin
          data[addr_set][hit_way]  <= write_data;
          dirty[addr_set][hit_way] <= 1;
        end
        begin
          logic [1:0] old_rank;
          old_rank = lru[addr_set][hit_way];
          for (int w = 0; w < NUM_WAYS; w++) begin
            if (w[$clog2(NUM_WAYS)-1:0] == hit_way)
              lru[addr_set][w] <= 2'd3;
            else if (lru[addr_set][w] > old_rank)
              lru[addr_set][w] <= lru[addr_set][w] - 1'b1;
          end
        end
      end else begin
        // Miss: evict victim, fill new line
        valid[addr_set][victim_way] <= 1;
        dirty[addr_set][victim_way] <= write_en;
        tags[addr_set][victim_way]  <= addr_tag;
        data[addr_set][victim_way]  <= write_data;
        begin
          logic [1:0] old_rank;
          old_rank = lru[addr_set][victim_way];
          for (int w = 0; w < NUM_WAYS; w++) begin
            if (w[$clog2(NUM_WAYS)-1:0] == victim_way)
              lru[addr_set][w] <= 2'd3;
            else if (lru[addr_set][w] > old_rank)
              lru[addr_set][w] <= lru[addr_set][w] - 1'b1;
          end
        end
      end
    end
  end
endmodule