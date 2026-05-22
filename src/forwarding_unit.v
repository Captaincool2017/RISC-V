`timescale 1ns / 1ps

module forwarding_unit (
    input [4:0] id_ex_rs1_addr_in,
    input [4:0] id_ex_rs2_addr_in,
    input [4:0] ex_mem_rd_in,
    input       ex_mem_reg_write_in,
    input [4:0] mem_wb_rd_in,
    input       mem_wb_reg_write_in,

    output reg [1:0] forward_a_out,
    output reg [1:0] forward_b_out
);

    always @(*) begin
        forward_a_out = 2'b00; // Default: no forwarding
        forward_b_out = 2'b00; // Default: no forwarding

        // EX/MEM to EX forwarding (forward_a for rs1)
        if (ex_mem_reg_write_in && (ex_mem_rd_in != 5'b00000) && (ex_mem_rd_in == id_ex_rs1_addr_in)) begin
            forward_a_out = 2'b01;
        end

        // MEM/WB to EX forwarding (forward_a for rs1)
        if (mem_wb_reg_write_in && (mem_wb_rd_in != 5'b00000) && (mem_wb_rd_in == id_ex_rs1_addr_in)) begin
            // Prioritize EX/MEM forwarding if both are hazards
            if (!(ex_mem_reg_write_in && (ex_mem_rd_in != 5'b00000) && (ex_mem_rd_in == id_ex_rs1_addr_in))) begin
                forward_a_out = 2'b10;
            end
        end

        // EX/MEM to EX forwarding (forward_b for rs2)
        if (ex_mem_reg_write_in && (ex_mem_rd_in != 5'b00000) && (ex_mem_rd_in == id_ex_rs2_addr_in)) begin
            forward_b_out = 2'b01;
        end

        // MEM/WB to EX forwarding (forward_b for rs2)
        if (mem_wb_reg_write_in && (mem_wb_rd_in != 5'b00000) && (mem_wb_rd_in == id_ex_rs2_addr_in)) begin
            // Prioritize EX/MEM forwarding if both are hazards
            if (!(ex_mem_reg_write_in && (ex_mem_rd_in != 5'b00000) && (ex_mem_rd_in == id_ex_rs2_addr_in))) begin
                forward_b_out = 2'b10;
            end
        end
    end

endmodule