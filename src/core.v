`include "src/config.vh"
`include "src/Modules/format.vh"

module riscv#(
    parameter IMEM_BASE=32'h0000_0000,
    parameter IMEM_SIZE=32768,    // 32kW = 128kB
    parameter IMEM_FILE="target/prog.mif",
    parameter DMEM_BASE=32'h0010_0000,
    parameter DMEM_SIZE=32768,    // 32kW = 128kB
    parameter DMEM_FILE="target/data.mif"
)(
    input CLK,  // clock
    input RSTN, // reset
    output [31:0] WB_RD_VAL
);

    wire RST;
    assign RST = ~RSTN;

    // Instruction Memory
    reg [31:0] imem [0:IMEM_SIZE-1];

    initial
        begin
            $readmemh(IMEM_FILE, imem);
        end

    reg [31:0] PC;        // Program Counter
    wire [31:0] PC4;        // PC+4
    wire [31:0] IDATA;
    wire [31:0] IR;        // Instruction Register
    wire [2:0] instruction_format_type;        // Instruction Format Type
    wire [4:0] destination_register_number;        // Destination Register Number
    wire [31:0] rs1_value;    // Register Value for RS1
    wire [31:0] rs2_value;    // Register Vlaue for RS2
    wire [31:0] branch_addr;    // Branch Target Address
    reg [31:0] WB_RD_VAL;   // Destination Register Value



    wire [4:0] alu_instruction;        // ALU operation
    wire pc_for_input_a;        // Use PC for RS1 value on "auipc"
    wire [31:0] RS1_VAL;        // ALU operand 1
    wire [31:0] RS2_IMM_VAL;    // ALU operand 2
    wire [31:0] immediate_value;        // Immediate Value
    wire [31:0] alu_result;    // ALU result
    wire [31:0] shifter_result;    // Shifter result
    wire [1:0] write_back_type;        // Destination value selecter

    wire [1:0] data_memory_write_status;        // Store Enable for Data Memory
    wire [1:0] data_memory_read_status;        // Load Enable for Data Memory
    wire data_memory_load_signed;        // Sign Extention for Load Inst.
    wire jump;        // Branch, jal, jalr Instruction
    wire E_PC_E;        // Modify PC with Branch Target Address

    wire [31:0] DADDR;
    wire [31:0] DATAI;

    wire [31:2] MADDR;
    wire [31:0] MDATAI;
    wire [31:0] MDATAI_DMEM;
    wire [31:0] MDATAO;
    wire [3:0] MWSTB;

    wire [31:0] E_RD_VAL;

    wire CEM;

    assign PC4 = PC+4;

    // PC
    always @(posedge CLK or posedge RST)
        begin
            if (RST) // reset vector
                PC <= 32'h0000_0000;
            else
                begin
                    if (E_PC_E)
                        PC <= branch_addr;    // branch target address from E stage (branch, jal, jalr)
                    else
                        PC <= PC4;    // otherwise PC + 4
                end
        end

    assign IDATA = imem[PC[31:2]];

    // Instruction Aligner for Big/Little endian
    `ifdef BIG_ENDIAN
        assign IR = IDATA;
    `endif
    `ifdef LITTLE_ENDIAN
        assign IR = {IDATA[7:0], IDATA[15:8], IDATA[23:16], IDATA[31:24]};
    `endif


    instruction_decoder instruction_decoder(
        .clk(CLK),
        .IR(IR),
        .alu_instruction(alu_instruction),
        .immediate_value(immediate_value),
        .instruction_format_type(instruction_format_type),
        .write_back_type(write_back_type),
        .data_memory_read_status(data_memory_read_status),
        .data_memory_write_status(data_memory_write_status),
        .data_memory_load_signed(data_memory_load_signed),
        .destination_register_number(destination_register_number),
        .pc_for_input_a(pc_for_input_a),
        .jump(jump)
    );

    // Regster File
    rf rf(
        .CLK(CLK),
        .RNUM1(`IR_RS1),
        .RDATA1(rs1_value),
        .RNUM2(`IR_RS2),
        .RDATA2(rs2_value),
        .WNUM(destination_register_number),
        .WDATA(WB_RD_VAL)
    );


    // MUX for source 1 of ALU
    assign RS1_VAL = (pc_for_input_a) ? PC:rs1_value; // PC for auipc
    // from Register File

    assign RS2_IMM_VAL = (instruction_format_type == `FT_R || instruction_format_type == `FT_B) ? rs2_value:immediate_value;

    alu e_alu(.C(alu_instruction), .Y(alu_result), .A(RS1_VAL), .B(RS2_IMM_VAL));
    shift e_sft(.C(alu_instruction), .Y(shifter_result), .A(RS1_VAL), .B(RS2_IMM_VAL[4:0]));

    // Branch Target Address
    // if jalr then target address is calculated by ALU.
    // if Conditional branch and jal then PC+Imm.
    assign branch_addr = (instruction_format_type == `FT_I) ? alu_result:PC+immediate_value;

    // if branch taken, IF and DE stages cancel for control dependency
    // jal and jalr are always taken, conditional branch has to check condition
    assign E_PC_E = jump && !((instruction_format_type == `FT_B) && !alu_result[0]);

    assign E_RD_VAL = (alu_instruction[4:2] == 3'b100) ? shifter_result:alu_result;

    assign DADDR = E_RD_VAL;

    // Data Memory via Data Aligner
    daligner daligner(
        .CLK(CLK),
        .ADDRI(DADDR),
        .DATAI(rs2_value),
        .DATAO(DATAI),
        .WE(data_memory_write_status), // 00: no write, 01: byte, 10: h-word, 11: word
        .RE(data_memory_read_status), // 00: no read,  01: byte, 10: h-word, 11: word
        .SE(data_memory_load_signed), // Sign Extend Control
        .MADDR(MADDR),
        .MDATAO(MDATAO),
        .MDATAI(MDATAI),
        .MWSTB(MWSTB)  // Write strobe 0000, 0001, 0010, 0100, 1000, 0011, 1100, 1111
    );

    // Data Memory Enable
    assign CEM = ((| data_memory_write_status || | data_memory_read_status) && (MADDR[31:20] == DMEM_BASE[31:20]));

    assign MDATAI = MDATAI_DMEM;

    // Data Memory
    dmem#(
        .DMEM_SIZE(DMEM_SIZE),
        .INIT_FILE(DMEM_FILE)
    ) dmem(
        .CLK(CLK),
        .ADDR(MADDR),
        .DATAI(MDATAO),
        .DATAO(MDATAI_DMEM),
        .CE(CEM),
        .WSTB(MWSTB)
    );


    // WB
    always @(write_back_type or DATAI or PC4 or E_RD_VAL)
        begin
            case (write_back_type)
                2'b01: WB_RD_VAL <= DATAI;    // Load inst.
                2'b10: WB_RD_VAL <= PC4;    // jal and jalr
                default: WB_RD_VAL <= E_RD_VAL;    // The others (ALU, Shifter)
            endcase // case ( WB_MUX )
        end

endmodule
