//ALU
`define IADD	5'b00000 // ADD
`define ISUB	5'b00001 // SUB
`define ISLT	5'b00010 //
`define ISLTU	5'b00011 //
`define IOR	    5'b00100 // OR
`define IXOR	5'b00101 // XOR
`define IAND	5'b00110 // AND
`define IPAS	5'b00111 // LUI
`define IEQ	    5'b01000 // BEQ
`define INE	    5'b01001 // BNE
`define ILT	    5'b01010 // BLT
`define IGE	    5'b01011 // BGE
`define ILTU	5'b01100  //BLT
`define IGEU	5'b01101 // BGEU

// Shifter
`define ISLL	5'b10001
`define ISRL	5'b10011
`define ISRA	5'b10010

// Multiplyer
`define IMUL	5'b11000
`define IMULH	5'b11001
`define IMULHSU	5'b11010
`define IMULHU	5'b11011

// Divider
`define IDIV	5'b11100
`define IDIVU	5'b11101
`define IREM	5'b11110
`define IREMU	5'b11111

`define IR_OP  	IR[ 6: 0]
`define IR_RD	IR[11: 7]
`define IR_F3	IR[14:12]
`define IR_RS1	IR[19:15]
`define IR_RS2	IR[24:20]
`define IR_F7	IR[31:25]


// opecode
`define OP_LUI		7'b0110111
`define OP_AUIPC	7'b0010111
`define OP_JAL		7'b1101111
`define OP_JALR		7'b1100111
`define OP_BR		7'b1100011
`define OP_LOAD		7'b0000011
`define OP_STORE	7'b0100011
`define OP_FUNC1	7'b0010011
`define OP_FUNC2	7'b0110011
`define OP_FENCEX	7'b0001111
`define OP_FUNC3	7'b1110011

// Instruction Format Type ( 00: illegal instruction )
`define FT_R	3'b001
`define FT_I	3'b010
`define FT_S	3'b011
`define FT_U	3'b100
`define FT_J	3'b101
`define FT_B	3'b110
