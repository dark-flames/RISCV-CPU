`include "src/format.vh"

module alu(
    input [31:0] input_a,
    input [31:0] input_b,
    input [4:0] instruction,
    output reg [31:0] result
);

    // internal wire
    reg [32:0] temp;      // temporary result
    wire overflow;      // overflow flag
    wire zero;      // zero flag
    wire lt_unsigned;      // less than unsigned flag
    wire lt;      // less than flag

    // Arithmetical and Logical operation
    always @(input_a or input_b or instruction)
        begin
            case (instruction)
                `IADD: temp <= {1'b0, input_a} + {1'b0, input_b};
                `IAND: temp <= {1'b0, input_a} & {1'b0, input_b};
                `IOR:  temp <= {1'b0, input_a} | {1'b0, input_b};
                `IXOR: temp <= {1'b0, input_a} ^ {1'b0, input_b};
                `IPAS: temp <= {1'b0, input_b};
                default:temp <= {1'b0, input_a} - {1'b0, input_b}; // sub and compare
            endcase
        end

    // flags
    assign overflow = (input_a[31:31] & (~input_b[31:31]) & (~temp[31:31])) | (~input_a[31:31] & input_b[31:31] & temp[31:31]);
    assign zero = temp == 0;
    assign lt_unsigned = temp[32:32] == 0;
    assign lt = temp[31:31] ^ overflow;

    // output multiplexor
    always @(temp or zero or lt_unsigned or lt or instruction)
        begin
            case (instruction)
                `ILT:result <= lt ? 1:0;
                `ILTU: result <= lt_unsigned ? 1:0;
                `IGE: result <= lt ? 0:1;
                `IGEU: result <= lt_unsigned ? 0:1;
                `IEQ: result <= zero ? 1:0;
                `INE: result <= zero ? 0:1;
                default:result <= temp[31:0];
            endcase
        end

endmodule
