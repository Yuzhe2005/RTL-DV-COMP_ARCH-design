/**
 * regfile.sv — 32 × 32-bit Register File
 * ─────────────────────────────────────────────────────────────────────────────
 * • Synchronous write (rising edge)
 * • Asynchronous read (combinational)
 * • x0 is hardwired to 0 — writes to x0 are ignored, reads always return 0
 * • Two independent read ports; one write port
 * ─────────────────────────────────────────────────────────────────────────────
 */

import riscv_pkg::*;

module regfile (
  input  logic        clk,

  // ── Read ports (combinational) ────────────────────────────────────────────
  input  logic [4:0]  rs1_addr,
  input  logic [4:0]  rs2_addr,
  output logic [31:0] rs1_data,
  output logic [31:0] rs2_data,

  // ── Write port (synchronous) ──────────────────────────────────────────────
  input  logic        we,
  input  logic [4:0]  rd_addr,
  input  logic [31:0] rd_data
);

  logic [31:0] regs [1:31];  // regs[0] is not stored — x0 is always 0

  // Synchronous write — ignore writes to x0
  always_ff @(posedge clk) begin
    if (we && rd_addr != 5'd0)
      regs[rd_addr] <= rd_data;
  end

  // Combinational read — x0 always returns 0
  assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
  assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];

endmodule
