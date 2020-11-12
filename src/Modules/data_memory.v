`include "src/config.vh"

module dmem#(
    parameter INIT_FILE="target/sort_data.mif",
    parameter DMEM_SIZE=32768
)(
    input CLK,
    input [31:2] ADDR,
    input [31:0] DATAI,
    output [31:0] DATAO,
    input CE,
    input [3:0] WSTB
);


    reg [31:0] mem [0:DMEM_SIZE-1];

    wire [31:0] datam;
    reg [31:0] dataw;

    initial
        begin
            $readmemh(INIT_FILE, mem);
        end

    assign datam = mem[ADDR[16:2]];
    assign DATAO = datam;

    always @(*)
        begin
            dataw <= datam;
            if (WSTB[0]) dataw[7:0] <= DATAI[7:0];
            if (WSTB[1]) dataw[15:8] <= DATAI[15:8];
            if (WSTB[2]) dataw[23:16] <= DATAI[23:16];
            if (WSTB[3]) dataw[31:24] <= DATAI[31:24];
        end

    always @(posedge CLK)
        if (CE && (| WSTB))
            mem[ADDR[16:2]] <= dataw;

endmodule
