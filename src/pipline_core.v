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
    wire [1:0] write_back_type_ra_input;
    wire [1:0] read_status_ra_input;
    wire [1:0] write_status_ra_input;
    wire [4:0] destination_register_number_ra_input;
    wire [4:0] register_number_a;
    wire [4:0] register_number_b;
    wire load_unsigned_ra_input;
    wire pc_for_input_a;
    wire immediate_value_for_b;
    wire change_branch_instruction;
    wire [31:0] pc;
    wire condition_branch_input_ra;
    wire taken_input_ra;

    fetch_decode fd #(
        .IMEM_SIZE(IMEM_SIZE),
        .IMEM_FILE(IMEM_FILE)
    ) (
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
        .write_back_type(write_back_type_ra_input),
        .read_status(read_status_ra_input),
        .write_status(write_status_ra_input),
        .destination_register_number(destination_register_number_ra_input),
        .register_number_a(register_number_a),
        .register_number_b(register_number_b),
        .load_unsigned(load_unsigned_ra_input),
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
    wire [31:0] rs2_value_ex_input;
    wire [1:0] read_status_ex_input;
    wire [1:0] write_status_ex_input;
    wire load_unsigned_ex_input;
    wire [4:0] destination_register_number_ex_input;
    wire [1:0] write_back_type_ex_input;


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
        .read_status_input(read_status_ra_input),
        .write_status_input(write_status_ra_input),
        .load_unsigned_input(load_unsigned_ra_input),
        .destination_register_number_input(destination_register_number_ra_input),
        .write_back_type_input(write_back_type_ra_input),
        .data_a(data_a),
        .data_b(data_b),
        .execute_instruction_output(execute_instruction),
        .condition_branch_output(condition_branch),
        .taken_output(taken),
        .read_status_output(read_status_ex_input),
        .write_status_output(write_status_ex_input),
        .load_unsigned_output(load_unsigned_ex_input),
        .destination_register_number_output(destination_register_number_ex_input),
        .write_back_type_output(write_back_type_ex_input),

        .destination_register_number(destination_register_number),
        .write_back_value(write_back_value),

        .jalr_input(jalr_input),
        .jalr_output(ra_jalr_output),
        .new_pc(stage_e_pc),
        .pc_output(pc_ex_input),
        .immediate_value_output(immediate_value_ex_input),
        .rs2_value(rs2_value_ex_input)
    );

    wire [31:0] ex_result_ma_input;
    wire [31:0] rs2_value;
    wire [1:0] read_status;
    wire [1:0] write_status;
    wire load_unsigned;
    wire [31:0] pc_ma_input;
    wire [4:0] destination_register_number_ma_input;
    wire [1:0] write_back_type_ma_input;

    execute ex(
        .clk(clk),
        .data_a(data_a),
        .data_b(data_b),
        .rs2_value_input(rs2_value_ex_input)
        .immediate_value(immediate_value_ex_input),
        .instruction(alu_instruction),
        .pc(pc_ex_input),
        .condition_branch(condition_branch),
        .taken(taken),
        .read_status_input(read_status_ra_input),
        .write_status_input(write_status_ra_input),
        .load_unsigned_input(load_unsigned_ra_input),
        .destination_register_number_input(destination_register_number_ex_input),
        .write_back_type_input(write_back_type_ex_input),
        .pc_output(pc_ma_input),
        .result(ex_result_ma_input),
        .mispredict(mispredict),
        .new_pc(stage_e_pc),
        .rs2_value_output(rs2_value),
        .read_status_output(read_status),
        .write_status_output(write_status),
        .load_unsigned_output(load_unsigned),
        .execute_result_output(ex_result_ma_input),
        .destination_register_number_output(destination_register_number_ma_input),
        .write_back_type_output(write_back_type_ma_input),
    );

    wire [31:0] read_ouput;
    wire [31:0] ex_result;
    wire [31:0] pc;
    wire [4:0] destination_register_number_wb_input;
    wire [1:0] write_back_type;

    memory_access ma #(
        .DMEM_BASE(DMEM_BASE),
        .INIT_FILE(INIT_FILE),
        .DMEM_SIZE(DMEM_SIZE)
    )(
        .clk(clk),
        .pc(pc_ma_input),
        .execute_result(ex_result_ma_input),
        .write_input(rs2_value),
        .read_status(read_status),
        .write_status(write_status),
        .load_unsigned(load_unsigned),
        .destination_register_number_input(destination_register_number_ma_input),
        .write_back_type_input(write_back_type_ma_input),
        .read_ouput(read_ouput),
        .execute_result_output(ex_result)
        .pc_output(pc),
        .destination_register_number_output(destination_register_number_wb_input),
        .write_back_type_output(write_back_type),
    );

    wire [31:0] write_back_value;
    wire [4:0] destination_register_number;

    write_back wb(
        .clk(clk),
        .write_back_type(write_back_type),
        .pc(pc),
        .memory_read_output(read_ouput),
        .execute_result(ex_result),
        .write_back_register_input(destination_register_number_wb_input),
        .write_back_value(write_back_value),
        .write_back_register_output(destination_register_number)
    )
endmodule
