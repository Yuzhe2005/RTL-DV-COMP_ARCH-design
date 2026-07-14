/**
 * riscv_pipeline.sv — 5-Stage Pipelined RISC-V RV32I (Top Level)
 * ─────────────────────────────────────────────────────────────────────────────
 * Connects the pipeline stages and sub-modules:
 *   regfile      — 32×32 register file
 *   alu          — RV32I arithmetic/logic unit
 *   hazard_unit  — stall + forwarding mux selects
 *
 * Pipeline stages (each separated by pipeline registers):
 *   IF  → IF/ID  → ID  → ID/EX  → EX  → EX/MEM  → MEM  → MEM/WB  → WB
 * ─────────────────────────────────────────────────────────────────────────────
 */
 // Added sample code to get you started. Feel free to modify as needed!

import riscv_pkg::*;

module riscv_pipeline (
  input  logic        clk,
  input  logic        rst_n,

  // ── Instruction memory (synchronous read, 1-cycle latency) ───────────────
  output logic [31:0] imem_addr,
  input  logic [31:0] imem_data,

  // ── Data memory ───────────────────────────────────────────────────────────
  output logic        dmem_req,
  output logic        dmem_we,
  output logic [31:0] dmem_addr,
  output logic [31:0] dmem_wdata,
  input  logic [31:0] dmem_rdata
);

  // ── PC ─────────────────────────────────────────────────────────────────────
  logic [31:0] pc;
  logic        stall;
  logic        branch_taken;
  logic [31:0] branch_target;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)        pc <= 32'd0;
    else if (!stall)   pc <= branch_taken ? branch_target : pc + 4;

  assign imem_addr = pc;

  // ── IF/ID ─────────────────────────────────────────────────────────────────
  logic [31:0] if_id_pc, if_id_inst;
  localparam logic [31:0] NOP = 32'h0000_0013;  // ADDI x0,x0,0

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n || branch_taken) begin if_id_pc <= 0; if_id_inst <= NOP; end
    else if (!stall)            begin if_id_pc <= pc; if_id_inst <= imem_data; end

  // ── ID — Decode ────────────────────────────────────────────────────────────
  logic [6:0]  id_opcode  ;  assign id_opcode   = if_id_inst[6:0];
  logic [4:0]  id_rd_addr ;  assign id_rd_addr  = if_id_inst[11:7];
  logic [2:0]  id_funct3  ;  assign id_funct3   = if_id_inst[14:12];
  logic [4:0]  id_rs1_addr;  assign id_rs1_addr = if_id_inst[19:15];
  logic [4:0]  id_rs2_addr;  assign id_rs2_addr = if_id_inst[24:20];
  logic [6:0]  id_funct7  ;  assign id_funct7   = if_id_inst[31:25];

  // Immediate generation
  logic [31:0] id_imm;
  always_comb case (id_opcode)
    OP_I_ALU, OP_LOAD, OP_JALR:
      id_imm = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
    OP_STORE:
      id_imm = {{20{if_id_inst[31]}}, if_id_inst[31:25], if_id_inst[11:7]};
    OP_BRANCH:
      id_imm = {{19{if_id_inst[31]}}, if_id_inst[31], if_id_inst[7],
                if_id_inst[30:25], if_id_inst[11:8], 1'b0};
    OP_LUI, OP_AUIPC:
      id_imm = {if_id_inst[31:12], 12'd0};
    OP_JAL:
      id_imm = {{11{if_id_inst[31]}}, if_id_inst[31], if_id_inst[19:12],
                if_id_inst[20], if_id_inst[30:21], 1'b0};
    default: id_imm = 32'd0;
  endcase

  // Control decode
  ctrl_t id_ctrl;
  always_comb begin
    id_ctrl = '0;
    id_ctrl.funct3 = id_funct3;
    case (id_opcode)
      OP_R: begin
        id_ctrl.reg_we = 1;
        case ({id_funct7[5], id_funct3})
          4'b0_000: id_ctrl.alu_op = ALU_ADD;
          4'b1_000: id_ctrl.alu_op = ALU_SUB;
          4'b0_111: id_ctrl.alu_op = ALU_AND;
          4'b0_110: id_ctrl.alu_op = ALU_OR;
          4'b0_100: id_ctrl.alu_op = ALU_XOR;
          4'b0_001: id_ctrl.alu_op = ALU_SLL;
          4'b0_101: id_ctrl.alu_op = ALU_SRL;
          4'b1_101: id_ctrl.alu_op = ALU_SRA;
          4'b0_010: id_ctrl.alu_op = ALU_SLT;
          4'b0_011: id_ctrl.alu_op = ALU_SLTU;
          default:  id_ctrl.alu_op = ALU_ADD;
        endcase
      end
      OP_I_ALU: begin
        id_ctrl.reg_we = 1; id_ctrl.alu_src = 1;
        case (id_funct3)
          3'b000: id_ctrl.alu_op = ALU_ADD;
          3'b111: id_ctrl.alu_op = ALU_AND;
          3'b110: id_ctrl.alu_op = ALU_OR;
          3'b100: id_ctrl.alu_op = ALU_XOR;
          3'b001: id_ctrl.alu_op = ALU_SLL;
          3'b101: id_ctrl.alu_op = id_funct7[5] ? ALU_SRA : ALU_SRL;
          3'b010: id_ctrl.alu_op = ALU_SLT;
          3'b011: id_ctrl.alu_op = ALU_SLTU;
          default: id_ctrl.alu_op = ALU_ADD;
        endcase
      end
      OP_LOAD:   begin id_ctrl.mem_re=1; id_ctrl.reg_we=1; id_ctrl.alu_src=1; end
      OP_STORE:  begin id_ctrl.mem_we=1; id_ctrl.alu_src=1; end
      OP_BRANCH: begin id_ctrl.branch=1; end
      OP_JAL:    begin id_ctrl.jal=1;   id_ctrl.reg_we=1; end
      OP_JALR:   begin id_ctrl.jalr=1;  id_ctrl.reg_we=1; id_ctrl.alu_src=1; end
      OP_LUI:    begin id_ctrl.lui=1;   id_ctrl.reg_we=1; end
      OP_AUIPC:  begin id_ctrl.auipc=1; id_ctrl.reg_we=1; end
      default: ;
    endcase
  end

  // Register file read
  logic [31:0] id_rs1_data, id_rs2_data;
  logic        wb_reg_we;
  logic [4:0]  wb_rd_addr;
  logic [31:0] wb_rd_data;

  regfile u_rf (
    .clk      (clk),
    .rs1_addr (id_rs1_addr), .rs1_data (id_rs1_data),
    .rs2_addr (id_rs2_addr), .rs2_data (id_rs2_data),
    .we       (wb_reg_we),   .rd_addr  (wb_rd_addr), .rd_data (wb_rd_data)
  );

  // ── ID/EX ─────────────────────────────────────────────────────────────────
  logic [31:0] id_ex_pc, id_ex_rs1, id_ex_rs2, id_ex_imm;
  logic [4:0]  id_ex_rd, id_ex_rs1_addr, id_ex_rs2_addr;
  ctrl_t       id_ex_ctrl;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n || branch_taken || stall) begin
      id_ex_pc<=0; id_ex_rs1<=0; id_ex_rs2<=0; id_ex_imm<=0;
      id_ex_rd<=0; id_ex_rs1_addr<=0; id_ex_rs2_addr<=0; id_ex_ctrl<='0;
    end else begin
      id_ex_pc       <= if_id_pc;
      id_ex_rs1      <= id_rs1_data;
      id_ex_rs2      <= id_rs2_data;
      id_ex_imm      <= id_imm;
      id_ex_rd       <= id_rd_addr;
      id_ex_rs1_addr <= id_rs1_addr;
      id_ex_rs2_addr <= id_rs2_addr;
      id_ex_ctrl     <= id_ctrl;
    end

  // ── Hazard unit ────────────────────────────────────────────────────────────
  logic [1:0] fwd_a, fwd_b;
  logic [31:0] ex_mem_alu_res;
  logic        ex_mem_reg_we; logic [4:0] ex_mem_rd;
  logic        mem_wb_reg_we; logic [4:0] mem_wb_rd;
  logic [31:0] mem_wb_result;

  hazard_unit u_haz (
    .id_ex_mem_re    (id_ex_ctrl.mem_re),
    .id_ex_rd        (id_ex_rd),
    .id_rs1_addr     (id_rs1_addr),
    .id_rs2_addr     (id_rs2_addr),
    .id_ex_rs1_addr  (id_ex_rs1_addr),
    .id_ex_rs2_addr  (id_ex_rs2_addr),
    .ex_mem_reg_we   (ex_mem_reg_we),
    .ex_mem_rd       (ex_mem_rd),
    .mem_wb_reg_we   (mem_wb_reg_we),
    .mem_wb_rd       (mem_wb_rd),
    .stall           (stall),
    .fwd_a           (fwd_a),
    .fwd_b           (fwd_b)
  );

  // ── EX — Execute ───────────────────────────────────────────────────────────
  logic [31:0] ex_rs1, ex_rs2_raw, ex_rs2, ex_alu_b;

  always_comb begin
    ex_rs1     = (fwd_a==FWD_EX) ? ex_mem_alu_res :
                 (fwd_a==FWD_MEM) ? mem_wb_result : id_ex_rs1;
    ex_rs2_raw = (fwd_b==FWD_EX) ? ex_mem_alu_res :
                 (fwd_b==FWD_MEM) ? mem_wb_result : id_ex_rs2;
    ex_rs2     = ex_rs2_raw;
    ex_alu_b   = id_ex_ctrl.alu_src ? id_ex_imm : ex_rs2_raw;
  end

  // Handle LUI / AUIPC / JAL / JALR result overrides
  logic [31:0] alu_result_raw, ex_alu_res_final;
  logic        alu_zero;

  // Override ALU B input for LUI/AUIPC: feed 0 or pc as A, imm as B
  logic [31:0] alu_a_in, alu_b_in;
  always_comb begin
    alu_a_in = id_ex_ctrl.lui   ? 32'd0       :
               id_ex_ctrl.auipc ? id_ex_pc     : ex_rs1;
    alu_b_in = (id_ex_ctrl.lui || id_ex_ctrl.auipc) ? id_ex_imm : ex_alu_b;
  end

  alu u_alu (
    .a      (alu_a_in),
    .b      (alu_b_in),
    .alu_op (id_ex_ctrl.alu_op),
    .result (alu_result_raw),
    .zero   (alu_zero)
  );

  // JAL/JALR write PC+4 as link address
  assign ex_alu_res_final = (id_ex_ctrl.jal || id_ex_ctrl.jalr)
                            ? id_ex_pc + 4 : alu_result_raw;

  // Branch resolution
  logic branch_cond;
  always_comb case (id_ex_ctrl.funct3)
    3'b000: branch_cond = (ex_rs1 == ex_rs2);
    3'b001: branch_cond = (ex_rs1 != ex_rs2);
    3'b100: branch_cond = ($signed(ex_rs1) < $signed(ex_rs2));
    3'b101: branch_cond = ($signed(ex_rs1) >= $signed(ex_rs2));
    3'b110: branch_cond = (ex_rs1 < ex_rs2);
    3'b111: branch_cond = (ex_rs1 >= ex_rs2);
    default: branch_cond = 1'b0;
  endcase

  assign branch_taken  = (id_ex_ctrl.branch && branch_cond)
                       || id_ex_ctrl.jal || id_ex_ctrl.jalr;
  assign branch_target = id_ex_ctrl.jalr
                         ? (ex_rs1 + id_ex_imm) & ~32'd1
                         : id_ex_pc + id_ex_imm;

  // ── EX/MEM ────────────────────────────────────────────────────────────────
  logic [31:0] ex_mem_rs2;
  logic [2:0]  ex_mem_funct3;
  logic        ex_mem_mem_re, ex_mem_mem_we;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      ex_mem_alu_res<=0; ex_mem_rs2<=0; ex_mem_rd<=0;
      ex_mem_reg_we<=0; ex_mem_mem_re<=0; ex_mem_mem_we<=0; ex_mem_funct3<=0;
    end else begin
      ex_mem_alu_res  <= ex_alu_res_final;
      ex_mem_rs2      <= ex_rs2;
      ex_mem_rd       <= id_ex_rd;
      ex_mem_reg_we   <= id_ex_ctrl.reg_we;
      ex_mem_mem_re   <= id_ex_ctrl.mem_re;
      ex_mem_mem_we   <= id_ex_ctrl.mem_we;
      ex_mem_funct3   <= id_ex_ctrl.funct3;
    end

  // ── MEM ───────────────────────────────────────────────────────────────────
  assign dmem_req   = ex_mem_mem_re || ex_mem_mem_we;
  assign dmem_we    = ex_mem_mem_we;
  assign dmem_addr  = ex_mem_alu_res;
  assign dmem_wdata = ex_mem_rs2;

  logic [31:0] mem_wb_alu_res, mem_wb_dmem;
  logic        mem_wb_mem_re;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      mem_wb_alu_res<=0; mem_wb_dmem<=0; mem_wb_rd<=0;
      mem_wb_reg_we<=0; mem_wb_mem_re<=0;
    end else begin
      mem_wb_alu_res <= ex_mem_alu_res;
      mem_wb_dmem    <= dmem_rdata;
      mem_wb_rd      <= ex_mem_rd;
      mem_wb_reg_we  <= ex_mem_reg_we;
      mem_wb_mem_re  <= ex_mem_mem_re;
    end

  // ── WB ────────────────────────────────────────────────────────────────────
  assign mem_wb_result = mem_wb_mem_re ? mem_wb_dmem : mem_wb_alu_res;
  assign wb_reg_we     = mem_wb_reg_we;
  assign wb_rd_addr    = mem_wb_rd;
  assign wb_rd_data    = mem_wb_result;

endmodule
