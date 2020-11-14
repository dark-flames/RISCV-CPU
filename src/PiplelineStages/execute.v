module execute(
    input clk,
    input [31:0] data_a,
    input [31:0] data_b,
    input [31:0] immediate_value,
    input [4:0] instruction,
    input [31:0] pc,
    input condition_branch,
    input taken,
    output reg [31:0] result,
    output reg mispredict,
    output reg [31:0] new_pc,
);

    wire [31:0] alu_output;

    alu alu(
        .input_a(data_a),
        .input_b(data_b),
        .instruction(instruction),
        .result(alu_output)
    );


    reg [31:0] result_internal;
    reg mispredict_internal,
    reg new_pc_internal;

    always @(posedge clk) begin
        result_internal <= alu_output;
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
        new_pc < new_pc_internal;
    end

endmodule