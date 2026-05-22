`timescale 1ns / 1ps

module hazard_detection_unit (                 
    input        reset,               
    input [31:0] if_id_instruction_in,
    input        id_ex_mem_read_in,
    input [4:0]  id_ex_rd_in,
    input        ex_branch_taken_in,
    input        div_mul_stall_in,

    output reg   stall_en_out,
    output reg   flush_en_out,
    output reg   id_ex_flush_out,
    output reg   pc_if_id_stall_out // NEW: Specific front-end stall
);

    wire [4:0] if_id_rs1 = if_id_instruction_in[19:15];
    wire [4:0] if_id_rs2 = if_id_instruction_in[24:20];

    // Added safety check so x0 doesn't trigger a hazard
    wire load_use_hazard = id_ex_mem_read_in && (id_ex_rd_in != 5'b00000) && ((id_ex_rd_in == if_id_rs1) || (id_ex_rd_in == if_id_rs2));

    always @(*) begin
        if (reset) begin
            stall_en_out = 1'b0;
            id_ex_flush_out = 1'b0;
            pc_if_id_stall_out = 1'b0;
            flush_en_out = 1'b0;
        end else begin
            // Default assignments
            stall_en_out = 1'b0;
            id_ex_flush_out = 1'b0;
            pc_if_id_stall_out = 1'b0;
            flush_en_out = 1'b0;

            // Priority 1: Branch Mispredict
            if (ex_branch_taken_in) begin
                flush_en_out = 1'b1;
            end 
            // Priority 2: Multicycle Operation
            else if (div_mul_stall_in) begin
                stall_en_out = 1'b1;       // Stalls EX_MEM and MEM_WB
                pc_if_id_stall_out = 1'b1; // Stalls PC and IF_ID
            end 
            // Priority 3: Load-Use Hazard
            else if (load_use_hazard) begin
                pc_if_id_stall_out = 1'b1; // Stall PC and IF_ID
                id_ex_flush_out = 1'b1;    // Bubble ID_EX
                stall_en_out = 1'b0;       // DO NOT stall EX/MEM/WB! Let the load proceed!
            end
        end
    end

endmodule