module rf(clk, RNUM1, RNUM2, RDATA1, RDATA2, WNUM, WDATA);
    input clk;
    input [4:0] RNUM1, RNUM2, WNUM;
    output [31:0] RDATA1, RDATA2;
    input [31:0] WDATA;

    reg [31:0] REGISTER_FILE [1:31];

    always @(posedge clk)
        begin
            if (WNUM != 5'b00000)
                REGISTER_FILE[WNUM] <= WDATA;
        end

    assign RDATA1 = (RNUM1 != 0) ? REGISTER_FILE[RNUM1]:32'h0000_0000;
    assign RDATA2 = (RNUM2 != 0) ? REGISTER_FILE[RNUM2]:32'h0000_0000;

endmodule // rf
