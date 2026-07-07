// ============================================================
// Problem: AXI4-Lite GPIO Peripheral
// ============================================================
// Design a simple AXI4-Lite slave peripheral that exposes GPIO
// input and output registers through a memory-mapped interface.
// Module interface:
// module axi_gpio #(
//   parameter GPIO_WIDTH = 32
// )(
//   input  logic                    ACLK,
//   input  logic                    ARESETn,
//   input  logic                    AWVALID,
//   output logic                    AWREADY,
//   input  logic [31:0]             AWADDR,
//   input  logic                    WVALID,
//   output logic                    WREADY,
//   input  logic [GPIO_WIDTH-1:0]   WDATA,
//   input  logic [3:0]              WSTRB,
//   output logic                    BVALID,
//   input  logic                    BREADY,
//   output logic [1:0]              BRESP,
//   input  logic                    ARVALID,
//   output logic                    ARREADY,
//   input  logic [31:0]             ARADDR,
//   output logic                    RVALID,
//   input  logic                    RREADY,
//   output logic [GPIO_WIDTH-1:0]   RDATA,
//   output logic [1:0]              RRESP,
//   input  logic [GPIO_WIDTH-1:0]   gpio_in,
//   output logic [GPIO_WIDTH-1:0]   gpio_out
// );
// Requirements:
// 1. Implement an AXI4-Lite slave GPIO peripheral.
// 2. The peripheral should contain two memory-mapped addresses:
//    - address 32'h0000_0000: GPIO output register
//    - address 32'h0000_0004: GPIO input register
// 3. GPIO output register behavior:
//    - The output register drives gpio_out.
//    - On reset, gpio_out should be cleared to 0.
//    - A valid AXI-Lite write to address 32'h0000_0000 should update gpio_out.
//    - A read from address 32'h0000_0000 should return the current gpio_out value.
// 4. GPIO input register behavior:
//    - gpio_in is an external input signal.
//    - A read from address 32'h0000_0004 should return the current gpio_in value.
//    - Writes to address 32'h0000_0004 should not modify gpio_out.
//    - A write to the input register should return SLVERR on the write response.
// 5. AXI4-Lite write address channel:
//    - AWVALID/AWREADY handshake accepts the write address.
//    - When AWVALID && AWREADY is true, latch AWADDR.
//    - The slave should not accept another write address while one is pending.
// 6. AXI4-Lite write data channel:
//    - WVALID/WREADY handshake accepts the write data.
//    - When WVALID && WREADY is true, latch WDATA.
//    - The slave should not accept another write data beat while one is pending.
// 7. Write operation behavior:
//    - The AXI-Lite write address and write data channels are independent.
//    - AWADDR may arrive before WDATA, or WDATA may arrive before AWADDR.
//    - The GPIO output register should update only after both AW and W have been accepted.
//    - If the latched write address is 32'h0000_0000, update gpio_out with WDATA.
//    - If the latched write address is 32'h0000_0004, do not update gpio_out.
//    - WSTRB is provided but may be ignored in this simplified design.
// 8. Write response channel:
//    - After both write address and write data have been received, assert BVALID.
//    - BRESP should be 2'b00 OKAY for a valid GPIO output write.
//    - BRESP should be 2'b10 SLVERR for a write to the GPIO input register.
//    - Keep BVALID asserted until BREADY is high.
//    - After BVALID && BREADY, clear the pending write state.
// 9. AXI4-Lite read address channel:
//    - ARVALID/ARREADY handshake accepts the read address.
//    - The slave may accept a read address only when no read response is pending.
//    - ARREADY should be deasserted while RVALID is high.
// 10. Read data channel:
//    - After accepting ARADDR, assert RVALID.
//    - If ARADDR is 32'h0000_0000, return gpio_out on RDATA.
//    - If ARADDR is 32'h0000_0004, return gpio_in on RDATA.
//    - If ARADDR is unsupported, return 0 on RDATA and return SLVERR.
//    - RRESP should be 2'b00 OKAY for supported addresses.
//    - RRESP should be 2'b10 SLVERR for unsupported read addresses.
//    - Keep RVALID asserted until RREADY is high.
// 11. Reset behavior:
//    - ARESETn is an active-low asynchronous reset.
//    - On reset, gpio_out should be cleared to 0.
//    - BVALID and RVALID should be cleared.
//    - BRESP and RRESP should be cleared to OKAY.
//    - Latched write address/data state should be cleared.
// 12. Handshake behavior:
//    - A channel transfer occurs only when VALID && READY are both high
//      on the same rising edge of ACLK.
//    - Slave VALID signals should remain asserted until the corresponding
//      READY signal is high.
//    - READY signals may be generated from internal pending-state flags.
// 13. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for registered state, GPIO output, and response signals.
//    - Use continuous assignments for simple READY generation.
//    - The design should be synthesizable.
// 14. Assumptions:
//    - This is a simplified AXI4-Lite slave.
//    - Only one outstanding write transaction needs to be supported.
//    - Only one outstanding read transaction needs to be supported.
//    - No burst support is required.
//    - No protection, cache, QoS, or exclusive access signaling is required.
// ============================================================

`default_nettype none

module axi_gpio #(
  parameter GPIO_WIDTH = 32
)(
  input  logic                    ACLK,
  input  logic                    ARESETn,
  input  logic                    AWVALID,
  output logic                    AWREADY,
  input  logic [31:0]             AWADDR,
  input  logic                    WVALID,
  output logic                    WREADY,
  input  logic [GPIO_WIDTH-1:0]   WDATA,
  input  logic [3:0]              WSTRB,
  output logic                    BVALID,
  input  logic                    BREADY,
  output logic [1:0]              BRESP,
  input  logic                    ARVALID,
  output logic                    ARREADY,
  input  logic [31:0]             ARADDR,
  output logic                    RVALID,
  input  logic                    RREADY,
  output logic [GPIO_WIDTH-1:0]   RDATA,
  output logic [1:0]              RRESP,
  input  logic [GPIO_WIDTH-1:0]   gpio_in,
  output logic [GPIO_WIDTH-1:0]   gpio_out
); 
    logic w_done, aw_done;
    // logic [GPIO_WIDTH-1:0] awaddr_reg, wdata_reg;

    logic [31:0] awaddr_reg;
    logic [GPIO_WIDTH-1:0] wdata_reg;

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
            gpio_out <= '0;
        end else begin
            if (w_done && aw_done && !BVALID) begin
                if (awaddr_reg == 32'h00)
                    gpio_out <= wdata_reg;
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
                if (awaddr_reg == 32'h04)
                    BRESP <= 2'b10;
                else
                    BRESP <= 2'b00;
            end
            if (BVALID && BREADY) 
                BVALID <= 0;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RVALID <= 0;
            RDATA <= '0;
            RRESP <= 2'b00;
        end else begin
            if (ARREADY && ARVALID) begin
                RVALID <= 1;
                if (ARADDR == 32'h00) begin
                    RDATA <= gpio_out;
                    RRESP <= 2'b00;
                end else if (ARADDR == 32'h04) begin
                    RDATA <= gpio_in;
                    RRESP <= 2'b00;
                end else begin
                    RRESP <= 2'b10;
                    RDATA <= '0;
                end
            end
            if (RVALID && RREADY)
                RVALID <= 0;
        end
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:

module axi_gpio #(
  parameter GPIO_WIDTH = 32
)(
  input  logic                    ACLK,
  input  logic                    ARESETn,
  // AXI-Lite write
  input  logic                    AWVALID, output logic AWREADY,
  input  logic [31:0]             AWADDR,
  input  logic                    WVALID,  output logic WREADY,
  input  logic [GPIO_WIDTH-1:0]   WDATA,
  input  logic [3:0]              WSTRB,
  output logic                    BVALID,  input  logic BREADY,
  output logic [1:0]              BRESP,
  // AXI-Lite read
  input  logic                    ARVALID, output logic ARREADY,
  input  logic [31:0]             ARADDR,
  output logic                    RVALID,  input  logic RREADY,
  output logic [GPIO_WIDTH-1:0]   RDATA,
  output logic [1:0]              RRESP,
  // GPIO
  input  logic [GPIO_WIDTH-1:0]   gpio_in,
  output logic [GPIO_WIDTH-1:0]   gpio_out
);
  localparam ADDR_OUT = 32'h00;
  localparam ADDR_IN  = 32'h04;

  logic aw_done, w_done;
  logic [31:0] aw_addr_lat;
  logic [GPIO_WIDTH-1:0] w_data_lat;
  logic write_err;

  assign AWREADY = !aw_done;
  assign WREADY  = !w_done;
  assign ARREADY = !RVALID;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      aw_done <= 0; aw_addr_lat <= '0;
    end else begin
      if (AWVALID && AWREADY) begin aw_done <= 1; aw_addr_lat <= AWADDR; end
      if (BVALID && BREADY)   aw_done <= 0;
    end
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      w_done <= 0; w_data_lat <= '0;
    end else begin
      if (WVALID && WREADY) begin w_done <= 1; w_data_lat <= WDATA; end
      if (BVALID && BREADY)  w_done <= 0;
    end
  end

  assign write_err = aw_done && (aw_addr_lat == ADDR_IN);

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      gpio_out <= '0;
    end else if (aw_done && w_done && !BVALID) begin
      if (aw_addr_lat == ADDR_OUT) gpio_out <= w_data_lat;
    end
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      BVALID <= 0; BRESP <= 2'b00;
    end else begin
      if (aw_done && w_done && !BVALID) begin
        BVALID <= 1;
        BRESP  <= write_err ? 2'b10 : 2'b00;   // SLVERR or OKAY
      end else if (BVALID && BREADY) begin
        BVALID <= 0;
      end
    end
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      RVALID <= 0; RDATA <= '0; RRESP <= 2'b00;
    end else begin
      if (ARVALID && ARREADY) begin
        RVALID <= 1;
        case (ARADDR)
          ADDR_OUT: begin RDATA <= gpio_out; RRESP <= 2'b00; end
          ADDR_IN:  begin RDATA <= gpio_in;  RRESP <= 2'b00; end
          default:  begin RDATA <= '0;       RRESP <= 2'b10; end
        endcase
      end else if (RVALID && RREADY) begin
        RVALID <= 0;
      end
    end
  end
endmodule