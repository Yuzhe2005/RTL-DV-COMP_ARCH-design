// ============================================================
// Problem: Cache Refill Controller FSM
// ============================================================
// Design a finite-state machine that controls a cache line refill
// after a cache miss. The FSM should request data from memory, wait
// for returned beats, count the refill beats, and signal when the
// refill is complete.
//
// Module interface:
// module cache_refill_fsm #(
//   parameter LINE_WORDS = 4
// )(
//   input  logic                          clk,
//   input  logic                          rst_n,
//   input  logic                          miss,
//   input  logic                          mem_rvalid,
//   input  logic                          mem_rlast,
//   output logic                          mem_req,
//   output logic                          stall,
//   output logic                          refill_done,
//   output logic [$clog2(LINE_WORDS)-1:0] beat_count
// );
//
// Requirements:
// 1. The module should start a refill transaction when a cache miss
//    occurs.
//
// 2. When miss is asserted in IDLE:
//    - issue a memory request by asserting mem_req;
//    - leave IDLE and begin the refill process;
//    - stall the cache pipeline while refill is in progress.
//
// 3. The output stall should indicate that the refill FSM is busy.
//    - stall should be 0 in IDLE.
//    - stall should be 1 in all non-IDLE states.
//
// 4. The output mem_req should be a request pulse to memory.
//    - mem_req should assert when the FSM starts a refill request.
//    - mem_req should otherwise default to 0.
//
// 5. The FSM should wait for memory read data beats.
//    - mem_rvalid indicates that a refill data beat is valid.
//    - mem_rlast indicates that the current beat is the final beat of
//      the cache line refill.
//
// 6. The module should maintain beat_count.
//    - beat_count counts received refill beats within the cache line.
//    - It should reset to 0 when entering or remaining in IDLE.
//    - It should update as valid memory beats arrive.
//
// 7. Refill completion:
//    - refill_done should assert when the final refill beat has been
//      received.
//    - The final beat may be detected using mem_rlast.
//    - The FSM may also use LINE_WORDS to determine when all expected
//      beats have arrived.
//    - refill_done should be a one-cycle pulse.
//
// 8. Parameter behavior:
//    - LINE_WORDS determines how many memory beats make up one cache line.
//    - For LINE_WORDS = 1, the refill may complete on the first valid
//      memory beat.
//    - The width of beat_count should be large enough to count beats
//      within the cache line.
//
// 9. FSM state behavior:
//    - IDLE:
//        No refill in progress.
//        Clear beat_count.
//        If miss is asserted, issue mem_req and move to REQUEST.
//    - REQUEST:
//        Memory request has been issued.
//        Move toward waiting for read response.
//    - WAIT:
//        Wait for the first valid memory beat.
//        If the first beat is also the last beat, complete refill.
//        Otherwise, move to FILL.
//    - FILL:
//        Continue accepting valid memory beats.
//        Increment beat_count on each valid beat.
//        Complete when the last beat is observed.
//    - COMPLETE:
//        Finish the refill operation and return to IDLE.
//
// 10. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset:
//        - FSM state should return to IDLE;
//        - mem_req should clear to 0;
//        - refill_done should clear to 0;
//        - beat_count should clear to 0;
//        - stall should indicate not busy.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use an enum type for FSM states.
//    - Use always_ff for state and registered output updates.
//    - Use nonblocking assignments for sequential logic.
//    - Provide default assignments for pulse outputs such as mem_req
//      and refill_done so they only assert for one cycle.
//    - Do not use simulation delays or initial blocks for normal operation.
//    - The design should be synthesizable.
//
// 12. Assumptions:
//    - miss is synchronous to clk.
//    - mem_rvalid and mem_rlast are synchronous to clk.
//    - Memory returns one refill beat whenever mem_rvalid is high.
//    - This FSM only controls refill sequencing; it does not store the
//      returned data, update cache tags, or manage dirty/writeback logic.
// ============================================================

`default_nettype done

module cache_refill_fsm #(
  parameter LINE_WORDS = 4
)(
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic                          miss,
  input  logic                          mem_rvalid,
  input  logic                          mem_rlast,
  output logic                          mem_req,
  output logic                          stall,
  output logic                          refill_done,
  output logic [$clog2(LINE_WORDS)-1:0] beat_count // 当像是表示最近收到的beat index
);
  typedef enum logic [2:0] {IDLE, REQUEST, WAIT, FILL, COMPLETE} state_t;
  state_t state;

  assign stall = (state != IDLE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      beat_count <= '0;
      mem_req <= 0;
      refill_done <= 0;
    end else begin
      mem_req <= 0;
      refill_done <= 0;

      case(state)
        IDLE: begin
          beat_count <= '0;
          if (miss) begin
            mem_req <= 1;
            state <= REQUEST;
          end
        end

        REQUEST: state <= WAIT;

        WAIT: begin
          if (mem_rvalid) begin
            beat_count <= '0;
            if (mem_rlast || LINE_WORDS == 1) begin
              state <= COMPLETE;
              refill_done <= 1;
            end else begin
              state <= FILL;
            end
          end
        end

        FILL: begin
          if (mem_rvalid) begin
            beat_count <= beat_count+1;
            if (mem_rlast || beat_count == LINE_WORDS-2) begin
              state <= COMPLETE;
              refill_done <= 1;
            end
          end
        end

        COMPLETE: state <= IDLE;

        default: state <= IDLE;
      endcase
    end
  end
endmodule