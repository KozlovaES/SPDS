/*
 * schoolMIPS - small MIPS CPU for "Young Russian Chip Architects" 
 *              summer school ( yrca@googlegroups.com )
 *
 * originally based on Sarah L. Harris MIPS CPU 
 * 
 * Copyright(c) 2017 Stanislav Zhelnio 
 *                   Alexander Romanov 
 */ 

`include "sm_cpu.vh"

module sm_cpu
(
    input           clk,        // clock
    input           rst_n,      // reset
    input   [ 4:0]  regAddr,    // debug access reg address
    output  [31:0]  regData,    // debug access reg data
    output  [31:0]  imAddr,     // instruction memory address
    input   [31:0]  imData,     // instruction memory data
    input	[ 3:0]	ramAddr,	// RAM address
    output	[ 7:0]	ramData		// RAM data (only low byte)
);
    //control wires
    wire        pcSrc;
    wire        regDst;
    wire        regWrite;
    wire        aluSrc;
    wire        aluZero;
    wire [ 3:0] aluControl;
    wire 		memToReg;
    wire		memWrite;

    //program counter
    wire [31:0] pc;
    wire [31:0] pcBranch;
    wire [31:0] pcNext  = pc + 1;
    wire [31:0] pc_new   = ~pcSrc ? pcNext : pcBranch;
    sm_register r_pc(clk ,rst_n, pc_new, pc);

    //program memory access
    assign imAddr = pc;
    wire [31:0] instr = imData;

    //debug register access
    wire [31:0] rd0;
    assign regData = (regAddr != 0) ? rd0 : pc;

    //register file
    wire [ 4:0] a3  = regDst ? instr[15:11] : instr[20:16];
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] wd3;
    
    wire [31:0] RAMReadData;
    wire [31:0] resultData = (memToReg) ? RAMReadData : wd3; 

    sm_register_file rf
    (
        .clk        ( clk          ),
        .a0         ( regAddr      ),
        .a1         ( instr[25:21] ),
        .a2         ( instr[20:16] ),
        .a3         ( a3           ),
        .rd0        ( rd0          ),
        .rd1        ( rd1          ),
        .rd2        ( rd2          ),
        .wd3        ( resultData   ),
        .we3        ( regWrite     )
    );

    //sign extension
    wire signExtend;
    wire [31:0] signImm = (~signExtend) ? { {16 { instr[15] }}, instr[15:0] } : { {16 {1'b0}}, instr[15:0] };
    assign pcBranch = pcNext + signImm;

    //alu
    wire [31:0] srcB = aluSrc ? signImm : rd2;

    sm_alu alu
    (
        .srcA       ( rd1          ),
        .srcB       ( srcB         ),
        .oper       ( aluControl   ),
        .shift      ( instr[10:6 ] ),
        .zero       ( aluZero      ),
        .result     ( wd3          ) 
    );

    //control
    sm_control sm_control
    (
        .cmdOper    ( instr[31:26] ),
        .cmdFunk    ( instr[ 5:0 ] ),
        .aluZero    ( aluZero      ),
        .pcSrc      ( pcSrc        ), 
        .regDst     ( regDst       ), 
        .regWrite   ( regWrite     ), 
        .aluSrc     ( aluSrc       ),
        .aluControl ( aluControl   ),
        .signExtend ( signExtend   ),
        .memToReg	( memToReg 	   ),
        .memWrite	( memWrite	   )
    );
    
    // Data memory file 
    wire [31:0] ramOut; 
    assign ramData = ramOut[7:0];  
    
    ram ram
    (
		.addr_a		( wd3[3:0]	  ),
		.addr_b		( ramAddr 	  ),
		.clk		( clk 	  	  ),
		.data_a		( rd2 	  	  ),
		.data_b		( ramData	  ),
		.we_a		( memToReg	  ),
		.we_b		(  			  ),
		.q_a		( RAMReadData ),
		.q_b		( ramOut	  )
    );

endmodule

module sm_control
(
    input      [5:0] cmdOper,
    input      [5:0] cmdFunk,
    input            aluZero,
    output           pcSrc, 
    output reg       regDst, 
    output reg       regWrite, 
    output reg       aluSrc,
    output reg [3:0] aluControl,
    output reg 		 signExtend,
    output reg		 memToReg,
    output reg		 memWrite
);
    reg          branch;
    reg          condZero;
    assign pcSrc = branch & (aluZero == condZero);

    always @ (*) begin
        branch      = 1'b0;
        condZero    = 1'b0;
        regDst      = 1'b0;
        regWrite    = 1'b0;
        aluSrc      = 1'b0;
        signExtend  = 1'b0;
        aluControl  = `ALU_ADD;
        memToReg	= 1'b0;
        memWrite	= 1'b0;

        casez( {cmdOper,cmdFunk} )
            default               : ;

            { `C_SPEC,  `F_ADDU } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_ADD;  end
            { `C_SPEC,  `F_OR   } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_OR;   end
            { `C_SPEC,  `F_SRL  } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_SRL;  end
            { `C_SPEC,  `F_SLTU } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_SLTU; end
            { `C_SPEC,  `F_SUBU } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_SUBU; end
            { `C_SPEC,  `F_SLLV } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_SLLV; end
			{ `C_SPEC,  `F_NOR  } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_NOR;  end
			
            { `C_ADDIU, `F_ANY  } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD;  end
            { `C_LUI,   `F_ANY  } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_LUI;  end
            { `C_XORI,	`F_ANY  } : begin regWrite = 1'b1; aluSrc = 1'b1; signExtend = 1'b1; aluControl = `ALU_XORI; end
            { `C_LW,	`F_ANY	} : begin regWrite = 1'b1; aluSrc = 1'b1; memToReg = 1'b1; aluControl = `ALU_ADD;    end
            { `C_SW,	`F_ANY	} : begin memWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD;  end 

            { `C_BEQ,   `F_ANY  } : begin branch = 1'b1; condZero = 1'b1; aluControl = `ALU_SUBU; end
            { `C_BNE,   `F_ANY  } : begin branch = 1'b1; aluControl = `ALU_SUBU; 				  end
            { `C_BGEZ,	`F_ANY 	} :	begin branch = 1'b1; aluControl = `ALU_SIGN; 				  end
        endcase
    end
endmodule


module sm_alu
(
    input  [31:0] srcA,
    input  [31:0] srcB,
    input  [ 3:0] oper,
    input  [ 4:0] shift,
    output        zero,
    output reg [31:0] result
);
    always @ (*) begin
        case (oper)
            default   : result = srcA + srcB;
            `ALU_ADD  : result = srcA + srcB;
            `ALU_OR   : result = srcA | srcB;
            `ALU_LUI  : result = (srcB << 16);
            `ALU_SRL  : result = srcB >> shift;
            `ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
            `ALU_SUBU : result = srcA - srcB;
            `ALU_XORI : result = srcA ^ srcB;
            // �������� SLLV ���� � ������ �������
            `ALU_SLLV : result = srcB << srcA;
            `ALU_NOR  : result = ~(srcA | srcB);
            
            // �������� �������� �����
            `ALU_SIGN : result = (srcA[31] == 1) ? 1 : 0;
            
        endcase
    end

    assign zero   = (result == 0);
endmodule

module sm_register_file
(
    input         clk,
    input  [ 4:0] a0,
    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd0,
    output [31:0] rd1,
    output [31:0] rd2,
    input  [31:0] wd3,
    input         we3
);
    reg [31:0] rf [31:0];

    assign rd0 = (a0 != 0) ? rf [a0] : 32'b0;
    assign rd1 = (a1 != 0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf [a2] : 32'b0;

    always @ (posedge clk)
        if(we3) rf [a3] <= wd3;
endmodule
