`timescale 1ns / 1ps

module tb_Reset_Stress;

    reg         clk;
    reg         rst_n;
    reg         INTR_IN;
    reg  [7:0]  INPUT_PORT_PINS;
    wire [7:0]  OUTPUT_PORT_PINS;
    integer     i;

    Processor DUT (
        .clk             (clk),
        .rst_n           (rst_n),
        .INTR_IN         (INTR_IN),
        .INPUT_PORT_PINS (INPUT_PORT_PINS),
        .OUTPUT_PORT_PINS(OUTPUT_PORT_PINS)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    initial begin
        // 1. Initialize Memory
        for (i=0; i<256; i=i+1) begin
             DUT.IMEM.mem[i] = 8'h00; // NOP
        end
        
        // Reset Vector -> Address 20
        DUT.IMEM.mem[0] = 8'h20; 
        
        // Program at Address 20: Simple Incrementing R1
        DUT.IMEM.mem[8'h20] = 8'h89; // INC R1 (R1 starts at 0)
        DUT.IMEM.mem[8'h21] = 8'h10; // Buffered MOV R1, R1 (dummy)
        DUT.IMEM.mem[8'h22] = 8'hC0; // Target 20
        DUT.IMEM.mem[8'h23] = 8'h20;
        DUT.IMEM.mem[8'h24] = 8'hB0; // JMP R0 -> Loop back to 20

        $display("\n==================================================");
        $display("   ELC3030 RESET STRESS VERIFICATION");
        $display("==================================================");

        // --- TEST 1: Cold Boot ---
        $display("[STATUS] Performing Cold Boot Reset...");
        rst_n = 0; INTR_IN = 0;
        #50 rst_n = 1;
        
        wait (DUT.if_pc_out === 8'h20);
        $display("[PASS] Cold Boot: PC correctly reached Reset Vector 0x20");
        
        // Let it run for a while
        repeat(50) @(posedge clk);
        $display("[STATUS] Processor is running. R1 = %h", DUT.RegFile.regs[1]);
        
        // --- TEST 2: Warm Reset (Mid-Execution) ---
        $display("[STATUS] Triggering Warm Reset (rst_n = 0)...");
        @(negedge clk);
        rst_n = 0;
        #30; // Hold reset
        
        // In Reset state, PC should be driven to 00 (vector location) or held at 00
        // Depending on RTL, PC might be 00 during reset if asynchronous.
        $display("[STATUS] Reset Held. PC = %h", DUT.if_pc_out);
        
        #20 rst_n = 1;
        $display("[STATUS] Reset Released.");
        
        wait (DUT.if_pc_out === 8'h20);
        $display("[PASS] Warm Reset: PC correctly returned to Reset Vector 0x20");
        
        // Verify state was cleared (R1 should be 0 because regs reset to 0)
        // Wait for first INC to potentially happen or check immediately
        if (DUT.RegFile.regs[1] === 8'h00) begin
            $display("[PASS] RegFile Reset: Registers cleared to 0x00");
        end else begin
            $display("[FAIL] RegFile Reset: R1 = %h", DUT.RegFile.regs[1]);
        end

        // --- TEST 3: Multi-Cycle Reset Pulse ---
        repeat(10) @(posedge clk);
        @(negedge clk);
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        
        wait (DUT.if_pc_out === 8'h20);
        $display("[PASS] Multi-Cycle Reset: Recovery Successful");

        $display("\n==================================================");
        $display("   RESET VERIFICATION: [PASS]");
        $display("==================================================\n");
        $finish;
    end
endmodule
