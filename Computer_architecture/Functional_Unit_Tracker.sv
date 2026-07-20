// ============================================================
// Problem: Functional Unit Busy Tracker
// ============================================================
// Design a simple tracker for a group of functional units.
//
// The module tracks which functional units are currently busy. A functional
// unit becomes busy when an instruction is issued to it, and becomes
// available again when it reports done.
//
// Module interface:
// module fu_tracker #(
//   parameter N_FU = 4
// )(
//   input  logic                    clk,
//   input  logic                    rst_n,
//   input  logic                    issue_req,
//   input  logic                    done_req,
//   input  logic [$clog2(N_FU)-1:0] issue_fu,
//   input  logic [$clog2(N_FU)-1:0] done_fu,
//   output logic [N_FU-1:0]         busy,
//   output logic                    any_available
// );
//
// Requirements:
// 1. The module should track the busy status of N_FU functional units.
//
// 2. busy behavior:
//    - busy[i] = 1 means functional unit i is currently busy.
//    - busy[i] = 0 means functional unit i is currently available.
//
// 3. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, all functional units should be marked available.
//    - Therefore busy should be cleared to 0.
//
// 4. Issue behavior:
//    - When issue_req is asserted:
//        - functional unit issue_fu should be marked busy.
//        - busy[issue_fu] should be set to 1.
//    - This represents assigning a new operation to that functional unit.
//
// 5. Done behavior:
//    - When done_req is asserted:
//        - functional unit done_fu should be marked available.
//        - busy[done_fu] should be cleared to 0.
//    - This represents that the functional unit has completed its operation.
//
// 6. Same-cycle issue and done behavior:
//    - If issue_req and done_req are both asserted in the same cycle:
//        - both updates should be applied.
//    - If issue_fu and done_fu are different, one FU is marked busy and the
//      other FU is marked available.
//    - If issue_fu and done_fu are the same, the later assignment in the
//      sequential block determines the final value.
//    - In the sample ordering, done has priority over issue for the same FU,
//      so busy[done_fu] becomes 0.
//
// 7. any_available behavior:
//    - any_available should be 1 if at least one functional unit is not busy.
//    - any_available should be 0 only when all functional units are busy.
//
//    Equivalent logic:
//      any_available = ~(&busy)
//
// 8. Output behavior:
//    - busy should be registered state.
//    - any_available can be generated combinationally from busy.
//
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for busy state updates.
//    - Use nonblocking assignments in sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 10. Assumptions:
//    - N_FU is at least 2.
//    - issue_fu is valid when issue_req is asserted.
//    - done_fu is valid when done_req is asserted.
//    - External scheduling logic should avoid issuing to an already-busy FU
//      unless that behavior is intentionally allowed.
// ============================================================

`default_nettype none

module fu_tracker #(
  parameter N_FU = 4
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    issue_req,
  input  logic                    done_req,
  input  logic [$clog2(N_FU)-1:0] issue_fu,
  input  logic [$clog2(N_FU)-1:0] done_fu,
  output logic [N_FU-1:0]         busy,
  output logic                    any_available
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= '0;
        end else begin
            if (issue_req) busy[issue_fu] <= 1'b1;
            if (done_req) busy[done_fu] <= 1'b0;
        end
    end

    assign any_available = (&busy == 0);
endmodule