// ============================================================
// Problem: AXI4-Lite Write-Only Control Register Block
// ============================================================
// Design a simple AXI4-Lite slave that exposes write-only control
// registers through a memory-mapped interface.
//
// Module interface:
// module axi_write_only_ctrl (
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
//   output logic [1:0]  RRESP,
//   output logic        enable_reg,
//   output logic [31:0] mode_reg
// );
//
// Requirements:
// 1. Implement an AXI4-Lite slave with write-only control registers.
// 2. The slave should expose two writable addresses:
//    - address 32'h0000_0000: enable register
//    - address 32'h0000_0004: mode register
// 3. Enable register behavior:
//    - A valid write to address 32'h0000_0000 should update enable_reg.
//    - enable_reg should be assigned from WDATA[0].
//    - On reset, enable_reg should be cleared to 0.
// 4. Mode register behavior:
//    - A valid write to address 32'h0000_0004 should update mode_reg.
//    - mode_reg should be assigned from the full 32-bit WDATA.
//    - On reset, mode_reg should be cleared to 0.
// 5. Invalid write address behavior:
//    - Writes to addresses other than 32'h0000_0000 or 32'h0000_0004
//      should not modify enable_reg or mode_reg.
//    - Invalid writes should return SLVERR on the write response.
// 6. AXI4-Lite write address channel:
//    - AWVALID/AWREADY handshake accepts the write address.
//    - When AWVALID && AWREADY is true, latch AWADDR.
//    - The slave should not accept another write address while one is pending.
// 7. AXI4-Lite write data channel:
//    - WVALID/WREADY handshake accepts the write data.
//    - When WVALID && WREADY is true, latch WDATA.
//    - The slave should not accept another write data beat while one is pending.
//    - WSTRB is provided but may be ignored in this simplified design.
// 8. Write operation behavior:
//    - AXI4-Lite write address and write data channels are independent.
//    - The write address may arrive before the write data,
//      or the write data may arrive before the write address.
//    - A register write should occur only after both AW and W have been accepted.
//    - If the latched write address is 32'h0000_0000, update enable_reg.
//    - If the latched write address is 32'h0000_0004, update mode_reg.
// 9. Write response channel:
//    - After both write address and write data have been received,
//      assert BVALID.
//    - BRESP should be 2'b00, OKAY, for valid write addresses.
//    - BRESP should be 2'b10, SLVERR, for invalid write addresses.
//    - BVALID should remain high until BREADY is high.
//    - After BVALID && BREADY, clear the pending write state.
// 10. Read behavior:
//    - This block is write-only.
//    - All AXI4-Lite read requests should return an error.
//    - No readable register values are exposed.
//    - Reads should return RDATA = 0.
//    - RRESP should be 2'b10, SLVERR, for all reads.
// 11. AXI4-Lite read address channel:
//    - ARVALID/ARREADY handshake accepts the read address.
//    - The actual read address value does not affect the returned data,
//      because all reads return SLVERR.
//    - The slave should accept a read address only when no read response
//      is currently pending.
//    - ARREADY should be deasserted while RVALID is high.
// 12. Read response channel:
//    - After accepting ARADDR, assert RVALID.
//    - RDATA should be 0.
//    - RRESP should be 2'b10, SLVERR.
//    - RVALID should remain high until RREADY is high.
// 13. Reset behavior:
//    - ARESETn is an active-low asynchronous reset.
//    - On reset, enable_reg should be cleared to 0.
//    - On reset, mode_reg should be cleared to 0.
//    - aw_done and w_done should be cleared.
//    - BVALID and RVALID should be cleared.
//    - RDATA should be cleared to 0.
//    - BRESP may reset to OKAY.
//    - RRESP may reset to SLVERR because all reads always return SLVERR.
// 14. Handshake behavior:
//    - A channel transfer occurs only when VALID && READY are both high
//      on the same rising edge of ACLK.
//    - Slave VALID signals should remain asserted until the corresponding
//      READY signal is high.
//    - READY signals may be generated from internal pending-state flags.
// 15. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for write tracking, control registers, and response signals.
//    - Use continuous assignments for simple READY generation.
//    - The design should be synthesizable.
// 16. Assumptions:
//    - This is a simplified AXI4-Lite slave.
//    - Only one outstanding write transaction needs to be supported.
//    - Only one outstanding read transaction needs to be supported.
//    - No burst support is required.
//    - No protection, cache, QoS, exclusive access, or ID signaling is required.
// ============================================================

`default_nettype none

module axi_write_only_ctrl (
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
  output logic [1:0]  RRESP,
  output logic        enable_reg,
  output logic [31:0] mode_reg
);
    logic w_done, aw_done;
    logic [31:0] awaddr_reg, wdata_reg;

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
            if (BVALID && BREADY)
                w_done <= 0;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            enable_reg <= 0;
            mode_reg <= '0;
        end else begin
            if (w_done && aw_done && !BVALID) begin
                case (awaddr_reg)
                    32'h00: enable_reg <= wdata_reg[0];
                    32'h04: mode_reg <= wdata_reg;
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
                if (awaddr_reg inside {32'h00, 32'h04})
                    BRESP <= 2'b00;
                else 
                    BRESP <= 2'b10;
            end else if (BVALID && BREADY)
                BVALID <= 0;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RVALID <= 0;
            RRESP <= 2'b00;
            RDATA <= '0;
        end else begin
            // if (AWVALID && AWREADY) begin // 这里老是打错
            if (ARVALID && ARREADY) begin
                RVALID <= 1;
                RRESP <= 2'b10;
                RDATA <= '0;
            end else if (RVALID && RREADY) 
                RVALID <= 0;
        end
    end
endmodule