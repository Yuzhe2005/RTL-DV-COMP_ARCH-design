// ============================================================
// Problem: Sequential Unsigned Divider
// ============================================================
// Design a parameterized multi-cycle unsigned divider.
//
// The module should divide a W-bit unsigned dividend by a W-bit unsigned
// divisor and produce a W-bit quotient and W-bit remainder. The division
// should be performed sequentially over multiple clock cycles, rather
// than using a single-cycle combinational divider.
//
// Module interface:
// module divider #(
//   parameter W = 16
// )(
//   input  logic          clk,
//   input  logic          rst_n,
//   input  logic          start,
//   input  logic [W-1:0]  dividend,
//   input  logic [W-1:0]  divisor,
//   output logic [W-1:0]  quotient,
//   output logic [W-1:0]  remainder,
//   output logic          busy,
//   output logic          done,
//   output logic          div_by_zero
// );
//
// Requirements:
// 1. The module should implement unsigned integer division:
//      quotient  = dividend / divisor
//      remainder = dividend % divisor
//
// 2. The division should start when start is asserted while the module is
//    in the IDLE state.
//
// 3. When start is accepted:
//    - If divisor is 0:
//        - do not enter the calculation state;
//        - assert div_by_zero for one clk cycle;
//        - assert done for one clk cycle;
//        - set quotient to 0;
//        - set remainder to dividend.
//
//    - If divisor is nonzero:
//        - capture dividend into an internal quotient/work register;
//        - capture divisor into an internal divisor register;
//        - clear the internal remainder register;
//        - clear the iteration counter;
//        - enter the calculation state.
//
// 4. The divider should use a sequential restoring-division style algorithm.
//    Each calculation cycle should process one bit of the dividend.
//
// 5. During each calculation cycle:
//    - Shift the current remainder left by 1 bit.
//    - Bring down the next dividend bit from the internal quotient/work
//      register.
//    - Compare the shifted remainder against the divisor.
//    - If the shifted remainder is greater than or equal to the divisor:
//        - subtract the divisor from the shifted remainder;
//        - set the newest quotient bit to 1.
//    - Otherwise:
//        - keep the shifted remainder;
//        - set the newest quotient bit to 0.
//
// 6. The calculation should run for W cycles.
//    - Each cycle determines one quotient bit.
//    - After W bits have been processed, the division is complete.
//
// 7. quotient behavior:
//    - quotient should be W bits wide.
//    - quotient should be updated with the final quotient when the
//      calculation finishes.
//    - quotient may hold its previous value while a new division is in
//      progress.
//
// 8. remainder behavior:
//    - remainder should be W bits wide.
//    - remainder should be updated with the final remainder when the
//      calculation finishes.
//    - remainder may hold its previous value while a new division is in
//      progress.
//
// 9. busy behavior:
//    - busy should be asserted while the divider is actively calculating.
//    - busy should be deasserted in IDLE and when the calculation has
//      finished.
//
// 10. done behavior:
//    - done should be a one-cycle pulse when the output quotient/remainder
//      are valid.
//    - For divide-by-zero, done should also pulse for one cycle immediately
//      when the error is detected.
//    - done should be 0 in all other cycles.
//
// 11. div_by_zero behavior:
//    - div_by_zero should assert for one clk cycle if start is accepted
//      and divisor is 0.
//    - div_by_zero should be 0 in normal division cycles.
//
// 12. start behavior:
//    - start should only be accepted in IDLE.
//    - If start is asserted while the divider is busy, it does not need to
//      start a new division.
//    - dividend and divisor only need to be sampled when start is accepted.
//
// 13. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low:
//        - return the FSM to IDLE;
//        - clear internal quotient/work register;
//        - clear internal divisor register;
//        - clear internal remainder register;
//        - clear the iteration counter;
//        - clear quotient;
//        - clear remainder;
//        - deassert busy;
//        - deassert done;
//        - deassert div_by_zero.
//
// 14. Suggested FSM states:
//    - IDLE: wait for start.
//    - CALC: perform W cycles of restoring division.
//    - FIN: update quotient and remainder, pulse done, and return to IDLE.
//
// 15. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use nonblocking assignments for registered state.
//    - Use an FSM to control the divider.
//    - Temporary variables may be used inside the calculation state to
//      compute the next remainder and quotient values.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 16. Assumptions:
//    - W is at least 1.
//    - dividend and divisor are unsigned values.
//    - Only one division operation is handled at a time.
//    - The module does not need to support signed division.
// ============================================================

`default_nettype none

module divider #(
  parameter W = 16
)(
  input  logic          clk,
  input  logic          rst_n,
  input  logic          start,
  input  logic [W-1:0]  dividend,
  input  logic [W-1:0]  divisor,
  output logic [W-1:0]  quotient,
  output logic [W-1:0]  remainder,
  output logic          busy,
  output logic          done,
  output logic          div_by_zero
);
    logic [W-1:0] divisor_reg;
    logic [W-1:0] dividend_reg;
    logic [W-1:0] quotient_reg;
    logic [W:0] remainder_reg;
    
    localparam int CNT_W = $clog2(W);
    logic [CNT_W-1:0] count;

    typedef enum logic [1:0] {IDLE, CALC, FIN} state_t;
    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= '0;
            remainder <= '0;
            quotient_reg <= '0;
            remainder_reg <= '0;
            busy <= 0;
            done <= 0;
            div_by_zero <= 0;
            state <= IDLE;
            divisor_reg <= '0;
            dividend_reg <= '0;
            count <= '0;
        end else begin
            // busy <= 0; // 错了
            done <= 0;
            div_by_zero <= 0;
            case (state)
                IDLE: begin
                    if (start) begin
                        if (divisor == '0) begin
                            div_by_zero <= 1;
                            quotient <= '0;
                            remainder <= dividend;
                            done <= 1;
                        end else begin
                            quotient_reg <= '0;
                            remainder_reg <= '0;
                            divisor_reg <= divisor;
                            dividend_reg <= dividend;
                            busy <= 1;
                            state <= CALC;
                            count <= '0;
                        end
                    end
                end

                CALC: begin
                    count <= count+1;
                    if ({remainder_reg[W-1:0], dividend_reg[W-1]} >= divisor_reg) begin
                        remainder_reg <= {remainder_reg[W-1:0], dividend_reg[W-1]}-divisor_reg;
                        quotient_reg <= {quotient_reg[W-2:0], 1'b1};
                    end else begin
                        quotient_reg <= {quotient_reg[W-2:0], 1'b0};
                        remainder_reg <= {remainder_reg[W-1:0], dividend_reg[W-1]};
                    end
                    dividend_reg <= dividend_reg << 1;

                    if (count == W-1) state <= FIN;
                end

                FIN: begin
                    quotient <= quotient_reg;
                    remainder <= remainder_reg[W-1:0];
                    state <= IDLE;
                    done <= 1;
                    busy <= 0;
                end

                default: state <= IDLE;
            endcase
        end
    end                  
endmodule

// -----------------------------------------------------------------------------

// sample solution:

module divider #(
  parameter W = 16
)(
  input  logic          clk,
  input  logic          rst_n,
  input  logic          start,
  input  logic [W-1:0]  dividend,
  input  logic [W-1:0]  divisor,
  output logic [W-1:0]  quotient,
  output logic [W-1:0]  remainder,
  output logic          busy,
  output logic          done,
  output logic          div_by_zero
);
  logic [W-1:0]       q, d;
  logic [W:0]         r;
  logic [$clog2(W):0] cnt;

  typedef enum logic [1:0] { IDLE, CALC, FIN } st_t;
  st_t st;

  assign busy = (st == CALC);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st          <= IDLE;
      q           <= '0;
      d           <= '0;
      r           <= '0;
      cnt         <= '0;
      quotient    <= '0;
      remainder   <= '0;
      done        <= 1'b0;
      div_by_zero <= 1'b0;
    end else begin
      done        <= 1'b0;
      div_by_zero <= 1'b0;
      case (st)
        IDLE: begin
          if (start) begin
            if (divisor == '0) begin
              quotient    <= '0;
              remainder   <= dividend;
              div_by_zero <= 1'b1;
              done        <= 1'b1;
            end else begin
              q   <= dividend;
              d   <= divisor;
              r   <= '0;
              cnt <= '0;
              st  <= CALC;
            end
          end
        end
        CALC: begin
          logic [W:0]   r_shift;
          logic [W:0]   r_next;
          logic [W-1:0] q_next;
          r_shift = {r[W-1:0], q[W-1]};
          q_next  = {q[W-2:0], 1'b0};
          r_next  = r_shift;
          if (r_shift >= {1'b0, d}) begin
            r_next    = r_shift - {1'b0, d};
            q_next[0] = 1'b1;
          end
          r   <= r_next;
          q   <= q_next;
          cnt <= cnt + 1'b1;
          if (cnt == W-1) st <= FIN;
        end
        FIN: begin
          quotient  <= q;
          remainder <= r[W-1:0];
          done      <= 1'b1;
          st        <= IDLE;
        end
      endcase
    end
  end
endmodule