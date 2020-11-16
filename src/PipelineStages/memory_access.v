`include "src/format.vh"

module memory_access#(
    parameter DMEM_BASE=32'h0010_0000,
    parameter INIT_FILE="target/data.mif",
    parameter DMEM_SIZE=32768
) (
    input clk,
    input [31:0] execute_result,
    input [31:0] write_input,
    input [1:0] read_status,
    input [1:0] write_status,
    input load_signed,
    input [31:0] pc_input,
    input [4:0] destination_register_number_input,
    input [1:0] write_back_type_input,
    output reg [31:0] read_output,
    output reg [31:0] execute_result_output,
    output reg [31:0] pc_output,
    output reg [4:0] destination_register_number_output,
    output reg [1:0] write_back_type_output,
    output [31:0] value_forward,
    output [4:0] register_forward,
    output forward_enable
);
    wire [31:0] da_output;  
    reg [31:0] pc_internal; 
    reg [4:0] destination_register_number_internal;
    reg [1:0] write_back_type_internal;
    reg [31:0] write_input_internal;
    reg [31:0] read_output_internal;
    reg [1:0] write_status_internal;
    reg [31:0] execute_result_internal;
    reg load_signed_internal;
    reg hiccup_internal;
    wire hiccup;
    wire [1:0] write_status_for_da;

    assign hiccup = (write_back_type_input == `WB_HICCUP);


    // write nothing when hiccup
    assign write_status_for_da = hiccup ? `DM_NONE : write_status;

    daligner #(
        .DMEM_BASE(DMEM_BASE),
            .INIT_FILE(INIT_FILE),
            .DMEM_SIZE(DMEM_SIZE)
    ) da (
        .clk(clk),
        .alu_result(execute_result),
        .input_data(write_input_internal),
        .read_output(da_output),
        .read_status(read_status),
        .write_status(write_status_internal),
        .load_signed(load_signed_internal)
    );

    assign forward_enable = (write_back_type_input == `WB_LOAD || write_back_type_input == `WB_NORMAL);
    assign value_forward = write_back_type_input == `WB_LOAD ? da_output : execute_result;
    assign register_forward = destination_register_number_input;

    always @(posedge clk) begin
        pc_internal <= pc_input;
        destination_register_number_internal <= destination_register_number_input;
        write_back_type_internal <= write_back_type_input;
        write_input_internal <= write_input;
        write_status_internal <= write_status_for_da;
        load_signed_internal <= load_signed;
        execute_result_internal <= execute_result;
        hiccup_internal <= hiccup;
        read_output_internal <= da_output;
    end

    always @(negedge clk) begin
        pc_output <= pc_internal;
        read_output <= read_output_internal;
        execute_result_output <= execute_result_internal;
        destination_register_number_output <= destination_register_number_internal;
        write_back_type_output <= write_back_type_internal;
    end

endmodule