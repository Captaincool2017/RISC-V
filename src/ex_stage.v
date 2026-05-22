`timescale 1ns / 1ps

module ex_stage (
    input clk,
    input reset,
    input [31:0] pc_plus_4_in,
    input [31:0] operand1_in,
    input [31:0] operand2_in,
    input [31:0] immediate_in,
    input [3:0]  alu_op_in, // CHANGED: 4-bit ALU instruction
    input        branch_in,
    input        jal_in,
    input        jalr_in,
    input [4:0]  rs1_addr_in,
    input [4:0]  rs2_addr_in,
    input [4:0]  rd_in,
    input        mem_read_in,
    input        mem_write_in,
    input        mem_to_reg_in,
    input        reg_write_in,
    input [1:0]  forward_a_in,
    input [1:0]  forward_b_in,
    input [31:0] ex_mem_alu_result_in,
    input [31:0] mem_wb_alu_result_in,
    input [31:0] mem_wb_read_data_in,
    input [4:0]  ex_mem_rd_in,
    input [4:0]  mem_wb_rd_in,
    input        ex_mem_reg_write_in,
    input        mem_wb_reg_write_in,
    input        mem_wb_mem_to_reg_in,
    input        mul_en_in,
    input        div_en_in,
    input        alu_src_in, 
    output reg   div_mul_stall_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,
    output reg        branch_taken_out,
    output reg [31:0] branch_target_out // ADDED: Destination for PC overriding
);

    reg [31:0] operand1_forwarded;
    reg [31:0] operand2_forwarded;
    reg [31:0] alu_op2; 

    // Forwarding logic
    always @(*) begin
        operand1_forwarded = operand1_in;
        operand2_forwarded = operand2_in;

        if (forward_a_in == 2'b01) operand1_forwarded = ex_mem_alu_result_in;
        else if (forward_a_in == 2'b10) operand1_forwarded = mem_wb_mem_to_reg_in ? mem_wb_read_data_in : mem_wb_alu_result_in;

        if (forward_b_in == 2'b01) operand2_forwarded = ex_mem_alu_result_in;
        else if (forward_b_in == 2'b10) operand2_forwarded = mem_wb_mem_to_reg_in ? mem_wb_read_data_in : mem_wb_alu_result_in;
    end

    wire [63:0] mul_ss = $signed(operand1_forwarded) * $signed(operand2_forwarded);
    wire [63:0] mul_su = $signed(operand1_forwarded) * $signed({1'b0, operand2_forwarded});
    wire [63:0] mul_uu = operand1_forwarded * operand2_forwarded;
    reg [31:0] mul_result;
    
    always @(*) begin
        mul_result = 32'h00000000;
        case (alu_op_in[2:0])
            3'b000: mul_result = mul_ss[31:0];
            3'b001: mul_result = mul_ss[63:32];
            3'b010: mul_result = mul_su[63:32];
            3'b011: mul_result = mul_uu[63:32];
            default: mul_result = 32'hxxxxxxxx;
        endcase
    end

    // Divider state machine
    localparam S_IDLE = 2'b00, S_DIVIDE = 2'b01, S_REM = 2'b10, S_DONE = 2'b11;
    reg [1:0] div_state;
    reg [31:0] dividend, divisor, quotient, remainder;
    reg [5:0]  div_counter;
    reg        div_active;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            div_state <= S_IDLE;
            div_mul_stall_out <= 1'b0;
            div_active <= 1'b0;
        end else begin
            case (div_state)
                S_IDLE: begin
                    if (div_en_in) begin
                        dividend <= operand1_forwarded;
                        divisor <= operand2_forwarded;
                        quotient <= 0; remainder <= 0; div_counter <= 32; div_active <= 1'b1;
                        div_mul_stall_out <= 1'b1;
                        div_state <= S_DIVIDE;
                    end else div_mul_stall_out <= 1'b0;
                end
                S_DIVIDE: begin
                    if (div_counter > 0) begin
                        if (remainder[31]) begin remainder <= (remainder << 1) + divisor; quotient <= (quotient << 1) | 1'b0; end
                        else begin remainder <= (remainder << 1) - divisor; quotient <= (quotient << 1) | 1'b1; end
                        div_counter <= div_counter - 1;
                    end else begin div_active <= 1'b0; div_mul_stall_out <= 1'b0; div_state <= S_DONE; end
                end
                S_DONE: if (!div_en_in) div_state <= S_IDLE;
                default: div_state <= S_IDLE;
            endcase
        end
    end

    always @(*) begin
        alu_result_out = 32'h00000000;
        write_data_out = operand2_forwarded; 
        branch_taken_out = 1'b0;
        branch_target_out = 32'h00000000;
        div_mul_stall_out = div_active; 
        
        alu_op2 = alu_src_in ? immediate_in : operand2_forwarded;

        if (mul_en_in) alu_result_out = mul_result;
        else if (div_en_in && div_active) alu_result_out = (alu_op_in[2:0] == 3'b110 || alu_op_in[2:0] == 3'b111) ? remainder : quotient;
        else begin
            case (alu_op_in)
                4'b0000: alu_result_out = operand1_forwarded + alu_op2; // ADD
                4'b0001: alu_result_out = operand1_forwarded - alu_op2; // SUB
                4'b0010: alu_result_out = operand1_forwarded << alu_op2[4:0]; // SLL
                4'b0011: alu_result_out = ($signed(operand1_forwarded) < $signed(alu_op2)) ? 32'h1 : 32'h0; // SLT
                4'b0100: alu_result_out = (operand1_forwarded < alu_op2) ? 32'h1 : 32'h0; // SLTU
                4'b0101: alu_result_out = operand1_forwarded ^ alu_op2; // XOR
                4'b0110: alu_result_out = operand1_forwarded >> alu_op2[4:0]; // SRL
                4'b0111: alu_result_out = $signed(operand1_forwarded) >>> alu_op2[4:0]; // SRA
                4'b1000: alu_result_out = operand1_forwarded | alu_op2; // OR
                4'b1001: alu_result_out = operand1_forwarded & alu_op2; // AND
                default: alu_result_out = 32'h00000000;
            endcase

            if (branch_in) begin
                branch_target_out = (pc_plus_4_in - 4) + immediate_in;
                case (alu_op_in) 
                    4'b1010: branch_taken_out = (operand1_forwarded == alu_op2); // BEQ
                    4'b1011: branch_taken_out = (operand1_forwarded != alu_op2); // BNE
                    4'b1100: branch_taken_out = ($signed(operand1_forwarded) < $signed(alu_op2)); // BLT
                    4'b1101: branch_taken_out = ($signed(operand1_forwarded) >= $signed(alu_op2)); // BGE
                    4'b1110: branch_taken_out = (operand1_forwarded < alu_op2); // BLTU
                    4'b1111: branch_taken_out = (operand1_forwarded >= alu_op2); // BGEU
                    default: branch_taken_out = 1'b0;
                endcase
            end else if (jal_in) begin
                branch_taken_out = 1'b1;
                branch_target_out = (pc_plus_4_in - 4) + immediate_in;
                alu_result_out = pc_plus_4_in;
            end else if (jalr_in) begin
                branch_taken_out = 1'b1;
                branch_target_out = (operand1_forwarded + immediate_in) & ~32'h1;
                alu_result_out = pc_plus_4_in;
            end
        end
    end
endmodule