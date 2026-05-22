`timescale 1ns / 1ps

module wb_stage (
    input [31:0] pc_plus_4_in,
    input [31:0] alu_result_in,
    input [31:0] read_data_in,
    input [4:0]  rd_in,
    input        mem_to_reg_in,
    input        reg_write_in,
    input        jal_in,
    input        jalr_in,

    output reg [31:0] write_data_out
);

    always @(*) begin
        if (reg_write_in) begin
            if (jal_in || jalr_in) begin
                write_data_out = pc_plus_4_in; // Return address for JAL/JALR
            end else if (mem_to_reg_in) begin
                write_data_out = read_data_in;
            end else begin
                write_data_out = alu_result_in;
            end
        end else begin
            write_data_out = 32'hxxxxxxxx;
        end
    end

endmodule