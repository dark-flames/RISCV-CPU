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
    input load_unsigned,
    input [31:0] pc_input,
    input [4:0] destination_register_number_input,
    input [1:0] write_back_type_input,
    output reg [31:0] read_output,
    output reg [31:0] execute_result_output,
    output reg [31:0] pc_output,
    output reg [4:0] destination_register_number_output,
    output reg [1:0] write_back_type_output
);
    wire [31:0] da_output;
    reg [31:0] read_output_internal;    
    reg [31:0] execute_result_internal;  
    reg [31:0] pc_internal; 
    reg [4:0] destination_register_number_internal;
    reg [1:0] write_back_type_internal;

    data_aligner da#(
        .DMEM_BASE(DMEM_BASE),
            .INIT_FILE(INIT_FILE),
            .DMEM_SIZE(DMEM_SIZE)
    )(
        .clk(clk),
        .alu_result(execute_result),
        .input_data(write_input),
        .read_output(da_output),
        .read_status(read_status),
        .write_status(write_status),
        .load_unsigned(load_unsigned),
    )

    always @(posedge clk) begin
        pc_internal <= pc_input;
        read_output_internal <= da_output;
        execute_result_internal <= execute_result;
        destination_register_number_internal <= destination_register_number_input;
        write_back_type_internal <= write_back_type_input;
    end

    always @(negedge clk) begin
        pc_output <= pc_internal;
        read_output <= read_output_internal;
        execute_result_output <= execute_result_internal;
        destination_register_number_output <= destination_register_number_internal;
        write_back_type_output <= write_back_type_internal;
    end

endmodule