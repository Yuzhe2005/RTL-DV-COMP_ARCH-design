// ============================================================
// Problem: Direct-Mapped Write-Through Cache with Write-Allocate
// ============================================================
// Design a parameterized direct-mapped cache.
// Module interface:
// module direct_mapped_cache #(
//   parameter ADDR_WIDTH  = 8,
//   parameter DATA_WIDTH  = 8,
//   parameter NUM_LINES   = 4,
//   parameter OFFSET_BITS = 0
// )(
//   input  logic                    clk,
//   input  logic                    rst_n,
//   input  logic                    access,
//   input  logic                    write_en,
//   input  logic [ADDR_WIDTH-1:0]  address,
//   input  logic [DATA_WIDTH-1:0]  write_data,
//   input  logic [DATA_WIDTH-1:0]  mem_read_data,
//   output logic [ADDR_WIDTH-1:0]  mem_address,
//   output logic [DATA_WIDTH-1:0]  mem_write_data,
//   output logic                    mem_write_en,
//   output logic                    mem_read_req,
//   output logic [DATA_WIDTH-1:0]  read_data,
//   output logic                    hit,
//   output logic                    miss
// );
// Requirements:
// 1. This is a direct-mapped cache.
//    - Each address maps to exactly one cache line.
//    - The number of cache lines is controlled by NUM_LINES.
//    - Each cache line stores one data word in this simplified version.
//    - No LRU or replacement policy is required.
// 2. Parameters:
//    - ADDR_WIDTH controls the width of the CPU address.
//    - DATA_WIDTH controls the width of each data word.
//    - NUM_LINES controls the number of cache lines.
//    - OFFSET_BITS represents block offset bits.
//    - For this problem, OFFSET_BITS may be 0 for single-word cache lines.
// 3. Internal storage:
//    - Store a valid bit for each cache line.
//    - Store a tag for each cache line.
//    - Store one data word for each cache line.
//    - On reset, all cache lines should become invalid.
// 4. Address handling:
//    - Decompose the input address into tag and index fields.
//    - The index selects which cache line to access.
//    - The tag is compared against the stored tag of the selected line.
// 5. Hit and miss behavior:
//    - A hit occurs when access is high, the selected cache line is valid,
//      and the stored tag matches the address tag.
//    - A miss occurs when access is high and the access is not a hit.
//    - When access is low, both hit and miss should be low.
// 6. Read behavior:
//    - When access is high and write_en is low, the operation is a read.
//    - On a read hit, read_data should return the cached data from the selected line.
//    - On a read miss, the cache should request data from memory.
//    - This simplified problem assumes mem_read_data is available for filling the cache.
//    - On a read miss, update the selected cache line with the memory data,
//      update its tag, and mark the line valid.
// 7. Write behavior:
//    - When access is high and write_en is high, the operation is a write.
//    - This cache uses write-through behavior.
//    - Every valid CPU write should also write the data to main memory.
//    - mem_write_en should indicate a memory write.
//    - mem_write_data should carry the CPU write data.
//    - mem_address should carry the CPU address.
// 8. Write hit behavior:
//    - On a write hit, update the selected cache line with write_data.
//    - Because the cache is write-through, also write the same data to memory.
// 9. Write miss behavior:
//    - This cache uses write-allocate behavior.
//    - On a write miss, allocate the selected cache line.
//    - Update the valid bit, tag, and cached data for that line.
//    - The cached data after allocation should be the CPU write data.
//    - The write should also be sent to memory because the cache is write-through.
// 10. Memory interface behavior:
//    - mem_address should correspond to the current CPU address.
//    - mem_write_data should correspond to the current CPU write data.
//    - mem_write_en should assert for valid write accesses.
//    - mem_read_req should assert for read misses.
// 11. Output behavior:
//    - read_data should reflect the data stored in the indexed cache line.
//    - hit and miss may be combinational outputs.
//    - Memory request signals may be combinational outputs.
// 12. Implementation style:
//    - Use SystemVerilog.
//    - Use sequential logic for cache state updates.
//    - Use combinational logic for hit/miss detection and memory interface outputs.
//    - The design should be synthesizable.
// 13. Assumptions:
//    - ADDR_WIDTH, DATA_WIDTH, and NUM_LINES are positive.
//    - NUM_LINES is compatible with $clog2(NUM_LINES).
//    - The address is always within the supported address range.
//    - No dirty bit is needed because this is a write-through cache.
//    - No byte enable is required.
//    - No multi-word cache line refill is required.
// ============================================================

`default_nettype none

module direct_mapped_cache #(
  parameter ADDR_WIDTH  = 8,
  parameter DATA_WIDTH  = 8,
  parameter NUM_LINES   = 4,
  parameter OFFSET_BITS = 0
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    access,
  input  logic                    write_en,
  input  logic [ADDR_WIDTH-1:0]  address,
  input  logic [DATA_WIDTH-1:0]  write_data,
  input  logic [DATA_WIDTH-1:0]  mem_read_data,
  output logic [ADDR_WIDTH-1:0]  mem_address,
  output logic [DATA_WIDTH-1:0]  mem_write_data,
  output logic                    mem_write_en,
  output logic                    mem_read_req,
  output logic [DATA_WIDTH-1:0]  read_data,
  output logic                    hit,
  output logic                    miss
);
    localparam int IDX_W = $clog2(NUM_LINES);
    localparam int TAG_W = ADDR_WIDTH - IDX_W - OFFSET_BITS;

    logic [DATA_WIDTH-1:0] data [NUM_LINES];
    logic [TAG_W-1:0] tag [NUM_LINES];
    logic valid [NUM_LINES];

    logic [TAG_W-1:0] addr_tag;
    logic [IDX_W-1:0] addr_idx;

    assign addr_tag = address[ADDR_WIDTH-1:ADDR_WIDTH-TAG_W];
    assign addr_idx = address[OFFSET_BITS+IDX_W-1:OFFSET_BITS];
    // assign addr_idx = address[IDX_W-1:0];

    assign hit = (addr_tag == tag[addr_idx]) && (valid[addr_idx]) && access;
    // assign miss = !hit;
    assign miss = access && (!hit);

    assign mem_address = address;
    assign mem_write_data = write_data;
    // assign mem_write_en = miss && write_en;
    assign mem_write_en = access && write_en;
    assign mem_read_req = miss && !write_en;
    assign read_data = data[addr_idx];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_LINES; i++) begin
                data[i] <= '0;
                tag[i] <= '0;
                valid[i] <= 0;
            end
        // end else begin
        end else if (access) begin
            if (write_en && miss) begin
                tag[addr_idx] <= addr_tag;
                valid[addr_idx] <= 1;
                data[addr_idx] <= write_data;
            end else if (write_en && hit) begin
                data[addr_idx] <= write_data;
            end else if (!write_en && miss) begin
                tag[addr_idx] <= addr_tag;
                valid[addr_idx] <= 1;
                data[addr_idx] <= mem_read_data;
            end
        end
    end
endmodule

//------------------------------------------------------------------------------
// sample solution:
// Direct-mapped write-through cache with write-allocate
module direct_mapped_cache #(
  parameter ADDR_WIDTH  = 8,
  parameter DATA_WIDTH  = 8,
  parameter NUM_LINES   = 4,    // Number of cache lines
  parameter OFFSET_BITS = 0     // Words per line = 1 (single-word lines)
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    access,
  input  logic                    write_en,
  input  logic [ADDR_WIDTH-1:0]  address,
  input  logic [DATA_WIDTH-1:0]  write_data,
  // Simulated memory interface
  input  logic [DATA_WIDTH-1:0]  mem_read_data,   // Data from main memory
  output logic [ADDR_WIDTH-1:0]  mem_address,
  output logic [DATA_WIDTH-1:0]  mem_write_data,
  output logic                    mem_write_en,
  output logic                    mem_read_req,
  // Cache status
  output logic [DATA_WIDTH-1:0]  read_data,
  output logic                    hit,
  output logic                    miss
);
  localparam INDEX_BITS = $clog2(NUM_LINES);
  localparam TAG_BITS   = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

  logic                  valid     [NUM_LINES];
  logic [TAG_BITS-1:0]   tag_array [NUM_LINES];
  logic [DATA_WIDTH-1:0] data_array[NUM_LINES];

  // Address decomposition
  logic [TAG_BITS-1:0]   addr_tag;
  logic [INDEX_BITS-1:0] addr_idx;

  assign addr_tag = address[ADDR_WIDTH-1 : ADDR_WIDTH-TAG_BITS];
  assign addr_idx = address[INDEX_BITS-1 : 0];

  // Hit detection (combinational)
  assign hit  = access && valid[addr_idx] && (tag_array[addr_idx] == addr_tag);
  assign miss = access && !hit;

  // Read data
  assign read_data = data_array[addr_idx];

  // Memory interface
  assign mem_address    = address;
  assign mem_write_data = write_data;
  assign mem_write_en   = access && write_en;   // Write-through: always write to memory
  assign mem_read_req   = miss && !write_en;    // Fetch on read miss

  // Cache update
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < NUM_LINES; i++) begin
        valid[i] <= 0;
      end
    end else if (access) begin
      if (hit && write_en) begin
        // Write hit — update cache (write-through also writes to memory)
        data_array[addr_idx] <= write_data;
      end else if (miss && !write_en) begin
        // Read miss — fill from memory
        valid[addr_idx]      <= 1;
        tag_array[addr_idx]  <= addr_tag;
        data_array[addr_idx] <= mem_read_data;
      end else if (miss && write_en) begin
        // Write miss — write-allocate: fill then update
        valid[addr_idx]      <= 1;
        tag_array[addr_idx]  <= addr_tag;
        data_array[addr_idx] <= write_data;
      end
    end
  end
endmodule