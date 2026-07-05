// ============================================================
// Problem: LSB-First Priority Encoder
// ============================================================
// Design a parameterized priority encoder.
// Module interface:
// module priority_encoder #(
//   parameter N = 8
// )(
//   input  logic [N-1:0]           request,
//   output logic [$clog2(N)-1:0]   index,
//   output logic                   valid
// );
// Requirements:
// 1. Implement a combinational priority encoder.
// 2. The input request is an N-bit request vector.
// 3. Lower bit positions have higher priority.
//    - request[0] has the highest priority.
//    - request[1] has the next highest priority.
//    - request[N-1] has the lowest priority.
// 4. If one or more request bits are high:
//    - valid should be asserted.
//    - index should contain the lowest-numbered asserted bit position.
// 5. If no request bits are high:
//    - valid should be deasserted.
//    - index should be set to 0.
// 6. The design should be parameterized by N.
// 7. The design should be purely combinational.
// 8. Use SystemVerilog.
// 9. The design should be synthesizable.
// 10. Assumptions:
//    - N is greater than 1.
//    - N is preferably a power of 2 for a clean index width.
// ============================================================

`default_nettype none

module priority_encoder #(
  parameter N = 8
)(
  input  logic [N-1:0]           request,
  output logic [$clog2(N)-1:0]   index,
  output logic                   valid
);
    always_comb begin
        index = '0;
        valid = 0;
        for (int i = 0; i < N; i++) begin
            if (request[i] == 1'b1) begin
                index = i[$clog2(N)-1:0];
                valid = 1;
                break;
            end
        end
    end
endmodule