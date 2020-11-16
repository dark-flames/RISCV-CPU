`include "src/format.vh"

module execute(
    input clk,
    input reset,
    input [31:0] data_a,
    input [31:0] data_b,
    input [31:0] rs2_value_input,
    input [31:0] immediate_value,
    input [4:0] instruction,
    input [31:0] pc,
    input condition_branch,
    input taken,
    input [1:0] read_status_input,
    input [1:0] write_status_input,
    input load_signed_input,
    input [4:0] destination_register_number_input,
    input [1:0] write_back_type_input,
    output reg [31:0] pc_output,
    output reg [31:0] result,
    output reg mispredict,
    output reg [31:0] new_pc,
    output reg [31:0] rs2_value_output,
    output reg [1:0] read_status_output,
    output reg [1:0] write_status_output,
    output reg load_signed_output,
    output reg [4:0] destination_register_number_output,
    output reg [1:0] write_back_type_output,
    output reg [31:0] value_forward,
    output reg [4:0] register_forward,
    output reg forward_enable
);

    wire [31:0] alu_output;
    wire [31:0] shift_output;

    alu alu(
        .input_a(data_a),
        .input_b(data_b),
        .instruction(instruction),
        .result(alu_output)
    );

    shift shift(
        .input_a(data_a),
        .input_b(data_b[4:0]),
        .instruction(instruction),
        .result(shift_output)
    );


    reg [31:0] result_internal;
    reg mispredict_internal;
    reg [31:0] new_pc_internal;
    reg [31:0] rs2_value_internal;
    reg [1:0] read_status_internal;
    reg [1:0] write_status_internal;
    reg load_signed_internal;
    reg [31:0] pc_internal;
    reg [4:0] destination_register_number_internal;
    reg [1:0] write_back_type_internal;
    reg condition_branch_internal;
    reg taken_internal;
    reg [31:0] immediate_value_internal;

    always @(posedge clk or posedge reset) begin
        pc_internal <= pc;
        mispredict <= 0;
        result_internal <= (instruction[4:2] == 3'b100) ? shift_output : alu_output;
        value_forward <= (instruction[4:2] == 3'b100) ? shift_output : alu_output;
        forward_enable <= (write_back_type_input == `WB_NORMAL) && (write_back_type_input != `WB_HICCUP);
        register_forward <= destination_register_number_input;
        rs2_value_internal <= rs2_value_input;
        read_status_internal <= read_status_input;
        write_status_internal <= write_status_input;
        load_signed_internal <= load_signed_input;
        destination_register_number_internal <= destination_register_number_input;
        write_back_type_internal <= write_back_type_input;
        condition_branch_internal <= condition_branch;
        taken_internal <= taken;
        immediate_value_internal <= immediate_value;
        if (reset) begin
            write_back_type_internal <= `WB_HICCUP;
            mispredict <= 0;
        end
    end

    always @(negedge clk) begin
        result <= result_internal;
        if (write_back_type_internal != `WB_HICCUP && condition_branch_internal && result_internal[0] && taken_internal) begin
            mispredict <= 1;
            new_pc <= pc_internal + immediate_value_internal;
        end else begin
            mispredict <= 0;
        end
        rs2_value_output <= rs2_value_internal;
        read_status_output <= read_status_internal;
        write_status_output <= write_status_internal;
        load_signed_output <= load_signed_internal;
        pc_output <= pc_internal;
        destination_register_number_output <=  destination_register_number_internal;
        write_back_type_output <= reset ? `WB_HICCUP : write_back_type_internal;
    end

endmodule