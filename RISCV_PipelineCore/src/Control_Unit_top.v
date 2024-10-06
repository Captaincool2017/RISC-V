`include "ALudec.v"
`include "mainDec.v"

module Control_Unit_Top(Op,zero,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,PCSrc,Branch,funct3,funct7,ALUControl);

    input zero;
    input [6:0]Op,funct7;
    input [2:0]funct3;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch,PCSrc;
    output [1:0]ImmSrc;
    output [2:0]ALUControl;

    wire [1:0]ALUOp;

    mainDec Main_Decoder(
                .op(Op),
                .RegWrite(RegWrite),
                .ImmSrc(ImmSrc),
                .MemWrite(MemWrite),
                .ResultSrc(ResultSrc),
                .Branch(Branch),
                .ALUSrc(ALUSrc),
                .ALUOp(ALUOp),
                .zero(zero),
                .PCSrc(PCSrc)
    );

    ALUdecoder ALU_Decoder(
                            .ALUOp(ALUOp),
                            .funct3(funct3),
                            .funct7(funct7),
                            .op(Op),
                            .ALUControl(ALUControl)
    );


endmodule