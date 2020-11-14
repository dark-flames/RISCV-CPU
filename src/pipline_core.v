module riscv#(
    parameter IMEM_BASE=32'h0000_0000,
    parameter IMEM_SIZE=32768,    // 32kW = 128kB
    parameter IMEM_FILE="target/prog.mif",
    parameter DMEM_BASE=32'h0010_0000,
    parameter DMEM_SIZE=32768,    // 32kW = 128kB
    parameter DMEM_FILE="target/data.mif"
)(
    input clk,  // clock
    input reset_n, // reset
    output [31:0] write_back_value
);
    wire reset;
    assign reset = ~reset_n;

    wire [31: 0] predict_pc;
    wire ra_jalr_output;
    wire ra_jalr_input;
    wire [31: 0] stage_e_pc;
    wire mispredict;
    wire [31: 0] stage_m_pc;
    wire ret;
    wire [31: 0] stage_w_pc;

    wire [4:0] alu_instruction_input_ra;
    wire [31:0] immediate_value_ra_input;
    wire [2:0] instruction_format_type;
    wire [1:0] write_back_type;
    wire [1:0] read_status;
    wire [1:0] write_status;
    wire [4:0] destination_register_number;
    wire [4:0] register_number_a;
    wire [4:0] register_number_b;
    wire load_signed;
    wire pc_for_input_a;
    wire immediate_value_for_b;
    wire change_branch_instruction;
    wire [31:0] pc;
    wire condition_branch_input_ra;
    wire taken_input_ra;

    fetch_decode fd (
        .clk(clk),
        .reset(reset),
        .predict_pc(predict_pc),
        .jal(ra_jalr_output),
        .stage_e_pc(stage_e_pc),
        .mispredict(mispredict),
        .stage_m_pc(stage_m_pc),
        .ret(reg),
        .stage_w_pc(stage_w_pc),
        .alu_instruction(alu_instruction_input_ra),
        .immediate_value(immediate_value_ra_input),
        .instruction_format_type(instruction_format_type),
        .write_back_type(write_back_type),
        .read_status(read_status),
        .write_status(write_status),
        .destination_register_number(destination_register_number),
        .register_number_a(register_number_a),
        .register_number_b(register_number_b),
        .load_signed(load_signed),
        .pc_for_input_a(pc_for_input_a),
        .immediate_value_for_b(immediate_value_for_b),
        .change_branch_instruction(change_branch_instruction),
        .predict_pc_output(predict_pc),
        .pc(pc),
        .condition_branch(condition_branch_input_ra),
        .taken(taken_input_ra)
    );

    wire [31:0] data_a;
    wire [31:0] data_b;
    wire [31:0] write_back_value;
    wire [4:0] execute_instruction;
    wire condition_branch;
    wire taken;
    wire [31:0] pc_ex_input;
    wire immediate_value_ex_input;


    register_access ra(
        .clk(clk),
        .register_number_a(register_number_a),
        .register_number_b(register_number_a),
        .pc_for_a(pc_for_input_a),
        .immediate_value_for_b(.immediate_value_for_b)
        .immediate_value(immediate_value_ra_input),
        .pc(pc),
        .execute_instruction_input(execute_instruction_input_ra),
        .condition_branch_input(condition_branch_input_ra),
        .taken_input(taken_input_ra),
        .data_a(data_a),
        .data_b(data_b),
        .execute_instruction_output(execute_instruction),
        .condition_branch_output(condition_branch),
        .taken_output(taken),

        .destination_register_number(destination_register_number),
        .write_back_value(write_back_value),

        .jalr_input(jalr_input),
        .jalr_output(ra_jalr_output),
        .new_pc(stage_e_pc),
        .pc_output(pc_ex_input),
        .immediate_value_output(immediate_value_ex_input)
    );

    wire [31:0] ex_result;


    execute ex(
        .clk(clk),
        .data_a(data_a),
        .data_b(data_b),
        .immediate_value(immediate_value_ex_input),
        .instruction(alu_instruction),
        .pc(pc_ex_input),
        .condition_branch(condition_branch),
        .taken(taken),
        .result(ex_result),
        .mispredict(mispredict),
        .new_pc(stage_e_pc)
    );
endmodule
