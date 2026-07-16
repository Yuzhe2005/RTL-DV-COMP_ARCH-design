// ============================================================
// Problem: Load-Use Hazard Detection Unit
// ============================================================
// Design a combinational hazard detection unit for a simple pipelined CPU.
//
// The module should detect a load-use data hazard between the instruction
// currently in the EX stage and the instruction currently in the ID stage.
//
// Module interface:
// module hazard_detect (
//   input  logic [4:0] id_rs1,
//   input  logic [4:0] id_rs2,
//   input  logic [4:0] ex_rd,
//   input  logic       ex_mem_read,
//   input  logic       id_uses_rs2,
//   output logic       stall
// );
//
// Requirements:
// 1. The module should detect whether the instruction in ID depends on a
//    value being loaded by the instruction in EX.
//
// 2. Register fields:
//    - id_rs1 is the first source register of the instruction in ID.
//    - id_rs2 is the second source register of the instruction in ID.
//    - ex_rd is the destination register of the instruction in EX.
//
// 3. Load indication:
//    - ex_mem_read is asserted when the instruction in EX is a load
//      instruction.
//    - A load-use hazard is only possible when ex_mem_read is 1.
//
// 4. Hazard condition for rs1:
//    - If ex_rd matches id_rs1, and the EX-stage instruction is a load,
//      then the ID-stage instruction needs a value that is not ready yet.
//    - In this case, stall should be asserted.
//
// 5. Hazard condition for rs2:
//    - Some instructions use rs2 as a real source register.
//    - Some instructions, such as I-type instructions, may not use rs2.
//    - id_uses_rs2 indicates whether id_rs2 should be checked.
//    - If id_uses_rs2 is 1 and ex_rd matches id_rs2, then stall should be
//      asserted.
//
// 6. x0 behavior:
//    - Register x0 is hardwired to zero.
//    - If ex_rd is 0, it should not cause a hazard.
//    - Therefore, stall should only assert when ex_rd is not 0.
//
// 7. stall behavior:
//    - stall should be asserted when all of the following are true:
//        - the EX-stage instruction is a load;
//        - ex_rd is not x0;
//        - ex_rd matches id_rs1, or ex_rd matches id_rs2 while id_uses_rs2
//          is asserted.
//
// 8. Output behavior:
//    - stall should be purely combinational.
//    - stall should update immediately when the inputs change.
//    - No clock or reset is needed.
//
// 9. Example cases:
//    - load x5, 0(x1)
//      add  x6, x5, x7
//      ex_rd = 5, id_rs1 = 5
//      stall should be 1.
//
//    - load x5, 0(x1)
//      addi x6, x7, 10
//      id_rs1 = 7, id_uses_rs2 = 0
//      stall should be 0.
//
//    - load x0, 0(x1)
//      add  x6, x0, x7
//      ex_rd = 0
//      stall should be 0.
//
// 10. Implementation style:
//    - Use SystemVerilog.
//    - Use combinational logic.
//    - Continuous assignment is acceptable.
//    - Do not use sequential logic.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 11. Assumptions:
//    - Register indices are 5 bits wide.
//    - Register 0 represents x0 and never needs forwarding or stalling.
//    - This module only detects load-use hazards from EX to ID.
//    - Other hazards, such as branch hazards or multi-cycle functional-unit
//      hazards, are handled elsewhere.
// ============================================================

`default_nettype none

module hazard_detect (
  input  logic [4:0] id_rs1,
  input  logic [4:0] id_rs2,
  input  logic [4:0] ex_rd,
  input  logic       ex_mem_read,
  input  logic       id_uses_rs2,
  output logic       stall
);
    assign stall = ex_mem_read && (ex_rd != '0) && ((ex_rd == id_rs1)
                    || (id_uses_rs2 && ex_rd == id_rs2));
endmodule