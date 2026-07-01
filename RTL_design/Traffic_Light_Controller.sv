// ============================================================
// Problem: Traffic Light Controller
// ============================================================
// Design a parameterized traffic light controller for a two-way
// intersection with North-South and East-West directions.
// Module interface:
// module traffic_light #(
//   parameter NS_GREEN_TIME  = 10,
//   parameter NS_YELLOW_TIME = 2,
//   parameter EW_GREEN_TIME  = 10,
//   parameter EW_YELLOW_TIME = 2
// )(
//   input  logic clk,
//   input  logic rst_n,
//   output logic ns_red,
//   output logic ns_yellow,
//   output logic ns_green,
//   output logic ew_red,
//   output logic ew_yellow,
//   output logic ew_green
// );
// Requirements:
// 1. This is a synchronous Moore FSM.
//    - State updates happen on the rising edge of clk.
//    - Reset is active-low asynchronous reset: rst_n.
//    - Outputs depend only on the current traffic-light phase/state.
// 2. Traffic-light phases:
//    - The controller should alternate traffic permission between NS and EW.
//    - NS direction should receive green first after reset.
//    - After NS green expires, NS should go yellow before EW gets green.
//    - After EW green expires, EW should go yellow before NS gets green again.
//    - The phase sequence should repeat continuously.
// 3. Timing parameters:
//    - NS_GREEN_TIME controls how many clock cycles NS green stays active.
//    - NS_YELLOW_TIME controls how many clock cycles NS yellow stays active.
//    - EW_GREEN_TIME controls how many clock cycles EW green stays active.
//    - EW_YELLOW_TIME controls how many clock cycles EW yellow stays active.
//    - Each parameter represents a number of clk cycles.
// 4. Timer behavior:
//    - Use an internal timer/counter to track how long the current phase remains active.
//    - On reset, the controller should enter the initial NS green phase.
//    - The initial timer value should make NS green last exactly NS_GREEN_TIME cycles.
//    - When the timer expires, move to the next traffic-light phase.
//    - When entering a new phase, reload the timer according to that phase's time parameter.
//    - If the timer has not expired, decrement or advance the timer each clock cycle.
// 5. Output behavior:
//    - During NS green phase:
//        ns_green should be high.
//        ew_red should be high.
//    - During NS yellow phase:
//        ns_yellow should be high.
//        ew_red should be high.
//    - During EW green phase:
//        ew_green should be high.
//        ns_red should be high.
//    - During EW yellow phase:
//        ew_yellow should be high.
//        ns_red should be high.
//    - For each direction, exactly one of red, yellow, and green should be high.
// 6. Safety behavior:
//    - NS and EW should never both be green at the same time.
//    - NS and EW should never both be yellow at the same time.
//    - When one direction is green or yellow, the other direction should be red.
// 7. Reset behavior:
//    - When rst_n is low:
//        the FSM should reset to the initial NS green phase.
//        the timer should be initialized for the NS green duration.
//    - Outputs should reflect the reset phase immediately after reset.
// 8. Implementation style:
//    - Use SystemVerilog.
//    - Use an enum type for the FSM states.
//    - Use always_ff for sequential state/timer registers.
//    - Use always_comb for output decode logic.
//    - The design should be synthesizable.
// 9. Assumptions:
//    - All timing parameters are positive integers.
//    - The timer width should be large enough for the given timing parameters.
//    - No pedestrian button or traffic sensor input is required.
//    - This problem only requires fixed-time phase sequencing.
// ============================================================

`default_nettype none

module traffic_light #(
  parameter NS_GREEN_TIME  = 10,
  parameter NS_YELLOW_TIME = 2,
  parameter EW_GREEN_TIME  = 10,
  parameter EW_YELLOW_TIME = 2
)(
  input  logic clk,
  input  logic rst_n,
  output logic ns_red,
  output logic ns_yellow,
  output logic ns_green,
  output logic ew_red,
  output logic ew_yellow,
  output logic ew_green
);

    typedef enum logic [1:0] {NS_GREEN, NS_YELLOW, EW_GREEN, EW_YELLOW} state_t;
    state_t cs, ns;

    localparam int MAX_TIME_GREEN = (NS_GREEN_TIME > EW_GREEN_TIME) ? NS_GREEN_TIME : EW_GREEN_TIME;
    localparam int MAX_TIME_YELLOW = (NS_YELLOW_TIME > EW_YELLOW_TIME) ? NS_YELLOW_TIME : EW_YELLOW_TIME;
    localparam int MAX_TIME = (MAX_TIME_GREEN > MAX_TIME_YELLOW) ? MAX_TIME_GREEN : MAX_TIME_YELLOW;
    localparam int TIME_PTR = $clog2(MAX_TIME);
    // localparam int TIME_PTR = (MAX_TIME <= 1) ? 1 : $clog2(MAX_TIME); 
    // 为了预防MAX_TIME == 1 因为 $clog2(1) = 0
    logic [TIME_PTR-1:0] count, count_d;

    always_comb begin
        ns = cs;
        ns_red = 0;
        ns_yellow = 0;
        ns_green = 0;
        ew_red = 0;
        ew_yellow = 0;
        ew_green = 0;
        count_d = count; // 第一遍写的时候忘记了
        
        case (cs)
            NS_GREEN: begin
                ns_green = 1;
                ew_red = 1;
                if (count == 0) begin
                    ns = NS_YELLOW;
                    count_d = NS_YELLOW_TIME-1;
                end else begin
                    count_d = count-1;
                    ns = NS_GREEN;
                end
            end
            NS_YELLOW: begin
                ns_yellow = 1;
                ew_red = 1;
                if (count == 0) begin
                    ns = EW_GREEN;
                    count_d = EW_GREEN_TIME-1;
                end else begin
                    ns = NS_YELLOW;
                    count_d = count-1;
                end
            end
            EW_GREEN: begin
                ew_green = 1;
                ns_red = 1;
                if (count == 0) begin
                    ns = EW_YELLOW;
                    count_d = EW_YELLOW_TIME-1;
                end else begin
                    ns = EW_GREEN;
                    count_d = count-1;
                end
            end
            EW_YELLOW: begin
                ew_yellow = 1;
                ns_red = 1;
                if (count == 0) begin
                    ns = NS_GREEN;
                    count_d = NS_GREEN_TIME-1;
                end else begin
                    ns = EW_YELLOW;
                    count_d = count-1;
                end
            end
            default: ;
        endcase
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs <= NS_GREEN;
            count <= NS_GREEN_TIME-1;
        end else begin
            cs <= ns;
            count <= count_d;
        end
    end
endmodule