// ============================================================
// Problem: Single-Port RAM with Write-First Read Behavior
// ============================================================
// Design a parameterized single-port RAM.
// Module interface:
// module sp_ram #(
//   parameter DEPTH = 256,
//   parameter WIDTH = 8
// )(
//   input  logic                      clk,
//   input  logic                      write_en,
//   input  logic                      read_en,
//   input  logic [$clog2(DEPTH)-1:0] address,
//   input  logic [WIDTH-1:0]          write_data,
//   output logic [WIDTH-1:0]          read_data
// );
// Requirements:
// 1. This is a synchronous single-port RAM.
//    - The RAM has one shared address port.
//    - The same address is used for both read and write.
//    - All read and write operations happen on the rising edge of clk.
//    - No reset is required.
// 2. Parameters:
//    - DEPTH controls the number of memory entries.
//    - WIDTH controls the number of bits stored in each entry.
//    - The address width should be based on $clog2(DEPTH).
// 3. Internal storage:
//    - Use an internal memory array.
//    - The memory should contain DEPTH entries.
//    - Each entry should be WIDTH bits wide.
// 4. Write behavior:
//    - On each rising edge of clk, if write_en is high,
//      write write_data into the memory location selected by address.
//    - If write_en is low, memory contents should not change.
// 5. Read behavior:
//    - On each rising edge of clk, if read_en is high,
//      update read_data with the value read from the selected address.
//    - read_data should be registered.
//    - This means read_data has synchronous read behavior.
//    - If read_en is low, read_data should hold its previous value.
// 6. Write-first behavior:
//    - If read_en and write_en are both high in the same cycle,
//      the RAM should return the newly written data on read_data.
//    - This is called write-first behavior.
//    - In this single-port RAM, because read and write share the same address,
//      simultaneous read and write always refer to the same address.
// 7. Output behavior:
//    - read_data should only update on a rising clock edge when read_en is high.
//    - During a normal read, read_data should receive the stored memory value.
//    - During simultaneous read and write, read_data should receive write_data.
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - The design should be synthesizable.
//    - You may use one or more always_ff blocks.
// 9. Assumptions:
//    - DEPTH and WIDTH are positive.
//    - address is always within the valid memory range.
//    - This problem only requires one shared address port.
//    - No byte enable, reset, or dual-port behavior is required.
// ============================================================

`default_nettype none

module sp_ram #(
  parameter DEPTH = 256,
  parameter WIDTH = 8
)(
  input  logic                      clk,
  input  logic                      write_en,
  input  logic                      read_en,
  input  logic [$clog2(DEPTH)-1:0] address,
  input  logic [WIDTH-1:0]          write_data,
  output logic [WIDTH-1:0]          read_data
);
    logic [WIDTH-1:0] mem [DEPTH];

    always_ff @(posedge clk) begin
        if (write_en && !read_en) begin
            mem[address] <= write_data;
        end else if (!write_en && read_en) begin
            read_data <= mem[address];
        end else if (read_en && write_en) begin
            mem[address] <= write_data;
            read_data <= write_data;
        end
    end
endmodule