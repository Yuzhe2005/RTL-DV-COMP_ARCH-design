// ============================================================
// Problem: Parameterized Signed FIR Filter
// ============================================================
// Design a parameterized signed FIR filter.
//
// The FIR filter should implement a direct-form finite impulse response
// filter:
//
//   y[n] = sum_{k=0}^{NUM_TAPS-1} coeffs[k] * x[n-k]
//
// In other words:
//   - coeffs[0] multiplies the newest input sample;
//   - coeffs[1] multiplies the previous input sample;
//   - coeffs[NUM_TAPS-1] multiplies the oldest sample used by the filter.
//
// Module interface:
// module fir_filter #(
//   parameter DATA_WIDTH  = 16,
//   parameter COEFF_WIDTH = 16,
//   parameter NUM_TAPS    = 8
// )(
//   input  logic                                     clk,
//   input  logic                                     rst_n,
//   input  logic signed [DATA_WIDTH-1:0]             x_in,
//   input  logic                                     x_valid,
//   input  logic signed [COEFF_WIDTH-1:0]            coeffs [0:NUM_TAPS-1],
//   output logic signed [DATA_WIDTH+COEFF_WIDTH+3:0] y_out,
//   output logic                                     y_valid
// );
//
// Requirements:
// 1. The module should implement a signed FIR filter with:
//    - NUM_TAPS taps;
//    - DATA_WIDTH-bit signed input samples;
//    - COEFF_WIDTH-bit signed coefficients;
//    - one signed registered output y_out;
//    - one output valid signal y_valid.
//
// 2. FIR computation behavior:
//    - When x_valid is asserted, the module should compute one FIR output.
//    - The computation should follow:
//
//        y[n] = coeffs[0] * x[n]
//             + coeffs[1] * x[n-1]
//             + coeffs[2] * x[n-2]
//             + ...
//             + coeffs[NUM_TAPS-1] * x[n-(NUM_TAPS-1)]
//
//    - x_in represents the newest input sample x[n].
//    - Previously accepted input samples should be stored internally.
//
// 3. Shift register behavior:
//    - Use an internal shift register to store previous input samples.
//    - shift_reg[0] should store the most recent previous sample.
//    - shift_reg[1] should store the sample before shift_reg[0].
//    - shift_reg[NUM_TAPS-1] should store the oldest stored sample.
//    - When x_valid is asserted on a rising clock edge:
//        - x_in should be written into shift_reg[0];
//        - old shift_reg[0] should move to shift_reg[1];
//        - old shift_reg[1] should move to shift_reg[2];
//        - and so on.
//
// 4. Accumulation behavior:
//    - The FIR accumulation should use:
//        - current x_in for coeffs[0];
//        - old shift_reg[0] for coeffs[1];
//        - old shift_reg[1] for coeffs[2];
//        - ...
//        - old shift_reg[NUM_TAPS-2] for coeffs[NUM_TAPS-1].
//
//    - Important:
//        The current x_in should be used directly in the accumulation before
//        it is shifted into shift_reg[0].
//
// 5. Timing behavior:
//    - When x_valid is high in a cycle:
//        - the accumulation should be computed from current x_in and old
//          shift_reg contents;
//        - y_out should capture the computed accumulation result on the
//          rising edge of clk;
//        - y_valid should be asserted after that clock edge.
//    - Therefore, y_out is a registered output.
//    - y_valid indicates that y_out contains a valid newly computed result.
//
// 6. Behavior when x_valid is low:
//    - No new input sample should be accepted.
//    - The shift register should hold its previous values.
//    - y_out may hold its previous value.
//    - y_valid should be deasserted to 0.
//
// 7. Reset behavior:
//    - Reset is synchronous active-low.
//    - On posedge clk, if rst_n is 0:
//        - all shift register entries should be cleared to 0;
//        - y_out should be cleared to 0;
//        - y_valid should be cleared to 0.
//
// 8. Signed arithmetic behavior:
//    - x_in should be treated as signed.
//    - coeffs should be treated as signed.
//    - Each multiplication should be signed multiplication.
//    - The accumulation should preserve signed values.
//    - The final output y_out should be signed.
//
// 9. Output width behavior:
//    - The output width should include guard bits for accumulation.
//    - For the given interface:
//
//        y_out is signed [DATA_WIDTH+COEFF_WIDTH+3:0]
//
//    - Therefore the total output width is:
//
//        DATA_WIDTH + COEFF_WIDTH + 4 bits
//
//    - For default parameters:
//        DATA_WIDTH  = 16
//        COEFF_WIDTH = 16
//        NUM_TAPS    = 8
//
//      y_out is:
//
//        signed [35:0]
//
//      which is 36 bits wide.
//
// 10. Implementation style:
//    - Use SystemVerilog.
//    - Use an unpacked array for the shift register.
//    - Use always_comb for combinational accumulation.
//    - Use always_ff for sequential state updates.
//    - Use nonblocking assignments in always_ff.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 11. Assumptions:
//    - NUM_TAPS is at least 1.
//    - coeffs[0] through coeffs[NUM_TAPS-1] are provided externally.
//    - x_valid is the only input handshake signal.
//    - There is no ready/backpressure signal.
//    - The module accepts at most one input sample per cycle.
//    - Coefficients are treated as stable during the computation cycle.
// ============================================================

`default_nettype none

module fir_filter #(
  parameter DATA_WIDTH  = 16,
  parameter COEFF_WIDTH = 16,
  parameter NUM_TAPS    = 8
)(
  input  logic                                     clk,
  input  logic                                     rst_n,
  input  logic signed [DATA_WIDTH-1:0]             x_in,
  input  logic                                     x_valid,
  input  logic signed [COEFF_WIDTH-1:0]            coeffs [0:NUM_TAPS-1],
  output logic signed [DATA_WIDTH+COEFF_WIDTH+3:0] y_out,
  output logic                                     y_valid
);
    logic signed [DATA_WIDTH-1:0] shift_reg [NUM_TAPS];
    logic signed [DATA_WIDTH+COEFF_WIDTH+3:0] y_out_d;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_TAPS; i++)
                shift_reg[i] <= '0;
        end else if (x_valid) begin
            for (int i = 0; i < NUM_TAPS-1; i++)
                shift_reg[i+1] <= shift_reg[i];
            shift_reg[0] <= x_in;
        end
    end

    always_comb begin
        y_out_d = '0;
        // for (int i = 0; i < NUM_TAPS; i++) begin
        //     y_out_d += shift_reg[i] * coeffs[i];
        for (int i = 1; i < NUM_TAPS; i++)
            y_out_d += shift_reg[i-1] * coeffs[i];
        y_out_d += x_in * coeffs[0];
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            y_out <= '0;
            y_valid <= 0;
        end else if (x_valid) begin
            y_out <= y_out_d;
            y_valid <= 1'b1;
        end else begin // 这里第一次忘了拉低 y_valid 了
            y_valid <= 1'b0;
        end
    end
endmodule

//------------------------------------------------------------------------------

// sample solution:

// ref.sv — FIR Filter reference implementation.
// Direct-form FIR: y[n] = sum_{k=0}^{NUM_TAPS-1} coeffs[k] * x[n-k]
//
// Output width: DATA_WIDTH + COEFF_WIDTH + log2(NUM_TAPS) guard bits.
// With DATA_WIDTH=16, COEFF_WIDTH=16, NUM_TAPS=8 (<=8 taps -> 3 guard bits):
//   y_out is 16+16+3+1 = 36 bits (DATA_WIDTH+COEFF_WIDTH+3:0 = 35 downto 0).
//
// Timing: x_valid high → accumulation computed combinationally from CURRENT x_in
// and OLD shift_reg contents → registered at posedge clk → y_valid=1, y_out valid
// on the cycle AFTER x_valid.
//
// Reset: synchronous active-low (rst_n).

module fir_filter #(
    parameter DATA_WIDTH  = 16,
    parameter COEFF_WIDTH = 16,
    parameter NUM_TAPS    = 8
) (
    input  logic                                     clk,
    input  logic                                     rst_n,
    input  logic signed [DATA_WIDTH-1:0]             x_in,
    input  logic                                     x_valid,
    input  logic signed [COEFF_WIDTH-1:0]            coeffs [0:NUM_TAPS-1],
    output logic signed [DATA_WIDTH+COEFF_WIDTH+3:0] y_out,
    output logic                                     y_valid
);

    localparam ACC_WIDTH = DATA_WIDTH + COEFF_WIDTH + 4;  // full output width

    // Shift register: shift_reg[0] = most recent stored sample,
    //                 shift_reg[NUM_TAPS-1] = oldest stored sample.
    // When x_valid pulses, x_in is coeffs[0]'s input and shift_reg[k-1]
    // is coeffs[k]'s input; then x_in is shifted into shift_reg[0].
    logic signed [DATA_WIDTH-1:0] shift_reg [0:NUM_TAPS-1];

    // Combinational accumulator: uses current x_in + OLD shift_reg values.
    logic signed [ACC_WIDTH-1:0] acc_comb;

    always_comb begin
        acc_comb = '0;
        // coeffs[0] * newest input sample (x_in, not yet in shift_reg)
        acc_comb = acc_comb + ACC_WIDTH'(coeffs[0] * x_in);
        // coeffs[k] * older samples from shift_reg
        for (int k = 1; k < NUM_TAPS; k++) begin
            acc_comb = acc_comb + ACC_WIDTH'(coeffs[k] * shift_reg[k-1]);
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_TAPS; i++) shift_reg[i] <= '0;
            y_out   <= '0;
            y_valid <= 1'b0;
        end else if (x_valid) begin
            // Shift in new sample: shift_reg[0] holds most recent past sample
            shift_reg[0] <= x_in;
            for (int i = 1; i < NUM_TAPS; i++) shift_reg[i] <= shift_reg[i-1];
            // Register the combinational accumulation result
            y_out   <= acc_comb;
            y_valid <= 1'b1;
        end else begin
            y_valid <= 1'b0;
        end
    end

endmodule