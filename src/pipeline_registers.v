`timescale 1ns / 1ps

// IF/ID Register
module pipeline_register_if_id (input clk, input reset, input stall_en, input flush_en, input [31:0] pc_plus_4_in, input [31:0] instruction_in, output reg [31:0] pc_plus_4_out, output reg [31:0] instruction_out);
    always @(posedge clk or posedge reset) begin
        if (reset || flush_en) begin pc_plus_4_out <= 0; instruction_out <= 32'h00000013; end
        else if (!stall_en) begin pc_plus_4_out <= pc_plus_4_in; instruction_out <= instruction_in; end
    end
endmodule

// ID/EX Register (Handles flushing and stalling)
module pipeline_register_id_ex (
    input clk, input reset, input stall_en, input flush_en,
    input [31:0] pc_plus_4_in, input [31:0] operand1_in, input [31:0] operand2_in, input [31:0] immediate_in, input [4:0] rd_in,
    input [3:0] alu_op_in, // CHANGED TO 4-BIT
    input mem_read_in, input mem_write_in, input mem_to_reg_in, input reg_write_in,
    input branch_in, input jal_in, input jalr_in, input [4:0] rs1_addr_in, input [4:0] rs2_addr_in, input mul_en_in, input div_en_in, input alu_src_in,
    
    output reg [31:0] pc_plus_4_out, output reg [31:0] operand1_out, output reg [31:0] operand2_out, output reg [31:0] immediate_out, output reg [4:0] rd_out,
    output reg [3:0] alu_op_out, // CHANGED TO 4-BIT
    output reg mem_read_out, output reg mem_write_out, output reg mem_to_reg_out, output reg reg_write_out,
    output reg branch_out, output reg jal_out, output reg jalr_out, output reg [4:0] rs1_addr_out, output reg [4:0] rs2_addr_out, output reg mul_en_out, output reg div_en_out, output reg alu_src_out
);
    always @(posedge clk or posedge reset) begin
        if (reset || flush_en) begin
            pc_plus_4_out <= 0; operand1_out <= 0; operand2_out <= 0; immediate_out <= 0; rd_out <= 0;
            alu_op_out <= 0; mem_read_out <= 0; mem_write_out <= 0; mem_to_reg_out <= 0; reg_write_out <= 0;
            branch_out <= 0; jal_out <= 0; jalr_out <= 0; rs1_addr_out <= 0; rs2_addr_out <= 0; mul_en_out <= 0; div_en_out <= 0; alu_src_out <= 0;
        end else if (!stall_en) begin
            pc_plus_4_out <= pc_plus_4_in; operand1_out <= operand1_in; operand2_out <= operand2_in; immediate_out <= immediate_in; rd_out <= rd_in;
            alu_op_out <= alu_op_in; mem_read_out <= mem_read_in; mem_write_out <= mem_write_in; mem_to_reg_out <= mem_to_reg_in; reg_write_out <= reg_write_in;
            branch_out <= branch_in; jal_out <= jal_in; jalr_out <= jalr_in; rs1_addr_out <= rs1_addr_in; rs2_addr_out <= rs2_addr_in; mul_en_out <= mul_en_in; div_en_out <= div_en_in; alu_src_out <= alu_src_in;
        end
    end
endmodule

// EX/MEM Register
module pipeline_register_ex_mem (input clk, input reset, input stall_en, input flush_en, input [31:0] pc_plus_4_in, input [31:0] alu_result_in, input [31:0] write_data_in, input [4:0] rd_in, input mem_read_in, input mem_write_in, input mem_to_reg_in, input reg_write_in, input branch_in, input jal_in, input jalr_in, input branch_taken_in,
                                 output reg [31:0] pc_plus_4_out, output reg [31:0] alu_result_out, output reg [31:0] write_data_out, output reg [4:0] rd_out, output reg mem_read_out, output reg mem_write_out, output reg mem_to_reg_out, output reg reg_write_out, output reg branch_out, output reg jal_out, output reg jalr_out, output reg branch_taken_out);
    always @(posedge clk or posedge reset) begin
        if (reset || flush_en) begin pc_plus_4_out <= 0; alu_result_out <= 0; write_data_out <= 0; rd_out <= 0; mem_read_out <= 0; mem_write_out <= 0; mem_to_reg_out <= 0; reg_write_out <= 0; branch_out <= 0; jal_out <= 0; jalr_out <= 0; branch_taken_out <= 0; end
        else if (!stall_en) begin pc_plus_4_out <= pc_plus_4_in; alu_result_out <= alu_result_in; write_data_out <= write_data_in; rd_out <= rd_in; mem_read_out <= mem_read_in; mem_write_out <= mem_write_in; mem_to_reg_out <= mem_to_reg_in; reg_write_out <= reg_write_in; branch_out <= branch_in; jal_out <= jal_in; jalr_out <= jalr_in; branch_taken_out <= branch_taken_in; end
    end
endmodule

// MEM/WB Register
module pipeline_register_mem_wb (input clk, input reset, input stall_en, input [31:0] pc_plus_4_in, input [31:0] alu_result_in, input [31:0] read_data_in, input [4:0] rd_in, input mem_to_reg_in, input reg_write_in, input jal_in, input jalr_in,
                                 output reg [31:0] pc_plus_4_out, output reg [31:0] alu_result_out, output reg [31:0] read_data_out, output reg [4:0] rd_out, output reg mem_to_reg_out, output reg reg_write_out, output reg jal_out, output reg jalr_out);
    always @(posedge clk or posedge reset) begin
        if (reset) begin pc_plus_4_out <= 0; alu_result_out <= 0; read_data_out <= 0; rd_out <= 0; mem_to_reg_out <= 0; reg_write_out <= 0; jal_out <= 0; jalr_out <= 0; end
        else if (!stall_en) begin pc_plus_4_out <= pc_plus_4_in; alu_result_out <= alu_result_in; read_data_out <= read_data_in; rd_out <= rd_in; mem_to_reg_out <= mem_to_reg_in; reg_write_out <= reg_write_in; jal_out <= jal_in; jalr_out <= jalr_in; end
    end
endmodule