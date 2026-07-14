/**
 * hazard_unit.sv — Pipeline Hazard Detection and Forwarding Control
 * ─────────────────────────────────────────────────────────────────────────────
 * Handles two classes of hazards:
 *
 * 1. DATA HAZARDS — Forwarding (EX→EX and MEM→EX)
 *    The forwarding unit computes 2-bit mux selects (fwd_a, fwd_b) that route
 *    results from later pipeline stages back to the EX stage ALU inputs.
 *    Priority: EX/MEM result (fresher) takes priority over MEM/WB result.
 *
 * 2. LOAD-USE HAZARD — Stall
 *    A load (LW) result is not available until the end of the MEM stage.
 *    Forwarding alone cannot resolve this — the pipeline must stall for 1 cycle.
 *    Detection: if the instruction in ID/EX is a load AND its destination
 *    register matches either source of the instruction currently in ID,
 *    assert stall (freeze PC and IF/ID) and inject a bubble into ID/EX.
 * ─────────────────────────────────────────────────────────────────────────────
 */

import riscv_pkg::*;

module hazard_unit (
  // ── Load-use stall detection inputs ──────────────────────────────────────
  input  logic       id_ex_mem_re,    // Instruction in ID/EX is a load
  input  logic [4:0] id_ex_rd,        // Destination of the load in ID/EX
  input  logic [4:0] id_rs1_addr,     // rs1 of instruction currently in ID
  input  logic [4:0] id_rs2_addr,     // rs2 of instruction currently in ID

  // ── Forwarding detection inputs ───────────────────────────────────────────
  input  logic [4:0] id_ex_rs1_addr,  // rs1 of instruction in ID/EX (EX stage)
  input  logic [4:0] id_ex_rs2_addr,  // rs2 of instruction in ID/EX (EX stage)

  input  logic       ex_mem_reg_we,   // EX/MEM instruction writes a register
  input  logic [4:0] ex_mem_rd,       // Destination of EX/MEM instruction

  input  logic       mem_wb_reg_we,   // MEM/WB instruction writes a register
  input  logic [4:0] mem_wb_rd,       // Destination of MEM/WB instruction

  // ── Outputs ───────────────────────────────────────────────────────────────
  output logic       stall,           // 1 = stall PC and IF/ID, bubble ID/EX
  output logic [1:0] fwd_a,           // ALU operand A mux select
  output logic [1:0] fwd_b            // ALU operand B mux select
);

  // ── Load-use stall ────────────────────────────────────────────────────────
  // Only stall when the load destination actually matches a needed register.
  // x0 never needs forwarding (it is always 0).
  assign stall = id_ex_mem_re &&
                 (id_ex_rd != 5'd0) &&
                 ((id_ex_rd == id_rs1_addr) || (id_ex_rd == id_rs2_addr));

  // ── Forwarding ────────────────────────────────────────────────────────────
  // Check EX/MEM first (fresher result has higher priority than MEM/WB).
  always_comb begin
    fwd_a = FWD_NONE;
    fwd_b = FWD_NONE;

    // EX→EX forward: result from the ALU one cycle ago
    if (ex_mem_reg_we && (ex_mem_rd != 5'd0)) begin
      if (ex_mem_rd == id_ex_rs1_addr) fwd_a = FWD_EX;
      if (ex_mem_rd == id_ex_rs2_addr) fwd_b = FWD_EX;
    end

    // MEM→EX forward: result from two cycles ago (ALU or load)
    if (mem_wb_reg_we && (mem_wb_rd != 5'd0)) begin
      if ((mem_wb_rd == id_ex_rs1_addr) && fwd_a == FWD_NONE) fwd_a = FWD_MEM;
      if ((mem_wb_rd == id_ex_rs2_addr) && fwd_b == FWD_NONE) fwd_b = FWD_MEM;
    end
  end

endmodule
