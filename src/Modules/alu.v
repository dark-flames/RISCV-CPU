`include "src/Modules/format.vh"

module alu(A, B, C, Y);
    input [31:0] A;
    input [31:0] B;
    input [4:0] C;
    output [31:0] Y;

    reg [31:0] Y;       // redefinition for non-blocking assignment

    // internal wire
    reg [32:0] S;      // temporary result
    wire overflow;      // overflow flag
    wire zero;      // zero flag
    wire lt_unsigned;      // less than unsigned flag
    wire lt;      // less than flag

    // Arithmetical and Logical operation
    always @(A or B or C)
        begin
            case (C)
                `IADD: S <= {1'b0, A}+{1'b0, B};
                    `IAND: S <= {1'b0, A} & {1'b0, B};
                    `IOR: S <= {1'b0, A} | {1'b0, B};
                    `IXOR: S <= {1'b0, A} ^ {1'b0, B};
                    `IPAS: S <= {1'b0, B};
                default: S <= {1'b0, A}-{1'b0, B}; // sub and compare
            endcase
        end

    // flags
    assign overflow = (A[31:31] & (~B[31:31]) & (~S[31:31])) | (~A[31:31] & B[31:31] & S[31:31]);
    assign zero = S == 0;
    assign lt_unsigned = S[32:32] == 0;
    assign lt = S[31:31] ^ overflow;

    // output multiplexor
    always @(S or zero or lt_unsigned or lt or C)
        begin
            case (C)
                `ILT: Y <= lt ? 1:0;
                    `ILTU: Y <= lt_unsigned ? 1:0;
                    `IGE: Y <= lt ? 0:1;
                    `IGEU: Y <= lt_unsigned ? 0:1;
                    `IEQ: Y <= zero ? 1:0;
                    `INE: Y <= zero ? 0:1;
                default: Y <= S[31:0];
            endcase
        end

endmodule
