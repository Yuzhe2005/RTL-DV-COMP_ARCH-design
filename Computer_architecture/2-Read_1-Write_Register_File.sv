// ============================================================
// Problem: Register File with Two Read Ports and One Write Port
// ============================================================
// Design a parameterized register file.
//
// The register file should contain DEPTH registers, each W bits wide.
// It should support two asynchronous read ports and one synchronous write
// port.
//
// Module interface:
// module regfile #(
//   parameter W     = 32,
//   parameter DEPTH = 32
// )(
//   input  logic                      clk,
//   input  logic                      we,
//   input  logic [$clog2(DEPTH)-1:0]  wa,
//   input  logic [$clog2(DEPTH)-1:0]  ra1,
//   input  logic [$clog2(DEPTH)-1:0]  ra2,
//   input  logic [W-1:0]              wd,
//   output logic [W-1:0]              rd1,
//   output logic [W-1:0]              rd2
// );
//
// Requirements:
// 1. The module should implement a register file with:
//    - DEPTH entries;
//    - W bits per entry;
//    - two read ports;
//    - one write port.
//
// 2. Read port behavior:
//    - ra1 selects the register to read for output rd1.
//    - ra2 selects the register to read for output rd2.
//    - Reads should be asynchronous/combinational.
//    - rd1 and rd2 should update immediately when ra1, ra2, or register
//      contents change.
//
// 3. Write port behavior:
//    - wa selects the register to write.
//    - wd is the data to write.
//    - we is the write enable.
//    - When we is asserted, wd should be written into register wa on the
//      rising edge of clk.
//    - When we is deasserted, no register should be modified.
//
// 4. Register zero behavior:
//    - Register index 0 should behave like a hardwired zero register.
//    - Reading register 0 should always return 0.
//    - Writes to register 0 should be ignored.
//    - This matches RISC-V x0 behavior.
//
// 5. Read data behavior:
//    - If ra1 is 0, rd1 should be 0.
//    - Otherwise, rd1 should be the content of regs[ra1].
//    - If ra2 is 0, rd2 should be 0.
//    - Otherwise, rd2 should be the content of regs[ra2].
//
// 6. Write data behavior:
//    - On posedge clk:
//        - if we is 1 and wa is not 0, regs[wa] should be updated with wd;
//        - if we is 0, no write should occur;
//        - if wa is 0, the write should be ignored.
//
// 7. Reset behavior:
//    - No reset input is required.
//    - The register file contents do not need to be cleared by reset.
//    - Register 0 should still read as 0 because read logic explicitly
//      forces index 0 to zero.
//
// 8. Read-after-write behavior:
//    - If a register is written on a clock edge and read afterward, the new
//      value should be visible through the asynchronous read port.
//    - If a read and write to the same address are observed exactly around
//      the same clock edge, behavior may depend on simulation/synthesis
//      timing and memory implementation style.
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use an unpacked array for the register storage.
//    - Use continuous assignments or always_comb for asynchronous reads.
//    - Use always_ff for the synchronous write port.
//    - Use nonblocking assignment for writes.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 10. Assumptions:
//    - DEPTH is at least 2.
//    - Register addresses are $clog2(DEPTH) bits wide.
//    - For a RISC-V-style register file, W = 32 and DEPTH = 32.
//    - This module only stores register values; instruction decode and
//      writeback data selection are handled elsewhere.
// ============================================================

`default_nettype none

module regfile #(
  parameter W     = 32,
  parameter DEPTH = 32
)(
  input  logic                      clk,
  input  logic                      we,
  input  logic [$clog2(DEPTH)-1:0]  wa,
  input  logic [$clog2(DEPTH)-1:0]  ra1,
  input  logic [$clog2(DEPTH)-1:0]  ra2,
  input  logic [W-1:0]              wd,
  output logic [W-1:0]              rd1,
  output logic [W-1:0]              rd2
);
    logic [W-1:0] regs [DEPTH];

    assign rd1 = (ra1 == '0) ? '0 : regs[ra1];
    assign rd2 = (ra2 == '0) ? '0 : regs[ra2];

    always_ff @(posedge clk) begin
        // if (we) begin  忘了考虑 wa == '0 的情况了
        if (we && wa != '0) begin
            regs[wa] <= wd;
        end
    end
endmodule