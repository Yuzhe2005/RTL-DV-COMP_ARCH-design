// ============================================================
// Problem: Mealy FSM Sequence Detector for 1011
// ============================================================
// Design a Mealy finite state machine that detects the overlapping
// bit sequence 1011.
// Module interface:
// module seq_det_1011 (
//   input  logic clk,
//   input  logic rst_n,
//   input  logic in,
//   output logic detect
// );
// Requirements:
// 1. FSM type:
//    - Implement a Mealy FSM.
//    - The output detect may depend on both the current state and the current input.
//    - detect should assert in the same cycle when the final input bit completes 1011.
// 2. Sequence to detect:
//    - Detect the serial input sequence:
//        1 0 1 1
//    - Input bits arrive one bit per clock cycle through input signal in.
//    - The FSM should track progress toward matching 1011.
// 3. Overlapping detection:
//    - The detector must support overlapping sequences.
//    - Example input:
//        1 0 1 1 0 1 1
//      should detect two matches:
//        1 0 1 1
//              1 0 1 1
//    - After detecting 1011, the last 1 can be reused as the beginning of a new match.
// 4. Reset behavior:
//    - Reset is active-low asynchronous reset: rst_n.
//    - When rst_n is low, the FSM should return to IDLE.
//    - detect should be low after reset because no sequence has been matched.
// 5. State definitions:
//    - Use SystemVerilog enum state encoding.
//    - The FSM should include states representing partial progress:
//        IDLE  : no useful prefix matched
//        S1    : seen 1
//        S10   : seen 10
//        S101  : seen 101
//        S1011 : seen 1011 complete state
// 6. State transition behavior:
//    - From IDLE:
//        if in == 1, go to S1
//        if in == 0, stay in IDLE
//    - From S1:
//        if in == 1, stay in S1
//        if in == 0, go to S10
//    - From S10:
//        if in == 1, go to S101
//        if in == 0, go to IDLE
//    - From S101:
//        if in == 1, go to S1011
//        if in == 0, go to S10
//    - From S1011:
//        if in == 1, go to S1
//        if in == 0, go to S10
// 7. Detect output behavior:
//    - detect should assert when the FSM is in S101 and the current input in is 1.
//    - This means the current input completes the sequence 1011.
//    - Use Mealy-style output:
//        detect = (state == S101) && in
//    - detect should otherwise be low.
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for the state register.
//    - Use always_comb for next-state logic.
//    - Use assign or always_comb for Mealy output logic.
//    - The design should be synthesizable.
// 9. Assumptions:
//    - Input in is sampled relative to clk.
//    - detect is a combinational Mealy output.
//    - The output is not required to be registered.
// ============================================================

`default_nettype none

module seq_det_1011 (
  input  logic clk,
  input  logic rst_n,
  input  logic in,
  output logic detect
);

    typedef enum logic [2:0] {IDLE, S1, S10, S101, S1011} state_t;
    state_t cs, ns;

    always_comb begin
        ns = cs;
        case (cs)
            IDLE: ns = (in) ? S1 : IDLE;
            S1: ns = (!in) ? S10 : S1;
            S10: ns = (in) ? S101 : IDLE;
            S101: ns = (in) ? S1011 : S10;
            S1011: ns = (in) ? S1 : S10;
            default: ns = IDLE;
        endcase
    end

    assign detect = (ns === S1011);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs <= IDLE;
        end else begin
            cs <= ns;
        end
    end
endmodule