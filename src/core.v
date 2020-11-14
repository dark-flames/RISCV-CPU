`include "src/config.vh"
`include "src/format.vh"

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

    // Instruction Memory
    

    initial
        begin
            $readmemh(IMEM_FILE, instruction_memory);
        end

    reg [31:0] PC;        // Program Counter
    wire [31:0] instruction;
    wire [31:0] IR;        // Instruction Register
    wire [2:0] instruction_format_type;        // Instruction Format Type
    wire [4:0] destination_register_number;        // Destination Register Number
    wire [31:0] rs1_value;    // Register Value for RS1
    wire [31:0] rs2_value;    // Register Vlaue for RS2
    wire [31:0] branch_addr;    // Branch Target Address
    reg [31:0] write_back_value;   // Destination Register Value



    wire [4:0] alu_instruction;        // ALU operation
    wire pc_for_input_a;        // Use PC for RS1 value on "auipc"
    wire [31:0] input_a;        // ALU operand 1
    wire [31:0] input_b;    // ALU operand 2
    wire [31:0] immediate_value;        // Immediate Value
    wire [31:0] alu_result;    // ALU result
    wire [31:0] shifter_result;    // Shifter result
    wire [1:0] write_back_type;        // Destination value selecter

    wire [1:0] write_status;        // Store Enable for Data Memory
    wire [1:0] read_status;        // Load Enable for Data Memory
    wire load_signed;        // Sign Extention for Load Inst.
    wire change_branch_instruction_instruction;        // Branch, jal, jalr Instruction
    wire change_branch;        // Modify PC with Branch Target Address

    wire [31:0] write_back_result;

    wire [31:2] memory_address;
    wire [31:0] input_from_data_memory;

    wire [31:0] execute_result;

    always @(posedge clk or posedge reset)
        begin
            if (reset)
                PC <= 32'h0000_0000;
            else
                begin
                    if (change_branch)
                        PC <= branch_addr;    // branch target address from E stage (branch, jal, jalr)
                    else
                        PC <= PC + 4;    // otherwise PC + 4
                end
        end

    assign instruction = instruction_memory[PC[31:2]];
    assign IR = {instruction[7:0], instruction[15:8], instruction[23:16], instruction[31:24]};

    instruction_decoder instruction_decoder(
        .IR(IR),
        .alu_instruction(alu_instruction),
        .immediate_value(immediate_value),
        .instruction_format_type(instruction_format_type),
        .write_back_type(write_back_type),
        .read_status(read_status),
        .write_status(write_status),
        .load_signed(load_signed),
        .destination_register_number(destination_register_number),
        .pc_for_input_a(pc_for_input_a),
        .change_branch_instruction(change_branch_instruction)
    );

    rf rf(
        .clk(clk),
        .register_number_a(`IR_RS1),
        .data_a(rs1_value),
        .register_number_b(`IR_RS2),
        .data_b(rs2_value),
        .destination_register_numer(destination_register_number),
        .write_data(write_back_value)
    );

    assign input_a = (pc_for_input_a) ? PC:rs1_value; // PC for auipc

    assign input_b = (instruction_format_type == `FT_R || instruction_format_type == `FT_B) ? rs2_value:immediate_value;

    alu e_alu(
        .instruction(alu_instruction),
        .result(alu_result),
        .input_a(input_a),
        .input_b(input_b)
    );

    shift e_sft(
        .instruction(alu_instruction),
        .result(shifter_result),
        .input_a(input_a),
        .input_b(input_b[4:0])
    );

    assign branch_addr = (instruction_format_type == `FT_I) ? alu_result:PC+immediate_value;

    assign change_branch = change_branch_instruction && !((instruction_format_type == `FT_B) && !alu_result[0]);

    assign execute_result = (alu_instruction[4:2] == 3'b100) ? shifter_result : alu_result;

    // Data Memory via Data Aligner
    daligner #(
        .DMEM_BASE(DMEM_BASE),
        .DMEM_SIZE(DMEM_SIZE),
        .INIT_FILE(DMEM_FILE)
    ) daligner(
        .clk(clk),
        .alu_result(execute_result),
        .input_data(rs2_value),
        .read_output(write_back_result),
        .write_status(write_status), // 00: no write, 01: byte, 10: h-word, 11: word
        .read_status(read_status), // 00: no read,  01: byte, 10: h-word, 11: word
        .load_unsigned(load_signed) // Sign Extend Control
    );
    

    // WB
    always @(write_back_type or write_back_result or PC or execute_result)
        begin
            case (write_back_type)
                `WB_LOAD: write_back_value <= write_back_result;    // Load inst.
                `WB_JAL: write_back_value <= PC + 4;    // jal and jalr
                `WB_NORMAL: write_back_value <= execute_result;    // The others (ALU, Shifter)
            endcase // case ( WB_MUX )
        end

endmodule
