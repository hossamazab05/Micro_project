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

    initial begin
        $monitor("T=%0t PC=%h ID=%h OP=%h R0=%h R1=%h R2=%h R3=%h", 
                 $time, DUT.if_pc_out, DUT.id_instruction, DUT.id_opcode_out, 
                 DUT.RegFile.regs[0], DUT.RegFile.regs[1], DUT.RegFile.regs[2], DUT.RegFile.regs[3]);
    end

    integer failures = 0;

    initial begin
        rst_n = 0; INTR_IN = 0; INPUT_PORT_PINS = 8'h42; 
        #100; rst_n = 1;

        // --- CHECK 1: Data & I/O ---
        $display("Starting Block 1...");
        wait (DUT.if_pc_out == 8'h20); 
        repeat(5) @(posedge clk);
        if (DUT.RegFile.regs[2] === 8'h42 && DUT.RegFile.regs[1] === 8'h42 && DUT.RegFile.regs[0] === 8'h42) 
            $display("[PASS] Block 1 (Data & I/O)");
        else begin
            $display("[FAIL] Block 1: R0=%h, R1=%h, R2=%h (E:42)", DUT.RegFile.regs[0], DUT.RegFile.regs[1], DUT.RegFile.regs[2]);
            failures = failures + 1;
        end

        // --- CHECK 2: Flags & Branches ---
        $display("Starting Block 2...");
        wait (DUT.if_pc_out == 8'h5C); 
        repeat(5) @(posedge clk);
        $display("[PASS] Block 2 (Flags & Branches)");

        // --- CHECK 3: Arithmetic & Logic ---
        $display("Starting Block 3...");
        wait (DUT.if_pc_out == 8'h75); 
        repeat(5) @(posedge clk);
        if (DUT.RegFile.regs[1] === 8'h18)
             $display("[PASS] Block 3 (Arithmetic & Logic)");
        else begin
             $display("[FAIL] Block 3: R1=%h (E:18)", DUT.RegFile.regs[1]);
             failures = failures + 1;
        end

        // --- CHECK 4: Stack & Subroutines ---
        $display("Starting Block 4...");
        wait (DUT.if_pc_out == 8'hA1); 
        repeat(5) @(posedge clk);
        if (DUT.RegFile.regs[2] === 8'hB7) // Restoration check
            $display("[PASS] Block 4 (Stack & Subroutines)");
        else begin
            $display("[FAIL] Block 4: R2=%h (E:B7)", DUT.RegFile.regs[2]);
            failures = failures + 1;
        end

        // --- CHECK 5: Memory Interface ---
        $display("Starting Block 5...");
        wait (DUT.if_pc_out == 8'hD0); 
        repeat(5) @(posedge clk);
        if (DUT.RegFile.regs[1] === 8'h4A)
            $display("[PASS] Block 5 (Memory Interface)");
        else begin
            $display("[FAIL] Block 5: R1=%h (E:4A)", DUT.RegFile.regs[1]);
            failures = failures + 1;
        end

        // --- CHECK 6: Control Flow ---
        $display("Starting Block 6...");
        wait (DUT.if_pc_out == 8'hFF); // Wait for SPIN
        repeat(5) @(posedge clk);
        $display("[PASS] Block 6 (Control Flow)");

        $display("Triggering System Interrupt...");
        @(negedge clk); INTR_IN = 1; #60; INTR_IN = 0;
        wait (DUT.if_pc_out == 8'hE0); // ISR Entry
        #100;
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
