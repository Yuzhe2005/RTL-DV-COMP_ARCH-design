// ============================================================
// Problem: FIFO Width Converter
// ============================================================
// Design a parameterized synchronous FIFO that supports different
// write and read data widths.
// Module interface:
// module fifo_width_conv #(
//   parameter WRITE_WIDTH = 32,
//   parameter READ_WIDTH  = 8,
//   parameter DEPTH_UNITS = 16
// )(
//   input  logic                    clk,
//   input  logic                    rst_n,
//   input  logic                    write_en,
//   input  logic [WRITE_WIDTH-1:0]  write_data,
//   output logic                    full,
//   input  logic                    read_en,
//   output logic [READ_WIDTH-1:0]   read_data,
//   output logic                    empty
// );
// Requirements:
// 1. This is a single-clock synchronous FIFO width converter.
//    - Both write and read operations use the same clk.
//    - Reset is active-low asynchronous reset: rst_n.
//    - The FIFO supports WRITE_WIDTH and READ_WIDTH being different.
// 2. Storage unit:
//    - Internally store data in chunks of UNIT_WIDTH bits.
//    - UNIT_WIDTH should be the smaller of WRITE_WIDTH and READ_WIDTH.
//    - Define:
//        UNIT_WIDTH = min(WRITE_WIDTH, READ_WIDTH)
//    - The storage depth is DEPTH_UNITS units.
//    - Use an internal memory array:
//        logic [UNIT_WIDTH-1:0] mem [0:DEPTH_UNITS-1];
// 3. Width conversion rule:
//    - Each write operation writes WRITE_WIDTH storage units.
//    - Each read operation reads READ_UNITS storage units.
//    - Define:
//        WRITE_UNITS = WRITE_WIDTH / UNIT_WIDTH
//        READ_UNITS  = READ_WIDTH  / UNIT_WIDTH
//    - You may assume the larger width is an integer multiple of the smaller width.
// 4. Example behavior:
//    - If WRITE_WIDTH = 32 and READ_WIDTH = 8:
//        UNIT_WIDTH  = 8
//        WRITE_UNITS = 4
//        READ_UNITS  = 1
//      Each write stores four 8-bit chunks.
//      Each read returns one 8-bit chunk.
//    - If WRITE_WIDTH = 8 and READ_WIDTH = 32:
//        UNIT_WIDTH  = 8
//        WRITE_UNITS = 1
//        READ_UNITS  = 4
//      Each write stores one 8-bit chunk.
//      Each read returns four 8-bit chunks.
// 5. Write behavior:
//    - On each rising edge of clk, if write_en is high and FIFO is not full,
//      accept write_data.
//    - Break write_data into WRITE_UNITS chunks of UNIT_WIDTH bits.
//    - Store the chunks into consecutive memory locations.
//    - Store chunks in LSB-first order.
//    - Chunk i should be:
//        write_data[i*UNIT_WIDTH +: UNIT_WIDTH]
//    - After a successful write, increment wr_ptr by WRITE_UNITS.
//    - If FIFO does not have enough free units for the whole write word,
//      full should be high and the write should be ignored.
// 6. Read behavior:
//    - On each rising edge of clk, if read_en is high and FIFO is not empty,
//      produce read_data.
//    - Assemble read_data from READ_UNITS chunks of UNIT_WIDTH bits.
//    - Read chunks from consecutive memory locations.
//    - Assemble chunks in LSB-first order.
//    - Chunk i should be assigned to:
//        read_data[i*UNIT_WIDTH +: UNIT_WIDTH]
//    - After a successful read, increment rd_ptr by READ_UNITS.
//    - If FIFO does not have enough stored units for the whole read word,
//      empty should be high and the read should be ignored.
//    - read_data should be a registered output.
// 7. Pointer behavior:
//    - Maintain a write pointer wr_ptr.
//    - Maintain a read pointer rd_ptr.
//    - Pointers index the UNIT_WIDTH storage array.
//    - Pointers should wrap around modulo DEPTH_UNITS.
//    - Implement pointer addition using a helper function.
//    - The helper function should compute:
//        (base + delta) % DEPTH_UNITS
// 8. Occupancy counter:
//    - Maintain a count_units register.
//    - count_units tracks how many UNIT_WIDTH chunks are currently stored.
//    - count_units should range from 0 to DEPTH_UNITS.
//    - On reset, count_units should become 0.
//    - A successful write increases count_units by WRITE_UNITS.
//    - A successful read decreases count_units by READ_UNITS.
//    - A simultaneous successful write and read updates count_units by:
//        count_units + WRITE_UNITS - READ_UNITS
// 9. Full flag:
//    - full should indicate that there is not enough free space for one
//      complete write_data word.
//    - full should be high when:
//        count_units + WRITE_UNITS > DEPTH_UNITS
//    - If full is high, write_en should not change memory, wr_ptr, or count_units.
// 10. Empty flag:
//    - empty should indicate that there is not enough stored data for one
//      complete read_data word.
//    - empty should be high when:
//        count_units < READ_UNITS
//    - If empty is high, read_en should not change read_data, rd_ptr, or count_units.
// 11. Simultaneous read and write behavior:
//    - If write_en is high and full is low, the write fires.
//    - If read_en is high and empty is low, the read fires.
//    - Write and read may both fire in the same clock cycle.
//    - If only write fires:
//        count_units increases by WRITE_UNITS.
//    - If only read fires:
//        count_units decreases by READ_UNITS.
//    - If both write and read fire:
//        count_units increases by WRITE_UNITS and decreases by READ_UNITS.
//    - wr_ptr and rd_ptr should update independently based on whether their
//      corresponding operation fires.
// 12. Reset behavior:
//    - When rst_n is low:
//        wr_ptr should reset to 0.
//        rd_ptr should reset to 0.
//        count_units should reset to 0.
//        read_data should reset to 0.
//    - Memory contents do not need to be reset.
// 13. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use assign statements for full, empty, write_fire, and read_fire.
//    - Use for loops to split write_data and assemble read_data.
//    - The design should be synthesizable.
// 14. Assumptions:
//    - WRITE_WIDTH and READ_WIDTH are positive.
//    - DEPTH_UNITS is positive.
//    - The larger of WRITE_WIDTH and READ_WIDTH is divisible by the smaller one.
//    - DEPTH_UNITS represents capacity in UNIT_WIDTH chunks, not full words.
//    - This problem only requires full and empty flags.
//    - almost_full and almost_empty are not required.
// ============================================================

`default_nettype none

module fifo_width_conv #(
  parameter WRITE_WIDTH = 32,
  parameter READ_WIDTH  = 8,
  parameter DEPTH_UNITS = 16
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    write_en,
  input  logic [WRITE_WIDTH-1:0]  write_data,
  output logic                    full,
  input  logic                    read_en,
  output logic [READ_WIDTH-1:0]   read_data,
  output logic                    empty
);

    localparam int UNIT_WIDTH = (WRITE_WIDTH > READ_WIDTH) ? READ_WIDTH : WRITE_WIDTH;
    localparam int READ_LEN   = READ_WIDTH  / UNIT_WIDTH;
    localparam int WRITE_LEN  = WRITE_WIDTH / UNIT_WIDTH;

    localparam int PTR_W   = (DEPTH_UNITS <= 1) ? 1 : $clog2(DEPTH_UNITS);
    localparam int COUNT_W = $clog2(DEPTH_UNITS + 1);

    logic [PTR_W-1:0]   write_ptr, read_ptr;
    logic [PTR_W-1:0]   write_ptr_d, read_ptr_d;
    logic [COUNT_W-1:0] count, count_d;

    logic [UNIT_WIDTH-1:0] mem [0:DEPTH_UNITS-1];

    logic read_able, write_able;

    function automatic logic [PTR_W-1:0] ptr_add(
        input [PTR_W-1:0] base,
        input int unsigned delta
    );
        int unsigned tmp;
        begin
            tmp = int'(base) + delta;
            ptr_add = PTR_W'(tmp % DEPTH_UNITS);
        end
    endfunction

    assign empty = (count < READ_LEN);
    assign full  = (count + WRITE_LEN > DEPTH_UNITS);

    assign read_able  = read_en  && !empty;
    assign write_able = write_en && !full;

    always_comb begin
        count_d     = count;
        read_ptr_d  = read_ptr;
        write_ptr_d = write_ptr;

        if (read_able) begin
            count_d    = count_d - READ_LEN;
            read_ptr_d = ptr_add(read_ptr, READ_LEN);
        end

        if (write_able) begin
            count_d     = count_d + WRITE_LEN;
            write_ptr_d = ptr_add(write_ptr, WRITE_LEN);
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data <= '0;
            count     <= '0;
            write_ptr <= '0;
            read_ptr  <= '0;
        end else begin
            count     <= count_d;
            write_ptr <= write_ptr_d;
            read_ptr  <= read_ptr_d;

            if (write_able) begin
                for (int i = 0; i < WRITE_LEN; i++) begin
                    mem[ptr_add(write_ptr, i)] <= write_data[i*UNIT_WIDTH +: UNIT_WIDTH];
                end
            end

            if (read_able) begin
                for (int i = 0; i < READ_LEN; i++) begin
                    read_data[i*UNIT_WIDTH +: UNIT_WIDTH] <= mem[ptr_add(read_ptr, i)];
                end
            end
        end
    end
endmodule
