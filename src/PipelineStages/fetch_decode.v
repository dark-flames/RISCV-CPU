
// stage fetch input at posedge and output at negedge
module fetch_decode#(
    parameter IMEM_SIZE=32768,
    parameter IMEM_FILE="target/prog.mif"
)(
    input clk,
    input reset,
    input [31: 0] predict_pc,
    input jalr,
    input ret,
    input [31: 0] stage_r_pc,
    input mispredict,
    input [31: 0] stage_e_pc,
    output reg [4:0] execute_instruction,
    output reg [31:0] immediate_value,
    output reg [2:0] instruction_format_type,
    output reg [1:0] write_back_type,
    output reg [1:0] read_status,
    output reg [1:0] write_status,
    output reg [4:0] destination_register_number,
    output reg [4:0] register_number_a,
    output reg [4:0] register_number_b,
    output reg load_signed,
    output reg pc_for_input_a,
    output reg immediate_value_for_b,
    output reg change_branch_instruction,
    output reg jalr_output,
    output reg condition_branch,
    output reg taken,
    output reg [31: 0] predict_pc_output,
    output reg reset_ra_and_ex,
    output reg [31:0] pc
);

    reg[31:0] pc_internal;
    wire[31:0] be_instruction;
    wire[31:0] instruction;

    reg [31:0] instruction_memory [0:IMEM_SIZE-1];

    reg prev_hiccup;
    reg prev_jalr;
    wire need_hiccup;
    reg prev_load;
    reg [4:0] prev_destination_register_number;
    wire [4:0] register_number_a_wire;
    wire [4:0] register_number_b_wire;

    initial
        begin
            $readmemh(IMEM_FILE, instruction_memory);
            $display("init {}\n", 1);
        end

    // handle mispredict or use predict pc
    always @(posedge clk or posedge reset)
        begin
            if(reset) begin
                pc_internal <= 32'h0000_0000;
                prev_hiccup <= 0;
                prev_load <= 0;
                reset_ra_and_ex <= 0;
                write_back_type <= 2'b11;
                prev_destination_register_number <= 5'b00000;
            end else begin
                if (jalr == 1) begin // pick pc from stage e to handle jalr
                    pc_internal <= stage_r_pc;
                    reset_ra_and_ex <= 0;
                end else if (mispredict == 1) begin // pick pc from stage m to handle mispredict
                    pc_internal <= stage_e_pc;
                    reset_ra_and_ex <= 1;
                end else if (!prev_hiccup) begin // pick predict from previous clk as default
                    pc_internal <= predict_pc;
                    reset_ra_and_ex <= 0;
                end
            end
        end
    
    // fetch instruction from instruction memory
    assign be_instruction = instruction_memory[pc_internal[31:2]];
    assign instruction = {be_instruction[7:0], be_instruction[15:8], be_instruction[23:16], be_instruction[31:24]};
    assign register_number_a_wire = instruction[19:15];
    assign register_number_b_wire = instruction[24:20];
    assign need_hiccup = (
        !prev_hiccup && ((
            prev_load == 1 && (
                prev_destination_register_number == register_number_a_wire ||
                prev_destination_register_number == register_number_b_wire
            )
        ) ||(prev_jalr))) || ret;
    // wire of decoder
    wire [4:0] execute_instruction_wire;
    wire [31:0] immediate_value_wire;
    wire [2:0] instruction_format_type_wire;
    wire [1:0] write_back_type_wire;
    wire [1:0] read_status_wire;
    wire [1:0] write_status_wire;
    wire [4:0] destination_register_number_wire;
    wire load_signed_wire;
    wire pc_for_input_a_wire;
    wire change_branch_instruction_wire;


    instruction_decoder decoder(
        .IR(instruction),
        .alu_instruction(execute_instruction_wire),
        .immediate_value(immediate_value_wire),
        .instruction_format_type(instruction_format_type_wire),
        .write_back_type(write_back_type_wire),
        .read_status(read_status_wire),
        .write_status(write_status_wire),
        .load_signed(load_signed_wire),
        .destination_register_number(destination_register_number_wire),
        .pc_for_input_a(pc_for_input_a_wire),
        .change_branch_instruction(change_branch_instruction_wire)
    );

    
    // set output at negede
    always @(negedge clk) begin
        execute_instruction <= execute_instruction_wire;
        immediate_value <= immediate_value_wire;
        instruction_format_type <= instruction_format_type_wire;
        write_back_type <= need_hiccup ? `WB_HICCUP : write_back_type_wire;
        read_status <= read_status_wire;
        write_status <= write_status_wire;
        load_signed <= load_signed_wire;
        destination_register_number <= destination_register_number_wire;
        pc_for_input_a <= pc_for_input_a_wire;
        immediate_value_for_b <= (instruction_format_type_wire != `FT_R && instruction_format_type_wire != `FT_B);
        change_branch_instruction <= change_branch_instruction_wire;
        register_number_a <= register_number_a_wire;
        register_number_b <= register_number_b_wire;
        pc <= pc_internal;
        condition_branch <= instruction_format_type_wire == `FT_B;
        jalr_output <= (write_back_type_wire == `WB_JAL && instruction_format_type_wire == `FT_I);
        // todo:predictor
        taken <= instruction_format_type_wire != `FT_B;
        // jal
        if(change_branch_instruction_wire && instruction_format_type_wire == `FT_J) begin
            predict_pc_output <= pc_internal + immediate_value_wire;
        end else begin // default
            predict_pc_output <= pc_internal + 4;
        end
        // hiccup
        prev_load <= write_back_type_wire == `WB_LOAD;
        prev_jalr <= (write_back_type_wire == `WB_JAL && instruction_format_type_wire == `FT_I);
        prev_destination_register_number <= reset ? 5'b00000 : destination_register_number_wire;
        prev_hiccup <= prev_hiccup ? 0 : need_hiccup;
    end
endmodule