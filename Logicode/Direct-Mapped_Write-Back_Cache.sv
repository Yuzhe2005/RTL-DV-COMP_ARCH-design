// ============================================================
// Problem: Direct-Mapped Cache
// ============================================================
// Design a parameterized direct-mapped cache.
//
// The cache should contain NUM_LINES cache lines, where:
//
//   NUM_LINES = 2 ** INDEX_BITS
//
// Each cache line stores:
//   - one DATA_WIDTH-bit data word;
//   - one tag;
//   - one valid bit;
//   - one dirty bit.
//
// This is a simple direct-mapped, write-back, write-allocate cache.
//
// Module interface:
// module direct_mapped_cache #(
//   parameter ADDR_WIDTH = 8,
//   parameter DATA_WIDTH = 32,
//   parameter INDEX_BITS = 3
// )(
//   input  logic                    clk,
//   input  logic                    rst_n,
//
//   input  logic [ADDR_WIDTH-1:0]   cpu_addr,
//   input  logic [DATA_WIDTH-1:0]   cpu_wdata,
//   input  logic                    cpu_we,
//   input  logic                    cpu_re,
//   output logic [DATA_WIDTH-1:0]   cpu_rdata,
//   output logic                    cpu_stall,
//
//   output logic [ADDR_WIDTH-1:0]   mem_addr,
//   output logic [DATA_WIDTH-1:0]   mem_wdata,
//   output logic                    mem_we,
//   output logic                    mem_re,
//   input  logic [DATA_WIDTH-1:0]   mem_rdata,
//   input  logic                    mem_ack
// );
//
// Requirements:
// 1. The module should implement a direct-mapped cache with:
//    - NUM_LINES = 2 ** INDEX_BITS cache lines;
//    - one DATA_WIDTH-bit word per cache line;
//    - one tag per cache line;
//    - one valid bit per cache line;
//    - one dirty bit per cache line.
//
// 2. Address decomposition:
//    - The lower INDEX_BITS bits of cpu_addr select the cache index.
//    - The upper ADDR_WIDTH - INDEX_BITS bits form the tag.
//    - For a CPU address:
//
//        cur_index = cpu_addr[INDEX_BITS-1:0]
//        cur_tag   = cpu_addr[ADDR_WIDTH-1:INDEX_BITS]
//
//    - This simplified cache has no byte offset or block offset.
//    - Each cache line stores exactly one DATA_WIDTH-bit word.
//
// 3. Hit detection:
//    - A CPU access is a hit when:
//        - the selected cache line is valid;
//        - the stored tag matches the address tag.
//
//    - In logic:
//
//        hit = valid_mem[cur_index] && (tag_mem[cur_index] == cur_tag)
//
// 4. CPU read hit behavior:
//    - If cpu_re is asserted and the access hits:
//        - cpu_rdata should return data_mem[cur_index];
//        - cpu_stall should be 0;
//        - cache contents should not be modified.
//
// 5. CPU write hit behavior:
//    - If cpu_we is asserted and the access hits:
//        - data_mem[cur_index] should be updated with cpu_wdata on the rising
//          edge of clk;
//        - dirty_mem[cur_index] should be set to 1;
//        - cpu_stall should be 0.
//    - This is a write-back cache, so memory is not updated immediately on a
//      write hit.
//
// 6. CPU miss behavior:
//    - If cpu_re or cpu_we is asserted and the access misses:
//        - cpu_stall should be asserted;
//        - the miss address should be saved internally;
//        - for a write miss, cpu_wdata should also be saved internally;
//        - the cache should begin miss handling.
//
// 7. Dirty eviction behavior:
//    - On a miss, if the cache line selected by the miss index is both:
//        - valid;
//        - dirty;
//      then the old cache line must be written back to memory before the new
//      line is filled.
//
//    - During writeback:
//        - mem_we should be asserted;
//        - mem_addr should be the address reconstructed from the old tag and
//          the miss index;
//        - mem_wdata should be the old cached data;
//        - cpu_stall should remain asserted.
//
//    - The cache should remain in WRITEBACK state until mem_ack is asserted.
//
// 8. Clean miss behavior:
//    - On a miss, if the selected line is invalid or clean:
//        - no writeback is needed;
//        - the cache should go directly to the FILL state.
//
// 9. Fill behavior:
//    - During FILL state:
//        - mem_re should be asserted;
//        - mem_addr should be the saved miss address;
//        - cpu_stall should remain asserted.
//    - The cache should remain in FILL state until mem_ack is asserted.
//
// 10. Fill completion behavior:
//    - When mem_ack is asserted in FILL state:
//        - the selected cache line should be updated;
//        - tag_mem should be updated with the tag of the miss address;
//        - valid_mem should be set to 1.
//
//    - For a read miss:
//        - data_mem should be filled with mem_rdata;
//        - dirty_mem should be cleared to 0.
//
//    - For a write miss:
//        - data_mem should be filled with the saved cpu_wdata;
//        - dirty_mem should be set to 1.
//
//    - This implements write-allocate behavior.
//
// 11. Write-back policy:
//    - Write hits update only the cache line and set the dirty bit.
//    - Dirty lines are written back to memory only when they are evicted.
//    - Clean lines do not need to be written back before replacement.
//
// 12. Write-allocate policy:
//    - On a write miss, the cache allocates the missed line.
//    - After the fill completes, the cache line should contain the CPU write
//      data rather than mem_rdata.
//    - The new line should be marked dirty.
//
// 13. FSM behavior:
//    - The cache should use an FSM with at least three states:
//        - IDLE:
//            Handles CPU requests and detects hits/misses.
//        - WRITEBACK:
//            Writes a dirty victim line back to memory.
//        - FILL:
//            Reads the missed line from memory and installs the new cache line.
//
//    - State transitions:
//        - IDLE -> WRITEBACK on miss with valid dirty victim.
//        - IDLE -> FILL on miss with invalid or clean victim.
//        - WRITEBACK -> FILL when mem_ack is asserted.
//        - FILL -> IDLE when mem_ack is asserted.
//
// 14. CPU stall behavior:
//    - cpu_stall should be 0 during IDLE when there is no miss.
//    - cpu_stall should be 0 on cache hits.
//    - cpu_stall should be 1:
//        - on a miss detected in IDLE;
//        - during WRITEBACK;
//        - during FILL.
//
// 15. Memory interface behavior:
//    - mem_we should be asserted only during WRITEBACK.
//    - mem_re should be asserted only during FILL.
//    - mem_addr should be:
//        - the victim line address during WRITEBACK;
//        - the saved miss address during FILL.
//    - mem_wdata should be the victim cache line data during WRITEBACK.
//    - The cache should wait for mem_ack before leaving WRITEBACK or FILL.
//
// 16. Request capture behavior:
//    - On a miss, the module should save:
//        - cpu_addr into an internal miss address register;
//        - cpu_we into an internal miss write-enable register;
//        - cpu_wdata into an internal miss write-data register.
//    - These saved values should be used throughout miss handling.
//
// 17. Reset behavior:
//    - Reset is synchronous active-low.
//    - On posedge clk, if rst_n is 0:
//        - state should return to IDLE;
//        - miss-tracking registers should be cleared;
//        - all valid bits should be cleared;
//        - all dirty bits should be cleared.
//    - Data and tag arrays do not strictly need to be cleared if valid bits are
//      cleared, but clearing them is also acceptable.
//
// 18. Implementation style:
//    - Use SystemVerilog.
//    - Use unpacked arrays or equivalent arrays for data, tag, valid, and dirty
//      cache storage.
//    - Use always_comb for combinational outputs and hit-related logic.
//    - Use always_ff for FSM state updates and cache array updates.
//    - Use nonblocking assignments in sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 19. Assumptions:
//    - Each cache line stores exactly one word.
//    - There is no byte-enable support.
//    - There is no burst memory support.
//    - The CPU should hold or retry its request while cpu_stall is asserted.
//    - cpu_re and cpu_we are not expected to both be asserted for different
//      operations at the same time.
//    - mem_ack indicates completion of the current memory transaction.
// ============================================================

`default_nettype none

module direct_mapped_cache #(
  parameter ADDR_WIDTH = 8,
  parameter DATA_WIDTH = 32,
  parameter INDEX_BITS = 3
)(
  input  logic                    clk,
  input  logic                    rst_n,

  input  logic [ADDR_WIDTH-1:0]   cpu_addr,
  input  logic [DATA_WIDTH-1:0]   cpu_wdata,
  input  logic                    cpu_we,
  input  logic                    cpu_re,
  output logic [DATA_WIDTH-1:0]   cpu_rdata,
  output logic                    cpu_stall,

  output logic [ADDR_WIDTH-1:0]   mem_addr,
  output logic [DATA_WIDTH-1:0]   mem_wdata,
  output logic                    mem_we,
  output logic                    mem_re,
  input  logic [DATA_WIDTH-1:0]   mem_rdata,
  input  logic                    mem_ack
);
    localparam int NUM_LINES = 2**INDEX_BITS;
    localparam int TAG_BITS = ADDR_WIDTH-INDEX_BITS;

    typedef enum logic [1:0] {IDLE, WRITEBACK, FILL} state_t;
    state_t state;

    logic [DATA_WIDTH-1:0] data_mem [NUM_LINES];
    logic [TAG_BITS-1:0] tag_mem [NUM_LINES];
    logic valid_mem [NUM_LINES];
    logic dirty_mem [NUM_LINES];

    logic [ADDR_WIDTH-1:0] miss_addr_r;
    logic miss_we_r;
    logic [DATA_WIDTH-1:0] miss_wdata_r;

    logic [INDEX_BITS-1:0] cur_index;
    logic [TAG_BITS-1:0] cur_tag;
    logic [INDEX_BITS-1:0] miss_index;
    logic hit;

    assign cur_index = cpu_addr[INDEX_BITS-1:0];
    assign cur_tag = cpu_addr[ADDR_WIDTH-1:INDEX_BITS];
    assign miss_index = miss_addr_r[INDEX_BITS-1:0];
    assign hit = valid_mem[cur_index] & (tag_mem[cur_index] == cur_tag);

    always_comb begin
        cpu_rdata = '0;
        cpu_stall = 1'b0;
        mem_we = 1'b0;
        mem_re = 1'b0;
        mem_addr = '0;
        mem_wdata = '0;

        case (state)
            IDLE: begin
                if (cpu_re | cpu_we) begin
                    if (hit) begin
                        cpu_rdata = data_mem[cur_index];
                    end else begin
                        cpu_stall = 1'b1;
                    end
                end
            end

            WRITEBACK: begin
                cpu_stall = 1'b1;
                mem_we = 1'b1;
                mem_addr = {tag_mem[miss_index], miss_index};
                mem_wdata = data_mem[miss_index];
            end

            FILL: begin
                cpu_stall = 1'b1;
                mem_re = 1'b1;
                mem_addr = miss_addr_r;
            end

            default;
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            miss_addr_r <= '0;
            miss_we_r <= 1'b0;
            miss_wdata_r <= '0;
            for (int i = 0; i < NUM_LINES; i++) begin
                valid_mem[i] <= 1'b0;
                dirty_mem[i] <= 1'b0;
            end 
        end else begin
            case (state)
                IDLE: begin
                    if (cpu_re | cpu_we) begin
                        if (!hit) begin
                            miss_addr_r <= cpu_addr;
                            miss_we_r <= cpu_we;
                            miss_wdata_r <= cpu_wdata;
                            if (valid_mem[cur_index] & dirty_mem[cur_index])
                                state <= WRITEBACK;
                            else
                                state <= FILL;
                        end else if (cpu_we) begin
                            data_mem[cur_index] <= cpu_wdata;
                            dirty_mem[cur_index] <= 1'b1;
                        end
                    end
                end

                WRITEBACK: begin
                    if (mem_ack)
                        state <= FILL;
                end

                FILL: begin
                    if (mem_ack) begin
                        data_mem[miss_index] <= miss_we_r ? miss_wdata_r : mem_rdata;
                        tag_mem[miss_index] <= miss_addr_r[ADDR_WIDTH-1:INDEX_BITS];
                        valid_mem[miss_index] <= 1'b1;
                        dirty_mem[miss_index] <= miss_we_r;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end     
endmodule