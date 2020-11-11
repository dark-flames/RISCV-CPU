`include "src/config.vh"
`include "src/Modules/format.vh"

module riscv#(
    parameter IMEM_BASE=32'h0000_0000,
    parameter IMEM_SIZE=32768,    // 32kW = 128kB
    parameter IMEM_FILE="target/sort_prog.mif",
    parameter DMEM_BASE=32'h0010_0000,
    parameter DMEM_SIZE=32768,    // 32kW = 128kB
    parameter DMEM_FILE="target/sort_data.mif"
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
    reg [2:0] FT;        // Instruction Format Type
    reg [4:0] D_RD;        // Destination Register Number
    wire [31:0] RF_DATA1;    // Register Value for RS1
    wire [31:0] RF_DATA2;    // Register Vlaue for RS2
    wire [31:0] BR_ADDR;    // Branch Target Address
    reg [31:0] WB_RD_VAL;    // Destination Register Value



    reg [4:0] IALU;        // ALU operation
    reg RS1_PC;        // Use PC for RS1 value on "auipc"
    wire [31:0] RS1_VAL;        // ALU operand 1
    wire [31:0] RS2_IMM_VAL;    // ALU operand 2
    reg [31:0] IMM;        // Immediate Value
    wire [31:0] ALU_RD_VAL;    // ALU result
    wire [31:0] SFT_RD_VAL;    // Shifter result
    reg [1:0] WB_MUX;        // Destination value selecter

    reg [1:0] DMWE;        // Store Enable for Data Memory
    reg [1:0] DMRE;        // Load Enable for Data Memory
    reg DMSE;        // Sign Extention for Load Inst.
    reg PC_E;        // Branch, jal, jalr Instruction
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
                        PC <= BR_ADDR;    // branch target address from E stage (branch, jal, jalr)
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


    // Instruction decoder
    always @(IR)
        begin
            FT <= 3'b000; // default : undefined instruction
            IALU <= `IADD;  // default operation
            WB_MUX <= 2'b00;  // for R-type, I-type, U-type
            DMWE <= 2'b00;  // no store
            DMRE <= 2'b00;  // no load
            DMSE <= 1'b0;   // unsigned
            RS1_PC <= 1'b0;   // no use PC for RS1
            PC_E <= 1'b0;   // no branch
            case (`IR_OP )
                `OP_LUI :
                begin
                    FT <= `FT_U;
                    IALU <= `IPAS;
                end
                `OP_AUIPC:
                begin
                    FT <= `FT_U;
                    RS1_PC <= 1'b1;
                end
                `OP_JAL:
                begin
                    FT <= `FT_J;
                    RS1_PC <= 1'b1;
                    PC_E <= 1'b1;
                    WB_MUX <= 2'b10;
                end
                `OP_JALR:
                begin
                    FT <= `FT_I;
                    PC_E <= 1'b1;
                    WB_MUX <= 2'b10;
                end
                `OP_BR:
                begin
                    FT <= `FT_B;
                    PC_E <= 1'b1;
                    case (`IR_F3 )
                        3'b000: begin IALU <= `IEQ; end // beq
                        3'b001: begin IALU <= `INE; end // bne
                        3'b100: begin IALU <= `ILT; end // blt
                        3'b101: begin IALU <= `IGE; end // bge
                        3'b110: begin IALU <= `ILTU; end // bltu
                        3'b111: begin IALU <= `IGEU; end // bgeu
                    endcase // case ( `IR_F3 )
                end
                `OP_LOAD:
                begin
                    FT <= `FT_I;
                    WB_MUX <= 2'b01;
                    case (`IR_F3 )
                        3'b000: begin DMRE <= 2'b01; DMSE <= 1'b1; end // lb
                        3'b001: begin DMRE <= 2'b10; DMSE <= 1'b1; end // lh
                        3'b010: begin DMRE <= 2'b11; DMSE <= 1'b1; end // lw
                        3'b100: begin DMRE <= 2'b01; end // lbu
                        3'b101: begin DMRE <= 2'b10; end // lhu
                        3'b110: begin DMRE <= 2'b11; end // lwu
                    endcase // case ( `IR_F3 )
                end
                `OP_STORE:
                begin
                    FT <= `FT_S;
                    case (`IR_F3 )
                        3'b000: begin DMWE <= 2'b01; end // sb
                        3'b001: begin DMWE <= 2'b10; end // sh
                        3'b010: begin DMWE <= 2'b11; end // sw
                    endcase // case ( `IR_F3 )
                end
                `OP_FUNC1: // Immediate
                begin
                    FT <= `FT_I;
                    case (`IR_F3 )
                        3'b000: begin IALU <= `IADD; end // addi
                        3'b001:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `ISLL;      // slli
                            end
                        3'b010: begin IALU <= `ILT; end // slti
                        3'b011: begin IALU <= `ILTU; end // sltiu
                        3'b100: begin IALU <= `IXOR; end // xori
                        3'b101:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `ISRL; else // srli
                                    if (`IR_F7 == 7'b0100000) IALU <= `ISRA;      // srai
                            end
                        3'b110: begin IALU <= `IOR; end // ori
                        3'b111: begin IALU <= `IAND; end // andi
                    endcase // case ( `IR_F3 )
                end
                `OP_FUNC2: // R type
                begin
                    FT <= `FT_R;
                    case (`IR_F3 )
                        3'b000:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `IADD; else // add
                                    if (`IR_F7 == 7'b0100000) IALU <= `ISUB;      // sub
                            end
                        3'b001:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `ISLL;      // sll
                            end
                        3'b010:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `ILT;       // slt
                            end
                        3'b011:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `ILTU;      // sltu
                            end
                        3'b100:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `IXOR;      // xori
                            end
                        3'b101:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `ISRL; else // srl
                                    if (`IR_F7 == 7'b0100000) IALU <= `ISRA;      // sra
                            end
                        3'b110:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `IOR;       // ori
                            end
                        3'b111:
                            begin
                                if (`IR_F7 == 7'b0000000) IALU <= `IAND;      // andi
                            end
                    endcase // case ( `IR_F3 )
                end
                `OP_FENCEX: // fence
            begin
            end
                `OP_FUNC3: // ecall, ebreak, CSRxxx
                begin
                end
            endcase // case ( `IR_OP )

        end


    always @(*)
        begin
            D_RD <= 5'b0000; // Don't use dest. on S format & B format
            case (FT)
                `FT_R, `FT_I, `FT_U, `FT_J : D_RD <= `IR_RD;
            endcase // case ( FT )
        end

    // Immediate Value
    always @(*)
        begin
            IMM <= {{20{IR[31]}}, IR[31:20]};                                              // I format
            case (FT)
                `FT_S : IMM <= {{20{IR[31]}}, `IR_F7, `IR_RD };           // S format
                    `FT_B : IMM <= {{20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};           // B format
                    `FT_U : IMM <= {IR[31:12], 12'h000};           // U format
                    `FT_J : IMM <= {{11{IR[31]}}, IR[31], IR[19:12], IR[20], IR[30:21], 1'b0}; // J format
            endcase // case ( FT )
        end

    // Regster File
    rf rf(
        .CLK(CLK),
        .RNUM1(`IR_RS1),
        .RDATA1(RF_DATA1),
        .RNUM2(`IR_RS2),
        .RDATA2(RF_DATA2),
        .WNUM(D_RD),
        .WDATA(WB_RD_VAL)
    );


    // MUX for source 1 of ALU
    assign RS1_VAL = (RS1_PC) ? PC:RF_DATA1; // PC for auipc
    // from Register File

    assign RS2_IMM_VAL = (FT == `FT_R || FT == `FT_B) ? RF_DATA2:IMM;

    alu e_alu(.C(IALU), .Y(ALU_RD_VAL), .A(RS1_VAL), .B(RS2_IMM_VAL));
    shift e_sft(.C(IALU), .Y(SFT_RD_VAL), .A(RS1_VAL), .B(RS2_IMM_VAL[4:0]));

    // Branch Target Address
    // if jalr then target address is calculated by ALU.
    // if Conditional branch and jal then PC+Imm.
    assign BR_ADDR = (FT == `FT_I) ? ALU_RD_VAL:PC+IMM;

    // if branch taken, IF and DE stages cancel for control dependency
    // jal and jalr are always taken, conditional branch has to check condition
    assign E_PC_E = PC_E && !((FT == `FT_B) && !ALU_RD_VAL[0]);

    assign E_RD_VAL = (IALU[4:2] == 3'b100) ? SFT_RD_VAL:ALU_RD_VAL;

    assign DADDR = E_RD_VAL;

    // Data Memory via Data Aligner
    daligner daligner(
        .CLK(CLK),
        .ADDRI(DADDR),
        .DATAI(RF_DATA2),
        .DATAO(DATAI),
        .WE(DMWE), // 00: no write, 01: byte, 10: h-word, 11: word
        .RE(DMRE), // 00: no read,  01: byte, 10: h-word, 11: word
        .SE(DMSE), // Sign Extend Control
        .MADDR(MADDR),
        .MDATAO(MDATAO),
        .MDATAI(MDATAI),
        .MWSTB(MWSTB)  // Write strobe 0000, 0001, 0010, 0100, 1000, 0011, 1100, 1111
    );

    // Data Memory Enable
    assign CEM = ((| DMWE || | DMRE) && (MADDR[31:20] == DMEM_BASE[31:20]));

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
    always @(WB_MUX or DATAI or PC4 or E_RD_VAL)
        begin
            case (WB_MUX)
                2'b01: WB_RD_VAL <= DATAI;    // Load inst.
                2'b10: WB_RD_VAL <= PC4;    // jal and jalr
                default: WB_RD_VAL <= E_RD_VAL;    // The others (ALU, Shifter)
            endcase // case ( WB_MUX )
        end

endmodule
