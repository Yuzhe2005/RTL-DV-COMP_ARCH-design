// ============================================================
// Problem: Fast-to-Slow Clock Domain Crossing Using Req/Ack Handshake
// ============================================================
// Design a clock-domain-crossing module that safely transfers a
// one-cycle request pulse from a fast clock domain into a slow clock
// domain using a request/acknowledge handshake.
//
// Module interface:
// module handshake_cdc (
//   // Fast domain
//   input  logic fast_clk,
//   input  logic fast_rst_n,
//   input  logic send_req,
//   output logic fast_busy,
//
//   // Slow domain
//   input  logic slow_clk,
//   input  logic slow_rst_n,
//   output logic slow_data_valid
// );
//
// Requirements:
// 1. The input send_req is a one-cycle pulse in the fast_clk domain.
//    When send_req is accepted, the module should start a CDC handshake
//    to notify the slow_clk domain.
//
// 2. The fast domain should stretch/hold the request long enough for
//    the slow domain to observe it.
//    - A one-cycle fast pulse may be too short for the slow clock domain.
//    - Therefore, the request must be converted into a level signal.
//    - The request level should stay asserted until the slow domain sends
//      back an acknowledge.
//
// 3. The output fast_busy should indicate that a request is currently
//    in progress.
//    - fast_busy should be high while the fast-domain request is being held.
//    - The sender should not issue another send_req while fast_busy is high.
//
// 4. The request signal crossing from fast_clk to slow_clk must be
//    synchronized before being used in the slow domain.
//    - Use a multi-flop synchronizer in the slow_clk domain.
//    - The slow domain should detect a rising edge of the synchronized
//      request.
//
// 5. The output slow_data_valid should be a one-cycle pulse in the
//    slow_clk domain.
//    - It should assert when the slow domain first observes a new request.
//    - It should only pulse once per accepted fast-domain send_req.
//
// 6. The slow domain should generate an acknowledge signal after it sees
//    a new synchronized request.
//    - The acknowledge should remain asserted while the synchronized
//      request is still high.
//    - The acknowledge should deassert after the request is cleared.
//
// 7. The acknowledge signal crossing from slow_clk back to fast_clk must
//    be synchronized before being used in the fast domain.
//    - Use a multi-flop synchronizer in the fast_clk domain.
//    - After the fast domain observes the synchronized acknowledge, it
//      should clear the held request.
//
// 8. Reset behavior:
//    - fast_rst_n is an active-low asynchronous reset for the fast domain.
//    - slow_rst_n is an active-low asynchronous reset for the slow domain.
//    - On reset, all request, acknowledge, synchronizer, and edge-detect
//      state should clear to 0.
//    - After reset, fast_busy and slow_data_valid should be 0 until a new
//      request is sent.
//
// 9. Handshake behavior:
//    - A request starts in the fast domain.
//    - The request is synchronized into the slow domain.
//    - The slow domain detects the request and pulses slow_data_valid.
//    - The slow domain asserts acknowledge.
//    - The acknowledge is synchronized back into the fast domain.
//    - The fast domain clears the request.
//    - The slow domain observes the cleared request and deasserts acknowledge.
//
// 10. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for clocked logic.
//    - Use separate always_ff blocks for fast_clk and slow_clk domains.
//    - Do not use combinational logic to directly pass unsynchronized
//      signals between clock domains.
//    - Do not use simulation delays such as # statements.
//    - The design should be synthesizable.
//
// 11. Assumptions:
//    - send_req is generated in the fast_clk domain.
//    - slow_data_valid is consumed in the slow_clk domain.
//    - The sender respects fast_busy and does not issue a new request
//      while a previous request is still active.
//    - This module transfers a control event, not a multi-bit data bus.
// ============================================================

`default_nettype none

module handshake_cdc (
  // Fast domain
  input  logic fast_clk,
  input  logic fast_rst_n,
  input  logic send_req,
  output logic fast_busy,

  // Slow domain
  input  logic slow_clk,
  input  logic slow_rst_n,
  output logic slow_data_valid
);
    logic req_ff, req_sync1, req_sync2, req_prev;
    logic ack_ff, ack_sync1, ack_sync2;

    always_ff @(posedge fast_clk or negedge fast_rst_n) begin
        if (!fast_rst_n) begin
            req_ff <= '0;
        end else begin
            if (send_req && !req_ff)
                req_ff <= 1;
            // else if (ack_sync2) // 表示有 ordering
            if (ack_sync2)
                req_ff <= 0;
        end
    end

    // always_ff @(posedge fast_clk or negedge fast_rst_n) begin
    always_ff @(posedge slow_clk or negedge slow_rst_n) begin // 刚开始写反了
        if (!slow_rst_n) begin
            req_sync1 <= 0;
            req_sync2 <= 0;
            req_prev <= 0;
        end else begin
            req_sync1 <= req_ff;
            req_sync2 <= req_sync1;
            req_prev <= req_sync2;
        end
    end

    assign fast_busy = req_ff;

    always_ff @(posedge slow_clk or negedge slow_rst_n) begin
        if (!slow_rst_n) begin
            ack_ff <= 0;
        end else begin
            if (!req_prev && req_sync2)
                ack_ff <= 1;
            else if (!req_sync2) // 刚开始忘了这个condition了
                ack_ff <= 0;
        end
    end

    // always_ff @(posedge slow_clk or negedge slow_rst_n) begin
    always_ff @(posedge fast_clk or negedge fast_rst_n) begin // 刚开始写反了
        if (!fast_rst_n) begin
            ack_sync1 <= 0;
            ack_sync2 <= 0;
        end else begin
            ack_sync1 <= ack_ff;
            ack_sync2 <= ack_sync1;
        end
    end

    assign slow_data_valid = !req_prev && req_sync2;
endmodule