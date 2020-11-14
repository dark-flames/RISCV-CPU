module register_access(
    input clk,
    // decode
    input [4:0] register_number_a,
    input [4:0] register_number_b,
    input pc_for_a,
    input immediate_value_for_b,
    input [4:0] pc,
    input [31:0] immediate_value,
    input [4:0] execute_instruction_input,
    input condition_branch_input,
    input taken_input,
    output reg [31:0] data_a,
    output reg [31:0] data_b,
    output reg [4:0] execute_instruction_output
    output reg condition_branch_output;
    output reg taken_output;
    output reg [31:0] immediate_value_output    ;
    output reg [31:0] pc_output;

    // write back
    input [4:0] destination_register_numer,
    input [31:0] write_back_data,

    //jalr
    input jalr_input,
    output reg jalr_output,
    output reg [31:0] new_pc,
    
);

    wire [31:0] register_data_a_internal;
    wire [31:0] register_data_b_internal;

    rf rf(
        .clk(clk),
        .register_number_a(register_number_a),
        .data_a(register_register_data_a_internal),
        .register_number_b(register_number_b),
        .data_b(register_data_b_internal),
        .destination_register_numer(destination_register_number),
        .write_data(write_back_value)
    );

    reg jalr_internal;
    reg pc_for_a_internal;
    reg immediate_value_for_b_internal;
    reg [31:0] pc_internal;
    reg [31:0] immediate_value_internal;
    reg condition_branch_internal;
    reg taken_internal;

    reg [4:0] execute_instruction_internal;

    always @(posedge clk) begin
        if (jalr_input) begin
            jal_internal <= jal_input;
            pc_internal <= pc;
            pc_for_a_internal <= pc_for_a;
            immediate_value_for_b_internal <= immediate_value_for_b;
            immediate_value_internal <= immediate_value;
            execute_instruction_internal <= execute_instruction_input;
            condition_branch_internal <= condition_branch_input;
            taken_internal <= taken_input;
        end
    end

    always@(negedge clk) begin
        jalr_output <= jalr_internal;
        if(jalr_internal) begin
            new_pc <= register_data_a_internal + immediate_value_internal;
        end

        data_a <= pc_for_a_internal ? pc_internal : register_data_a_internal;
        data_b <= immediate_value_for_b_internal ? immediate_value_internal : register_data_b_internal;
        execute_instruction_output <= execute_instruction_internal;
        condition_branch_output <= condition_branch_internal;
        taken_output <= taken_internal;
        immediate_value_output <= immediate_value_internal;
        pc_output <= pc_internal;
    end




endmodule