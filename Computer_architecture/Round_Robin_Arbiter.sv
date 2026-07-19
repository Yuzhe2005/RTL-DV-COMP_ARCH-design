// ============================================================
// Problem: Parameterized Round-Robin Arbiter
// ============================================================
// Design a parameterized round-robin arbiter.
//
// The arbiter receives N request signals and grants at most one requester
// per cycle. Arbitration should be fair: after one requester is granted,
// the next search should start from the requester after the last granted
// requester.
//
// Module interface:
// module rr_arbiter #(
//   parameter N = 4
// )(
//   input  logic          clk,
//   input  logic          rst_n,
//   input  logic [N-1:0] req,
//   output logic [N-1:0] grant
// );
//
// Requirements:
// 1. The module should implement an N-input round-robin arbiter.
//
// 2. Request behavior:
//    - req[i] = 1 means requester i is asking for service.
//    - req[i] = 0 means requester i is not requesting service.
//
// 3. Grant behavior:
//    - grant should be one-hot or all-zero.
//    - If at least one request is asserted, exactly one grant bit should be 1.
//    - If no requests are asserted, grant should be all zeros.
//
// 4. Round-robin priority:
//    - The arbiter should remember the last granted requester.
//    - The next arbitration search should start from last + 1.
//    - The search should wrap around from N-1 back to 0.
//    - This prevents one requester from always having highest priority.
//
// 5. Example with N = 4:
//    - Suppose last = 0.
//    - The next priority order should be:
//        requester 1, requester 2, requester 3, requester 0
//
//    If:
//        req = 4'b1010
//    then requester 1 and requester 3 are requesting.
//    Since requester 1 appears first in the round-robin search order,
//    grant should be:
//        grant = 4'b0010
//
// 6. Another example:
//    - Suppose last = 2.
//    - The next priority order should be:
//        requester 3, requester 0, requester 1, requester 2
//
//    If:
//        req = 4'b0101
//    then requester 0 and requester 2 are requesting.
//    Since requester 0 appears first in the search order,
//    grant should be:
//        grant = 4'b0001
//
// 7. State update:
//    - The arbiter should store the index of the granted requester in last.
//    - last should update only when a grant is issued.
//    - If no grant is issued, last should keep its old value.
//
// 8. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, last should be cleared to 0.
//    - After reset, the first search starts from requester 1.
//    - If the desired first priority is requester 0, last can instead be
//      reset to N-1.
//
// 9. Combinational and sequential logic:
//    - grant should be generated combinationally from req and last.
//    - last should be updated sequentially on the rising edge of clk.
//
// 10. Implementation style:
//    - Use SystemVerilog.
//    - Use always_comb for grant generation.
//    - Use always_ff for last update.
//    - Use nonblocking assignments in always_ff.
//    - Provide default assignments to avoid latches.
//    - The design should be synthesizable.
//    - Do not use delays or simulation-only constructs.
//
// 11. Assumptions:
//    - N is at least 2.
//    - N is small enough that a simple combinational loop is acceptable.
//    - grant is consumed in the same cycle it is generated.
// ============================================================

`default_nettype none

module rr_arbiter #(
  parameter N = 4
)(
  input  logic          clk,
  input  logic          rst_n,
  input  logic [N-1:0] req,
  output logic [N-1:0] grant
);
    localparam int N_W = $clog2(N);
    logic [N_W-1:0] last;

    int idx, select;
    logic found;

    always_comb begin
        idx = 0;
        found = 0;
        select = 0;
        for (int i = 0; i < N; i++) begin
            idx = (last+1+i >= N) ? last+1+i-N : last+1+i;
            if (req[idx] && !found) begin
                found = 1'b1;
                select = idx;
            end
        end
    end

    always_comb begin
        grant = '0;
        if (found) grant[select] = 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // last <= '0;
            last <= N-1;
        end else begin
            if (found) last <= select[N_W-1:0];
        end
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:

module rr_arbiter #(
  parameter N = 4
)(
  input  logic          clk,
  input  logic          rst_n,
  input  logic [N-1:0] req,
  output logic [N-1:0] grant
);
  logic [$clog2(N)-1:0] last;

  always_comb begin
    logic [$clog2(N)-1:0] idx;

    grant = '0;
    idx   = '0;
    for (int i = 1; i <= N; i++) begin
      idx = (last + i) % N;
      if (req[idx]) begin
        grant[idx] = 1;
        break;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      last <= '0;
    end else if (|grant) begin
      for (int i = 0; i < N; i++) begin
        if (grant[i]) last <= i;
      end
    end
  end
endmodule