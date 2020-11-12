`include "src/config.vh"
`timescale 1ns / 1ns

module riscv_tb ();
    reg CLK, RSTN;

    initial
        begin
            // for iverilog + gtkwave and the others
            $dumpfile("target/riscv.vcd");
            $dumpvars(0, riscv );
        end

    initial
        begin
            CLK = 0;
            while( 1 )
                CLK = #5 ~CLK;
        end

    //
    // Data Memory Dump for Debug
    //
    task dump;
        input [31:0] addr;

        integer 	   i;
        reg [31:0] data;

        for( i = addr ; i < 1000 ; i=i+1 )
            begin
                data = riscv.daligner.dmem.mem[i];
                $display( "%08x %02x%02x%02x%02x", addr+i*4,
                    data[7:0], data[15:8], data[23:16], data[31:24] );
            end
    endtask


    initial
        begin
            RSTN = 1;
            RSTN = #10 0;
            RSTN = #10 1;
            #4000000000;
            dump(0);
            $finish();
        end

    always @( posedge CLK )
        if( riscv.PC == 32'h0000009c ) // Last instruction address on "startup.s"
            begin
                $display("Time", $time );
                dump(0);
                $finish;
            end

    riscv #( .IMEM_FILE("target/prog.mif"),
        .DMEM_FILE("target/data.mif"),
        .IMEM_SIZE(32768),
        .DMEM_SIZE(32768)
    ) riscv ( .clk(CLK), .reset_n(RSTN) );

    //
    // Debug code
    //
`ifdef ST_DEBUG
    always @( negedge CLK )
    if(  ( riscv.DMWE ) && ( riscv.alu_result[31:20] == 12'h001 ) )
    $display( "ST  :%08h %08h %01h ", riscv.alu_result, riscv.RF_DATA2, riscv.DMWE );
`endif
`ifdef LD_DEBUG
    always @( negedge CLK )
    if(  ( riscv.DMRE  ) && ( riscv.alu_result[31:20] == 12'h001 ) )
    $display( "LD  :%08h %08h %01h ", riscv.alu_result, riscv.daligner.DATAO, riscv.DMRE );
`endif

endmodule
