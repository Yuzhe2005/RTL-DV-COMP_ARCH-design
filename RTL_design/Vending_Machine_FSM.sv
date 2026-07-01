// ============================================================
// Problem: Vending Machine Controller
// ============================================================
// Design a parameterized vending machine controller.
// Module interface:
// module vending_machine #(
//   parameter ITEM_PRICE = 25
// )(
//   input  logic        clk,
//   input  logic        rst_n,
//   input  logic        coin_valid,
//   input  logic [4:0]  coin_value,
//   output logic        dispense,
//   output logic        change_valid,
//   output logic [4:0]  change_amount
// );
// Requirements:
// 1. This is a synchronous vending machine controller.
//    - All state and credit updates happen on the rising edge of clk.
//    - Reset is active-low asynchronous reset: rst_n.
//    - The item price is parameterized by ITEM_PRICE.
// 2. Coin input behavior:
//    - coin_valid indicates that coin_value should be considered in the current cycle.
//    - The machine should only accept valid coin denominations.
//    - Valid denominations are 5, 10, and 25 cents.
//    - Invalid coin values should be ignored and should not change the stored credit.
// 3. Credit tracking:
//    - Maintain an internal credit value.
//    - The credit value represents how much valid money has been inserted.
//    - On reset, credit should become 0.
//    - When a valid coin is inserted, add its value to the current credit.
//    - Credit should be wide enough to store values larger than ITEM_PRICE.
// 4. Dispense behavior:
//    - When the accumulated credit reaches or exceeds ITEM_PRICE, the machine should dispense one item.
//    - dispense should assert for one clock cycle per purchased item.
//    - After dispensing, subtract ITEM_PRICE from the stored credit.
//    - The machine should not dispense if the accumulated credit is less than ITEM_PRICE.
// 5. Change behavior:
//    - If there is remaining credit after an item is dispensed, return it as change.
//    - change_valid should assert for one clock cycle when change is being returned.
//    - change_amount should contain the remaining credit amount.
//    - After returning change, clear the stored credit back to 0.
//    - If there is no remaining credit after dispensing, no change should be returned.
// 6. Output behavior:
//    - dispense should normally be 0 unless an item is being dispensed.
//    - change_valid should normally be 0 unless change is being returned.
//    - change_amount should normally be 0 unless change_valid is high.
//    - Output pulses should be registered and last one clock cycle.
// 7. Reset behavior:
//    - When rst_n is low:
//        stored credit should reset to 0.
//        dispense should reset to 0.
//        change_valid should reset to 0.
//        change_amount should reset to 0.
//        the controller should return to its initial idle condition.
// 8. Transaction behavior:
//    - The machine should support multiple coins being inserted over multiple cycles.
//    - The machine should ignore additional invalid coins.
//    - A valid coin that causes the accumulated credit to reach the price should trigger a dispense sequence.
//    - If the inserted amount exceeds the item price, the excess should be returned as change.
// 9. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for sequential logic.
//    - You may use an FSM or equivalent registered control logic.
//    - The design should be synthesizable.
// 10. Assumptions:
//    - Only one coin can be presented per clock cycle.
//    - coin_value is meaningful only when coin_valid is high.
//    - ITEM_PRICE is positive.
//    - This problem only requires one item to be dispensed per completed purchase.
// ============================================================

`default_nettype none

module vending_machine #(
  parameter ITEM_PRICE = 25
)(
  input  logic        clk,
  input  logic        rst_n,
  input  logic        coin_valid,
  input  logic [4:0]  coin_value,
  output logic        dispense,
  output logic        change_valid,
  output logic [4:0]  change_amount
);
    localparam int MAX_POSSIBLE = ITEM_PRICE + 25;
    localparam int CREDIT_PTW = $clog2(MAX_POSSIBLE);
    logic [CREDIT_PTW:0] credit, credit_d;

    typedef enum logic [1:0] {ACC, DISPENSE, CHANGE} state_t;
    state_t state, ns;

    logic valid_coin;
    assign valid_coin = (coin_valid) && (coin_value == 5 || coin_value == 10
                                         || coin_value == 25);

    always_comb begin
        ns       = state;
        credit_d = credit;

        case (state)
            ACC: begin
                if (valid_coin) begin
                    credit_d = credit + coin_value;
                end

                if (credit_d >= ITEM_PRICE) begin
                    ns = DISPENSE;
                end
            end
            DISPENSE: begin
                credit_d = credit - ITEM_PRICE;

                if ((credit - ITEM_PRICE) > 0) begin
                    ns = CHANGE;
                end else begin
                    ns = ACC;
                end
            end
            CHANGE: begin
                credit_d = '0;
                ns       = ACC;
            end
            default: begin
                ns       = ACC;
                credit_d = '0;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= ACC;
            credit        <= '0;
            dispense      <= 1'b0;
            change_valid  <= 1'b0;
            change_amount <= '0;
        end else begin
            state     <= ns;
            credit <= credit_d;
            dispense      <= 1'b0;
            change_valid  <= 1'b0;
            change_amount <= '0;

            if (state == DISPENSE) begin
                dispense <= 1'b1;
            end
            if (state == CHANGE) begin
                change_valid  <= 1'b1;
                change_amount <= credit[4:0];
            end
        end
    end
endmodule