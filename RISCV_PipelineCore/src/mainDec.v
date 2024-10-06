module mainDec(op,zero,RegWrite,MemWrite,ResultSrc,ALUSrc,ImmSrc,ALUOp,PCSrc,Branch);
input [6:0] op;
input zero;
output RegWrite,MemWrite,ResultSrc,ALUSrc,PCSrc,Branch;
output [1:0] ImmSrc,ALUOp;

reg [8:0] control_signals;

assign {RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,ALUOp}=control_signals; 

assign PCSrc = zero & Branch;

always @(*) begin
    casez (op)
    7'b0000011:control_signals <= 9'b1_00_1_0_1_0_00;
    7'b0100011:control_signals <= 9'b0_01_1_1_x_0_00;
    7'b0110011:control_signals <= 9'b1_xx_0_0_0_0_10;
    7'b1100011:control_signals <= 9'b0_10_0_0_x_1_01;
    default : control_signals <=9'bxxxxxxxxx;       
    endcase
end
endmodule