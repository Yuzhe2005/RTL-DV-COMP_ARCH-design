// ============================================================
// Problem: Sequential Unsigned Divider
// ============================================================
// Design a parameterized sequential unsigned divider.
// Module interface:
// module seq_divider #(
//   parameter WIDTH = 16
// )(
//   input  logic              clk,
//   input  logic              rst_n,
//   input  logic              start,
//   input  logic [WIDTH-1:0]  dividend,
//   input  logic [WIDTH-1:0]  divisor,
//   output logic [WIDTH-1:0]  quotient,
//   output logic [WIDTH-1:0]  remainder,
//   output logic              done,
//   output logic              busy,
//   output logic              div_by_zero
// );
// Requirements:
// 1. Implement a sequential unsigned divider.
// 2. The dividend and divisor are WIDTH-bit unsigned values.
// 3. The divider should produce:
//    - quotient = dividend / divisor
//    - remainder = dividend % divisor
// 4. When start is asserted in IDLE state:
//    - If divisor is zero, immediately report divide-by-zero.
//    - If divisor is nonzero, capture dividend and divisor and start division.
// 5. Divide-by-zero behavior:
//    - div_by_zero should be asserted for one clock cycle.
//    - done should be asserted for one clock cycle.
//    - quotient should be set to all 1s.
//    - remainder should be set to dividend.
//    - The divider should not enter the calculation state.
// 6. Normal division behavior:
//    - Use a sequential restoring division style algorithm.
//    - The divider should process one quotient bit per cycle.
//    - The operation should complete after WIDTH calculation cycles.
// 7. Internal calculation behavior:
//    - Maintain a quotient/dividend shift register.
//    - Maintain a remainder register that is one bit wider than WIDTH.
//    - On each calculation cycle:
//      - Shift the next dividend bit into the remainder.
//      - Shift the quotient register left by one bit.
//      - Compare the shifted remainder with the divisor.
//      - If the remainder is greater than or equal to the divisor,
//        subtract the divisor and set the new quotient bit to 1.
//      - Otherwise, keep the quotient bit as 0.
//      - Increment the cycle counter.
// 8. Completion behavior:
//    - After WIDTH calculation cycles, output the final quotient and remainder.
//    - done should be asserted for one clock cycle.
//    - busy should be deasserted.
//    - The FSM should return to IDLE.
// 9. Busy behavior:
//    - busy should be high while division is actively calculating.
//    - While busy is high, new start requests should not begin a new operation.
// 10. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, the FSM should return to IDLE.
//    - quotient, remainder, done, busy, and div_by_zero should be cleared.
//    - Internal registers should be reset to known values.
// 11. Output pulse behavior:
//    - done should pulse for one clock cycle when the result is valid.
//    - div_by_zero should pulse for one clock cycle only on divide-by-zero.
// 12. Implementation style:
//    - Use SystemVerilog.
//    - Use an FSM with states such as IDLE, CALC, and FIN.
//    - Use sequential logic for state and datapath registers.
//    - The design should be synthesizable.
// 13. Assumptions:
//    - WIDTH is positive.
//    - Division is unsigned.
//    - No signed division support is required.
//    - No early termination optimization is required.
// ============================================================

`default_nettype none

module seq_divider #(
  parameter WIDTH = 16
)(
  input  logic              clk,
  input  logic              rst_n,
  input  logic              start,
  input  logic [WIDTH-1:0]  dividend,
  input  logic [WIDTH-1:0]  divisor,
  output logic [WIDTH-1:0]  quotient,
  output logic [WIDTH-1:0]  remainder,
  output logic              done,
  output logic              busy,
  output logic              div_by_zero
);
    logic [WIDTH-1:0] div_reg, q_reg;
    logic [WIDTH:0] r_reg;

    typedef enum logic [1:0] {IDLE, CALC, FIN} state_t;
    state_t state;

    localparam int CNT_W = $clog2(WIDTH)+1;
    logic [CNT_W-1:0] count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 0;
            busy <= 0;
            div_by_zero <= 0;
            div_reg <= '0;
            q_reg <= '0;
            r_reg <= '0;
            quotient <= '0;
            remainder <= '0;
            state <= IDLE;
            count <= '0; // 第一遍忘了
        end else begin
            div_by_zero <= 0;
            done <= 0; // 第一遍忘了
            case (state)
                IDLE: begin
                    if (start) begin
                        if (divisor == '0) begin
                            div_by_zero <= 1;
                            done <= 1;
                            quotient <= '1;
                            remainder <= dividend;
                        end else begin
                            div_reg <= divisor;
                            q_reg <= dividend;
                            r_reg <= '0;
                            busy <= 1;
                            state <= CALC;
                            count <= '0; // 第一遍忘了
                            done <= 0; // 第一遍忘了
                        end
                    end
                end

                CALC: begin
                    count <= count+1;
                    if ({r_reg[WIDTH-1:0], q_reg[WIDTH-1]} >= div_reg) begin
                        r_reg <= {r_reg[WIDTH-1:0], q_reg[WIDTH-1]}-div_reg;
                        q_reg[0] <= 1;
                    end else begin // 忘了这个else condition了
                        r_reg <= {r_reg[WIDTH-1:0], q_reg[WIDTH-1]};
                        q_reg[0] <= 0;
                    end
                    q_reg[WIDTH-1:1] <= q_reg[WIDTH-2:0];

                    if (count == WIDTH-1) state <= FIN;
                end

                FIN: begin
                    done <= 1;
                    busy <= 0;
                    state <= IDLE;
                    quotient <= q_reg;
                    remainder <= r_reg[WIDTH-1:0]; // 第一遍没注意位宽
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule

//-----------------------------------------------------------------------------------------------

//sample solution:

module seq_divider #(
  parameter WIDTH = 16
)(
  input  logic              clk,
  input  logic              rst_n,
  input  logic              start,
  input  logic [WIDTH-1:0]  dividend,
  input  logic [WIDTH-1:0]  divisor,
  output logic [WIDTH-1:0]  quotient,
  output logic [WIDTH-1:0]  remainder,
  output logic              done,
  output logic              busy,
  output logic              div_by_zero
);
  logic [WIDTH-1:0]        q_reg, div_reg;
  logic [WIDTH:0]          r_reg;
  logic [$clog2(WIDTH):0]  cnt;

  typedef enum logic [1:0] { IDLE, CALC, FIN } st_t;
  st_t st;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st          <= IDLE;
      q_reg       <= '0;
      div_reg     <= '0;
      r_reg       <= '0;
      quotient    <= '0;
      remainder   <= '0;
      cnt         <= '0;
      done        <= 0;
      busy        <= 0;
      div_by_zero <= 0;
    end else begin
      done        <= 0;
      div_by_zero <= 0;

      case (st)
        IDLE: begin
          busy <= 0;
          if (start) begin
            if (divisor == 0) begin
              quotient    <= '1;
              remainder   <= dividend;
              div_by_zero <= 1;
              done        <= 1;
            end else begin
              q_reg   <= dividend;
              div_reg <= divisor;
              r_reg   <= '0;
              cnt     <= '0;
              busy    <= 1;
              st      <= CALC;
            end
          end
        end

        CALC: begin
          logic [WIDTH:0]       r_next;
          logic [WIDTH-1:0]     q_next;

          r_next = {r_reg[WIDTH-1:0], q_reg[WIDTH-1]};
          q_next = {q_reg[WIDTH-2:0], 1'b0};

          if (r_next >= {1'b0, div_reg}) begin
            r_next   = r_next - {1'b0, div_reg};
            q_next[0] = 1'b1;
          end

          r_reg <= r_next;
          q_reg <= q_next;
          cnt   <= cnt + 1;

          if (cnt == WIDTH - 1) begin
            st <= FIN;
          end
        end

        FIN: begin
          quotient  <= q_reg;
          remainder <= r_reg[WIDTH-1:0];
          done      <= 1;
          busy      <= 0;
          st        <= IDLE;
        end
      endcase
    end
  end
endmodule