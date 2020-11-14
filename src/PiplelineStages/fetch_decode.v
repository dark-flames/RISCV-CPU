
// stage fetch input at posedge and output at negedge
module fetch_decode#(
    parameter IMEM_SIZE=32768,
    parameter IMEM_FILE="target/prog.mif"
)(
    input clk,
    input reset,
    input [31: 0] predict_pc,
    input jalr,
    input [31: 0] stage_e_pc,
    input mispredict,
    input [31: 0] stage_m_pc,
    input ret,
    input [31: 0] stage_w_pc,
    output reg [4:0] alu_instruction,
    output reg [31:0] immediate_value,
    output reg [2:0] instruction_format_type,
    output reg [1:0] write_back_type,
    output reg [1:0] read_status,
    output reg [1:0] write_status,
    output reg [4:0] destination_register_number,
    output reg [4:0] register_number_a,
    output reg [4:0] register_number_b,
    output reg load_unsigned,
    output reg pc_for_input_a,
    output reg immediate_value_for_b,
    output reg change_branch_instruction,
    output reg condition_branch,
    output reg taken,
    output reg [31: 0] predict_pc_output,
    reg[31:0] pc
);

    reg[31:0] pc_internal;
    wire[31:0] be_instruction；
    wire[31:0] instruction;

    reg [31:0] instruction_memory [0:IMEM_SIZE-1];


    initial
        begin
            $readmemh(IMEM_FILE, instruction_memory);
        end

    // handle mispredict or use predict pc
    always @(posedge clk or posedge reset)
        begin
            if reset begin
                pc_internal <= 32'h0000_0000;
            end else begin
                if (jalr) begin // pick pc from stage e to handle jalr
                    pc_internal <= stage_e_pc;
                end else if (mispredict) begin // pick pc from stage m to handle mispredict
                    pc_internal <= stage_m_pc;
                end else if(ret) begin // pick pc from stage w to handle ret
                    pc_internal <= stage_w_pc;
                end else begin // pick predict from previous clk as default
                    pc_internal <= predict_pc;
                end
            end
        end
    
    // fetch instruction from instruction memory
    assign be_instruction = instruction_memory[pc_internal[31:2]];
    assign instruction = {instruction[7:0], instruction[15:8], instruction[23:16], instruction[31:24]};

    // wire of decoder
    wire [4:0] alu_instruction_wire;
    wire [31:0] immediate_value_wire;
    wire [2:0] instruction_format_type_wire;
    wire [1:0] write_back_type_wire;
    wire [1:0] read_status_wire;
    wire [1:0] write_status_wire;
    wire [4:0] destination_register_number_wire;
    wire load_unsigned_wire;
    wire pc_for_input_a_wire;
    wire change_branch_instruction_wire;

    instruction_decoder decoder(
        .IR(instruction),
        .alu_instruction(alu_instruction_wire),
        .immediate_value(immediate_value_wire),
        .instruction_format_type(instruction_format_type_wire),
        .write_back_type(write_back_type_wire),
        .read_status(read_status_wire),
        .write_status(write_status_wire),
        .load_unsigned(load_unsigned_wire),
        .destination_register_number(destination_register_number_wire),
        .pc_for_input_a(pc_for_input_a_wire),
        .change_branch_instruction(change_branch_instruction_wire)
    );

    
    // set output at negede
    always @(negedge clk) begin
        alu_instruction <= alu_instruction_wire;
        immediate_value <= immediate_value_wire;
        instruction_format_type <= instruction_format_type_wire;
        write_back_type <= write_back_type_wire;
        read_status <= read_status_wire;
        write_status <= write_status_wire;
        load_unsigned <= load_unsigned_wire;
        destination_register_number <= destination_register_number_wire;
        pc_for_input_a <= pc_for_input_a_wire;
        immediate_value_for_b <= (instruction_format_type != `FT_R && instruction_format_type != `FT_B);
        change_branch_instruction <= change_branch_instruction_wire;
        register_number_a <= instruction[19:15];
        register_number_b <= instruction[24:20];
        pc <= pc_internal;
        condition_branch <= instruction_format_type == `FT_B;
        // todo:predictor
        taken <= instruction_format_type == `FT_B;
        // jal
        if(change_branch_instruction_wire && instruction_format_type_wire = FT_J) begin
            predict_pc <= pc_internal + immediate_value
        end else begin // default
            predict_pc <= pc_internal + 4;
        end
    end


end module