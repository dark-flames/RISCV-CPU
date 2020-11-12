module shift(
    input [4:0] instruction,
    input [31:0] input_a,
    input [4:0] input_b,
    output [31:0] result
);
    reg [31:0] tmp;

    always @(instruction or input_a or input_b or tmp)
        begin
            tmp = input_a;
            if (input_b[0]) tmp = (instruction == `ISLL) ? tmp << 1:(instruction == `ISRL) ? tmp >> 1:tmp >>> 1;
            if (input_b[1]) tmp = (instruction == `ISLL) ? tmp << 2:(instruction == `ISRL) ? tmp >> 2:tmp >>> 2;
            if (input_b[2]) tmp = (instruction == `ISLL) ? tmp << 4:(instruction == `ISRL) ? tmp >> 4:tmp >>> 4;
            if (input_b[3]) tmp = (instruction == `ISLL) ? tmp << 8:(instruction == `ISRL) ? tmp >> 8:tmp >>> 8;
            if (input_b[4]) tmp = (instruction == `ISLL) ? tmp << 16:(instruction == `ISRL) ? tmp >> 16:tmp >>> 16;
        end

    assign result = tmp;

endmodule