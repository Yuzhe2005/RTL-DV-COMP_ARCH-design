// ============================================================
// Problem: Synchronous FIFO
// ============================================================
//
// Design a parameterized synchronous FIFO with the following
// interface:
//
// module sync_fifo #(
//   parameter DEPTH               = 8,
//   parameter WIDTH               = 8,
//   parameter ALMOST_FULL_THRESH  = DEPTH - 1,
//   parameter ALMOST_EMPTY_THRESH = 1
// )(
//   input  logic              clk,
//   input  logic              rst_n,
//   input  logic              write_en,
//   input  logic [WIDTH-1:0]  write_data,
//   input  logic              read_en,
//   output logic [WIDTH-1:0]  read_data,
//   output logic              full,
//   output logic              empty,
//   output logic              almost_full,
//   output logic              almost_empty
// );
//
// Requirements:
//
// 1. This is a single-clock synchronous FIFO.
//    - Both read and write operations are controlled by the same clk.
//    - Reset is active-low asynchronous reset: rst_n.
//
// 2. FIFO storage:
//    - The FIFO stores DEPTH entries.
//    - Each entry has WIDTH bits.
//    - Use an internal memory array:
//
//        logic [WIDTH-1:0] mem [DEPTH];
//
// 3. Write behavior:
//    - On each rising edge of clk, if write_en is high and FIFO is not full,
//      write write_data into the FIFO.
//    - The data should be written at the current write pointer location.
//    - After a successful write, increment the write pointer by 1.
//    - If FIFO is full, ignore the write request.
//
// 4. Read behavior:
//    - The FIFO uses combinational read.
//    - read_data should always reflect the memory entry pointed to by
//      the current read pointer.
//    - On each rising edge of clk, if read_en is high and FIFO is not empty,
//      consume one entry from the FIFO by incrementing the read pointer by 1.
//    - If FIFO is empty, ignore the read request.
//
// 5. Occupancy counter:
//    - Maintain an internal count register to track how many valid entries
//      are currently stored in the FIFO.
//    - count should range from 0 to DEPTH.
//    - On reset, count should become 0.
//    - If there is a valid write only, increment count.
//    - If there is a valid read only, decrement count.
//    - If there is both a valid read and a valid write in the same cycle,
//      count should remain unchanged.
//
// 6. Status flags:
//    - full should be high when count == DEPTH.
//    - empty should be high when count == 0.
//    - almost_full should be high when count >= ALMOST_FULL_THRESH.
//    - almost_empty should be high when count <= ALMOST_EMPTY_THRESH.
//
// 7. Reset behavior:
//    - When rst_n is low:
//        write pointer should reset to 0.
//        read pointer should reset to 0.
//        count should reset to 0.
//    - Memory contents do not need to be reset.
//
// 8. Pointer width:
//    - Use $clog2(DEPTH) to calculate the read/write pointer width.
//    - For this version, you may assume DEPTH is a power of 2.
//
// 9. Simultaneous read and write behavior:
//    - If FIFO is neither full nor empty, simultaneous read and write are both allowed.
//      In this case:
//        write pointer increments.
//        read pointer increments.
//        count does not change.
//    - If FIFO is full and both write_en and read_en are high:
//        read is allowed.
//        write is blocked.
//        count decreases by 1.
//    - If FIFO is empty and both write_en and read_en are high:
//        write is allowed.
//        read is blocked.
//        count increases by 1.
//
// 10. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use assign statements for combinational status flags.
//    - The design should be synthesizable.
//
// ============================================================

`default_nettype none

module sync_fifo #(
  parameter DEPTH               = 8,
  parameter WIDTH               = 8,
  parameter ALMOST_FULL_THRESH  = DEPTH - 1,
  parameter ALMOST_EMPTY_THRESH = 1
)(
  input  logic              clk,
  input  logic              rst_n,
  input  logic              write_en,
  input  logic [WIDTH-1:0]  write_data,
  input  logic              read_en,
  output logic [WIDTH-1:0]  read_data,
  output logic              full,
  output logic              empty,
  output logic              almost_full,
  output logic              almost_empty
);
    localparam int PTR_LEN = $clog2(DEPTH);
    logic [PTR_LEN-1:0] write_ptr, read_ptr;
    logic [PTR_LEN:0] count;
    
    logic [WIDTH-1:0] mem [DEPTH-1:0];

    assign almost_full = (count >= ALMOST_FULL_THRESH);
    assign almost_empty = (count <= ALMOST_EMPTY_THRESH);
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    assign read_data = mem[read_ptr];
    
    logic write_able, read_able;
    assign write_able = write_en && (!full);
    assign read_able = read_en && (!empty);

    logic [PTR_LEN:0] count_d;
    always_comb begin
        count_d = count;
        if (write_able) count_d++;
        if (read_able) count_d--;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            write_ptr <= '0;
            read_ptr <= '0;
            for (int i = 0; i < DEPTH; i++) begin
                mem[i] <= '0;
            end
        end else begin
            count <= count_d;
            if (write_able) begin
                write_ptr <= (write_ptr ==  DEPTH-1) ? 0 : write_ptr+1;
                // write_ptr <= (write_ptr ==  DEPTH) ? 0 : write_ptr+1;
                mem[write_ptr] <= write_data;
            end
            if (read_able) begin
                read_ptr <= (read_ptr == DEPTH-1) ? 0 : read_ptr+1;
                // read_ptr <= (read_ptr == DEPTH) ? 0 : read_ptr+1;
            end
        end
    end
endmodule

