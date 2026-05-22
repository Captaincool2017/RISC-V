`timescale 1ns / 1ps

module id_stage (
    input clk,
    input reset,
    input [31:0] instruction_in,
    input [31:0] pc_plus_4_in,
    input [4:0]  wb_rd_in,
    input [31:0] wb_write_data_in,
    input        wb_reg_write_in,
    input [31:0] pc_in,

    output reg [2:0]  funct3_out,
    output reg [31:0] operand1_out,
    output reg [31:0] operand2_out,
    output reg [31:0] immediate_out,
    output reg [4:0]  rd_out,
    output reg [3:0]  alu_op_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        reg_write_out,
    output reg        branch_out,
    output reg        jal_out,
    output reg        jalr_out,
    output reg [4:0]  rs1_addr_out,
    output reg [4:0]  rs2_addr_out,
    output reg        mul_en_out,
    output reg        div_en_out,
    output reg        alu_src_out
);
    // Register File
    reg [31:0] registers [0:31];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) registers[i] = 32'h00000000;
    end

    // Write-back
    always @(posedge clk) begin
        if (wb_reg_write_in && wb_rd_in != 5'b00000) begin
            registers[wb_rd_in] <= wb_write_data_in;
        end
    end

    wire [6:0] opcode = instruction_in[6:0];
    wire [4:0] rs1    = instruction_in[19:15];
    wire [4:0] rs2    = instruction_in[24:20];
    wire [4:0] rd     = instruction_in[11:7];
    wire [2:0] funct3 = instruction_in[14:12];
    wire [6:0] funct7 = instruction_in[31:25];
    
    wire [31:0] i_immediate = {{21{instruction_in[31]}}, instruction_in[30:20]};
    wire [31:0] s_immediate = {{21{instruction_in[31]}}, instruction_in[30:25], instruction_in[11:7]};
    wire [31:0] b_immediate = {{20{instruction_in[31]}}, instruction_in[7], instruction_in[30:25], instruction_in[11:8], 1'b0};
    wire [31:0] u_immediate = {instruction_in[31:12], {12{1'b0}}};
    wire [31:0] j_immediate = {{12{instruction_in[31]}}, instruction_in[19:12], instruction_in[20], instruction_in[30:21], 1'b0};

    // INTERNAL FORWARDING: Resolves Write-back to Decode phase hazard
    wire [31:0] rs1_val = (wb_reg_write_in && (wb_rd_in == rs1) && (rs1 != 5'b00000)) ? wb_write_data_in : registers[rs1];
    wire [31:0] rs2_val = (wb_reg_write_in && (wb_rd_in == rs2) && (rs2 != 5'b00000)) ? wb_write_data_in : registers[rs2];

    always @(*) begin
        funct3_out = funct3;
        operand1_out = 32'h00000000; 
        operand2_out = 32'h00000000; 
        immediate_out = 32'h00000000;
        rd_out = 5'b00000; 
        alu_op_out = 4'b0000; 
        mem_read_out = 1'b0; 
        mem_write_out = 1'b0; 
        mem_to_reg_out = 1'b0;
        reg_write_out = 1'b0; 
        branch_out = 1'b0; 
        jal_out = 1'b0; 
        jalr_out = 1'b0;
        rs1_addr_out = rs1; 
        rs2_addr_out = rs2; 
        mul_en_out = 1'b0; 
        div_en_out = 1'b0; 
        alu_src_out = 1'b0; 

        case (opcode)
            7'b0110011: begin // R-type instructions
                rd_out = rd; 
                reg_write_out = 1'b1; 
                operand1_out = rs1_val; 
                operand2_out = rs2_val;
                rs1_addr_out = rs1; 
                rs2_addr_out = rs2;
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_op_out = 4'b0000; // ADD
                    {7'b0100000, 3'b000}: alu_op_out = 4'b0001; // SUB
                    {7'b0000000, 3'b001}: alu_op_out = 4'b0010; // SLL
                    {7'b0000000, 3'b010}: alu_op_out = 4'b0011; // SLT
                    {7'b0000000, 3'b011}: alu_op_out = 4'b0100; // SLTU
                    {7'b0000000, 3'b100}: alu_op_out = 4'b0101; // XOR
                    {7'b0000000, 3'b101}: alu_op_out = 4'b0110; // SRL
                    {7'b0100000, 3'b101}: alu_op_out = 4'b0111; // SRA
                    {7'b0000000, 3'b110}: alu_op_out = 4'b1000; // OR
                    {7'b0000000, 3'b111}: alu_op_out = 4'b1001; // AND
                    {7'b0000001, 3'b000}: begin alu_op_out = 4'b0000; mul_en_out = 1'b1; end // MUL
                    {7'b0000001, 3'b001}: begin alu_op_out = 4'b0001; mul_en_out = 1'b1; end // MULH
                    {7'b0000001, 3'b010}: begin alu_op_out = 4'b0010; mul_en_out = 1'b1; end // MULHSU
                    {7'b0000001, 3'b011}: begin alu_op_out = 4'b0011; mul_en_out = 1'b1; end // MULHU
                    {7'b0000001, 3'b100}: begin alu_op_out = 4'b0100; div_en_out = 1'b1; end // DIV
                    {7'b0000001, 3'b101}: begin alu_op_out = 4'b0101; div_en_out = 1'b1; end // DIVU
                    {7'b0000001, 3'b110}: begin alu_op_out = 4'b0110; div_en_out = 1'b1; end // REM
                    {7'b0000001, 3'b111}: begin alu_op_out = 4'b0111; div_en_out = 1'b1; end // REMU
                    default: alu_op_out = 4'bxxxx;
                endcase
            end
            7'b0010011: begin // I-type instructions
                rd_out = rd; 
                reg_write_out = 1'b1; 
                operand1_out = rs1_val; 
                immediate_out = i_immediate;
                rs1_addr_out = rs1; 
                alu_src_out = 1'b1;
                case (funct3)
                    3'b000: alu_op_out = 4'b0000; // ADDI
                    3'b010: alu_op_out = 4'b0011; // SLTI
                    3'b011: alu_op_out = 4'b0100; // SLTIU
                    3'b100: alu_op_out = 4'b0101; // XORI
                    3'b110: alu_op_out = 4'b1000; // ORI
                    3'b111: alu_op_out = 4'b1001; // ANDI
                    3'b001: alu_op_out = 4'b0010; // SLLI
                    3'b101: alu_op_out = funct7[5] ? 4'b0111 : 4'b0110; // SRAI / SRLI
                    default: alu_op_out = 4'bxxxx;
                endcase
            end
            7'b0000011: begin // Load
                rd_out = rd; reg_write_out = 1'b1; mem_read_out = 1'b1; mem_to_reg_out = 1'b1;
                operand1_out = rs1_val; immediate_out = i_immediate; rs1_addr_out = rs1;
                alu_op_out = 4'b0000; alu_src_out = 1'b1; 
            end
            7'b0100011: begin // Store
                mem_write_out = 1'b1; operand1_out = rs1_val; operand2_out = rs2_val; immediate_out = s_immediate;
                rs1_addr_out = rs1; rs2_addr_out = rs2;
                alu_op_out = 4'b0000; alu_src_out = 1'b1; 
            end
            7'b1100011: begin // Branch
                branch_out = 1'b1; operand1_out = rs1_val; operand2_out = rs2_val; immediate_out = b_immediate;
                rs1_addr_out = rs1; rs2_addr_out = rs2;
                alu_src_out = 1'b0;
                case (funct3)
                    3'b000: alu_op_out = 4'b1010; // BEQ
                    3'b001: alu_op_out = 4'b1011; // BNE
                    3'b100: alu_op_out = 4'b1100; // BLT
                    3'b101: alu_op_out = 4'b1101; // BGE
                    3'b110: alu_op_out = 4'b1110; // BLTU
                    3'b111: alu_op_out = 4'b1111; // BGEU
                    default: alu_op_out = 4'b0000;
                endcase
            end
            7'b1101111: begin // JAL
                jal_out = 1'b1; reg_write_out = 1'b1; rd_out = rd; immediate_out = j_immediate;
                operand1_out = pc_plus_4_in; alu_op_out = 4'b0000;
            end
            7'b1100111: begin // JALR
                jalr_out = 1'b1; reg_write_out = 1'b1; rd_out = rd; immediate_out = i_immediate; operand1_out = rs1_val;
                alu_op_out = 4'b0000; rs1_addr_out = rs1; alu_src_out = 1'b1;  
            end
            7'b0110111: begin // LUI
                reg_write_out = 1'b1; rd_out = rd; immediate_out = u_immediate; operand1_out = 32'h0;
                alu_op_out = 4'b0000; alu_src_out = 1'b1; 
            end
            7'b0010111: begin // AUIPC
                reg_write_out = 1'b1; rd_out = rd; immediate_out = u_immediate; 
                operand1_out = pc_in; 
                alu_op_out = 4'b0000; alu_src_out = 1'b1;
            end
        endcase
    end
endmodule