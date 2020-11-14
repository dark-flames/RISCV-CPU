module write_back(
    input clk,
    input [1:0] write_back_type,
    input [31:0] pc,
    input [31:0] memory_read_output,
    input [31:0] execute_result,
    input [4:0] write_back_register_input,
    output reg [31:0] write_back_value,
    output reg [4:0] write_back_register_output
);

    reg [31:0] write_back_value_internal;
    reg [4:0] write_back_register_internal;

    always @(posedge clk) begin
        write_back_register_internal <= write_back_register_input;
        case (write_back_type)
            `WB_LOAD: write_back_value_internal <= memory_read_output;    // Load inst.
            `WB_JAL: write_back_value_internal <= pc + 4;    // jal and jalr
            `WB_NORMAL: write_back_value_internal <= execute_result;    // The others (ALU, Shifter)
        endcase 
    end

    always @(posedge clk) begin
        write_back_register_output <= write_back_register_internal;
        write_back_value <= write_back_value_internal;
    end
endmodule