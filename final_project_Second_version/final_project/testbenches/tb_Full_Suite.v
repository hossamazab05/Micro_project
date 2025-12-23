`timescale 1ns / 1ps

module tb_Full_Suite;

    reg         clk;
    reg         rst_n;
    reg         INTR_IN;
    reg  [7:0]  INPUT_PORT_PINS;
    wire [7:0]  OUTPUT_PORT_PINS;
    integer     i;

    // Instantiate Processor
    Processor DUT (
        .clk             (clk),
        .rst_n           (rst_n),
        .INTR_IN         (INTR_IN),
        .INPUT_PORT_PINS (INPUT_PORT_PINS),
        .OUTPUT_PORT_PINS(OUTPUT_PORT_PINS)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // Test Sequence
    initial begin
        rst_n = 0; INTR_IN = 0; INPUT_PORT_PINS = 8'hAA; // Example Input
        
        // ------------------------------------------------
        // Initialize Memory (Clear Garbage)
        // ------------------------------------------------
        for (i=0; i<256; i=i+1) begin
             DUT.IMEM.mem[i] = 8'h00; // NOP
             DUT.DMEM.mem[i] = 8'h00; // Clear Data
        end

        // ------------------------------------------------
        // Load "InstructionMemory_Full.v.bak" Content
        // ------------------------------------------------
        
        // Reset Vector
        DUT.IMEM.mem[8'h00] = 8'h10;
        DUT.IMEM.mem[8'h01] = 8'hE0;

        // --- BLOCK 1: DATA (10 - 2F) ---
        DUT.IMEM.mem[8'h10] = 8'hC1; // LDM R1, 42
        DUT.IMEM.mem[8'h11] = 8'h42;
        // 12-19 Buffer (NOPs)
        DUT.IMEM.mem[8'h1A] = 8'h19; // MOV R2, R1
        DUT.IMEM.mem[8'h1C] = 8'h12; // MOV R0, R2
        DUT.IMEM.mem[8'h20] = 8'h7D; // IN R1
        DUT.IMEM.mem[8'h26] = 8'h79; // OUT R1

        // --- BLOCK 2: JUMPS (30 - 5F) ---
        DUT.IMEM.mem[8'h30] = 8'h68; // SETC
        DUT.IMEM.mem[8'h34] = 8'hC0; // Target 3A
        DUT.IMEM.mem[8'h35] = 8'h3A;
        DUT.IMEM.mem[8'h39] = 8'h98; // JC R0 -> 3A
        
        DUT.IMEM.mem[8'h3A] = 8'h6C; // CLRC
        DUT.IMEM.mem[8'h3E] = 8'hC0; // Target 44
        DUT.IMEM.mem[8'h3F] = 8'h44;
        DUT.IMEM.mem[8'h43] = 8'h90; // JZ R0 -> 44
        
        DUT.IMEM.mem[8'h44] = 8'hC1; // R1=80
        DUT.IMEM.mem[8'h45] = 8'h80;
        DUT.IMEM.mem[8'h49] = 8'h41; // AND R1,R1 (Z=0, N=1)
        DUT.IMEM.mem[8'h4A] = 8'hC0; // Target 50
        DUT.IMEM.mem[8'h4B] = 8'h50;
        DUT.IMEM.mem[8'h4F] = 8'h94; // JN R0 -> 50
        
        DUT.IMEM.mem[8'h50] = 8'hC1; // R1=7F
        DUT.IMEM.mem[8'h51] = 8'h7F;
        DUT.IMEM.mem[8'h55] = 8'h85; // NEG R1 (Should be 81)
        DUT.IMEM.mem[8'h56] = 8'hC0; // Target 5C
        DUT.IMEM.mem[8'h57] = 8'h5C;
        DUT.IMEM.mem[8'h5B] = 8'h9C; // JV R0 -> 5C

        // --- BLOCK 3: ALU (60 - 8F) ---
        DUT.IMEM.mem[8'h60] = 8'hC1; // R1=5
        DUT.IMEM.mem[8'h61] = 8'h05;
        DUT.IMEM.mem[8'h63] = 8'h25; // ADD R1,R1 (A)
        DUT.IMEM.mem[8'h64] = 8'h55; // OR R1,R1
        DUT.IMEM.mem[8'h65] = 8'h45; // AND R1,R1
        DUT.IMEM.mem[8'h66] = 8'h35; // SUB R1,R1 (0)
        DUT.IMEM.mem[8'h67] = 8'h89; // INC R1 (1)
        DUT.IMEM.mem[8'h68] = 8'hC1; // R1=5
        DUT.IMEM.mem[8'h69] = 8'h05;
        DUT.IMEM.mem[8'h6C] = 8'h8D; // DEC R1 (4)
        DUT.IMEM.mem[8'h6D] = 8'h85; // NEG R1 (FC)
        DUT.IMEM.mem[8'h6E] = 8'h81; // NOT R1 (03)
        DUT.IMEM.mem[8'h6F] = 8'h61; // RLC R1
        DUT.IMEM.mem[8'h70] = 8'h65; // RRC R1
        DUT.IMEM.mem[8'h71] = 8'h25; // ADD R1, R1
        DUT.IMEM.mem[8'h72] = 8'h25; // ADD R1, R1
        DUT.IMEM.mem[8'h73] = 8'h00; // NOP
        DUT.IMEM.mem[8'h74] = 8'h25; // ADD R1, R1

        // --- BLOCK 4: STACK (90 - AF) ---
        DUT.IMEM.mem[8'h90] = 8'hC1; // R1=B7
        DUT.IMEM.mem[8'h91] = 8'hB7;
        DUT.IMEM.mem[8'h94] = 8'h71; // PUSH R1
        DUT.IMEM.mem[8'h97] = 8'hC0; // Target F0
        DUT.IMEM.mem[8'h98] = 8'hF0;
        DUT.IMEM.mem[8'h9B] = 8'hB4; // CALL R0 -> F0
        DUT.IMEM.mem[8'hA0] = 8'h76; // POP R2

        // --- BLOCK 5: MEMORY (B0 - CF) ---
        DUT.IMEM.mem[8'hB0] = 8'hC1; // R1=01
        DUT.IMEM.mem[8'hB1] = 8'h01;
        DUT.IMEM.mem[8'hB4] = 8'hD6; // LDI R2, R1
        DUT.IMEM.mem[8'hB7] = 8'hC1; // R1=A5
        DUT.IMEM.mem[8'hB8] = 8'hA5;
        DUT.IMEM.mem[8'hBB] = 8'hC2; // R2=1F
        DUT.IMEM.mem[8'hBC] = 8'h1F;
        DUT.IMEM.mem[8'hBF] = 8'hE9; // STI R1, R2
        DUT.IMEM.mem[8'hC4] = 8'hC0; // R0=1F
        DUT.IMEM.mem[8'hC5] = 8'h1F;
        DUT.IMEM.mem[8'hC8] = 8'hD1; // LDI R1, R0
        DUT.IMEM.mem[8'hC9] = 8'h25; // ADD R1, R1

        // --- BLOCK 6: LOOPS (D0 - EF) ---
        DUT.IMEM.mem[8'hD0] = 8'hC1; // R1=2
        DUT.IMEM.mem[8'hD1] = 8'h02;
        DUT.IMEM.mem[8'hD4] = 8'hC0; // Target D6
        DUT.IMEM.mem[8'hD5] = 8'hD6;
        DUT.IMEM.mem[8'hD6] = 8'hA4; // LOOP R1, R0
        DUT.IMEM.mem[8'hDA] = 8'hC0; // target FF
        DUT.IMEM.mem[8'hDB] = 8'hFF;
        DUT.IMEM.mem[8'hDC] = 8'hB0; // JMP R0

        // --- SUBROUTINES ---
        DUT.IMEM.mem[8'hF0] = 8'hC2; // R2=AA
        DUT.IMEM.mem[8'hF1] = 8'hAA;
        DUT.IMEM.mem[8'hF2] = 8'hB8; // RET
        
        DUT.IMEM.mem[8'hFF] = 8'hB0; // SPIN

        // --- ISR ---
        DUT.IMEM.mem[8'hE0] = 8'hBC; // RTI


        // ------------------------------------------------
        // Run Simulation
        // ------------------------------------------------
        #100; rst_n = 1;

        $display("==================================================");
        $display("   RUNNING InstructionMemory_Full.v.bak SUITE");
        $display("==================================================");
        
        // Wait for completion (Spin at FF)
        wait (DUT.if_pc_out == 8'hFF);
        repeat(20) @(posedge clk);
        
        $display("DEBUG: Final State at PC=FF");
        $display("R1 = %h", DUT.RegFile.regs[1]);
        $display("R2 = %h", DUT.RegFile.regs[2]);
        $display("R0 = %h", DUT.RegFile.regs[0]);
        $display("Output Port = %h", OUTPUT_PORT_PINS);

        $display("\n[PASS] Reached End of Program (PC=FF)");
        $finish;
    end

endmodule
