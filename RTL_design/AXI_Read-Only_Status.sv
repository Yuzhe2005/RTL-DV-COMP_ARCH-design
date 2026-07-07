// ============================================================
// Problem: AXI4-Lite Read-Only Status Register Block
// ============================================================
// Design a simple AXI4-Lite slave that exposes read-only status
// registers through a memory-mapped interface.
//
// Module interface:
// module axi_read_only_status #(
//   parameter VERSION = 32'h0000_0001
// )(
//   input  logic        ACLK,
//   input  logic        ARESETn,
//   input  logic [31:0] status_in,
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
// 1. Implement an AXI4-Lite slave with read-only registers.
// 2. The slave should expose two readable addresses:
//    - address 32'h0000_0000: VERSION register
//    - address 32'h0000_0004: STATUS register
// 3. VERSION register behavior:
//    - Reads from address 32'h0000_0000 should return the VERSION parameter.
//    - VERSION is a constant parameter and does not need storage.
// 4. STATUS register behavior:
//    - Reads from address 32'h0000_0004 should return status_in.
//    - status_in is an external input and should be sampled/returned during
//      the read response.
// 5. Write behavior:
//    - This block is read-only.
//    - All AXI4-Lite writes should be accepted at the protocol level.
//    - No internal register should be modified by any write.
//    - Every write should return SLVERR on the write response.
//    - BRESP should be 2'b10 for all writes.
// 6. AXI4-Lite write address channel:
//    - AWVALID/AWREADY handshake accepts the write address.
//    - The actual write address value does not need to be stored because
//      all writes return an error.
//    - The slave should not accept another write address while one is pending.
// 7. AXI4-Lite write data channel:
//    - WVALID/WREADY handshake accepts the write data.
//    - The actual write data value does not need to be stored because
//      all writes are ignored.
//    - The slave should not accept another write data beat while one is pending.
//    - WSTRB is provided but may be ignored.
// 8. Write response channel:
//    - After both write address and write data have been received,
//      assert BVALID.
//    - BRESP should be 2'b10, SLVERR.
//    - BVALID should remain high until BREADY is high.
//    - After BVALID && BREADY, clear the pending write state.
// 9. AXI4-Lite read address channel:
//    - ARVALID/ARREADY handshake accepts the read address.
//    - The slave should accept a read address only when no read response
//      is currently pending.
//    - ARREADY should be deasserted while RVALID is high.
// 10. Read data channel:
//    - After accepting ARADDR, assert RVALID.
//    - If ARADDR is 32'h0000_0000, return VERSION on RDATA.
//    - If ARADDR is 32'h0000_0004, return status_in on RDATA.
//    - If ARADDR is unsupported, return 0 on RDATA.
//    - RRESP should be 2'b00, OKAY, for supported read addresses.
//    - RRESP should be 2'b10, SLVERR, for unsupported read addresses.
//    - RVALID should remain high until RREADY is high.
// 11. Reset behavior:
//    - ARESETn is an active-low asynchronous reset.
//    - On reset, aw_done and w_done should be cleared.
//    - BVALID and RVALID should be cleared.
//    - RDATA should be cleared to 0.
//    - RRESP should be cleared to OKAY.
//    - BRESP may reset to SLVERR because all writes always return SLVERR.
// 12. Handshake behavior:
//    - A channel transfer occurs only when VALID && READY are both high
//      on the same rising edge of ACLK.
//    - Slave VALID signals should remain asserted until the corresponding
//      READY signal is high.
//    - READY signals may be generated from internal pending-state flags.
// 13. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for write tracking and response registers.
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

module axi_read_only_status #(
  parameter VERSION = 32'h0000_0001
)(
  input  logic        ACLK,
  input  logic        ARESETn,
  input  logic [31:0] status_in,
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
    logic w_done, aw_done;

    assign AWREADY = !aw_done;
    assign WREADY = !w_done;
    assign ARREADY = !RVALID;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            aw_done <= 0;
        end else begin
            if (AWVALID && AWREADY) aw_done <= 1;
            if (BVALID && BREADY) aw_done <= 0;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            w_done <= 0;
        end else begin
            if (WVALID && WREADY) w_done <= 1;
            if (BVALID && BREADY)  w_done <= 0;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            BVALID <= 0;
            // BRESP <= 2'b00; 既然是read only, 那就reset成SLVERR
            BRESP <= 2'b10;
        end else begin
            if (w_done && aw_done && !BVALID) begin
                BVALID <= 1;
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
            if (ARREADY && ARVALID) begin
                RVALID <= 1;
                case (ARADDR)
                    32'h00: begin
                        RRESP <= 2'b00;
                        RDATA <= VERSION;
                    end

                    32'h04: begin
                        RRESP <= 2'b00;
                        RDATA <= status_in;
                    end

                    default: begin
                        RRESP <= 2'b10;
                        RDATA <= '0;
                    end
                endcase
            end else if (RVALID && RREADY)
                RVALID <= 0;
        end
    end
endmodule