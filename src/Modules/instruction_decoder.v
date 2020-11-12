`include "src/Modules/format.vh"

module instruction_decoder(
    input clk,
    input wire [31:0] IR,
    output reg [4:0] alu_instruction,
    output reg [31:0] immediate_value,
    output reg [2:0] instruction_format_type,
    output reg [1:0] write_back_type,
    output reg [1:0] read_status,
    output reg [1:0] write_status,
    output reg [4:0] destination_register_number,
    output reg load_signed,
    output reg pc_for_input_a,
    output reg change_branch_instruction
);

    always @(IR)
        begin
            instruction_format_type <= `FT_NONE;
            alu_instruction <= `IADD;  // default operation
            write_back_type <= `WB_NORMAL;
            write_status <= `DM_NONE;  // no store
            read_status <= `DM_NONE;
            load_signed <= 0;   // unsigned
            pc_for_input_a <= 0;   // no use PC for RS1x
            change_branch_instruction <= 0;  // no branch
        
            case (IR[6:0])
                `OP_LUI:
                begin
                    instruction_format_type <= `FT_U;
                    alu_instruction <= `IPAS;
                end
                `OP_AUIPC:
                begin
                    instruction_format_type <= `FT_U;
                    pc_for_input_a <= 1;
                end
                `OP_JAL:
                begin
                    instruction_format_type <= `FT_J;
                    pc_for_input_a <= 1;
                    change_branch_instruction <= 1;
                    write_back_type <= `WB_JAL;
                end
                `OP_JALR:
                begin
                    instruction_format_type <= `FT_I;
                    change_branch_instruction <= 1;
                    write_back_type <= `WB_JAL;
                end
                `OP_BR:
                begin
                    instruction_format_type <= `FT_B;
                    change_branch_instruction <= 1'b1;
                    case (`IR_F3 )
                        3'b000: begin alu_instruction <= `IEQ; end // beq
                        3'b001: begin alu_instruction <= `INE; end // bne
                        3'b100: begin alu_instruction <= `ILT; end // blt
                        3'b101: begin alu_instruction <= `IGE; end // bge
                        3'b110: begin alu_instruction <= `ILTU; end // bltu
                        3'b111: begin alu_instruction <= `IGEU; end // bgeu
                    endcase // case ( `IR_F3 )
                end
                `OP_LOAD:
                begin
                    instruction_format_type <= `FT_I;
                    write_back_type <= `WB_LOAD;
                    case (`IR_F3 )
                        3'b000: begin
                            read_status <= `DM_BYTE;
                            load_signed <= 1;
                        end // lb
                        3'b001: begin
                            read_status <= `DM_HWORD;
                            load_signed <= 1;
                        end // lh
                        3'b010: begin
                            read_status <= `DM_WORD;
                            load_signed <= 1;
                        end // lw
                        3'b100: begin read_status <= `DM_BYTE; end // lbu
                        3'b101: begin read_status <= `DM_HWORD; end // lhu
                        3'b110: begin read_status <= `DM_WORD; end // lwu
                    endcase // case ( `IR_F3 )
                end
                `OP_STORE:
                begin
                    instruction_format_type <= `FT_S;
                    case (`IR_F3)
                        3'b000: begin write_status <= `DM_BYTE; end // sb
                        3'b001: begin write_status <= `DM_HWORD; end // sh
                        3'b010: begin write_status <= `DM_WORD; end // sw
                    endcase // case ( `IR_F3 )
                end
                `OP_FUNC1: // Immediate
                begin
                    instruction_format_type <= `FT_I;

                    case (`IR_F3)
                        3'b000: begin alu_instruction <= `IADD; end // addi
                        3'b001:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `ISLL;      // slli
                            end
                        3'b010: begin alu_instruction <= `ILT; end // slti
                        3'b011: begin alu_instruction <= `ILTU; end // sltiu
                        3'b100: begin alu_instruction <= `IXOR; end // xori
                        3'b101:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `ISRL; else // srli
                            if (`IR_F7 == 7'b0100000) alu_instruction <= `ISRA;      // srai
                            end
                        3'b110: begin alu_instruction <= `IOR; end // ori
                        3'b111: begin alu_instruction <= `IAND; end // andi
                    endcase // case ( `IR_F3 )
                end
                `OP_FUNC2: // R type
                begin
                    instruction_format_type <= `FT_R;
                    case (`IR_F3)
                        3'b000:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `IADD; else // add
                            if (`IR_F7 == 7'b0100000) alu_instruction <= `ISUB;      // sub
                            end
                        3'b001:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `ISLL;      // sll
                            end
                        3'b010:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `ILT;       // slt
                            end
                        3'b011:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `ILTU;      // sltu
                            end
                        3'b100:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `IXOR;      // xori
                            end
                        3'b101:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `ISRL; else // srl
                            if (`IR_F7 == 7'b0100000) alu_instruction <= `ISRA;      // sra
                            end
                        3'b110:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `IOR;       // ori
                            end
                        3'b111:
                            begin
                            if (`IR_F7 == 7'b0000000) alu_instruction <= `IAND;      // andi
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
            destination_register_number <= 5'b0000; // Don't use dest. on S format & B format
            case (instruction_format_type)
                `FT_R, `FT_I, `FT_U, `FT_J :destination_register_number <= `IR_RD;
            endcase // case ( FT )
        end

    always @(*)
        begin
            immediate_value <= {{20{IR[31]}}, IR[31:20]};                                              // I format
            case (instruction_format_type)
                `FT_S:immediate_value <= {{20{IR[31]}}, `IR_F7, `IR_RD };           // S format
                `FT_B:immediate_value <= {{20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};           // B format
                `FT_U:immediate_value <= {IR[31:12], 12'h000};           // U format
                `FT_J:immediate_value <= {{11{IR[31]}}, IR[31], IR[19:12], IR[20], IR[30:21], 1'b0}; // J format
            endcase // case ( FT )
        end

endmodule