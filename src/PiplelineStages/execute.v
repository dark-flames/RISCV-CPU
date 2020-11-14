module execute(
    input clk,
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
    input load_unsigned_input,
    input [4:0] destination_register_number_input,
    input [1:0] write_back_type_input,
    output reg [31:0] pc_output,
    output reg [31:0] result,
    output reg mispredict,
    output reg [31:0] new_pc,
    output reg [31:0] rs2_value_output,
    output reg [1:0] read_status_output,
    output reg [1:0] write_status_output,
    output reg load_unsigned_output,
    output reg [4:0] destination_register_number_output,
    output reg [1:0] write_back_type_output,
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
    reg mispredict_internal,
    reg [31:0] new_pc_internal;
    reg [31:0] rs2_value_internal;
    reg [1:0] read_status_internal;
    reg [1:0] write_status_internal;
    reg load_unsigned_internal;
    reg [31:0] pc_internal;
    reg [4:0] destination_register_number_internal;
    reg [1:0] write_back_type_internal;

    always @(posedge clk) begin
        result_internal <= (instruction[4:2] == 3'b100) ? shifter_output : alu_output;
        rs2_value_internal <= rs2_value_input;
        read_status_internal <= read_status_input;
        write_status_internal <= write_status_input;
        load_unsigned_internal <= load_unsigned_input;
        destination_register_number_internal <= destination_register_number_input;
        write_back_type_internal <= write_back_type_input;
        pc_internal <= pc;
        if (condition_branch && !alu_result[0] && !taken) begin
            mispredict_internal <= 1;
            new_pc_internal <= pc + immediate_value;
        end else begin
            mispredict_internal <= 0;
        end
    end

    always @(negedge clk) begin
        result <= result_internal;
        mispredict <= mispredict_internal;
        new_pc <= new_pc_internal;
        rs2_value_output <= rs2_value_internal;
        read_status_output <= read_status_internal;
        write_status_output <= write_status_internal;
        load_unsigned_output <= load_unsigned_internal;
        pc_output <= pc_internal;
        destination_register_number_output <= destination_register_number_internal;
        write_back_type_output <= write_back_type_internal;
    end

endmodule