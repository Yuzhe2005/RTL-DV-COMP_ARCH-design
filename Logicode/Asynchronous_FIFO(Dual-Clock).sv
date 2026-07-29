// ============================================================
// Problem: Asynchronous FIFO
// ============================================================
// Design a parameterized asynchronous FIFO.
//
// The FIFO has separate write and read clock domains:
//   - wr_clk controls writes;
//   - rd_clk controls reads.
//
// The design should safely pass status information between clock domains
// using Gray-coded pointers and 2-flop synchronizers.
//
// Module interface:
// module async_fifo #(
//   parameter DATA_WIDTH = 8,
//   parameter DEPTH      = 16
// )(
//   input  logic                  wr_clk,
//   input  logic                  wr_rst_n,
//   input  logic                  wr_en,
//   input  logic [DATA_WIDTH-1:0] wr_data,
//   output logic                  wr_full,
//
//   input  logic                  rd_clk,
//   input  logic                  rd_rst_n,
//   input  logic                  rd_en,
//   output logic [DATA_WIDTH-1:0] rd_data,
//   output logic                  rd_empty
// );
//
// Requirements:
// 1. The module should implement an asynchronous FIFO with:
//    - DATA_WIDTH-bit data entries;
//    - DEPTH total entries;
//    - independent write clock wr_clk;
//    - independent read clock rd_clk;
//    - full flag in the write clock domain;
//    - empty flag in the read clock domain.
//
// 2. FIFO storage behavior:
//    - Use an internal memory array with DEPTH entries.
//    - Each entry should be DATA_WIDTH bits wide.
//    - Writes occur in the write clock domain.
//    - Reads occur in the read clock domain.
//    - The memory index should come from the lower address bits of the binary
//      write/read pointers.
//
// 3. Pointer width behavior:
//    - Use binary read and write pointers with one extra bit beyond the memory
//      address width.
//    - Pointer width should be:
//
//        PTR_WIDTH = $clog2(DEPTH) + 1
//
//    - The extra pointer bit is used to distinguish full from empty.
//
// 4. Write pointer behavior:
//    - wr_ptr_bin tracks the next write location.
//    - When wr_en is asserted and wr_full is 0:
//        - wr_data should be written into memory at wr_ptr_bin index;
//        - wr_ptr_bin should increment by 1;
//        - wr_ptr_gray should update to the Gray code of the new write pointer.
//    - When no write occurs, wr_ptr_bin should hold its value.
//
// 5. Read pointer behavior:
//    - rd_ptr_bin tracks the next read location.
//    - When rd_en is asserted and rd_empty is 0:
//        - rd_data should capture the memory value at rd_ptr_bin index;
//        - rd_ptr_bin should increment by 1;
//        - rd_ptr_gray should update to the Gray code of the new read pointer.
//    - When no read occurs, rd_ptr_bin should hold its value.
//
// 6. Gray code pointer behavior:
//    - Binary pointers should be converted to Gray code before crossing clock
//      domains.
//    - Gray code conversion should use:
//
//        gray = binary ^ (binary >> 1)
//
//    - Gray code is used because only one bit changes between adjacent pointer
//      values, reducing clock-domain crossing risk.
//
// 7. Read pointer synchronization into write domain:
//    - rd_ptr_gray should be synchronized into the write clock domain using
//      two flip-flops.
//    - The synchronized read pointer is used to compute wr_full.
//    - The synchronizer should be clocked by wr_clk.
//
// 8. Write pointer synchronization into read domain:
//    - wr_ptr_gray should be synchronized into the read clock domain using
//      two flip-flops.
//    - The synchronized write pointer is used to compute rd_empty.
//    - The synchronizer should be clocked by rd_clk.
//
// 9. Full flag behavior:
//    - wr_full should be generated in the write clock domain.
//    - The FIFO is full when the next write pointer would catch up to the
//      synchronized read pointer with the upper pointer bits inverted.
//    - Conceptually, full means:
//        - the write pointer has wrapped around to the same memory index as
//          the read pointer;
//        - but it is one full FIFO depth ahead.
//    - When wr_full is 1, writes should be blocked.
//
// 10. Empty flag behavior:
//    - rd_empty should be generated in the read clock domain.
//    - The FIFO is empty when the synchronized write pointer equals the read
//      pointer.
//    - When rd_empty is 1, reads should be blocked.
//
// 11. Write enable behavior:
//    - If wr_en is 1 and wr_full is 0:
//        - accept the write;
//        - store wr_data;
//        - increment the write pointer.
//    - If wr_en is 1 and wr_full is 1:
//        - do not write;
//        - do not increment the write pointer.
//    - If wr_en is 0:
//        - do not write.
//
// 12. Read enable behavior:
//    - If rd_en is 1 and rd_empty is 0:
//        - read the current FIFO entry;
//        - update rd_data;
//        - increment the read pointer.
//    - If rd_en is 1 and rd_empty is 1:
//        - do not read;
//        - do not increment the read pointer.
//    - If rd_en is 0:
//        - do not read;
//        - rd_data may hold its previous value.
//
// 13. Reset behavior:
//    - wr_rst_n is asynchronous active-low reset for the write clock domain.
//    - On wr_rst_n reset:
//        - clear wr_ptr_bin;
//        - clear wr_ptr_gray;
//        - clear the synchronized read-pointer registers;
//        - deassert wr_full.
//
//    - rd_rst_n is asynchronous active-low reset for the read clock domain.
//    - On rd_rst_n reset:
//        - clear rd_ptr_bin;
//        - clear rd_ptr_gray;
//        - clear the synchronized write-pointer registers;
//        - assert rd_empty;
//        - clear rd_data.
//
// 14. Clock-domain crossing behavior:
//    - Binary pointers should not be directly passed across clock domains.
//    - Only Gray-coded pointers should cross clock domains.
//    - Each crossed pointer should pass through a 2-flop synchronizer before
//      being used in the other domain.
//
// 15. Timing behavior:
//    - Write-side state updates only on wr_clk.
//    - Read-side state updates only on rd_clk.
//    - wr_full is valid in the write clock domain.
//    - rd_empty is valid in the read clock domain.
//    - Due to pointer synchronization latency, full/empty flags may update
//      conservatively after a few cycles.
//
// 16. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for write-domain sequential logic.
//    - Use always_ff for read-domain sequential logic.
//    - Use nonblocking assignments in sequential logic.
//    - Use Gray-coded pointers for cross-domain status.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 17. Assumptions:
//    - DEPTH is a power of 2.
//    - DEPTH is at least 2.
//    - The memory supports one write port in wr_clk domain and one read port
//      in rd_clk domain, or is modeled as a simple dual-clock FIFO memory.
//    - wr_en is synchronous to wr_clk.
//    - rd_en is synchronous to rd_clk.
//    - wr_rst_n is used only in the write domain.
//    - rd_rst_n is used only in the read domain.
// ============================================================

`default_nettype none

module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH      = 16
)(
  input  logic                  wr_clk,
  input  logic                  wr_rst_n,
  input  logic                  wr_en,
  input  logic [DATA_WIDTH-1:0] wr_data,
  output logic                  wr_full,

  input  logic                  rd_clk,
  input  logic                  rd_rst_n,
  input  logic                  rd_en,
  output logic [DATA_WIDTH-1:0] rd_data,
  output logic                  rd_empty
);
    localparam int PTR_W = $clog2(DEPTH);
    logic [PTR_W:0] rd_bin, rd_gray, rd_gray_sync1, rd_gray_sync2;
    logic [PTR_W:0] wr_bin, wr_gray, wr_gray_sync1, wr_gray_sync2;
    logic [DATA_WIDTH-1:0] mem [DEPTH];

    assign rd_gray = rd_bin ^ (rd_bin >> 1);
    assign wr_gray = wr_bin ^ (wr_bin >> 1);

    // assign rd_empty = (wr_gray == rd_gray_sync2);
    assign rd_empty = (rd_gray == wr_gray_sync2);
    // assign wr_full = (rd_gray == {~wr_gray_sync2[PTR_W:PTR_W-1], wr_gray_sync2[PTR_W-2:0]});
    assign wr_full = (wr_gray == {~rd_gray_sync2[PTR_W:PTR_W-1], rd_gray_sync2[PTR_W-2:0]});


    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin <= '0;
            rd_gray_sync1 <= '0;
            rd_gray_sync2 <= '0;
        end else begin
            if (wr_en & !wr_full) begin
                mem[wr_bin[PTR_W-1:0]] <= wr_data;
                wr_bin <= wr_bin+1;
            end
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin <= '0;
            wr_gray_sync1 <= '0;
            wr_gray_sync2 <= '0;
            rd_data <= '0;
        end else begin
            if (rd_en & !rd_empty) begin
                rd_data <= mem[rd_bin[PTR_W-1:0]];
                rd_bin <= rd_bin+1;
            end
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  wr_full,
    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  rd_empty
);
  // Pointer width: $clog2(DEPTH)+1 bits to allow full/empty distinction
  localparam PTR_WIDTH = $clog2(DEPTH) + 1;

  // Shared memory (combinational read)
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Write domain registers
  logic [PTR_WIDTH-1:0] wr_ptr_bin;
  logic [PTR_WIDTH-1:0] wr_ptr_gray;
  logic [PTR_WIDTH-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

  // Read domain registers
  logic [PTR_WIDTH-1:0] rd_ptr_bin;
  logic [PTR_WIDTH-1:0] rd_ptr_gray;
  logic [PTR_WIDTH-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

  // ---------------------------------------------------------------------------
  // Write domain
  // ---------------------------------------------------------------------------
  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wr_ptr_bin        <= '0;
      wr_ptr_gray       <= '0;
      rd_ptr_gray_sync1 <= '0;
      rd_ptr_gray_sync2 <= '0;
      wr_full           <= 1'b0;
    end else begin
      // 2-FF synchronizer: capture read-domain gray pointer into write domain
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;

      if (wr_en && !wr_full) begin
        mem[wr_ptr_bin[$clog2(DEPTH)-1:0]] <= wr_data;
        wr_ptr_bin  <= wr_ptr_bin + 1'b1;
        // Gray code of the *new* pointer (after increment)
        wr_ptr_gray <= (wr_ptr_bin + 1'b1) ^ ((wr_ptr_bin + 1'b1) >> 1);
      end else begin
        // Keep gray pointer in sync with binary pointer even when not writing
        wr_ptr_gray <= wr_ptr_bin ^ (wr_ptr_bin >> 1);
      end

      // Full: write gray pointer with top two bits inverted equals sync'd read gray
      wr_full <= ({~wr_ptr_gray[PTR_WIDTH-1],
                   ~wr_ptr_gray[PTR_WIDTH-2],
                    wr_ptr_gray[PTR_WIDTH-3:0]} == rd_ptr_gray_sync2);
    end
  end

  // ---------------------------------------------------------------------------
  // Read domain
  // ---------------------------------------------------------------------------
  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_ptr_bin        <= '0;
      rd_ptr_gray       <= '0;
      wr_ptr_gray_sync1 <= '0;
      wr_ptr_gray_sync2 <= '0;
      rd_empty          <= 1'b1;
      rd_data           <= '0;
    end else begin
      // 2-FF synchronizer: capture write-domain gray pointer into read domain
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;

      if (rd_en && !rd_empty) begin
        rd_data    <= mem[rd_ptr_bin[$clog2(DEPTH)-1:0]];
        rd_ptr_bin <= rd_ptr_bin + 1'b1;
        rd_ptr_gray <= (rd_ptr_bin + 1'b1) ^ ((rd_ptr_bin + 1'b1) >> 1);
      end else begin
        rd_ptr_gray <= rd_ptr_bin ^ (rd_ptr_bin >> 1);
      end

      // Empty: synchronized write gray pointer equals read gray pointer
      rd_empty <= (wr_ptr_gray_sync2 == rd_ptr_gray);
    end
  end

endmodule