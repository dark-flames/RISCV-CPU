`include "src/config.vh"

module dmem#(
    parameter INIT_FILE="target/data.mif",
    parameter DMEM_SIZE=32768
)(
    input clk,
    input [31:2] address,
    input [31:0] write_data,
    output [31:0] read_output,
    input enable,
    input [3:0] write_flag
);


    reg [31:0] mem [0:DMEM_SIZE-1];

    wire [31:0] datam;
    reg [31:0] dataw;

    initial
        begin
            $readmemh(INIT_FILE, mem);
        end

    assign datam = mem[address[16:2]];
    assign read_output = datam;

    always @(*)
        begin
            dataw <= datam;
            if (write_flag[0]) dataw[7:0] <= write_data[7:0];
            if (write_flag[1]) dataw[15:8] <= write_data[15:8];
            if (write_flag[2]) dataw[23:16] <= write_data[23:16];
            if (write_flag[3]) dataw[31:24] <= write_data[31:24];
        end

    always @(dataw or address[16:2])
        if (enable)
            mem[address[16:2]] <= dataw;

endmodule
