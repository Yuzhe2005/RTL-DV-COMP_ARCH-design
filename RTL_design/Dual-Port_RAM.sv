// ============================================================
// Problem: Simple Dual-Port RAM
// ============================================================
// Design a parameterized dual-port RAM with one write-only port
// and one read-only port.
// Module interface:
// module dp_ram #(
//   parameter DEPTH = 256,
//   parameter WIDTH = 8
// )(
//   input  logic                      clk,
//   input  logic                      write_en_a,
//   input  logic [$clog2(DEPTH)-1:0] addr_a,
//   input  logic [WIDTH-1:0]          write_data_a,
//   input  logic                      read_en_b,
//   input  logic [$clog2(DEPTH)-1:0] addr_b,
//   output logic [WIDTH-1:0]          read_data_b
// );
// Requirements:
// 1. This is a synchronous simple dual-port RAM.
//    - Both ports use the same clk.
//    - Port A is write-only.
//    - Port B is read-only.
//    - No reset is required.
// 2. Parameters:
//    - DEPTH controls the number of memory entries.
//    - WIDTH controls the number of bits stored in each entry.
//    - Address width should be based on $clog2(DEPTH).
// 3. Internal storage:
//    - Use an internal memory array.
//    - The memory should contain DEPTH entries.
//    - Each entry should be WIDTH bits wide.
// 4. Port A write behavior:
//    - On each rising edge of clk, if write_en_a is high,
//      write write_data_a into the memory location selected by addr_a.
//    - If write_en_a is low, memory contents should not change.
// 5. Port B read behavior:
//    - On each rising edge of clk, if read_en_b is high,
//      read the memory location selected by addr_b.
//    - read_data_b should be registered.
//    - If read_en_b is low, read_data_b should hold its previous value.
// 6. Same-address read/write behavior:
//    - Port A and Port B may access the same address in the same cycle.
//    - If write_en_a and read_en_b are both high and addr_a == addr_b,
//      the read should return the old stored memory value, not the new write_data_a.
//    - This is read-first behavior on same-address collision.
// 7. Output behavior:
//    - read_data_b should only update on a rising clock edge when read_en_b is high.
//    - read_data_b should not be combinationally driven from memory.
//    - No output is required for Port A.
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential write and read logic.
//    - The design should be synthesizable.
//    - You may use separate always_ff blocks for write and read ports.
// 9. Assumptions:
//    - DEPTH and WIDTH are positive.
//    - addr_a and addr_b are always within the valid memory range.
//    - There is only one write port and one read port.
//    - No byte enable, reset, or write-through behavior is required.
// ============================================================

`default_nettype none

module dp_ram #(
  parameter DEPTH = 256,
  parameter WIDTH = 8
)(
  input  logic                      clk,
  input  logic                      write_en_a,
  input  logic [$clog2(DEPTH)-1:0] addr_a,
  input  logic [WIDTH-1:0]          write_data_a,
  input  logic                      read_en_b,
  input  logic [$clog2(DEPTH)-1:0] addr_b,
  output logic [WIDTH-1:0]          read_data_b
);
    logic [WIDTH-1:0] mem [DEPTH];

    always_ff @(posedge clk) begin
        if (write_en_a) begin
            mem[addr_a] <= write_data_a;
        end

        if (read_en_b) begin
            read_data_b <= mem[addr_b];
        end
    end
endmodule