`timescale 1ns / 1ps

module mem_stage (
    input clk,
    input reset,
    input [31:0] alu_result_in,
    input [31:0] write_data_in,
    input        mem_read_in,
    input        mem_write_in,

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

    always @(posedge clk) begin
        if (reset) begin
            // No specific reset for memory contents
        end else begin
            if (mem_write_in) begin
                data_memory[alu_result_in[11:2]] <= write_data_in;
            end
        end
    end

    always @(*) begin
        if (mem_read_in) begin
            read_data_out = data_memory[alu_result_in[11:2]];
        end else begin
            read_data_out = 32'hxxxxxxxx;
        end
    end

endmodule