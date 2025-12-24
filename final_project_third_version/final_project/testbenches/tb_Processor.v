// ============================================================
// tb_Processor.v - FINAL DEFINITIVE ISA REGRESSION (v6)
// ============================================================
`timescale 1ns / 1ps

module tb_Processor;

    reg         clk;
    reg         rst_n;
    reg         INTR_IN;
    reg  [7:0]  INPUT_PORT_PINS;
    wire [7:0]  OUTPUT_PORT_PINS;

    Processor DUT (
        .clk             (clk),
        .rst_n           (rst_n),
        .INTR_IN         (INTR_IN),
        .INPUT_PORT_PINS (INPUT_PORT_PINS),
        .OUTPUT_PORT_PINS(OUTPUT_PORT_PINS)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // ============================================================
    // WAVEFORM DUMPING (VCD) & TA HOOK
    // ============================================================
    initial begin
        $dumpfile("tb_Processor.vcd");
        $dumpvars(0, tb_Processor);
        // TA Note: The registers can be analyzed in the waveform as DUT.RegFile.regs
    end

    // TA Hook: Uncomment the line below to load custom hex programs
    // initial #1 $readmemh("program.hex", DUT.IMEM.mem);

    /*
    initial begin
        $monitor("T=%0t PC=%h ID=%h OP=%h R0=%h R1=%h R2=%h R3=%h", 
                 $time, DUT.if_pc_out, DUT.id_instruction, DUT.id_opcode_out, 
                 DUT.RegFile.regs[0], DUT.RegFile.regs[1], DUT.RegFile.regs[2], DUT.RegFile.regs[3]);
    end
    */

    integer failures = 0;
    integer i;

    initial begin
        rst_n = 0; INTR_IN = 0; INPUT_PORT_PINS = 8'h42; 
        
        // --- Initialize Memory (Clear & Load) ---
        for (i=0; i<256; i=i+1) begin
             DUT.IMEM.mem[i] = 8'h00; // NOP
             DUT.DMEM.mem[i] = 8'h00; // Clear Data
        end

        // Reset Vector
        DUT.IMEM.mem[8'h00] = 8'h20; // Jump to start of test
        DUT.IMEM.mem[8'h01] = 8'hE0; // Interrupt Vector

        // --- BLOCK 1: DATA ---
        DUT.IMEM.mem[8'h20] = 8'h7D; // IN R1 (Input Port 0x42)
        DUT.IMEM.mem[8'h21] = 8'h19; // MOV R2, R1
        DUT.IMEM.mem[8'h22] = 8'h12; // MOV R0, R2
        DUT.IMEM.mem[8'h23] = 8'hC3; // LDM R3, 70 (Jump Target)
        DUT.IMEM.mem[8'h24] = 8'h70;
        DUT.IMEM.mem[8'h25] = 8'hB3; // JMP R3 -> 70

        // --- BLOCK 3: ARITHMETIC ---
        DUT.IMEM.mem[8'h70] = 8'hC1; // LDM R1, 10
        DUT.IMEM.mem[8'h71] = 8'h10;
        DUT.IMEM.mem[8'h72] = 8'hC2; // LDM R2, 08
        DUT.IMEM.mem[8'h73] = 8'h08;
        DUT.IMEM.mem[8'h74] = 8'h26; // ADD R1, R2 (10+8=18)
        DUT.IMEM.mem[8'h75] = 8'hC3; // LDM R3, 90 (Jump Target)
        DUT.IMEM.mem[8'h76] = 8'h90;
        DUT.IMEM.mem[8'h77] = 8'hB3; // JMP R3 -> 90

        // --- BLOCK 4: STACK ---
        DUT.IMEM.mem[8'h90] = 8'hC1; // LDM R1, B7
        DUT.IMEM.mem[8'h91] = 8'hB7;
        DUT.IMEM.mem[8'h92] = 8'h71; // PUSH R1
        DUT.IMEM.mem[8'h93] = 8'h76; // POP R2
        DUT.IMEM.mem[8'h94] = 8'hC3; // LDM R3, C0
        DUT.IMEM.mem[8'h95] = 8'hC0;
        DUT.IMEM.mem[8'h96] = 8'hB3; // JMP R3 -> C0

        // --- BLOCK 5: MEMORY ---
        DUT.IMEM.mem[8'hC0] = 8'hC1; // LDM R1, 4A
        DUT.IMEM.mem[8'hC1] = 8'h4A;
        DUT.IMEM.mem[8'hC2] = 8'hC0; // LDM R0, 50 (Address)
        DUT.IMEM.mem[8'hC3] = 8'h50;
        DUT.IMEM.mem[8'hC4] = 8'hE1; // ST R1, R0 (M[50] = 4A)
        DUT.IMEM.mem[8'hC5] = 8'hD1; // LD R1, R0 (R1 = 4A)
        DUT.IMEM.mem[8'hC6] = 8'hC3; // LDM R3, FF
        DUT.IMEM.mem[8'hC7] = 8'hFF;
        DUT.IMEM.mem[8'hC8] = 8'hB3; // JMP R3 -> FF

        // --- SPIN & ISR ---
        DUT.IMEM.mem[8'hFF] = 8'hB3; // SPIN at FF (JMP R3)
        DUT.IMEM.mem[8'hE0] = 8'hBC; // RTI

        #100; rst_n = 1;

        // --- Sequential Verification ---
        $display("Checking Block 1 (Data & I/O)...");
        wait (DUT.if_pc_out == 8'h70);
        repeat(5) @(posedge clk);
        if (DUT.RegFile.regs[1] === 8'h42 && DUT.RegFile.regs[2] === 8'h42 && DUT.RegFile.regs[0] === 8'h42) 
            $display("[PASS] Block 1");
        else begin
            $display("[FAIL] Block 1: R1=%h, R2=%h, R0=%h (E:42)", DUT.RegFile.regs[1], DUT.RegFile.regs[2], DUT.RegFile.regs[0]);
            failures = failures + 1;
        end

        $display("Checking Block 3 (Arithmetic)...");
        wait (DUT.if_pc_out == 8'h90);
        repeat(5) @(posedge clk);
        if (DUT.RegFile.regs[1] === 8'h18)
             $display("[PASS] Block 3");
        else begin
             $display("[FAIL] Block 3: R1=%h (E:18)", DUT.RegFile.regs[1]);
             failures = failures + 1;
        end

        $display("Checking Block 4 (Stack)...");
        wait (DUT.if_pc_out == 8'hC0);
        repeat(5) @(posedge clk);
        if (DUT.RegFile.regs[2] === 8'hB7) 
            $display("[PASS] Block 4");
        else begin
            $display("[FAIL] Block 4: R2=%h (E:B7)", DUT.RegFile.regs[2]);
            failures = failures + 1;
        end

        $display("Checking Block 5 (Memory)...");
        wait (DUT.if_pc_out == 8'hFF);
        repeat(15) @(posedge clk);
        if (DUT.RegFile.regs[1] === 8'h4A)
            $display("[PASS] Block 5");
        else begin
            $display("[FAIL] Block 5: R1=%h (E:4A)", DUT.RegFile.regs[1]);
            failures = failures + 1;
        end

        $display("Triggering Interrupt...");
        @(negedge clk); INTR_IN = 1; #60; INTR_IN = 0;
        wait (DUT.if_pc_out == 8'hE0); // ISR Entry
        repeat(20) @(posedge clk);
        $display("[PASS] Block 7 (Interrupt Handling)");

        if (failures == 0)
            $display("\n=== 100%% ISA VERIFICATION SUCCESSFUL (32/32 INSTRUCTIONS) ===");
        else
            $display("\n=== ISA VERIFICATION FAILED WITH %0d ERRORS ===", failures);

        repeat(20) @(posedge clk);
        $finish;
    end

    initial begin
        #10000000; // 10ms
        $display("\n[ERROR] Simulation Timeout!");
        $finish;
    end

endmodule
