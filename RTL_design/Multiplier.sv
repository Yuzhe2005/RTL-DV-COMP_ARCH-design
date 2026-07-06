// ============================================================
// Problem: Sequential Shift-and-Add Multiplier
// ============================================================
// Design a parameterized sequential unsigned multiplier.
// Module interface:
// module seq_multiplier #(
//   parameter WIDTH = 16
// )(
//   input  logic              clk,
//   input  logic              rst_n,
//   input  logic              start,
//   input  logic [WIDTH-1:0]  a,
//   input  logic [WIDTH-1:0]  b,
//   output logic [2*WIDTH-1:0] product,
//   output logic              done,
//   output logic              busy
// );
// Requirements:
// 1. Implement a sequential shift-and-add multiplier.
// 2. The operands a and b are WIDTH-bit unsigned values.
// 3. The product output should be 2*WIDTH bits wide.
// 4. When start is asserted in IDLE state:
//    - Capture input operand a.
//    - Capture input operand b.
//    - Clear the accumulator.
//    - Start the multiplication operation.
//    - Assert busy.
// 5. The multiplier should compute the product over multiple clock cycles.
// 6. In each calculation cycle:
//    - Check the current LSB of the multiplier operand.
//    - If the bit is 1, add the shifted multiplicand into the accumulator.
//    - Shift the multiplier operand right by 1.
//    - Shift the multiplicand operand left by 1.
//    - Increment the cycle counter.
// 7. After WIDTH calculation cycles:
//    - Store the final multiplication result into product.
//    - Assert done for one clock cycle.
//    - Deassert busy.
//    - Return to IDLE state.
// 8. While busy is asserted, new start requests should not begin a new operation.
// 9. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, the FSM should return to IDLE.
//    - done and busy should be cleared.
//    - product should be cleared.
// 10. Output behavior:
//    - busy should be high while the multiplier is actively calculating.
//    - done should be a one-cycle pulse when product becomes valid.
//    - product should hold the completed multiplication result.
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use an FSM with states such as IDLE, CALC, and FIN.
//    - Use sequential logic for state and datapath registers.
//    - The design should be synthesizable.
// 12. Assumptions:
//    - WIDTH is positive.
//    - Multiplication is unsigned.
//    - No signed multiplication support is required.
//    - No early termination optimization is required.
// ============================================================

`default_nettype none

module seq_multiplier #(
  parameter WIDTH = 16
)(
  input  logic              clk,
  input  logic              rst_n,
  input  logic              start,
  input  logic [WIDTH-1:0]  a,
  input  logic [WIDTH-1:0]  b,
  output logic [2*WIDTH-1:0] product,
  output logic              done,
  output logic              busy
);
    localparam int CNT_W = $clog2(WIDTH)+1;
    logic [CNT_W-1:0] count;

    typedef enum logic [1:0] {IDLE, CALC, FIN} state_t;
    state_t state;

    logic [2*WIDTH-1:0] acc;
    logic [2*WIDTH-1:0] b_shifted;
    logic [WIDTH-1:0] a_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
            busy <= 0;
            done <= 0;
            product <= '0;
            state <= IDLE;
            acc <= '0;
            b_shifted <= '0;
            a_reg <= '0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    busy <= 0;
                    if (start) begin
                        state <= CALC;
                        busy <= 1;
                        count <= '0; // 第一遍忘了
                        acc <= 0;
                        b_shifted <= {{WIDTH{1'b0}}, b};
                        a_reg <= a;
                    end
                end

                CALC: begin
                    if (a_reg[0])
                        acc <= acc + b_shifted;
                    
                    a_reg <= a_reg >> 1;
                    b_shifted <= b_shifted << 1;
                    count <= count+1;

                    if (count == WIDTH-1) state <= FIN;
                end

                FIN: begin
                    state <= IDLE;
                    done <= 1;
                    busy <= 0;
                    product <= acc;
                end
                
                default: ;
            endcase
        end
    end
endmodule

