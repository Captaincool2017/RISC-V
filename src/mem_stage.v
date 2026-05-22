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
                3'b000: begin // SB
                    case (alu_result_in[1:0])
                        2'b00: data_memory[alu_result_in[11:2]][7:0]   <= write_data_in[7:0];
                        2'b01: data_memory[alu_result_in[11:2]][15:8]  <= write_data_in[7:0];
                        2'b10: data_memory[alu_result_in[11:2]][23:16] <= write_data_in[7:0];
                        2'b11: data_memory[alu_result_in[11:2]][31:24] <= write_data_in[7:0];
                    endcase
                end
                3'b001: begin // SH
                    case (alu_result_in[1])
                        1'b0: data_memory[alu_result_in[11:2]][15:0]  <= write_data_in[15:0];
                        1'b1: data_memory[alu_result_in[11:2]][31:16] <= write_data_in[15:0];
                    endcase
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
                3'b000: begin // LB
                    case (alu_result_in[1:0])
                        2'b00: read_data_out = {{24{data_memory[alu_result_in[11:2]][7]}},  data_memory[alu_result_in[11:2]][7:0]};
                        2'b01: read_data_out = {{24{data_memory[alu_result_in[11:2]][15]}}, data_memory[alu_result_in[11:2]][15:8]};
                        2'b10: read_data_out = {{24{data_memory[alu_result_in[11:2]][23]}}, data_memory[alu_result_in[11:2]][23:16]};
                        2'b11: read_data_out = {{24{data_memory[alu_result_in[11:2]][31]}}, data_memory[alu_result_in[11:2]][31:24]};
                    endcase
                end
                3'b001: begin // LH
                    case (alu_result_in[1])
                        1'b0: read_data_out = {{16{data_memory[alu_result_in[11:2]][15]}}, data_memory[alu_result_in[11:2]][15:0]};
                        1'b1: read_data_out = {{16{data_memory[alu_result_in[11:2]][31]}}, data_memory[alu_result_in[11:2]][31:16]};
                    endcase
                end
                3'b010: read_data_out = data_memory[alu_result_in[11:2]];                                 // LW
                3'b100: begin // LBU
                    case (alu_result_in[1:0])
                        2'b00: read_data_out = {24'b0, data_memory[alu_result_in[11:2]][7:0]};
                        2'b01: read_data_out = {24'b0, data_memory[alu_result_in[11:2]][15:8]};
                        2'b10: read_data_out = {24'b0, data_memory[alu_result_in[11:2]][23:16]};
                        2'b11: read_data_out = {24'b0, data_memory[alu_result_in[11:2]][31:24]};
                    endcase
                end
                3'b101: begin // LHU
                    case (alu_result_in[1])
                        1'b0: read_data_out = {16'b0, data_memory[alu_result_in[11:2]][15:0]};
                        1'b1: read_data_out = {16'b0, data_memory[alu_result_in[11:2]][31:16]};
                    endcase
                end
                default: read_data_out = 32'hxxxxxxxx;
            endcase
        end else begin
            read_data_out = 32'hxxxxxxxx;
        end
    end

endmodule