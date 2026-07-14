// ============================================================
// Problem: Sequential Shift-Add Multiplier
// ============================================================
// Design a parameterized multi-cycle unsigned multiplier.
//
// The module should multiply two W-bit unsigned operands a and b and
// produce a 2W-bit product. The multiplication should be performed
// sequentially over multiple clock cycles using a shift-and-add algorithm,
// rather than using a single-cycle combinational multiplier.
//
// Module interface:
// module multiplier #(
//   parameter W = 16
// )(
//   input  logic            clk,
//   input  logic            rst_n,
//   input  logic            start,
//   input  logic [W-1:0]    a,
//   input  logic [W-1:0]    b,
//   output logic [2*W-1:0]  product,
//   output logic            busy,
//   output logic            done
// );
//
// Requirements:
// 1. The module should implement unsigned multiplication:
//      product = a * b
//
// 2. The multiplication should start when start is asserted while the
//    module is in the IDLE state.
//
// 3. When start is accepted:
//    - capture input operand a into an internal shift register;
//    - capture input operand b into an internal shifted version;
//    - clear the accumulator;
//    - clear the iteration counter;
//    - enter the calculation state.
//
// 4. The multiplier should use the shift-add algorithm:
//    - Check the least significant bit of the current a shift register.
//    - If that bit is 1, add the current shifted b value into the
//      accumulator.
//    - Shift a right by 1 bit.
//    - Shift b left by 1 bit.
//    - Increment the counter.
//
// 5. The calculation should run for W cycles.
//    - Each cycle processes one bit of operand a.
//    - After W bits have been processed, the multiplication is complete.
//
// 6. product behavior:
//    - product should be 2W bits wide.
//    - product should be updated with the final accumulated value when
//      the multiplication finishes.
//    - product may hold its previous value while a new multiplication is
//      still in progress.
//
// 7. busy behavior:
//    - busy should be asserted while the multiplier is actively calculating.
//    - busy should be deasserted in IDLE and after the calculation finishes.
//
// 8. done behavior:
//    - done should be a one-cycle pulse when the final product becomes
//      available.
//    - done should be cleared in all other cycles.
//
// 9. start behavior:
//    - start should only be accepted in IDLE.
//    - If start is asserted while the multiplier is busy, it does not need
//      to start a new multiplication.
//    - The inputs a and b only need to be sampled when start is accepted.
//
// 10. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low:
//        - return the FSM to IDLE;
//        - clear product;
//        - clear done;
//        - clear internal accumulator;
//        - clear shifted operands;
//        - clear the counter.
//
// 11. Suggested FSM states:
//    - IDLE: wait for start.
//    - CALC: perform W cycles of shift-add multiplication.
//    - FIN: write final product, pulse done, and return to IDLE.
//
// 12. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - Use nonblocking assignments for registers.
//    - Use an FSM to control the multiplier.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 13. Assumptions:
//    - W is at least 1.
//    - a and b are unsigned operands.
//    - Only one multiplication is handled at a time.
// ============================================================

`default_nettype none

module multiplier #(
  parameter W = 16
)(
  input  logic            clk,
  input  logic            rst_n,
  input  logic            start,
  input  logic [W-1:0]    a,
  input  logic [W-1:0]    b,
  output logic [2*W-1:0]  product,
  output logic            busy,
  output logic            done
);
    logic [2*W-1:0] b_shifted, acc;
    logic [W-1:0] a_shifted;

    localparam int CNT_W = $clog2(W);
    logic [CNT_W-1:0] count;

    typedef enum logic [1:0] {IDLE, CALC, FIN} state_t;
    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            b_shifted <= '0;
            acc <= '0;
            a_shifted <= '0;
            busy <= 0;
            done <= 0;
            product <= '0;
            count <= '0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        b_shifted <= {{W{1'b0}}, b};
                        a_shifted <= a;
                        busy <= 1;
                        count <= '0;
                        state <= CALC;
                        acc <= '0; // 第一遍忘了
                    end
                end

                CALC: begin
                    count <= count+1;
                    state <= (count == W-1) ? FIN : CALC;
                    b_shifted <= b_shifted << 1;
                    acc <= (a_shifted[0]) ? acc+b_shifted : acc;
                    a_shifted <= a_shifted >> 1;
                end

                FIN: begin
                    done <= 1;
                    busy <= 0;
                    product <= acc;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule