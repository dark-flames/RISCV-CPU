module daligner
    (
        input CLK,
        // M stage interface
        input [31:0] ADDRI,
        input [31:0] DATAI,
        //   output reg [31:0] DATAO,
        output [31:0] DATAO,
        input [1:0] WE, // 00: no write, 01: byte, 10: h-word, 11: word
        input [1:0] RE, // 00: no read,  01: byte, 10: h-word, 11: word
        input SE, // Sign Extend Control
        // Memory interface
        output [31:2] MADDR,
        output reg [31:0] MDATAO,
        input [31:0] MDATAI,
        output reg [3:0] MWSTB  // Write strobe 0000, 0001, 0010, 0100, 1000, 0011, 1100, 1111
    );

    reg [31:0] iDATAO;

    assign MADDR = ADDRI[31:2];

`ifdef BIG_ENDIAN
    always @( MDATAI or ADDRI or WE or DATAI )
    begin
    case( WE )
    2'b01: case( ADDRI[1:0] )
    2'b00: MDATAO <= { MDATAI[31: 8],              DATAI[ 7:0] };
    2'b01: MDATAO <= { MDATAI[31:16], DATAI[7:0], MDATAI[ 7:0] };
    2'b10: MDATAO <= { MDATAI[31:24], DATAI[7:0], MDATAI[15:0] };
    2'b11: MDATAO <= {  DATAI[7:0],               MDATAI[23:0] };
    endcase
    2'b10: case( ADDRI[1:0] )
    2'b00: MDATAO <= { MDATAI[31:16],  DATAI[15: 0] };
    2'b10: MDATAO <= {  DATAI[15: 0], MDATAI[15: 0] };
    endcase
    default: MDATAO <= DATAI;
    endcase
    end

    always @( MDATAI or ADDRI or RE )
    begin
    case( RE )
    2'b01: case( ADDRI[1:0] )
    2'b00: DATAO <= { ( SE ) ? {24{MDATAI[ 7]}} : 24'h000, MDATAI[ 7: 0] };
    2'b01: DATAO <= { ( SE ) ? {24{MDATAI[15]}} : 24'h000, MDATAI[15: 8] };
    2'b10: DATAO <= { ( SE ) ? {24{MDATAI[23]}} : 24'h000, MDATAI[23:16] };
    2'b11: DATAO <= { ( SE ) ? {24{MDATAI[31]}} : 24'h000, MDATAI[31:24] };
    endcase
    2'b10: case( ADDRI[1:0] )
    2'b00: DATAO <= { ( SE ) ? {16{MDATAI[15]}} : 16'h00, MDATAI[15: 0] };
    2'b10: DATAO <= { ( SE ) ? {16{MDATAI[31]}} : 16'h00, MDATAI[31:16] };
    endcase
    default: DATAO <= MDATAI;
    endcase // case ( RE )
    end // always @ ( MDATAI or ADDRI or RE )
`endif //  `ifdef BIG_ENDIAN

`ifdef LITTLE_ENDIAN
    always @(*)
        begin
            case (WE)
                2'b01: case (ADDRI[1:0]) // byte access
                    2'b00:
                        begin
                            MDATAO <= {DATAI[7:0], 24'h00_0000};
                            MWSTB <= 4'b1000;
                        end
                    2'b01:
                        begin
                            MDATAO <= {8'h00, DATAI[7:0], 16'h0000};
                            MWSTB <= 4'b0100;
                        end
                    2'b10:
                        begin
                            MDATAO <= {16'h0000, DATAI[7:0], 8'h00};
                            MWSTB <= 4'b0010;
                        end
                    2'b11:
                        begin
                            MDATAO <= {24'h0000_00, DATAI[7:0]};
                            MWSTB <= 4'b0001;
                        end
                endcase
                2'b10: case (ADDRI[1]) // half word access
                    1'b0:
                        begin
                            MDATAO <= {DATAI[7:0], DATAI[15:8], 16'h0000};
                            MWSTB <= 4'b1100;
                        end
                    1'b1:
                        begin
                            MDATAO <= {16'h0000, DATAI[7:0], DATAI[15:8]};
                            MWSTB <= 4'b0011;
                        end
                endcase
                2'b11:        // word access
                    begin
                        MDATAO <= {DATAI[7:0], DATAI[15:8], DATAI[23:16], DATAI[31:24]};
                        MWSTB <= 4'b1111;
                    end
                default:    // No access
                    begin
                        MDATAO <= 32'h0000_0000;
                        MWSTB <= 4'b0000;
                    end
            endcase
        end

    always @(*)
        begin
            case (RE)
                2'b01:
                    case (ADDRI[1:0])    // byte access
                        2'b00: iDATAO <= {{24{(SE) ? MDATAI[31]:1'b0}}, MDATAI[31:24]};
                        2'b01: iDATAO <= {{24{(SE) ? MDATAI[23]:1'b0}}, MDATAI[23:16]};
                        2'b10: iDATAO <= {{24{(SE) ? MDATAI[15]:1'b0}}, MDATAI[15:8]};
                        2'b11: iDATAO <= {{24{(SE) ? MDATAI[7]:1'b0}}, MDATAI[7:0]};
                    endcase
                2'b10:
                    case (ADDRI[1:0])    // half word access
                        2'b00: iDATAO <= {{16{(SE) ? MDATAI[23]:1'b0}}, MDATAI[23:16], MDATAI[31:24]};
                        2'b10: iDATAO <= {{16{(SE) ? MDATAI[7]:1'b0}}, MDATAI[7:0], MDATAI[15:8]};
                    endcase
                2'b11:  // word access
                    iDATAO <= {MDATAI[7:0], MDATAI[15:8], MDATAI[23:16], MDATAI[31:24]};
                default:
                    iDATAO <= 32'h0000_0000;
            endcase // case ( RE )
        end

//   always @( posedge CLK )    // for pipeline
//     DATAO <= iDATAO;

    assign DATAO = iDATAO;        // for non-pipeline

`endif //  `ifdef LITTLE_ENDIAN


endmodule
