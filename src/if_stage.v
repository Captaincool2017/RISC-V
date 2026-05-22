`timescale 1ns / 1ps

module if_stage (
    input clk,
    input reset,
    input stall_en,
    input flush_en,
    input ex_branch_taken_in,
    input [31:0] ex_branch_target_in,
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] instruction_out,
    output [31:0] pc_out
);
    reg [31:0] pc;
    wire [31:0] next_pc;

    // Instruction Memory
    reg [31:0] instruction_memory [0:1023];
    initial begin
        $readmemh("firmware/build/firmware.mem", instruction_memory);
    end

    assign pc_out = pc;
    assign next_pc = ex_branch_taken_in ? ex_branch_target_in : (pc + 4);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;
        end else if (!stall_en || ex_branch_taken_in) begin
            pc <= next_pc;
        end
    end

    // Fetch the raw instruction from memory
    wire [31:0] raw_instr = instruction_memory[pc[11:2]];
    
    always @(*) begin
        if (flush_en) begin
            instruction_out = 32'h00000013; // NOP
            pc_plus_4_out = pc + 4;
        end else begin
            instruction_out = raw_instr;
            pc_plus_4_out = pc + 4;
        end
    end
endmodule