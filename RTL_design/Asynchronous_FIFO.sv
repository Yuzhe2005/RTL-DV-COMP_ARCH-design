// ============================================================
// Problem: Asynchronous FIFO
// ============================================================
// Design a parameterized asynchronous FIFO with separate write
// and read clock domains.
// Module interface:
// module async_fifo #(
//   parameter DEPTH = 8,
//   parameter WIDTH = 8
// )(
//   // Write domain
//   input  logic              write_clk,
//   input  logic              write_rst_n,
//   input  logic              write_en,
//   input  logic [WIDTH-1:0]  write_data,
//   output logic              full,
//   // Read domain
//   input  logic              read_clk,
//   input  logic              read_rst_n,
//   input  logic              read_en,
//   output logic [WIDTH-1:0]  read_data,
//   output logic              empty
// );
// Requirements:
// 1. This is an asynchronous FIFO.
//    - The write side uses write_clk.
//    - The read side uses read_clk.
//    - write_clk and read_clk are independent clock domains.
//    - write_rst_n is the active-low asynchronous reset for the write domain.
//    - read_rst_n is the active-low asynchronous reset for the read domain.
// 2. FIFO storage:
//    - The FIFO stores DEPTH entries.
//    - Each entry has WIDTH bits.
//    - Use an internal memory array:
//        logic [WIDTH-1:0] mem [DEPTH];
//    - Memory contents do not need to be reset.
// 3. Pointer width:
//    - Use binary pointers with one extra bit for full/empty detection.
//    - Pointer width should be:
//        localparam PTR_W = $clog2(DEPTH) + 1;
//    - The lower $clog2(DEPTH) bits are used to index memory.
//    - The full PTR_W-bit pointer is used for full and empty detection.
// 4. Binary and Gray pointers:
//    - Maintain a binary write pointer: wr_ptr_bin.
//    - Maintain a Gray-code write pointer: wr_ptr_gray.
//    - Maintain a binary read pointer: rd_ptr_bin.
//    - Maintain a Gray-code read pointer: rd_ptr_gray.
//    - Convert binary to Gray code using:
//        gray = (binary >> 1) ^ binary
//    - Implement the conversion using a function.
// 5. Clock domain crossing:
//    - Do not directly synchronize binary pointers across clock domains.
//    - Synchronize Gray-code pointers across clock domains.
//    - Use Gray code because only one bit changes between consecutive values.
//    - Use 2-flop synchronizers for pointer synchronization.
// 6. Write behavior:
//    - On each rising edge of write_clk, if write_en is high and FIFO is not full,
//      write write_data into the FIFO.
//    - The data should be written at the current write pointer location.
//    - The write address should use the lower $clog2(DEPTH) bits of wr_ptr_bin.
//    - After a successful write, increment wr_ptr_bin by 1.
//    - If FIFO is full, ignore the write request.
// 7. Read behavior:
//    - On each rising edge of read_clk, if read_en is high and FIFO is not empty,
//      read one entry from the FIFO into read_data.
//    - The read address should use the lower $clog2(DEPTH) bits of rd_ptr_bin.
//    - After a successful read, increment rd_ptr_bin by 1.
//    - If FIFO is empty, ignore the read request.
//    - read_data should be a registered output in the read clock domain.
// 8. Synchronize read pointer into write domain:
//    - The read Gray pointer should be synchronized into the write clock domain.
//    - Use two registers: rd_gray_sync1 and rd_gray_sync2.
//    - On each rising edge of write_clk:
//        rd_gray_sync1 <= rd_ptr_gray;
//        rd_gray_sync2 <= rd_gray_sync1;
//    - On write reset, both synchronizer registers should reset to 0.
// 9. Synchronize write pointer into read domain:
//    - The write Gray pointer should be synchronized into the read clock domain.
//    - Use two registers: wr_gray_sync1 and wr_gray_sync2.
//    - On each rising edge of read_clk:
//        wr_gray_sync1 <= wr_ptr_gray;
//        wr_gray_sync2 <= wr_gray_sync1;
//    - On read reset, both synchronizer registers should reset to 0.
// 10. Full flag:
//    - full should be generated in the write clock domain.
//    - FIFO is full when the current write Gray pointer equals the synchronized
//      read Gray pointer with the top two bits inverted.
//    - Full condition:
//        full = wr_ptr_gray == {
//                 ~rd_gray_sync2[PTR_W-1:PTR_W-2],
//                  rd_gray_sync2[PTR_W-3:0]
//               };
// 11. Empty flag:
//    - empty should be generated in the read clock domain.
//    - FIFO is empty when the current read Gray pointer equals the synchronized
//      write Gray pointer.
//    - Empty condition:
//        empty = rd_ptr_gray == wr_gray_sync2;
// 12. Reset behavior:
//    - When write_rst_n is low:
//        wr_ptr_bin should reset to 0.
//        rd_gray_sync1 should reset to 0.
//        rd_gray_sync2 should reset to 0.
//    - When read_rst_n is low:
//        rd_ptr_bin should reset to 0.
//        wr_gray_sync1 should reset to 0.
//        wr_gray_sync2 should reset to 0.
//        read_data should reset to 0.
//    - Memory contents do not need to be reset.
// 13. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use assign statements for combinational logic.
//    - Implement binary-to-Gray conversion using a function.
//    - Do not use an occupancy counter.
//    - Do not directly synchronize binary pointers across clock domains.
//    - The design should be synthesizable.
// 14. Assumptions:
//    - DEPTH is a power of 2.
//    - The internal memory supports one write port in the write clock domain
//      and one read port in the read clock domain.
//    - This problem only requires full and empty flags.
//    - almost_full and almost_empty are not required.
// ============================================================

`default_nettype none

module async_fifo #(
  parameter DEPTH = 8,
  parameter WIDTH = 8
)(
  input  logic              write_clk,
  input  logic              write_rst_n,
  input  logic              write_en,
  input  logic [WIDTH-1:0]  write_data,
  output logic              full,
  input  logic              read_clk,
  input  logic              read_rst_n,
  input  logic              read_en,
  output logic [WIDTH-1:0]  read_data,
  output logic              empty
);

  localparam int PTR_W = $clog2(DEPTH);

  logic [PTR_W:0] read_bin, read_gray, read_gray_sync1, read_gray_sync2;
  logic [PTR_W:0] write_bin, write_gray, write_gray_sync1, write_gray_sync2;
  logic [WIDTH-1:0] mem [DEPTH];

  logic write_able, read_able;
  
  assign full = (write_gray == {~read_gray_sync2[PTR_W:PTR_W-1],
                                     read_gray_sync2[PTR_W-2:0]});
  assign empty = (read_gray == write_gray_sync2);

  assign write_able = write_en && (!full);
  assign read_able = read_en && (!empty);

  logic [PTR_W-1:0] write_idx, read_idx;
  assign write_idx = write_bin[PTR_W-1:0];
  assign read_idx = read_bin[PTR_W-1:0];

  always_comb begin
    read_gray = read_bin ^ (read_bin >> 1);
    write_gray = write_bin ^ (write_bin >> 1);
  end


  always_ff @(posedge write_clk or negedge write_rst_n) begin
    if (!write_rst_n) begin
      write_bin <= '0;
      read_gray_sync1 <= '0;
      read_gray_sync2 <= '0;
    end else begin
      if (write_able) begin
        mem[write_idx] <= write_data;
        write_bin <= write_bin+1;
      end
      read_gray_sync1 <= read_gray;
      read_gray_sync2 <= read_gray_sync1;
    end
  end

  always_ff @(posedge read_clk or negedge read_rst_n) begin
    if (!read_rst_n) begin
      read_bin <= '0;
      write_gray_sync1 <= '0;
      write_gray_sync2 <= '0;
      read_data <= '0;
    end else begin
      if (read_able) begin
        read_data <= mem[read_idx];
        read_bin <= read_bin+1;
      end
      write_gray_sync1 <= write_gray;
      write_gray_sync2 <= write_gray_sync1;
    end
  end
endmodule