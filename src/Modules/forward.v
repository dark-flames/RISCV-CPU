module forward(
    // posedge
    input [4:0] execute_destination_register_number,
    input [31:0] execute_result_forward,
    input execute_forward_enable,
    input [4:0] memory_access_destination_register_number,
    input [31:0] memory_access_result_forward,
    input memory_access_forward_enable,
    input [4:0] write_back_destination_register_number,
    input [31:0] write_back_result_forward,
    // negedge
    input [4:0] register_number_a,
    input [31:0] register_value_a,
    output reg [31:0] result_a,
    input [4:0] register_number_b,
    input [31:0] register_value_b,
    output reg [31:0] result_b
);


    always @(*) begin
        
        result_a = (
                execute_destination_register_number == register_number_a &&
                execute_forward_enable
            ) ? execute_result_forward : ((
                memory_access_destination_register_number == register_number_a &&
                memory_access_forward_enable
            ) ? memory_access_result_forward : ((
                write_back_destination_register_number == register_number_a &&
                write_back_destination_register_number != 0
            ) ? write_back_result_forward : register_value_a));

        result_b = (
                execute_destination_register_number == register_number_b &&
                execute_forward_enable
            ) ? execute_result_forward : ((
                memory_access_destination_register_number == register_number_b &&
                memory_access_forward_enable
            ) ? memory_access_result_forward : ((
                write_back_destination_register_number == register_number_b &&
                write_back_destination_register_number != 0
            ) ? write_back_result_forward : register_value_b));
    end

endmodule