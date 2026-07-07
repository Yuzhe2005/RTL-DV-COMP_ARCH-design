// ============================================================
// Problem: AXI4-Lite Single Register Slave
// ============================================================
// Design a simple AXI4-Lite slave containing one 32-bit register.
// Module interface:
// module axi_lite_single_reg (
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
// Requirements:
// 1. Implement a simple AXI4-Lite slave with one 32-bit memory-mapped register.
// 2. The register should be located at address 32'h0000_0000.
// 3. Reset behavior:
//    - ARESETn is an active-low asynchronous reset.
//    - On reset, the internal register should be cleared to 0.
//    - All valid response signals should be cleared.
//    - Latched write address/data state should be cleared.
// 4. AXI4-Lite write address channel:
//    - AWVALID/AWREADY handshake accepts the write address.
//    - When AWVALID && AWREADY is true, latch AWADDR.
//    - The slave should not accept another write address while a previous one is pending.
// 5. AXI4-Lite write data channel:
//    - WVALID/WREADY handshake accepts the write data.
//    - When WVALID && WREADY is true, latch WDATA.
//    - The slave should not accept another write data beat while a previous one is pending.
// 6. Write operation behavior:
//    - AXI4-Lite write address and write data channels are independent.
//    - The address may arrive before the data, or the data may arrive before the address.
//    - The register write should occur only after both AW and W have been accepted.
//    - If the latched write address is 32'h0000_0000, update the internal register with the latched write data.
//    - Writes to unsupported addresses should not modify the register.
// 7. Write response channel:
//    - After both write address and write data have been received, assert BVALID.
//    - BRESP should return OKAY, encoded as 2'b00.
//    - Keep BVALID asserted until BREADY is high.
//    - After BVALID && BREADY, clear the pending write state and allow a new write transaction.
// 8. AXI4-Lite read address channel:
//    - ARVALID/ARREADY handshake accepts the read address.
//    - The slave may accept a read address when no read response is currently pending.
//    - ARREADY should be deasserted while RVALID is high and the previous read response has not completed.
// 9. Read data channel:
//    - After accepting ARADDR, assert RVALID.
//    - If ARADDR is 32'h0000_0000, return the internal register value on RDATA.
//    - If ARADDR is unsupported, return 0 on RDATA.
//    - RRESP should return OKAY, encoded as 2'b00.
//    - Keep RVALID asserted until RREADY is high.
// 10. Handshake behavior:
//    - A channel transfer occurs only when VALID && READY are both high on the same clock edge.
//    - VALID must remain asserted by the slave until the corresponding READY is seen.
//    - READY may be combinationally generated from the slave's pending state.
// 11. Write strobe behavior:
//    - WSTRB is provided by the interface.
//    - For this simplified problem, byte strobes may be ignored and the full 32-bit WDATA may be written.
// 12. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for registered state and response signals.
//    - Use continuous assignments for simple READY generation if desired.
//    - The design should be synthesizable.
// 13. Assumptions:
//    - This is a simplified AXI4-Lite slave.
//    - Only one outstanding write transaction needs to be supported.
//    - Only one outstanding read transaction needs to be supported.
//    - No burst support is required.
//    - No exclusive access, protection, cache, or QoS signaling is required.
//    - Unsupported addresses return OKAY with zero read data and ignored writes.
// ============================================================

`default_nettype none

module axi_lite_single_reg (
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
    logic [31:0] reg0;
    logic [31:0] awaddr_reg, wdata_reg;

    logic w_done, aw_done;

    // 这两个assign 第一遍不知道怎么写
    assign AWREADY  = !aw_done;
    assign WREADY = !w_done;
    assign ARREADY = !RVALID;

    // assign w_done = WVALID && WREADY;
    // assign aw_done = AWVALID && AWREADY;

    // 一下的else if 都可以用独立的 if

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            awaddr_reg <= '0;
            aw_done <= 0;
        end else begin
            if (AWREADY && AWVALID) begin
                awaddr_reg <= AWADDR;
                aw_done <= 1;
            end else if (BVALID && BREADY) begin
                aw_done <= 0;
            end
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
            end else if (BVALID && BREADY) begin
                w_done <= 0;
            end
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            reg0 <= '0;
        end else begin
            if (w_done && aw_done && !BVALID) begin
                if (awaddr_reg == '0) reg0 <= wdata_reg;
            end
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            BVALID <= 0;
            BRESP <= '0;
        end else begin
            if (w_done && aw_done && !BVALID) begin
                BVALID <= 1;
                BRESP <= 2'b00;
            end else if (BVALID && BREADY) begin
                BVALID <= 0;
            end
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin

        if (!ARESETn) begin
            RDATA <= '0;
            RVALID <= 0;
            RRESP <= 2'b00;
        end else begin
            if (ARVALID && ARREADY) begin
                RDATA <= (ARADDR == '0) ? reg0 : '0;
                RRESP <= 2'b00;
                RVALID <= 1;
            end else if (RVALID && RREADY) begin
                RVALID <= 0;
            end
        end
    end
endmodule