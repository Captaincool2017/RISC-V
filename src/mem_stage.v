`timescale 1ns / 1ps

module mem_stage (
    input clk,
    input reset,
    input [31:0] alu_result_in,
    input [31:0] write_data_in,
    input        mem_read_in,
    input        mem_write_in,
    input [2:0] funct3_in,
    
    output reg [31:0] read_data_out
);
    // Data Memory
    reg [31:0] data_memory [0:1023];
    // 4KB data memory

    // Initialize data memory
    // FIX: Named the block ": init_mem" so the integer declaration is valid
    initial begin : init_mem
        integer i;
        for (i = 0; i < 1024; i = i + 1) begin
            data_memory[i] = 32'hdeadbeef;
        end
    end

    // WRITE
    always @(posedge clk) begin
        if (mem_write_in && !reset) begin
            case (funct3_in)
                3'b000: begin // SB - store byte
                    data_memory[alu_result_in[11:2]][alu_result_in[1:0]*8 +: 8] <= write_data_in[7:0];
                end
                3'b001: begin // SH - store halfword
                    data_memory[alu_result_in[11:2]][alu_result_in[1]*16 +: 16] <= write_data_in[15:0];
                end
                3'b010: begin // SW - store word
                    data_memory[alu_result_in[11:2]] <= write_data_in;
                end
            endcase
        end
    end

    // READ
    always @(*) begin
        if (mem_read_in) begin
            case (funct3_in)
                3'b000: read_data_out = {{24{data_memory[alu_result_in[11:2]][alu_result_in[1:0]*8 + 7]}}, 
                                        data_memory[alu_result_in[11:2]][alu_result_in[1:0]*8 +: 8]}; // LB
                3'b001: read_data_out = {{16{data_memory[alu_result_in[11:2]][alu_result_in[1]*16 + 15]}}, 
                                        data_memory[alu_result_in[11:2]][alu_result_in[1]*16 +: 16]}; // LH
                3'b010: read_data_out = data_memory[alu_result_in[11:2]];                                 // LW
                3'b100: read_data_out = {24'b0, data_memory[alu_result_in[11:2]][alu_result_in[1:0]*8 +: 8]}; // LBU
                3'b101: read_data_out = {16'b0, data_memory[alu_result_in[11:2]][alu_result_in[1]*16 +: 16]}; // LHU
                default: read_data_out = 32'hxxxxxxxx;
            endcase
        end else begin
            read_data_out = 32'hxxxxxxxx;
        end
    end

endmodule