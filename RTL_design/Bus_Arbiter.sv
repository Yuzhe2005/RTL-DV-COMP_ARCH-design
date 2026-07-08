// ============================================================
// Problem: Round-Robin Bus Arbiter
// ============================================================
// Design a parameterized round-robin arbiter that grants access
// to one requesting master at a time.
//
// Module interface:
// module bus_arbiter #(
//   parameter NUM_MASTERS = 4
// )(
//   input  logic                    clk,
//   input  logic                    rst_n,
//   input  logic [NUM_MASTERS-1:0]  request,
//   output logic [NUM_MASTERS-1:0]  grant,
//   output logic                    grant_valid
// );
//
// Requirements:
// 1. Implement a round-robin bus arbiter for NUM_MASTERS masters.
// 2. Each bit of request represents one master's request:
//    - request[i] = 1 means master i is requesting the bus.
//    - request[i] = 0 means master i is not requesting the bus.
// 3. The arbiter should output a one-hot grant vector:
//    - grant[i] = 1 means master i is granted bus access.
//    - At most one bit of grant should be high at a time.
// 4. grant_valid behavior:
//    - grant_valid should be 1 if any request is granted.
//    - grant_valid should be 0 if no request is active.
// 5. Round-robin priority behavior:
//    - The arbiter should remember the most recently granted master.
//    - On the next arbitration, search starting from the master after
//      the last granted master.
//    - Wrap around to master 0 after reaching NUM_MASTERS-1.
// 6. Fairness behavior:
//    - If multiple masters keep requesting, grants should rotate among them.
//    - A continuously requesting master should not be permanently starved.
// 7. Example for NUM_MASTERS = 4:
//    - If last_grant was 1, the search order should be:
//      master 2, master 3, master 0, master 1.
//    - The first requesting master in that order should receive the grant.
// 8. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, initialize the last granted pointer so that the first search
//      starts from master 0.
//    - For NUM_MASTERS = 4, this can be done by resetting last_grant to 3.
// 9. State update behavior:
//    - last_grant should update only when grant_valid is high.
//    - If there is no active request, last_grant should hold its value.
//    - When a grant is issued, last_grant should update to the granted master.
// 10. Combinational grant behavior:
//    - grant and grant_valid may be computed combinationally from request
//      and last_grant.
//    - next_grant_idx should represent the selected grant index.
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use always_comb for grant selection.
//    - Use always_ff for last_grant state update.
//    - The design should be synthesizable.
// 12. Assumptions:
//    - NUM_MASTERS is at least 1.
//    - request is stable during combinational arbitration.
//    - This module only arbitrates requests; it does not implement bus data,
//      ready/valid transfer, or transaction locking.
// ============================================================

`default_nettype none

module bus_arbiter #(
  parameter NUM_MASTERS = 4
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic [NUM_MASTERS-1:0]  request,
  output logic [NUM_MASTERS-1:0]  grant,
  output logic                    grant_valid
);
    // localparam int MASTER_W = $clog2(NUM_MASTERS);
    localparam int MASTER_W = (NUM_MASTERS <= 1) ? 1 : $clog2(NUM_MASTERS);

    // logic [MASTER_W-1:0] last_grant, this_grant_d;
    logic [MASTER_W:0] last_grant, this_grant_d;

    // logic [NUM_MASTERS-1:0] start;
    // assign start = 1'b1;

    always_comb begin
        grant_valid = 0;
        this_grant_d = '0;
        grant = '0;
        for (int i = 1; i <= NUM_MASTERS; i++) begin
            if (last_grant+i >= NUM_MASTERS)
                this_grant_d = last_grant+i-NUM_MASTERS;
            else
                this_grant_d = last_grant+i; // 第一遍忘了这个else condition了
            if (!grant_valid && request[this_grant_d]) begin
                grant_valid = 1;
                // grant = (start << this_grant_d);
                grant[this_grant_d] = 1'b1;
                break;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // last_grant <= '0;
            last_grant <= NUM_MASTERS-1; // 因为我们 always_comb loop 里面是从 i=1 开始的
        end else if (grant_valid) begin
            last_grant <= this_grant_d;
        end
    end
endmodule

//-------------------------------------------------------------------------------

// sample solution
module bus_arbiter #(
  parameter NUM_MASTERS = 4
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic [NUM_MASTERS-1:0]  request,
  output logic [NUM_MASTERS-1:0]  grant,
  output logic                    grant_valid
);
  localparam LOG2 = (NUM_MASTERS <= 1) ? 1 : $clog2(NUM_MASTERS);

  logic [LOG2-1:0] last_grant;
  logic [LOG2-1:0] next_grant_idx;
  logic            found_grant;

  always_comb begin
    integer idx;

    grant          = '0;
    next_grant_idx = last_grant;
    found_grant    = 0;
    idx            = 0;

    for (int i = 1; i <= NUM_MASTERS; i++) begin
      idx = (last_grant + i) % NUM_MASTERS;
      if (!found_grant && request[idx]) begin
        grant[idx]      = 1'b1;
        next_grant_idx  = idx[LOG2-1:0];
        found_grant     = 1'b1;
      end
    end
  end

  assign grant_valid = found_grant;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      last_grant <= NUM_MASTERS-1;
    end else if (grant_valid) begin
      last_grant <= next_grant_idx;
    end
  end
endmodule
