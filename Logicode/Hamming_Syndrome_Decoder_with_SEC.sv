// ============================================================
// Problem: Hamming(7,4) Decoder
// ============================================================
// Design a combinational Hamming(7,4) decoder.
//
// The module should take a 7-bit Hamming codeword, detect whether there is
// a single-bit error, correct the error if present, and output the original
// 4-bit data.
//
// Hamming(7,4) code format:
//
//   position:  1   2   3   4   5   6   7
//   bit type:  p1  p2  d1  p4  d2  d3  d4
//   index:     0   1   2   3   4   5   6
//
// Module interface:
// module hamming_decoder (
//   input  logic [6:0] codeword_in,
//   output logic [3:0] data_out,
//   output logic       error_detected,
//   output logic       error_corrected,
//   output logic [2:0] syndrome_out
// );
//
// Requirements:
// 1. The module should implement a Hamming(7,4) decoder.
//    - Input is a 7-bit encoded codeword.
//    - Output is the corrected 4-bit data.
//    - The decoder should detect and correct single-bit errors.
//
// 2. Syndrome calculation:
//    - Compute a 3-bit syndrome from parity checks.
//    - syndrome[0] should check positions 1, 3, 5, and 7:
//
//        syndrome[0] = codeword_in[0] ^ codeword_in[2] ^
//                      codeword_in[4] ^ codeword_in[6]
//
//    - syndrome[1] should check positions 2, 3, 6, and 7:
//
//        syndrome[1] = codeword_in[1] ^ codeword_in[2] ^
//                      codeword_in[5] ^ codeword_in[6]
//
//    - syndrome[2] should check positions 4, 5, 6, and 7:
//
//        syndrome[2] = codeword_in[3] ^ codeword_in[4] ^
//                      codeword_in[5] ^ codeword_in[6]
//
// 3. Syndrome meaning:
//    - If syndrome == 3'b000, no error is detected.
//    - If syndrome != 3'b000, the syndrome value indicates the 1-indexed
//      bit position of the error.
//    - Example:
//        syndrome == 3'd1 means position 1, index 0 is wrong.
//        syndrome == 3'd5 means position 5, index 4 is wrong.
//        syndrome == 3'd7 means position 7, index 6 is wrong.
//
// 4. Error detection outputs:
//    - error_detected should be 1 when syndrome is nonzero.
//    - error_detected should be 0 when syndrome is zero.
//
//        error_detected = |syndrome
//
// 5. Error correction outputs:
//    - error_corrected should be 1 when syndrome is nonzero.
//    - error_corrected should be 0 when syndrome is zero.
//    - For this basic Hamming(7,4) decoder, any nonzero syndrome is treated
//      as a correctable single-bit error.
//
//        error_corrected = |syndrome
//
// 6. Error mask generation:
//    - Decode syndrome into a one-hot 7-bit error mask.
//    - If syndrome == 0, error_mask should be 7'b0000000.
//    - If syndrome == k, error_mask should have bit k-1 set to 1.
//
//    Examples:
//        syndrome == 3'd1 -> error_mask = 7'b0000001
//        syndrome == 3'd2 -> error_mask = 7'b0000010
//        syndrome == 3'd3 -> error_mask = 7'b0000100
//        syndrome == 3'd4 -> error_mask = 7'b0001000
//        syndrome == 3'd5 -> error_mask = 7'b0010000
//        syndrome == 3'd6 -> error_mask = 7'b0100000
//        syndrome == 3'd7 -> error_mask = 7'b1000000
//
// 7. Correction behavior:
//    - Correct the codeword by XORing codeword_in with error_mask.
//
//        corrected = codeword_in ^ error_mask
//
//    - XOR with 1 flips the erroneous bit.
//    - XOR with 0 keeps all other bits unchanged.
//
// 8. Data extraction:
//    - Extract the 4 data bits from the corrected codeword.
//    - The data bits are stored in positions 3, 5, 6, and 7.
//    - In zero-based indexing, these are:
//
//        corrected[2], corrected[4], corrected[5], corrected[6]
//
//    - data_out should be:
//
//        data_out = {corrected[6], corrected[5],
//                    corrected[4], corrected[2]}
//
//    - This corresponds to:
//
//        data_out = {d4, d3, d2, d1}
//
// 9. Syndrome output:
//    - syndrome_out should directly output the calculated syndrome.
//
//        syndrome_out = syndrome
//
// 10. Timing behavior:
//    - The module should be purely combinational.
//    - There should be no clock.
//    - There should be no reset.
//    - Outputs should update immediately when codeword_in changes.
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use continuous assignments and/or always_comb.
//    - Do not use always_ff.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 12. Assumptions and limitations:
//    - This is a standard Hamming(7,4) single-error-correcting decoder.
//    - It can correct one bit error.
//    - It cannot reliably detect or correct double-bit errors.
//    - If two bits are wrong, syndrome may still be nonzero, and this decoder
//      may incorrectly flip another bit.
// ============================================================

`default_nettype none

module hamming_decoder (
  input  logic [6:0] codeword_in,
  output logic [3:0] data_out,
  output logic       error_detected,
  output logic       error_corrected,
  output logic [2:0] syndrome_out
);
    logic [2:0] syndrome;
    logic [6:0] error_mask;
    logic [6:0] corrected;

    // Compute syndrome bits
    // s[0]: positions 1,3,5,7 -> indices 0,2,4,6
    // s[1]: positions 2,3,6,7 -> indices 1,2,5,6
    // s[2]: positions 4,5,6,7 -> indices 3,4,5,6
    assign syndrome[0] = codeword_in[0] ^ codeword_in[2] ^ codeword_in[4] ^ codeword_in[6];
    assign syndrome[1] = codeword_in[1] ^ codeword_in[2] ^ codeword_in[5] ^ codeword_in[6];
    assign syndrome[2] = codeword_in[3] ^ codeword_in[4] ^ codeword_in[5] ^ codeword_in[6];

    assign syndrome_out    = syndrome;
    assign error_detected  = |syndrome;
    assign error_corrected = |syndrome;

     // One-hot decode: syndrome value is 1-indexed bit position to flip
    always_comb begin
        case (syndrome)
            3'd1:    error_mask = 7'b0000001;
            3'd2:    error_mask = 7'b0000010;
            3'd3:    error_mask = 7'b0000100;
            3'd4:    error_mask = 7'b0001000;
            3'd5:    error_mask = 7'b0010000;
            3'd6:    error_mask = 7'b0100000;
            3'd7:    error_mask = 7'b1000000;
            default: error_mask = 7'b0000000;
        endcase
    end

    // XOR the mask to flip exactly the errored bit
    assign corrected = codeword_in ^ error_mask;

    // Extract data bits from corrected codeword
    // d1=position3=corrected[2], d2=position5=corrected[4],
    // d3=position6=corrected[5], d4=position7=corrected[6]
    assign data_out = {corrected[6], corrected[5], corrected[4], corrected[2]};
endmodule