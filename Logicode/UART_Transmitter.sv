// ============================================================
// Problem: UART Transmitter
// ============================================================
// Design a parameterized UART transmit module.
//
// The module should serialize parallel input data into a UART TX waveform.
// A UART frame consists of:
//   - idle line high;
//   - one start bit, low;
//   - DATA_BITS data bits, transmitted LSB first;
//   - optional parity bit;
//   - one or two stop bits, high.
//
// Module interface:
// module uart_tx #(
//   parameter CLK_FREQ  = 50_000_000,
//   parameter BAUD_RATE = 115_200,
//   parameter DATA_BITS = 8,
//   parameter PARITY_EN = 0,
//   parameter STOP_BITS = 1
// )(
//   input  logic                 clk,
//   input  logic                 resetn,
//   input  logic                 tx_start,
//   input  logic [DATA_BITS-1:0] tx_data,
//   output logic                 tx,
//   output logic                 tx_busy
// );
//
// Requirements:
// 1. UART frame format:
//    - When idle, tx should stay high.
//    - When transmission starts, output one start bit:
//        tx = 0
//    - Then transmit DATA_BITS data bits, LSB first:
//        tx = tx_data[0], then tx_data[1], ..., tx_data[DATA_BITS-1]
//    - If parity is enabled, transmit one parity bit after the data bits.
//    - Then transmit STOP_BITS stop bits:
//        tx = 1
//
// 2. Baud timing:
//    - Define:
//
//        CLKS_PER_BIT = CLK_FREQ / BAUD_RATE
//
//    - Each UART bit should be held on tx for exactly CLKS_PER_BIT clock cycles.
//    - This applies to:
//        - start bit;
//        - each data bit;
//        - optional parity bit;
//        - each stop bit.
//
// 3. Start behavior:
//    - The transmitter should begin a new frame only when:
//        tx_start == 1
//        and the transmitter is in IDLE.
//    - On start, latch tx_data into an internal shift register.
//    - Ignore new tx_start requests while tx_busy is high.
//
// 4. Busy behavior:
//    - tx_busy should be 0 in IDLE.
//    - tx_busy should become 1 once a transmission starts.
//    - tx_busy should remain 1 during START, DATA, optional PARITY, and STOP.
//    - tx_busy should return to 0 after all stop bits are transmitted.
//
// 5. Data shifting behavior:
//    - Data should be transmitted LSB first.
//    - During each DATA bit period, tx should output the current LSB of the
//      shift register.
//    - After one bit period completes, shift the register right by one bit.
//    - Increment the data bit counter after each transmitted data bit.
//    - After DATA_BITS bits have been transmitted, go to PARITY if enabled,
//      otherwise go directly to STOP.
//
// 6. Parity behavior:
//    - PARITY_EN controls parity generation:
//        PARITY_EN == 0: no parity bit;
//        PARITY_EN == 1: even parity;
//        PARITY_EN == 2: odd parity.
//
//    - For even parity:
//        parity_bit = ^tx_data
//
//      This makes the total number of 1s in data plus parity even.
//
//    - For odd parity:
//        parity_bit = ~(^tx_data)
//
//      This makes the total number of 1s in data plus parity odd.
//
//    - The parity bit should be computed from the latched tx_data at the start
//      of the frame.
//
// 7. Stop bit behavior:
//    - During STOP, tx should be high.
//    - If STOP_BITS == 1, hold tx high for one bit period.
//    - If STOP_BITS == 2, hold tx high for two bit periods.
//    - After the stop period completes, return to IDLE.
//
// 8. FSM behavior:
//    - Implement the transmitter using an FSM with states similar to:
//        IDLE
//        START
//        DATA
//        PARITY
//        STOP
//
//    - IDLE:
//        tx = 1
//        tx_busy = 0
//        wait for tx_start
//
//    - START:
//        tx = 0
//        hold for one bit period
//
//    - DATA:
//        tx = current data bit
//        transmit DATA_BITS bits, LSB first
//
//    - PARITY:
//        tx = parity_bit
//        hold for one bit period
//
//    - STOP:
//        tx = 1
//        hold for STOP_BITS bit periods
//
// 9. Reset behavior:
//    - resetn is active-low.
//    - On reset:
//        state should return to IDLE;
//        tx should be 1;
//        tx_busy should be 0;
//        counters should clear;
//        shift register should clear;
//        parity bit should clear.
//
// 10. Timing behavior:
//    - The design should be synchronous to clk.
//    - State transitions, counters, shift register, tx, and tx_busy should
//      update on the rising edge of clk.
//    - There should be no combinational output glitches on tx.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use a baud counter to count clock cycles within each UART bit.
//    - Use a bit counter to count transmitted data bits.
//    - The baud counter should be wide enough to count up to
//      STOP_BITS * CLKS_PER_BIT - 1.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 12. Assumptions:
//    - CLK_FREQ is greater than BAUD_RATE.
//    - CLK_FREQ / BAUD_RATE is an integer or acceptable integer approximation.
//    - DATA_BITS is at least 1.
//    - PARITY_EN is 0, 1, or 2.
//    - STOP_BITS is 1 or 2.
// ============================================================

`default_nettype none

module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200,
    parameter DATA_BITS = 8,
    parameter PARITY_EN = 0,   // 0=none, 1=even parity, 2=odd parity
    parameter STOP_BITS = 1    // 1 or 2
) (
    input  logic                  clk,
    input  logic                  resetn,
    input  logic                  tx_start,
    input  logic [DATA_BITS-1:0]  tx_data,
    output logic                  tx,
    output logic                  tx_busy
);

  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

  // FSM states
  localparam [2:0]
    IDLE   = 3'd0,
    START  = 3'd1,
    DATA   = 3'd2,
    PARITY = 3'd3,
    STOP   = 3'd4;

  logic [2:0]                  state;
  logic [$clog2(CLKS_PER_BIT)-1:0] baud_cnt;
  logic [$clog2(DATA_BITS)-1:0]    bit_cnt;
  logic [DATA_BITS-1:0]        shift_reg;
  logic                        parity_bit;

  always_ff @(posedge clk) begin
    if (!resetn) begin
      state     <= IDLE;
      baud_cnt  <= '0;
      bit_cnt   <= '0;
      shift_reg <= '0;
      parity_bit <= 1'b0;
      tx        <= 1'b1;
      tx_busy   <= 1'b0;
    end else begin
      case (state)

        IDLE: begin
          tx      <= 1'b1; // assert high when no sending
          tx_busy <= 1'b0;
          if (tx_start) begin
            shift_reg  <= tx_data;
            // Compute parity from latched data
            if (PARITY_EN == 1)
              parity_bit <= ^tx_data;       // even parity
            else if (PARITY_EN == 2)
              parity_bit <= ~^tx_data;      // odd parity
            else
              parity_bit <= 1'b0;
            baud_cnt   <= '0;
            bit_cnt    <= '0;
            tx_busy    <= 1'b1;
            state      <= START;
          end
        end

        START: begin
          tx <= 1'b0;
          if (baud_cnt == CLKS_PER_BIT - 1) begin
            baud_cnt <= '0;
            state    <= DATA;
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        DATA: begin
          tx <= shift_reg[0];
          if (baud_cnt == CLKS_PER_BIT - 1) begin
            baud_cnt  <= '0;
            shift_reg <= shift_reg >> 1;
            if (bit_cnt == DATA_BITS - 1) begin
              bit_cnt <= '0;
              if (PARITY_EN != 0)
                state <= PARITY;
              else
                state <= STOP;
            end else begin
              bit_cnt <= bit_cnt + 1'b1;
            end
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        PARITY: begin
          tx <= parity_bit;
          if (baud_cnt == CLKS_PER_BIT - 1) begin
            baud_cnt <= '0;
            state    <= STOP;
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        STOP: begin
          tx <= 1'b1;
          if (baud_cnt == (STOP_BITS * CLKS_PER_BIT) - 1) begin
            baud_cnt <= '0;
            tx_busy  <= 1'b0;
            state    <= IDLE;
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        default: begin
          state    <= IDLE;
          tx       <= 1'b1;
          tx_busy  <= 1'b0;
          baud_cnt <= '0;
          bit_cnt  <= '0;
        end

      endcase
    end
  end

endmodule