`include"src/format.vh"

module daligner#(
    parameter DMEM_BASE=32'h0010_0000,
    parameter INIT_FILE="target/data.mif",
    parameter DMEM_SIZE=32768
)   (
        input clk,
        input [31:0] alu_result,
        input [31:0] input_data,
        output reg [31:0] read_output,
        input [1:0] write_status, // 00: no write, 01: byte, 10: h-word, 11: word
        input [1:0] read_status, // 00: no read,  01: byte, 10: h-word, 11: word
        input load_unsigned // Sign Extend Control
    );

    
    wire [31:2] memory_address;
    wire enable_data_memory;
    wire [31:0] data_memory_output;
    reg [3:0] write_flag;
    reg [31:0] write_data;

    assign memory_address = alu_result[31:2];

    always @(*)
        begin
            case (write_status)
                `DM_BYTE: 
                    case (alu_result[1:0]) // byte access
                        2'b00:
                            begin
                                write_data <= {input_data[7:0], 24'h00_0000};
                                write_flag <= 4'b1000;
                            end
                        2'b01:
                            begin
                                write_data <= {8'h00, input_data[7:0], 16'h0000};
                                write_flag <= 4'b0100;
                            end
                        2'b10:
                            begin
                                write_data <= {16'h0000, input_data[7:0], 8'h00};
                                write_flag <= 4'b0010;
                            end
                        2'b11:
                            begin
                                write_data <= {24'h0000_00, input_data[7:0]};
                                write_flag <= 4'b0001;
                            end
                    endcase
                `DM_HWORD: 
                    case (alu_result[1]) // half word access
                        1'b0:
                            begin
                                write_data <= {input_data[7:0], input_data[15:8], 16'h0000};
                                write_flag <= 4'b1100;
                            end
                        1'b1:
                            begin
                                write_data <= {16'h0000, input_data[7:0], input_data[15:8]};
                                write_flag <= 4'b0011;
                            end
                    endcase
                `DM_WORD:        // word access
                    begin
                        write_data <= {input_data[7:0], input_data[15:8], input_data[23:16], input_data[31:24]};
                        write_flag <= 4'b1111;
                    end
                default:    // No access
                    begin
                        write_data <= 32'h0000_0000;
                        write_flag <= 4'b0000;
                    end
            endcase
        end

    always @(*)
        begin
            case (read_status)
                `DM_BYTE:
                    case (alu_result[1:0])    // byte access
                        2'b00: read_output <= {{24{(load_unsigned) ? data_memory_output[31]:1'b0}}, data_memory_output[31:24]};
                        2'b01: read_output <= {{24{(load_unsigned) ? data_memory_output[23]:1'b0}}, data_memory_output[23:16]};
                        2'b10: read_output <= {{24{(load_unsigned) ? data_memory_output[15]:1'b0}}, data_memory_output[15:8]};
                        2'b11: read_output <= {{24{(load_unsigned) ? data_memory_output[7]:1'b0}}, data_memory_output[7:0]};
                    endcase
                `DM_HWORD:
                    case (alu_result[1:0])    // half word access
                        2'b00: read_output <= {{16{(load_unsigned) ? data_memory_output[23]:1'b0}}, data_memory_output[23:16], data_memory_output[31:24]};
                        2'b10: read_output <= {{16{(load_unsigned) ? data_memory_output[7]:1'b0}}, data_memory_output[7:0], data_memory_output[15:8]};
                    endcase
                `DM_WORD:  // word access
                    read_output <= {data_memory_output[7:0], data_memory_output[15:8], data_memory_output[23:16], data_memory_output[31:24]};
                default:
                    read_output <= 32'h0000_0000;
            endcase // case ( read_status )
        end

    // Data Memory Enable
    assign enable_data_memory = ((| write_status || | read_status) && (memory_address[31:20] == DMEM_BASE[31:20]));

    dmem#(
        .DMEM_SIZE(DMEM_SIZE),
        .INIT_FILE(INIT_FILE)
    ) dmem(
        .clk(clk),
        .address(memory_address),
        .write_data(write_data),
        .read_output(data_memory_output),
        .enable(enable_data_memory),
        .write_flag(write_flag)
    );


endmodule
