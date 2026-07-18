// ============================================================
// Problem: Round-Robin Warp Scheduler
// ============================================================
// Design a simple round-robin warp scheduler.
//
// The scheduler receives a ready bit for each warp and selects one ready
// warp to issue. It should rotate priority based on the last selected warp
// so that ready warps are selected fairly over time.
//
// Module interface:
// module warp_scheduler #(
//   parameter N_WARPS = 8
// )(
//   input  logic                         clk,
//   input  logic                         rst_n,
//   input  logic [N_WARPS-1:0]           warp_ready,
//   output logic [$clog2(N_WARPS)-1:0]   selected_warp,
//   output logic                         valid
// );
//
// Requirements:
// 1. The module should select one ready warp from warp_ready.
//
// 2. warp_ready behavior:
//    - warp_ready[i] = 1 means warp i is ready to issue.
//    - warp_ready[i] = 0 means warp i cannot be selected.
//
// 3. Output valid behavior:
//    - valid should be 1 if at least one warp is ready.
//    - valid should be 0 if no warp is ready.
//
// 4. selected_warp behavior:
//    - If valid is 1, selected_warp should contain the index of the chosen
//      ready warp.
//    - If valid is 0, selected_warp may be 0.
//
// 5. Round-robin policy:
//    - The scheduler should remember the last selected warp.
//    - On each cycle, selection should start from the warp after last.
//    - The search should wrap around from the highest warp index back to 0.
//    - The first ready warp found in this round-robin order should be
//      selected.
//
// 6. Example:
//    - N_WARPS = 8
//    - last = 2
//    - Search order should be:
//        3, 4, 5, 6, 7, 0, 1, 2
//    - The first ready warp in this order should be selected.
//
// 7. State update:
//    - last should be updated to selected_warp on the rising edge of clk
//      only when valid is 1.
//    - If valid is 0, last should hold its previous value.
//
// 8. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, last should be cleared to 0.
//
// 9. Combinational selection:
//    - valid and selected_warp should be computed combinationally from
//      warp_ready and last.
//    - No latch should be inferred.
//    - Provide default values for valid and selected_warp.
//
// 10. Fairness:
//    - The scheduler should not always prefer warp 0.
//    - Priority should rotate after each successful selection.
//    - If multiple warps are ready continuously, they should be selected
//      in round-robin order.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use always_comb for selection logic.
//    - Use always_ff for the last-selected state.
//    - Use nonblocking assignment for sequential state update.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 12. Assumptions:
//    - N_WARPS is at least 2.
//    - N_WARPS is the number of hardware warps being scheduled.
//    - This module only selects a warp index; instruction issue and warp
//      state updates are handled elsewhere.
// ============================================================
       
`default_nettype none

module warp_scheduler #(
  parameter N_WARPS = 8
)(
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic [N_WARPS-1:0]           warp_ready,
  output logic [$clog2(N_WARPS)-1:0]   selected_warp,
  output logic                         valid
);
    localparam int WRAPS_W = $clog2(N_WARPS);
    logic [WRAPS_W-1:0] last;

    int idx;
    always_comb begin
        valid = '0;
        selected_warp = '0;
        for (int i = 0; i < N_WARPS; i++) begin
            // idx = (i+last >= N_WARPS) ? '0 : i+last;
            idx = (i+last+1 >= N_WARPS) ? i+last+1-N_WARPS : i+last+1;
            if (warp_ready[idx]) begin
                selected_warp = idx[WRAPS_W-1:0];
                valid = 1;
                break;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // last <= '0;
            last <= N_WARPS-1;
        // end else begin
        //     last <= selected_warp;
        // end
        end else if (valid) begin
            last <= selected_warp;
        end
    end
endmodule