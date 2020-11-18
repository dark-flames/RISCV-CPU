`include "src/format.vh"

module write_back(
    input clk,
    input [1:0] write_back_type,
    input [31:0] pc,
    input [31:0] memory_read_output,
    input [31:0] execute_result,
    input [4:0] write_back_register_input,
    output [31:0] write_back_value,
    output [4:0] write_back_register
);

    reg [31:0] write_back_value_internal;
    reg [4:0] write_back_register_internal;

    assign write_back_value = (write_back_type == `WB_LOAD) ? 
        memory_read_output : (
            (write_back_type == `WB_JAL) ? pc + 4 : (
                (write_back_type == `WB_NORMAL) ? execute_result : 0
            )
        );
    assign write_back_register = write_back_type == `WB_HICCUP ? 5'b00000 : write_back_register_input;
endmodule