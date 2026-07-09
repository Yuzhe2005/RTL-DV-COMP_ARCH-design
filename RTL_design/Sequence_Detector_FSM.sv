// ============================================================
// Problem: Mealy Sequence Detector for Pattern 10110
// ============================================================
// Design a serial sequence detector that detects the bit pattern
// 1,0,1,1,0 from an input bit stream.
//
// Module interface:
// module seq_det_10110 (
//   input  logic clk,
//   input  logic rst_n,
//   input  logic bit_in,
//   output logic match_pulse
// );
//
// Requirements:
// 1. The module receives one serial input bit per clock cycle through
//    bit_in.
//
// 2. The detector should assert match_pulse when the input stream
//    completes the pattern:
//        1 0 1 1 0
//
// 3. The output match_pulse should be a one-cycle pulse.
//    - It should assert only during the cycle when the final 0 of the
//      pattern is observed.
//    - It should deassert otherwise.
//
// 4. The FSM should be a Mealy-style detector.
//    - match_pulse may depend on both the current state and the current
//      input bit_in.
//    - Therefore, the output can assert in the same cycle that the final
//      input bit of the pattern arrives.
//
// 5. The detector is non-overlapping after a successful match.
//    - Once 10110 is detected, the FSM should return to the initial state.
//    - The detected sequence should not be reused as the beginning of
//      another match.
//
// 6. State meaning:
//    - S0:    no useful prefix has been matched.
//    - S1:    the detector has seen "1".
//    - S10:   the detector has seen "10".
//    - S101:  the detector has seen "101".
//    - S1011: the detector has seen "1011" and is waiting for the final 0.
//
// 7. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - When rst_n is low, the FSM should return to S0.
//    - match_pulse should be 0 after reset unless a valid pattern is
//      detected later.
//
// 8. Transition behavior:
//    - From each state, update the FSM according to the next input bit.
//    - Preserve useful partial matches when possible.
//    - For example, if the detector has seen "101" and receives 0,
//      the remaining useful suffix is "10", so it may transition to S10.
//    - If the detector has seen "1011" and receives 0, the full pattern
//      10110 is detected and match_pulse should assert.
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use an enum type for FSM states.
//    - Use always_ff for state updates.
//    - The output may be generated combinationally from state and bit_in.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 10. Assumptions:
//    - bit_in is synchronous to clk.
//    - One input bit is consumed per clk cycle.
//    - This module only detects the serial pattern; it does not store
//      the full input stream.
// ============================================================

`default_nettype none

module seq_det_10110 (
  input  logic clk,
  input  logic rst_n,
  input  logic bit_in,
  output logic match_pulse
);
    typedef enum logic [2:0] {S0, S1, S10, S101, S1011} state_t;
    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
        end else begin
            case (state)
                S0: state <= (bit_in) ? S1 : S0;
                S1: state <= (bit_in) ? S1 : S10;
                S10: state <= (bit_in) ? S101 : S0;
                S101: state <= (bit_in) ? S1011 : S10;
                S1011: state <= (bit_in) ? S1 : S0;
                default: state <= S0;
            endcase
        end
    end

    assign match_pulse = (state == S1011) && (!bit_in);
endmodule