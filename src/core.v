`timescale 1ns / 1ps

module core (
    input clk,
    input reset
);
    // Intermediate wires
    wire [31:0] if_pc_plus_4, if_instr, pc_out;
    wire [31:0] id_pc_plus_4, id_instr;
    wire [31:0] id_ex_pc_plus_4, id_ex_op1, id_ex_op2, id_ex_imm;
    wire [4:0]  id_ex_rd, id_ex_rs1, id_ex_rs2;
    wire [3:0]  id_ex_alu_op;
    wire        id_ex_mem_read, id_ex_mem_write, id_ex_mem_to_reg, id_ex_reg_write, id_ex_branch, id_ex_jal, id_ex_jalr, id_ex_mul, id_ex_div, id_ex_alu_src;
    wire [2:0] id_ex_funct3;
    wire [2:0] ex_mem_funct3;
    wire [2:0] mem_funct3;
    wire [31:0] ex_pc_plus_4, ex_op1, ex_op2, ex_imm;
    wire [4:0]  ex_rd, ex_rs1, ex_rs2;
    wire [3:0]  ex_alu_op;
    wire        ex_mem_read, ex_mem_write, ex_mem_to_reg, ex_reg_write, ex_branch, ex_jal, ex_jalr, ex_mul, ex_div, ex_alu_src;
    wire [31:0] ex_alu_res, ex_write_data;
    wire        ex_branch_taken;
    wire [31:0] ex_branch_target;

    wire [31:0] mem_pc_plus_4, mem_alu_res, mem_write_data;
    wire [4:0]  mem_rd;
    wire        mem_mem_read, mem_mem_write, mem_mem_to_reg, mem_reg_write, mem_jal, mem_jalr, mem_branch_taken;
    wire [31:0] mem_read_data;
    wire [31:0] wb_pc_plus_4, wb_alu_res, wb_read_data;
    wire [4:0]  wb_rd;
    wire        wb_mem_to_reg, wb_reg_write, wb_jal, wb_jalr;
    wire [31:0] wb_result;

    wire [1:0] forward_a, forward_b;
    wire stall_en, flush_en, div_mul_stall;
    wire id_ex_flush; 
    wire pc_if_id_stall; // NEW WIRE

    // --- Instantiations ---
    if_stage IF (
        .clk(clk), .reset(reset), .stall_en(pc_if_id_stall), .flush_en(flush_en),
        .ex_branch_taken_in(ex_branch_taken), .ex_branch_target_in(ex_branch_target), 
        .pc_plus_4_out(if_pc_plus_4), .instruction_out(if_instr), .pc_out(pc_out)
    );
    pipeline_register_if_id IF_ID (
        .clk(clk), .reset(reset), .stall_en(pc_if_id_stall), .flush_en(flush_en), 
        .pc_plus_4_in(if_pc_plus_4), .instruction_in(if_instr), 
        .pc_plus_4_out(id_pc_plus_4), .instruction_out(id_instr)
    );
    id_stage ID (
        .clk(clk), .reset(reset), .instruction_in(id_instr), .pc_plus_4_in(id_pc_plus_4), 
        .funct3_out(id_ex_funct3), .wb_rd_in(wb_rd), .wb_write_data_in(wb_result), .wb_reg_write_in(wb_reg_write),
        .operand1_out(id_ex_op1), .operand2_out(id_ex_op2), .immediate_out(id_ex_imm), .rd_out(id_ex_rd), .alu_op_out(id_ex_alu_op),
        .mem_read_out(id_ex_mem_read), .mem_write_out(id_ex_mem_write), .mem_to_reg_out(id_ex_mem_to_reg), .reg_write_out(id_ex_reg_write),
        .branch_out(id_ex_branch), .jal_out(id_ex_jal), .jalr_out(id_ex_jalr), .rs1_addr_out(id_ex_rs1), .rs2_addr_out(id_ex_rs2), .mul_en_out(id_ex_mul), .div_en_out(id_ex_div), .alu_src_out(id_ex_alu_src)
    );
    pipeline_register_id_ex ID_EX (
        .clk(clk), .reset(reset), .stall_en(stall_en), .flush_en(flush_en | id_ex_flush),
        .pc_plus_4_in(id_pc_plus_4), .operand1_in(id_ex_op1), .operand2_in(id_ex_op2), .immediate_in(id_ex_imm), .rd_in(id_ex_rd),
        .alu_op_in(id_ex_alu_op), .funct3_in(id_ex_funct3), .mem_read_in(id_ex_mem_read), .mem_write_in(id_ex_mem_write), .mem_to_reg_in(id_ex_mem_to_reg), .reg_write_in(id_ex_reg_write),
        .branch_in(id_ex_branch), .jal_in(id_ex_jal), .jalr_in(id_ex_jalr), .rs1_addr_in(id_ex_rs1), .rs2_addr_in(id_ex_rs2), .mul_en_in(id_ex_mul), .div_en_in(id_ex_div), .alu_src_in(id_ex_alu_src),
        .pc_plus_4_out(ex_pc_plus_4), .operand1_out(ex_op1), .operand2_out(ex_op2), .immediate_out(ex_imm), .rd_out(ex_rd), .alu_op_out(ex_alu_op),
        .funct3_out(ex_mem_funct3), .mem_read_out(ex_mem_read), .mem_write_out(ex_mem_write), .mem_to_reg_out(ex_mem_to_reg), .reg_write_out(ex_reg_write),
        .branch_out(ex_branch), .jal_out(ex_jal), .jalr_out(ex_jalr), .rs1_addr_out(ex_rs1), .rs2_addr_out(ex_rs2), .mul_en_out(ex_mul), .div_en_out(ex_div), .alu_src_out(ex_alu_src)
    );
    ex_stage EX (
        .clk(clk), .reset(reset), 
        .pc_plus_4_in(ex_pc_plus_4), .operand1_in(ex_op1), .operand2_in(ex_op2), .immediate_in(ex_imm), .alu_op_in(ex_alu_op), 
        .branch_in(ex_branch), .jal_in(ex_jal), .jalr_in(ex_jalr), .rs1_addr_in(ex_rs1), .rs2_addr_in(ex_rs2), .rd_in(ex_rd), 
        .mem_read_in(ex_mem_read), .mem_write_in(ex_mem_write), .mem_to_reg_in(ex_mem_to_reg), .reg_write_in(ex_reg_write),
        .forward_a_in(forward_a), .forward_b_in(forward_b), 
        .ex_mem_alu_result_in(mem_alu_res), .mem_wb_alu_result_in(wb_alu_res), .mem_wb_read_data_in(wb_read_data), 
        .ex_mem_rd_in(mem_rd), .mem_wb_rd_in(wb_rd), .ex_mem_reg_write_in(mem_reg_write), .mem_wb_reg_write_in(wb_reg_write), .mem_wb_mem_to_reg_in(wb_mem_to_reg), 
        .mul_en_in(ex_mul), .div_en_in(ex_div), .alu_src_in(ex_alu_src),
      
        .div_mul_stall_out(div_mul_stall), .alu_result_out(ex_alu_res), .write_data_out(ex_write_data), 
        .branch_taken_out(ex_branch_taken), .branch_target_out(ex_branch_target) 
    );

    wire mem_branch_flag;
    pipeline_register_ex_mem EX_MEM (
        .clk(clk), .reset(reset), .stall_en(stall_en), .flush_en(1'b0), // Changed to 1'b0 so branch writes aren't lost
        .pc_plus_4_in(ex_pc_plus_4), .alu_result_in(ex_alu_res), .funct3_in(ex_mem_funct3), .write_data_in(ex_write_data), .rd_in(ex_rd), 
        .mem_read_in(ex_mem_read), .mem_write_in(ex_mem_write), .mem_to_reg_in(ex_mem_to_reg), .reg_write_in(ex_reg_write), 
        .jal_in(ex_jal), .jalr_in(ex_jalr), .branch_taken_in(ex_branch_taken),
        .pc_plus_4_out(mem_pc_plus_4), .alu_result_out(mem_alu_res), .funct3_out(mem_funct3), .write_data_out(mem_write_data), .rd_out(mem_rd), 
        .mem_read_out(mem_mem_read), .mem_write_out(mem_mem_write), .mem_to_reg_out(mem_mem_to_reg), .reg_write_out(mem_reg_write), 
        .jal_out(mem_jal), .jalr_out(mem_jalr), .branch_taken_out(mem_branch_taken) 
    );
    mem_stage MEM (
        .clk(clk), .reset(reset), 
        .alu_result_in(mem_alu_res), .write_data_in(mem_write_data), .mem_read_in(mem_mem_read), .mem_write_in(mem_mem_write), 
        .funct3_in(mem_funct3), .read_data_out(mem_read_data)
    );
    pipeline_register_mem_wb MEM_WB (
        .clk(clk), .reset(reset), .stall_en(stall_en),
        .pc_plus_4_in(mem_pc_plus_4), .alu_result_in(mem_alu_res), .read_data_in(mem_read_data), .rd_in(mem_rd), 
        .mem_to_reg_in(mem_mem_to_reg), .reg_write_in(mem_reg_write), .jal_in(mem_jal), .jalr_in(mem_jalr),
        .pc_plus_4_out(wb_pc_plus_4), .alu_result_out(wb_alu_res), .read_data_out(wb_read_data), .rd_out(wb_rd), 
        .mem_to_reg_out(wb_mem_to_reg), .reg_write_out(wb_reg_write), .jal_out(wb_jal), .jalr_out(wb_jalr)
    );
    wb_stage WB (
        .pc_plus_4_in(wb_pc_plus_4), .alu_result_in(wb_alu_res), .read_data_in(wb_read_data), .rd_in(wb_rd), 
        .mem_to_reg_in(wb_mem_to_reg), .reg_write_in(wb_reg_write), .jal_in(wb_jal), .jalr_in(wb_jalr), 
        .write_data_out(wb_result)
    );
    forwarding_unit FU (
        .id_ex_rs1_addr_in(ex_rs1), 
        .id_ex_rs2_addr_in(ex_rs2), 
        .ex_mem_rd_in(mem_rd), 
        .ex_mem_reg_write_in(mem_reg_write), 
        .mem_wb_rd_in(wb_rd), 
        .mem_wb_reg_write_in(wb_reg_write), 
        .forward_a_out(forward_a), 
        .forward_b_out(forward_b)
    );
    hazard_detection_unit HDU (
        .clk(clk),                  
        .reset(reset),              
        .if_id_instruction_in(id_instr), 
        .id_ex_mem_read_in(ex_mem_read), 
        .id_ex_rd_in(ex_rd), 
        .id_ex_rs1_addr_in(ex_rs1), 
        .id_ex_rs2_addr_in(ex_rs2), 
        .ex_branch_in(ex_branch), 
        .ex_branch_taken_in(ex_branch_taken), 
        .div_mul_stall_in(div_mul_stall), 
        .stall_en_out(stall_en), 
        .flush_en_out(flush_en),
        .id_ex_flush_out(id_ex_flush),
        .pc_if_id_stall_out(pc_if_id_stall) // Separated stall wire
    );
endmodule