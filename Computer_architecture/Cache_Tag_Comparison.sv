// ============================================================
// Problem: Set-Associative Cache Tag Comparator
// ============================================================
// Design combinational logic for comparing a request tag against
// the tags stored in multiple cache ways.
//
// Module interface:
// module cache_tag_cmp #(
//   parameter TAG_W  = 20,
//   parameter N_WAYS = 4
// )(
//   input  logic [TAG_W-1:0]           req_tag,
//   input  logic [TAG_W-1:0]           way_tag [N_WAYS],
//   input  logic [N_WAYS-1:0]          way_valid,
//   output logic [N_WAYS-1:0]          way_match,
//   output logic                       hit,
//   output logic                       miss,
//   output logic [$clog2(N_WAYS)-1:0]  hit_way,
//   output logic                       multi_hit_error
// );
//
// Requirements:
// 1. Compare the incoming request tag req_tag against every cache way's
//    stored tag way_tag[w].
//
// 2. A way only matches if:
//    - that way is valid;
//    - its stored tag equals req_tag.
//
// 3. Generate way_match as a one-bit-per-way match vector.
//    - way_match[w] should be 1 when way w is valid and its tag matches.
//    - way_match[w] should be 0 otherwise.
//
// 4. Generate hit:
//    - hit should be 1 if at least one way matches.
//    - hit should be 0 if no way matches.
//
// 5. Generate miss:
//    - miss should be the opposite of hit.
//    - miss should be 1 when no valid matching way exists.
//
// 6. Generate hit_way:
//    - hit_way should indicate which way hit.
//    - If multiple ways match, choose the lowest-index matching way as
//      the reported hit_way.
//    - If there is no hit, hit_way should default to 0.
//
// 7. Generate multi_hit_error:
//    - multi_hit_error should be 1 if more than one way matches the
//      request tag at the same time.
//    - This indicates an invalid cache state, because normally a given
//      tag should not appear as valid in multiple ways of the same set.
//
// 8. Implementation style:
//    - The module should be purely combinational.
//    - Use always_comb.
//    - Do not use clocked logic.
//    - Do not infer latches.
//    - Make sure all outputs have deterministic values for every input
//      combination.
//
// 9. Parameter behavior:
//    - TAG_W controls the width of each cache tag.
//    - N_WAYS controls the number of associative ways.
//    - The design should work for different N_WAYS values.
//
// 10. Assumptions:
//    - N_WAYS is at least 1.
//    - way_tag and way_valid correspond to the ways of one selected
//      cache set.
//    - This module only performs tag comparison; it does not store cache
//      data, update valid bits, choose replacement victims, or handle
//      cache refills.
// ============================================================

`default_nettype none

module cache_tag_cmp #(
  parameter TAG_W  = 20,
  parameter N_WAYS = 4
)(
  input  logic [TAG_W-1:0]           req_tag,
  input  logic [TAG_W-1:0]           way_tag [N_WAYS],
  input  logic [N_WAYS-1:0]          way_valid,
  output logic [N_WAYS-1:0]          way_match,
  output logic                       hit,
  output logic                       miss,
  output logic [$clog2(N_WAYS)-1:0]  hit_way,
  output logic                       multi_hit_error
);
    always_comb begin
        way_match = '0;
        hit = 0;
        hit_way = '0;
        multi_hit_error = 0;

        for (int w = 0; w < N_WAYS; w++) begin
            if (way_valid[w] && way_tag[w] ==  req_tag) begin
                if (hit == 1) begin
                    multi_hit_error = 1;
                    way_match[w] = 1; // 这个还是要写的
                    // break;
                end else begin
                    hit = 1;
                    hit_way = w[$clog2(N_WAYS)-1:0];
                    way_match[w] = 1;
                end
            end
        end
    end

    assign miss = !hit;
endmodule

//------------------------------------------------------------------------------

// sample solution:

module cache_tag_cmp #(
  parameter TAG_W  = 20,
  parameter N_WAYS = 4
)(
  input  logic [TAG_W-1:0]           req_tag,
  input  logic [TAG_W-1:0]           way_tag [N_WAYS],
  input  logic [N_WAYS-1:0]          way_valid,
  output logic [N_WAYS-1:0]          way_match,
  output logic                       hit,
  output logic                       miss,
  output logic [$clog2(N_WAYS)-1:0]  hit_way,
  output logic                       multi_hit_error
);
  always_comb begin
    for (int w = 0; w < N_WAYS; w++) begin
      way_match[w] = way_valid[w] && (way_tag[w] == req_tag);
    end

    hit             = |way_match;
    miss            = !hit;
    multi_hit_error = |(way_match & (way_match - 1'b1));
    hit_way         = '0;

    // Lowest-index match wins.
    for (int w = 0; w < N_WAYS; w++) begin
      if (way_match[w]) begin
        hit_way = w[$clog2(N_WAYS)-1:0];
        break;
      end
    end
  end
endmodule