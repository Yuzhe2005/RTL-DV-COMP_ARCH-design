// ============================================================
// Problem: Memory-Mapped GPIO Controller
// ============================================================
// Design a parameterized memory-mapped GPIO controller.
// Module interface:
// module gpio_mm #(
//   parameter GPIO_WIDTH = 8
// )(
//   input  logic                      clk,
//   input  logic                      rst_n,
//   input  logic [3:0]                address,
//   input  logic [GPIO_WIDTH-1:0]     write_data,
//   input  logic                      write_en,
//   input  logic                      read_en,
//   output logic [GPIO_WIDTH-1:0]     read_data,
//   inout  wire  [GPIO_WIDTH-1:0]     gpio_pins
// );
// Requirements:
// 1. Implement a memory-mapped GPIO peripheral.
// 2. The GPIO width should be parameterized by GPIO_WIDTH.
// 3. The design should provide three memory-mapped registers:
//    - address 4'h0: GPIO output register.
//    - address 4'h4: GPIO input register.
//    - address 4'h8: GPIO direction register.
// 4. GPIO output register behavior:
//    - Writes to address 4'h0 should update the output value register.
//    - Reads from address 4'h0 should return the current output register value.
// 5. GPIO direction register behavior:
//    - Writes to address 4'h8 should update the direction register.
//    - Reads from address 4'h8 should return the current direction register value.
//    - For each GPIO bit:
//      - direction bit = 1 means the pin is configured as output.
//      - direction bit = 0 means the pin is configured as input/high-Z.
// 6. GPIO pin behavior:
//    - If direction bit is 1, drive gpio_pins[i] using the output register bit.
//    - If direction bit is 0, gpio_pins[i] should be high impedance.
// 7. GPIO input register behavior:
//    - Reads from address 4'h4 should return the current value observed on gpio_pins.
//    - This allows software to read external pin values.
// 8. Write behavior:
//    - Writes should occur synchronously on the rising edge of clk.
//    - write_en controls whether a write happens.
//    - Invalid write addresses should be ignored.
// 9. Read behavior:
//    - read_data should return the decoded register value based on address.
//    - Invalid read addresses should return 0.
//    - The read path may be combinational.
// 10. Reset behavior:
//    - rst_n is an active-low asynchronous reset.
//    - On reset, the output register should be cleared to 0.
//    - On reset, the direction register should be cleared to 0.
//    - After reset, all GPIO pins should default to input/high-Z.
// 11. Implementation style:
//    - Use SystemVerilog.
//    - Use always_ff for writable registers.
//    - Use always_comb for read decode.
//    - Use continuous assignments for tri-state GPIO pin driving.
//    - The design should be synthesizable for an FPGA/ASIC-style GPIO interface.
// 12. Assumptions:
//    - GPIO pins are bidirectional.
//    - Direction register controls output enable.
//    - read_en is provided by the bus interface, but read_data may be decoded combinationally.
//    - No interrupt logic, edge detection, pull-up, or debounce logic is required.
// ============================================================

`default_nettype none

module gpio_mm #(
  parameter GPIO_WIDTH = 8
)(
  input  logic                      clk,
  input  logic                      rst_n,
  input  logic [3:0]                address,
  input  logic [GPIO_WIDTH-1:0]     write_data,
  input  logic                      write_en,
  input  logic                      read_en,
  output logic [GPIO_WIDTH-1:0]     read_data,
  inout  wire  [GPIO_WIDTH-1:0]     gpio_pins
);
    localparam logic [3:0] GPIO_OUT = 4'h0;
    localparam logic [3:0] GPIO_IN = 4'h4;
    localparam logic [3:0] GPIO_DIR = 4'h8;

    logic [GPIO_WIDTH-1:0] gpio_out_reg;
    logic [GPIO_WIDTH-1:0] gpio_dir_reg;

    // always_comb begin // wire signal 不能放进 always_comb block 里赋值
    //     for (int i = 0; i < GPIO_WIDTH; i++) begin
    //         gpio_pins[i] = gpio_dir_reg[i] ? gpio_out_reg[i] : 'z;
    //     end
    // end

    genvar g;
    generate
        for(g = 0; g < GPIO_WIDTH; g++) begin : tristate
            assign gpio_pins[g] = gpio_dir_reg[g] ? gpio_out_reg[g] : 1'bz;
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_out_reg <= '0;
            gpio_dir_reg <= '0;
        end else begin
            if (write_en) begin
                case (address)
                    GPIO_OUT: gpio_out_reg <= write_data;
                    GPIO_DIR: gpio_dir_reg <= write_data;
                    default: ;
                endcase
            end
        end
    end
    
    // always_comb begin
    //     read_data = '0;
    //     if (read_en) begin
    //         for (int i = 0; i < GPIO_WIDTH; i++) begin
    //             if (!gpio_dir_reg[i]) read_data[i] = gpio_pins[i];
    //         end
    //     end
    // end

    always_comb begin
        read_data = '0;
        case (address)
            GPIO_IN: read_data = gpio_pins;
            GPIO_OUT: read_data = gpio_out_reg;
            GPIO_DIR: read_data = gpio_dir_reg;
            default: read_data = '0;
        endcase
    end
endmodule