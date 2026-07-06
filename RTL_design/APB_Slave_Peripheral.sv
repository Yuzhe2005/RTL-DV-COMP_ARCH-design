// ============================================================
// Problem: Simple Zero-Wait-State APB Slave
// ============================================================
// Design a parameterized APB slave with a small memory-mapped register map.
// Module interface:
// module apb_slave #(
//   parameter DATA_WIDTH = 32,
//   parameter ADDR_WIDTH = 8
// )(
//   input  logic                      PCLK,
//   input  logic                      PRESETn,
//   input  logic                      PSEL,
//   input  logic                      PENABLE,
//   input  logic                      PWRITE,
//   input  logic [ADDR_WIDTH-1:0]     PADDR,
//   input  logic [DATA_WIDTH-1:0]     PWDATA,
//   output logic [DATA_WIDTH-1:0]     PRDATA,
//   output logic                      PREADY,
//   output logic                      PSLVERR
// );
// Requirements:
// 1. Implement a simple APB slave peripheral.
// 2. The slave should support zero-wait-state APB transfers.
//    - PREADY should always be 1.
//    - A transfer completes when PSEL && PENABLE && PREADY is true.
// 3. The slave should support three memory-mapped addresses:
//    - address 8'h00: REG0
//    - address 8'h04: REG1
//    - address 8'h08: REG2
// 4. REG0 behavior:
//    - REG0 should be writable.
//    - On a valid APB write transfer to address 8'h00, store PWDATA into REG0.
//    - On a read from address 8'h00, return the current REG0 value.
// 5. REG1 behavior:
//    - REG1 should behave as a read-only register.
//    - Reads from address 8'h04 should return a fixed constant value.
//    - Writes to address 8'h04 should not modify any writable state.
// 6. REG2 behavior:
//    - REG2 should behave as a read-only register.
//    - Reads from address 8'h08 should return a fixed constant value.
//    - Writes to address 8'h08 should not modify any writable state.
// 7. Invalid address behavior:
//    - Any address other than 8'h00, 8'h04, or 8'h08 is invalid.
//    - During an APB access phase to an invalid address,
//      PSLVERR should be asserted.
//    - Reads from invalid addresses should return 0.
//    - Writes to invalid addresses should be ignored.
// 8. APB write behavior:
//    - A write should only occur during the APB access phase.
//    - The write condition should be PSEL && PENABLE && PREADY && PWRITE.
//    - Only REG0 should update on a valid write.
// 9. APB read behavior:
//    - PRDATA should be decoded combinationally based on PADDR.
//    - During a read, PRDATA should return the selected register value.
//    - During a write, PRDATA may return 0.
// 10. Reset behavior:
//    - PRESETn is an active-low asynchronous reset.
//    - On reset, REG0 should be cleared to 0.
//    - Read-only constant registers do not need storage.
// 11. Error behavior:
//    - PSLVERR should indicate an invalid APB access.
//    - PSLVERR should be high only when PSEL && PENABLE is high
//      and PADDR is not one of the supported addresses.
// 12. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for writable registers.
//    - Use always_comb for read-data decode.
//    - Use continuous assignment for PREADY and simple error decode.
//    - The design should be synthesizable.
// 13. Assumptions:
//    - This is an APB-style zero-wait-state slave.
//    - No byte strobes are required.
//    - No wait-state insertion is required.
//    - No side-effect read behavior is required.
//    - REG1 and REG2 are fixed read-only demo registers.
// ============================================================

`default_nettype none

module apb_slave #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 8
)(
  input  logic                      PCLK,
  input  logic                      PRESETn,
  input  logic                      PSEL,
  input  logic                      PENABLE,
  input  logic                      PWRITE,
  input  logic [ADDR_WIDTH-1:0]     PADDR,
  input  logic [DATA_WIDTH-1:0]     PWDATA,
  output logic [DATA_WIDTH-1:0]     PRDATA,
  output logic                      PREADY,
  output logic                      PSLVERR
);
    localparam logic [7:0] REG0 = 8'h00;
    localparam logic [7:0] REG1 = 8'h04;
    localparam logic [7:0] REG2 = 8'h08;

    assign PREADY = 1;
    logic valid_addr;
    assign valid_addr = (PADDR == REG0) || (PADDR == REG1) || (PADDR == REG2);

    logic valid_transaction;
    assign valid_transaction = PSEL && PENABLE && PREADY && valid_addr;

    assign PSLVERR = PSEL && PENABLE && !valid_addr; // 第一遍忘了

    logic [DATA_WIDTH-1:0] reg0;

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            reg0 <= '0;
        end else begin
            if (PWRITE && valid_transaction) begin
                case (PADDR)
                    REG0: reg0 <= PWDATA;
                    default: ;
                endcase
            end
        end
    end

    always_comb begin
        PRDATA = '0;
        if (!PWRITE) begin
            case (PADDR)
                REG0: PRDATA = reg0;
                REG1: PRDATA = 32'hDEAD_C0DE;
                REG2: PRDATA = 32'hCAFE_BABE;
                default: PRDATA = 0;
            endcase
        end
    end
endmodule

//--------------------------------------------------------------------------

// sample solution:

module apb_slave #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 8
)(
  input  logic                      PCLK,
  input  logic                      PRESETn,
  // APB signals
  input  logic                      PSEL,
  input  logic                      PENABLE,
  input  logic                      PWRITE,
  input  logic [ADDR_WIDTH-1:0]     PADDR,
  input  logic [DATA_WIDTH-1:0]     PWDATA,
  output logic [DATA_WIDTH-1:0]     PRDATA,
  output logic                      PREADY,
  output logic                      PSLVERR
);
  localparam ADDR_REG0 = 8'h00;
  localparam ADDR_REG1 = 8'h04;
  localparam ADDR_REG2 = 8'h08;

  logic [DATA_WIDTH-1:0] reg0;
  logic [DATA_WIDTH-1:0] reg1;   // Read-only (hardcoded for demo)
  logic                   addr_valid;

  assign addr_valid = (PADDR == ADDR_REG0) || (PADDR == ADDR_REG1) || (PADDR == ADDR_REG2);

  // Zero-wait-state: always ready
  assign PREADY  = 1'b1;
  assign PSLVERR = PSEL && PENABLE && !addr_valid;

  // Transfer complete condition: PSEL && PENABLE && PREADY
  // Write
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      reg0 <= '0;
    end else if (PSEL && PENABLE && PREADY && PWRITE) begin
      case (PADDR)
        ADDR_REG0: reg0 <= PWDATA;
        default: ;
      endcase
    end
  end

  // Read (combinational)
  always_comb begin
    PRDATA = '0;
    if (!PWRITE) begin
      case (PADDR)
        ADDR_REG0: PRDATA = reg0;
        ADDR_REG1: PRDATA = 32'hDEAD_C0DE;   // Hardcoded read-only
        ADDR_REG2: PRDATA = 32'hCAFE_BABE;
        default:   PRDATA = '0;
      endcase
    end
  end
endmodule