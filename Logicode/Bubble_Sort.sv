// ============================================================
// Problem: 8-Input Bubble Sort Datapath
// ============================================================
// Design a module that collects 8 input values and outputs them in sorted
// order when requested.
//
// The module receives one input value per clock cycle while sortit is low.
// When sortit is high, the module sorts the 8 stored values and drives a
// packed sorted output.
//
// Module interface:
// module bubble_sort #(
//   parameter BITWIDTH = 3
// )(
//   input  logic [BITWIDTH-1:0] din,
//   input  logic                sortit,
//   input  logic                clk,
//   input  logic                resetn,
//   output logic [8*BITWIDTH:0] dout
// );
//
// Requirements:
// 1. The module should store 8 input values internally.
//    - Each value has width BITWIDTH.
//    - The number of stored values is fixed to 8.
//
// 2. Reset behavior:
//    - resetn is active-low.
//    - On reset:
//        - clear the internal write address to 0;
//        - clear all stored values;
//        - clear dout to 0.
//
// 3. Input loading behavior:
//    - When sortit = 0:
//        - store din into the current internal memory slot;
//        - increment the internal write address;
//        - after address 7, the address wraps back to 0.
//    - This means the module captures one BITWIDTH-wide input per clock.
//
// 4. Sorting behavior:
//    - When sortit = 1:
//        - sort the 8 stored values.
//        - The intended order is descending numeric order:
//            largest value first,
//            smallest value last.
//    - The sorting should be based on unsigned comparison.
//
// 5. Output behavior:
//    - dout should contain the sorted result packed into one vector.
//    - Since dout has width 8*BITWIDTH + 1, the extra top bit should be 0.
//    - The packed data portion should contain all 8 sorted values.
//
// 6. Packing convention:
//    - After sorting, the sorted values should be packed into dout in a
//      consistent order.
//    - For the provided style:
//        sorted[0] is the largest value,
//        sorted[7] is the smallest value.
//    - The packed vector places sorted values into the output data field,
//      with one extra leading 0 bit.
//
// 7. Timing behavior:
//    - dout is registered.
//    - The sorted output appears on dout after a clock edge when sortit is
//      asserted.
//    - While sortit = 0, the module is in input-loading mode.
//
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use sequential logic for stored memory, address, and dout.
//    - Use combinational logic for sorting temporary copies of the stored
//      values.
//    - Use unsigned comparisons.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 9. Assumptions:
//    - Exactly 8 values are stored.
//    - External logic should provide enough loading cycles before asserting
//      sortit.
//    - If more than 8 values are loaded, newer inputs overwrite older slots
//      according to the wrapping address.
//    - This is a small fixed-size sorting problem, so a fully combinational
//      sorting network or bubble-sort-style compare/swap logic is acceptable.
// ============================================================

`default_nettype none

module bubble_sort #(
  parameter BITWIDTH = 3
)(
  input  logic [BITWIDTH-1:0] din,
  input  logic                sortit,
  input  logic                clk,
  input  logic                resetn,
  output logic [8*BITWIDTH:0] dout
);
    logic [BITWIDTH-1:0] mem [8];
    logic [BITWIDTH-1:0] temp [8];
    
    localparam int ADDR_W = $clog2(8);
    logic [ADDR_W-1:0] addr;

    // dout规定是registered output
    always_ff @(posedge clk) begin
        if (!resetn) begin
            for (int i = 0; i < 8; i++) begin
                mem[i] <= '0;
            end
            addr <= '0;
            dout <= '0;
        end else begin
            if (!sortit) begin
                addr <= addr+1;
                mem[addr] <= din;
                dout <= '0;
            end else begin
                for (int i = 0; i < 8; i++)
                    dout[i*BITWIDTH +: BITWIDTH] <= temp[8-i-1];
            end
        end
    end

    always_comb begin
        for (int i = 0; i < 8; i++) temp[i] = mem[i];
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 7; j++) begin
                // if (mem[j] > mem[j+1])
                if (temp[j] > temp[j+1]) // 比较错了
                    {temp[j], temp[j+1]} = {temp[j+1], temp[j]};
            end
        end
    end     
endmodule