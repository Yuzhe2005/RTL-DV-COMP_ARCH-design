// ============================================================
// Problem: Serial Divisibility-by-3 Detector
// ============================================================
// Design a finite-state machine that reads a serial binary number
// one bit per clock cycle and indicates whether the value seen so far
// is divisible by 3.
//
// Module interface:
// module div_by_3 (
//   input  logic clk,
//   input  logic rst_n,
//   input  logic bit_in,
//   output logic div_by_3
// );
//
// Requirements:
// 1. The module receives one input bit per clock cycle through bit_in.
//
// 2. The input stream represents a binary number arriving MSB-first.
//    - The first bit received is the most significant bit of the number
//      seen so far.
//    - Each new bit extends the previous value by one binary digit.
//
// 3. The FSM should track the remainder of the serially received value
//    modulo 3.
//
// 4. The output div_by_3 should be 1 when the current value represented
//    by all bits received so far is divisible by 3.
//    - If the current remainder is 0, div_by_3 should be 1.
//    - Otherwise, div_by_3 should be 0.
//
// 5. The FSM should use three logical states:
//    - one state for remainder 0;
//    - one state for remainder 1;
//    - one state for remainder 2.
//
// 6. On every rising edge of clk, the FSM should update its state based
//    on:
//    - the previous remainder state;
//    - the new incoming bit bit_in.
//
// 7. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low, the FSM should return to the remainder-0 state.
//    - After reset, div_by_3 should indicate that the current value is 0,
//      which is divisible by 3.
//
// 8. Output behavior:
//    - div_by_3 may be generated combinationally from the current FSM state.
//    - The output should reflect whether the value represented so far is
//      divisible by 3.
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use an enum type for FSM states.
//    - Use always_ff for state updates.
//    - Do not use simulation delays or initial blocks for normal operation.
//    - The design should be synthesizable.
//
// 10. Assumptions:
//    - bit_in is synchronous to clk.
//    - Bits arrive MSB-first.
//    - The module does not need a separate valid signal; every clock cycle
//      consumes one input bit.
// ============================================================

`default_nettype none

module div_by_3 (
  input  logic clk,
  input  logic rst_n,
  input  logic bit_in,
  output logic div_by_3
);
    typedef enum logic [1:0] {R0, R1, R2} state_t;
    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= R0;
        end else begin
            case (state)
                R0: state <= (bit_in) ? R1 : R0;
                R1: state <= (bit_in) ? R0 : R2;
                R2: state <= (bit_in) ? R2 : R1;
                default: state <= R0;
            endcase
        end
    end

    assign div_by_3 = (state == R0);
endmodule