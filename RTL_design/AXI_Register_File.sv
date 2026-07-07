// ============================================================
// Problem: AXI4-Lite Register File Slave
// ============================================================
// Design a simple AXI4-Lite slave that exposes four 32-bit
// memory-mapped registers.
//
// Module interface:
// module axi_reg_file (
//   input  logic        ACLK,
//   input  logic        ARESETn,
//   input  logic        AWVALID,
//   output logic        AWREADY,
//   input  logic [31:0] AWADDR,
//   input  logic        WVALID,
//   output logic        WREADY,
//   input  logic [31:0] WDATA,
//   input  logic [3:0]  WSTRB,
//   output logic        BVALID,
//   input  logic        BREADY,
//   output logic [1:0]  BRESP,
//   input  logic        ARVALID,
//   output logic        ARREADY,
//   input  logic [31:0] ARADDR,
//   output logic        RVALID,
//   input  logic        RREADY,
//   output logic [31:0] RDATA,
//   output logic [1:0]  RRESP
// );
//
// Requirements:
// 1. Implement an AXI4-Lite slave register file.
// 2. The slave should contain four 32-bit registers:
//    - address 32'h0000_0000: regs[0]
//    - address 32'h0000_0004: regs[1]
//    - address 32'h0000_0008: regs[2]
//    - address 32'h0000_000C: regs[3]
// 3. Reset behavior:
//    - ARESETn is an active-low asynchronous reset.
//    - On reset, all four registers should be cleared to 0.
//    - BVALID and RVALID should be cleared.
//    - BRESP and RRESP should be cleared to OKAY.
//    - Latched write address/data state should be cleared.
// 4. AXI4-Lite write address channel:
//    - AWVALID/AWREADY handshake accepts the write address.
//    - When AWVALID && AWREADY is true, latch AWADDR.
//    - The slave should not accept another write address while one is pending.
// 5. AXI4-Lite write data channel:
//    - WVALID/WREADY handshake accepts the write data.
//    - When WVALID && WREADY is true, latch WDATA.
//    - The slave should not accept another write data beat while one is pending.
// 6. Write operation behavior:
//    - AXI4-Lite write address and write data channels are independent.
//    - The write address may arrive before the write data,
//      or the write data may arrive before the write address.
//    - A register write should occur only after both AW and W have been accepted.
//    - If the latched write address is valid, update the selected register.
//    - If the latched write address is invalid, do not modify any register.
//    - WSTRB is provided but may be ignored in this simplified design.
// 7. Valid write addresses:
//    - 32'h0000_0000 writes regs[0]
//    - 32'h0000_0004 writes regs[1]
//    - 32'h0000_0008 writes regs[2]
//    - 32'h0000_000C writes regs[3]
// 8. Write response channel:
//    - After both write address and write data have been received, assert BVALID.
//    - If the write address is valid, BRESP should be 2'b00, OKAY.
//    - If the write address is invalid, BRESP should be 2'b10, SLVERR.
//    - BVALID should remain high until BREADY is high.
//    - After BVALID && BREADY, clear the pending write state.
// 9. AXI4-Lite read address channel:
//    - ARVALID/ARREADY handshake accepts the read address.
//    - The slave should accept a read address only when no read response is pending.
//    - ARREADY should be deasserted while RVALID is high.
// 10. Read data channel:
//    - After accepting ARADDR, assert RVALID.
//    - If ARADDR is valid, return the selected register value on RDATA.
//    - If ARADDR is invalid, return 0 on RDATA.
//    - If ARADDR is valid, RRESP should be 2'b00, OKAY.
//    - If ARADDR is invalid, RRESP should be 2'b10, SLVERR.
//    - RVALID should remain high until RREADY is high.
// 11. Valid read addresses:
//    - 32'h0000_0000 reads regs[0]
//    - 32'h0000_0004 reads regs[1]
//    - 32'h0000_0008 reads regs[2]
//    - 32'h0000_000C reads regs[3]
// 12. Handshake behavior:
//    - A channel transfer occurs only when VALID && READY are both high
//      on the same rising edge of ACLK.
//    - Slave VALID signals should remain asserted until the corresponding
//      READY signal is high.
//    - READY signals may be generated from internal pending-state flags.
// 13. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for registered state, register file storage,
//      and response signals.
//    - Use continuous assignments for simple READY generation.
//    - The design should be synthesizable.
// 14. Assumptions:
//    - This is a simplified AXI4-Lite slave.
//    - Only one outstanding write transaction needs to be supported.
//    - Only one outstanding read transaction needs to be supported.
//    - No burst support is required.
//    - No protection, cache, QoS, exclusive access, or ID signaling is required.
// ============================================================

`default_nettype none

module axi_reg_file (
  input  logic        ACLK,
  input  logic        ARESETn,
  input  logic        AWVALID,
  output logic        AWREADY,
  input  logic [31:0] AWADDR,
  input  logic        WVALID,
  output logic        WREADY,
  input  logic [31:0] WDATA,
  input  logic [3:0]  WSTRB,
  output logic        BVALID,
  input  logic        BREADY,
  output logic [1:0]  BRESP,
  input  logic        ARVALID,
  output logic        ARREADY,
  input  logic [31:0] ARADDR,
  output logic        RVALID,
  input  logic        RREADY,
  output logic [31:0] RDATA,
  output logic [1:0]  RRESP
);
    localparam logic [31:0] REG0 = 32'h00;
    localparam logic [31:0] REG1 = 32'h04;
    localparam logic [31:0] REG2 = 32'h08;
    localparam logic [31:0] REG3 = 32'h0c;

    logic w_done, aw_done;
    logic [31:0] awaddr_reg, wdata_reg;
    logic [31:0] regs [4];

    assign AWREADY = !aw_done;
    assign WREADY = !w_done;
    assign ARREADY = !RVALID;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            aw_done <= 0;
            awaddr_reg <= '0;
        end else begin
            if (AWVALID && AWREADY) begin
                aw_done <= 1;
                awaddr_reg <= AWADDR;
            end
            if (BVALID && BREADY)
                aw_done <= 0;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            w_done <= 0;
            wdata_reg <= '0;
        end else begin
            if (WVALID && WREADY) begin
                w_done <= 1;
                wdata_reg <= WDATA;
            end 
            if (BREADY && BVALID)
                w_done <= 0;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            for (int i = 0; i < 4; i++) begin
                regs[i] <= '0;
            end
        end else begin
            if (w_done && aw_done && !BVALID) begin
                case (awaddr_reg)
                    REG0: regs[0] <= wdata_reg;
                    REG1: regs[1] <= wdata_reg;
                    REG2: regs[2] <= wdata_reg;
                    REG3: regs[3] <= wdata_reg;
                    default: ;
                endcase
            end
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            BVALID <= 0;
            BRESP <= 2'b00;
        end else begin
            if (w_done && aw_done && !BVALID) begin
                BVALID <= 1;
                if (awaddr_reg == REG0 ||
                    awaddr_reg == REG1 ||
                    awaddr_reg == REG2 ||
                    awaddr_reg == REG3)
                    BRESP <= 2'b00;
                else
                    BRESP <= 2'b10;
            end
            // if (BVALID && BREADY)
            else if (BVALID && BREADY) // 最好用else, 更清晰
                BVALID <= 0;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RDATA <= '0;
            RRESP <= 2'b00;
            RVALID <= 0;
        end else begin
            if (ARVALID && ARREADY) begin
                RVALID <= 1;
                case (ARADDR)
                    REG0: begin
                        RDATA <= regs[0];
                        RRESP <= 2'b00;
                    end

                    REG1: begin
                        RDATA <= regs[1];
                        RRESP <= 2'b00;
                    end

                    REG2: begin
                        RDATA <= regs[2];
                        RRESP <= 2'b00;
                    end

                    REG3: begin
                        RDATA <= regs[3];
                        RRESP <= 2'b00;
                    end

                    default: begin
                        RDATA <= '0;
                        RRESP <= 2'b10;
                    end
                endcase
            end
            // if (RVALID && RREADY)
            else if (RVALID && RREADY) // 用else if, 更清晰
                RVALID <= 0;
        end
    end
endmodule