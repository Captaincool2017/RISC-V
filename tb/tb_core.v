`timescale 1ns / 1ps

module tb_core;
    reg clk;
    reg reset;
    
    // Instantiate the core
    core dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation: 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench Watchdog
    initial begin        
        reset = 1;
        #20;
        reset = 0;

        // Failsafe timeout: If the C code is truly stuck, kill it after 1ms
        #1000000;
        $display("\n>>> TEST TIMEOUT! <<<");
        $finish;
    end

    // PC trace — prints every cycle after reset
    always @(posedge clk) begin
        if (!reset) begin
            $display("Time: %0t | PC: %h | Instr: %h", 
                    $time, 
                    dut.IF.pc,           // access IF stage's pc register
                    dut.IF.raw_instr);   // access the fetched instruction
        end
    end

    always @(posedge clk) begin
        if (!reset && dut.MEM.mem_write_in) begin
            $display("STORE at addr=%h data=%h funct3=%b", 
                    dut.MEM.alu_result_in, 
                    dut.MEM.write_data_in,
                    dut.MEM.funct3_in);
        end
    end

    // Continuous Monitor: Watch the Memory Array directly!
    // 0x07FC / 4 = Word Index 511
    always @(posedge clk) begin
        // Wait for the default 'deadbeef' initialization to be overwritten
        if (!reset && dut.MEM.data_memory[511] != 32'hdeadbeef) begin
            $display("\n========== TEST RESULTS ==========");
            
            if (dut.MEM.data_memory[511] == 32'h1) begin
                $display(">>> TEST PASSED! <<<");
            end 
            else if (dut.MEM.data_memory[511] == 32'h2) begin
                $display(">>> TEST FAILED! <<<");
            end 
            else if (dut.MEM.data_memory[511] == 32'h3) begin
                $display(">>> TEST FINISHED <<<");
                // 0x07F8 / 4 = Word Index 510
                $display("Final Result: %0d (Hex: %h)", dut.MEM.data_memory[510], dut.MEM.data_memory[510]);
            end
            else begin
                $display(">>> UNKNOWN TEST CODE: %h <<<", dut.MEM.data_memory[511]);
            end
            
            $display("===================================\n");
            $finish; // End simulation instantly!
        end
    end

    // Generate waveform
    initial begin
        $dumpfile("tb_core.vcd");
        $dumpvars(0, tb_core);
    end
endmodule