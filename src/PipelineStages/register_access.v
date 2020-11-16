module register_access(
    input clk,
    input reset,
    // decode
    input [4:0] register_number_a,
    input [4:0] register_number_b,
    input pc_for_a,
    input immediate_value_for_b,
    input [31:0] pc,
    input [31:0] immediate_value,
    input [4:0] execute_instruction_input,
    input condition_branch_input,
    input taken_input,
    input [1:0] read_status_input,
    input [1:0] write_status_input,
    input load_signed_input,
    input [4:0] destination_register_number_input,
    input [1:0] write_back_type_input,
    output reg [31:0] data_a,
    output reg [31:0] data_b,
    output reg [31: 0] rs2_value,
    output reg [4:0] execute_instruction_output,
    output reg condition_branch_output,
    output reg taken_output,
    output reg [31:0] immediate_value_output,
    output reg [31:0] pc_output,
    output reg [1:0] read_status_output,
    output reg [1:0] write_status_output,
    output reg load_signed_output,
    output reg [4:0] destination_register_number_output,
    output reg [1:0] write_back_type_output,

    // write back
    input [4:0] destination_register_number,
    input [31:0] write_back_data,

    //jalr
    input jalr_input,
    output reg jalr_output,
    output reg [31:0] new_pc,
    output reg ret = 0,

    //forward
    input [4:0] execute_destination_register_number,
    input [31:0] execute_result_forward,
    input execute_forward_enable,
    input [4:0] memory_access_destination_register_number,
    input [31:0] memory_access_result_forward,
    input memory_access_forward_enable,
    input [4:0] write_back_destination_register_number,
    input [31:0] write_back_result_forward,
    input write_back_forward_enable
);

    wire [31:0] register_data_a_internal;
    wire [31:0] register_data_b_internal;
    wire [31:0] result_a_internal;
    wire [31:0] result_b_internal;

    rf rf(
        .clk(clk),
        .register_number_a(register_number_a),
        .data_a(register_data_a_internal),
        .register_number_b(register_number_b),
        .data_b(register_data_b_internal),
        .destination_register_numer(destination_register_number),
        .write_data(write_back_data)
    );

    reg jalr_internal;
    reg pc_for_a_internal;
    reg immediate_value_for_b_internal;
    reg [31:0] pc_internal;
    reg [31:0] immediate_value_internal;
    reg condition_branch_internal;
    reg taken_internal;
    reg [1:0] read_status_internal;
    reg [1:0] write_status_internal;
    reg load_signed_internal;
    reg [4:0] destination_register_number_internal;
    reg [1:0] write_back_type_internal;

    reg [4:0] execute_instruction_internal;

    always @(posedge clk or posedge reset) begin
        pc_internal <= pc;
        destination_register_number_internal <= destination_register_number_input;
        write_back_type_internal <= write_back_type_input;
        pc_for_a_internal <= pc_for_a;
        immediate_value_for_b_internal <= immediate_value_for_b;
        immediate_value_internal <= immediate_value;
        execute_instruction_internal <= execute_instruction_input;
        condition_branch_internal <= condition_branch_input;
        taken_internal <= taken_input;
        read_status_internal <= read_status_input;
        write_status_internal <= write_status_input;
        load_signed_internal <= load_signed_input;
        jalr_internal <= jalr_input;
        if(reset) begin
            write_back_type_internal <= `WB_HICCUP;
        end
    end

    forward fd (
        .execute_destination_register_number(execute_destination_register_number),
        .execute_result_forward(execute_result_forward),
        .execute_forward_enable(execute_forward_enable),
        .memory_access_destination_register_number(memory_access_destination_register_number),
        .memory_access_result_forward(memory_access_result_forward),
        .memory_access_forward_enable(memory_access_forward_enable),
        .write_back_destination_register_number(write_back_destination_register_number),
        .write_back_result_forward(write_back_result_forward),
        .write_back_forward_enable(write_back_forward_enable),

        .register_number_a(register_number_a),
        .register_value_a(register_data_a_internal),
        .result_a(result_a_internal),
        .register_number_b(register_number_b),
        .register_value_b(register_data_b_internal),
        .result_b(result_b_internal)
    );

    always@(negedge clk) begin
        jalr_output <= jalr_internal && write_back_type_internal !=`WB_HICCUP;
        if(jalr_internal) begin
            new_pc <= (pc_for_a_internal ? pc_internal : result_a_internal) + immediate_value_internal;
            ret <= write_back_type_internal !=`WB_HICCUP && destination_register_number_internal == 5'b00000;
        end

        data_a <= pc_for_a_internal ? pc_internal : result_a_internal;
        data_b <= immediate_value_for_b_internal ? immediate_value_internal : result_b_internal;
        rs2_value <= result_b_internal;
        execute_instruction_output <= execute_instruction_internal;
        condition_branch_output <= condition_branch_internal;
        taken_output <= taken_internal;
        immediate_value_output <= immediate_value_internal;
        pc_output <= pc_internal;
        read_status_output <= read_status_internal;
        write_status_output <= write_status_internal;
        load_signed_output <= load_signed_internal;
        destination_register_number_output <= destination_register_number_internal;
        write_back_type_output <= reset ? `WB_HICCUP : write_back_type_internal;
    end




endmodule