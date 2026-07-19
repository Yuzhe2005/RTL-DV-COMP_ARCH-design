// ============================================================
// Problem: SIMD/SIMT Memory Bank Conflict Detector
// ============================================================
// Design a combinational bank-conflict detector for a SIMD/SIMT memory
// access.
//
// Multiple active threads may access memory in the same cycle. Memory is
// divided into N_BANKS banks. If two or more active threads access the same
// bank in the same cycle, a bank conflict occurs.
//
// Module interface:
// module bank_conflict #(
//   parameter N_BANKS     = 32,
//   parameter THREADS     = 32,
//   parameter ADDR_W      = 32,
//   parameter BANK_OFFSET = 2
// )(
//   input  logic [ADDR_W-1:0]                   addr [THREADS],
//   input  logic [THREADS-1:0]                  active_mask,
//   output logic                                has_conflict,
//   output logic [$clog2(N_BANKS)-1:0]          conflict_bank_id,
//   output logic                                can_issue,
//   output logic [THREADS-1:0]                  conflict_mask
// );
//
// Requirements:
// 1. The module should check whether the active threads access conflicting
//    memory banks.
//
// 2. Thread activity:
//    - active_mask[t] = 1 means thread t is active and its address should be
//      checked.
//    - active_mask[t] = 0 means thread t is inactive and should be ignored.
//
// 3. Bank calculation:
//    - For each active thread t, compute its target memory bank from addr[t].
//    - BANK_OFFSET removes the byte offset inside a word or access unit.
//    - The bank index is selected from the address bits above BANK_OFFSET.
//
//    Conceptually:
//      bank = (addr[t] >> BANK_OFFSET) & (N_BANKS - 1)
//
// 4. Conflict definition:
//    - A conflict occurs when two or more active threads map to the same
//      bank in the same cycle.
//    - If every active thread maps to a different bank, there is no conflict.
//
// 5. has_conflict behavior:
//    - has_conflict should be 1 if any bank has more than one active thread
//      accessing it.
//    - has_conflict should be 0 if no conflict exists.
//
// 6. can_issue behavior:
//    - can_issue should be 1 if there is no bank conflict.
//    - can_issue should be 0 if any bank conflict exists.
//
// 7. conflict_bank_id behavior:
//    - If a conflict exists, conflict_bank_id should indicate a bank where a
//      conflict was detected.
//    - If multiple banks conflict, reporting any detected conflicting bank is
//      acceptable unless otherwise specified.
//    - If no conflict exists, conflict_bank_id may be 0.
//
// 8. conflict_mask behavior:
//    - conflict_mask[t] should be 1 if thread t participates in a detected
//      bank conflict.
//    - Threads that access unique banks should remain 0 in conflict_mask.
//    - Inactive threads should remain 0 in conflict_mask.
//
// 9. Example:
//    - THREADS = 4
//    - active_mask = 4'b1111
//    - thread 0 accesses bank 3
//    - thread 1 accesses bank 5
//    - thread 2 accesses bank 3
//    - thread 3 accesses bank 7
//
//    Then:
//      has_conflict = 1
//      can_issue = 0
//      conflict_bank_id may be 3
//      conflict_mask = 4'b0101
//
//    because threads 0 and 2 both access bank 3.
//
// 10. No-conflict example:
//    - active threads access banks 0, 1, 2, and 3.
//    - No two active threads access the same bank.
//
//    Then:
//      has_conflict = 0
//      can_issue = 1
//      conflict_mask = 0
//
// 11. Implementation style:
//    - Use SystemVerilog.
//    - The design should be purely combinational.
//    - No clock or reset is required.
//    - Use temporary per-bank tracking to remember which threads have
//      already accessed each bank.
//    - Provide default assignments to avoid latches.
//    - Do not use delays or simulation-only constructs.
//    - The design should be synthesizable.
//
// 12. Assumptions:
//    - N_BANKS is a power of two.
//    - THREADS is at least 1.
//    - BANK_OFFSET corresponds to the number of low address bits ignored
//      when selecting the memory bank.
//    - This module only detects conflicts; conflict resolution or replay is
//      handled elsewhere.
// ============================================================

`default_nettype none

module bank_conflict #(
  parameter N_BANKS     = 32,
  parameter THREADS     = 32,
  parameter ADDR_W      = 32,
  parameter BANK_OFFSET = 2
)(
  input  logic [ADDR_W-1:0]                   addr [THREADS],
  input  logic [THREADS-1:0]                  active_mask,
  output logic                                has_conflict,
  output logic [$clog2(N_BANKS)-1:0]          conflict_bank_id,
  output logic                                can_issue,
  output logic [THREADS-1:0]                  conflict_mask
);
    logic [THREADS-1:0] used[N_BANKS];
    logic [$clog2(N_BANKS)-1:0] bank;

    always_comb begin
        has_conflict = 1'b0;
        conflict_bank_id = '0;
        can_issue = 1'b1;
        conflict_mask = '0;
        for (int i = 0; i < N_BANKS; i++)
            used[i] = '0;

        for (int i = 0; i < THREADS; i++) begin
            if (active_mask[i]) begin
                bank = (addr[i] >> BANK_OFFSET) & (N_BANKS-1);
                if (|used[bank]) begin
                    has_conflict = 1'b1;
                    conflict_bank_id = bank;
                    can_issue = 1'b0;
                    conflict_mask = conflict_mask | used[bank];
                    conflict_mask[i] = 1'b1;
                end
                used[bank][i] = 1'b1;
            end
        end
    end
endmodule