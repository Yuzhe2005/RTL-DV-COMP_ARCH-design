/**
 * riscv_pipeline_tb.sv — Testbench for riscv_pipeline
 * ─────────────────────────────────────────────────────────────────────────────
 * Verifies: ADDI, ADD (EX→EX forwarding), SW/LW (load-use stall),
 *           branch not-taken, branch taken (flush).
 * ─────────────────────────────────────────────────────────────────────────────
 */

`timescale 1ns/1ps
import riscv_pkg::*;

module riscv_pipeline_tb;

  logic        clk, rst_n;
  logic [31:0] imem_addr, imem_data;
  logic        dmem_req, dmem_we;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

  riscv_pipeline dut (.*);

  always #5 clk = ~clk;

  // ── Instruction memory ────────────────────────────────────────────────────
  logic [31:0] imem [0:31];
  assign imem_data = imem[imem_addr[6:2]];

  // ── Data memory ───────────────────────────────────────────────────────────
  logic [31:0] dmem [0:63];
  always_ff @(posedge clk) begin
    dmem_rdata <= '0;
    if (dmem_req) begin
      if (dmem_we) dmem[dmem_addr[7:2]] <= dmem_wdata;
      else         dmem_rdata <= dmem[dmem_addr[7:2]];
    end
  end

  // ── Scoreboard ────────────────────────────────────────────────────────────
  int pass_cnt = 0, fail_cnt = 0;

  task automatic check32(logic [31:0] got, exp, string label);

    if (got === exp) begin $display("  PASS  %s = 0x%08h", label, got); pass_cnt++; end
    else             begin $display("  FAIL  %s got=0x%08h exp=0x%08h", label, got, exp); fail_cnt++; end
  endtask

  `define RF dut.u_rf.regs  // Hierarchical access to regfile internals

  initial begin
    // ── VCD waveform dump (generates waveform viewer data) ───────────────────
    $dumpfile("dump.vcd");
    $dumpvars(0, riscv_pipeline_tb);
    // ─────────────────────────────────────────────────────────────────────────
    clk=0; rst_n=0;

    // ── Hand-assembled RV32I program ─────────────────────────────────────
    //
    //   imem[0]  ADDI x1, x0, 5        x1 = 5
    //   imem[1]  ADDI x2, x0, 3        x2 = 3
    //   imem[2]  ADD  x3, x1, x2       x3 = 8  (EX→EX forwarding)
    //   imem[3]  SW   x3, 0(x0)        dmem[0] = 8
    //   imem[4]  LW   x4, 0(x0)        x4 = 8  (load-use stall)
    //   imem[5]  BEQ  x1, x2, +8       NOT taken (5≠3), skip 1 instr
    //   imem[6]  ADDI x5, x0, 99       x5 = 99 (executes — branch not taken)
    //   imem[7]  BEQ  x4, x3, +8       TAKEN (8==8) — skip imem[8]
    //   imem[8]  ADDI x6, x0, 42       SKIPPED
    //   imem[9]  ADDI x7, x0, 7        x7 = 7
    //   imem[10..] NOP loop

    imem[0]  = 32'h00500093;  // ADDI x1, x0, 5
    imem[1]  = 32'h00300113;  // ADDI x2, x0, 3
    imem[2]  = 32'h002081B3;  // ADD  x3, x1, x2
    imem[3]  = 32'h00302023;  // SW   x3, 0(x0)
    imem[4]  = 32'h00002203;  // LW   x4, 0(x0)
    imem[5]  = 32'h00208463;  // BEQ  x1, x2, +8
    imem[6]  = 32'h06300293;  // ADDI x5, x0, 99
    imem[7]  = 32'h00320463;  // BEQ  x4, x3, +8
    imem[8]  = 32'h02A00313;  // ADDI x6, x0, 42  (SKIPPED)
    imem[9]  = 32'h00700393;  // ADDI x7, x0, 7
    for (int i=10; i<32; i++) imem[i] = 32'h0000_0013; // NOP
    for (int i=0;  i<64; i++) dmem[i] = '0;

    $display("=== riscv_pipeline testbench ===");
    repeat(3) @(posedge clk); rst_n = 1;
    repeat(35) @(posedge clk);  // Let pipeline drain

    $display("-- Register checks --");
    check32(`RF[1], 32'd5,  "x1  (ADDI 5)");
    check32(`RF[2], 32'd3,  "x2  (ADDI 3)");
    check32(`RF[3], 32'd8,  "x3  (ADD, EX→EX fwd)");
    check32(`RF[4], 32'd8,  "x4  (LW, load-use stall)");
    check32(`RF[5], 32'd99, "x5  (not-taken branch)");
    check32(`RF[6], 32'd0,  "x6  (skipped by taken branch)");
    check32(`RF[7], 32'd7,  "x7  (after taken branch)");

    $display("-- Memory check --");
    check32(dmem[0], 32'd8, "dmem[0] (SW x3)");

    $display("\n=== %0d passed, %0d failed ===", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("PASS");
    else               $display("FAIL");
    $finish;
  end

endmodule
