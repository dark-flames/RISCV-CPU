module rf(
    input clk,
    input [4:0] register_number_a,
    input [4:0] register_number_b,
    output [31:0] data_a,
    output [31:0] data_b,
    input [4:0] destination_register_numer,
    input [31:0] write_data
);
    reg [31:0] register_file [1:31];

    always @(posedge clk)
        begin
            if (destination_register_numer != 5'b00000)
                register_file[destination_register_numer] <= write_data;
        end

    assign data_a = (register_number_a != 0) ? register_file[register_number_a]:32'h0000_0000;
    assign data_b = (register_number_b != 0) ? register_file[register_number_b]:32'h0000_0000;

endmodule // rf
