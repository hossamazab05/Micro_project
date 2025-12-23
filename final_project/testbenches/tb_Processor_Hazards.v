// ============================================================
// tb_Processor_Hazards.v
// Verification Testbench for Pipeline Hazards & Forwarding
// ============================================================
`timescale 1ns / 1ps

module tb_Processor_Hazards;

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
        rst_n = 0; INTR_IN = 0; INPUT_PORT_PINS = 0;
        
        // ------------------------------------------------
        // Initialize Memory (Clear Garbage)
        // ------------------------------------------------
        for (i=0; i<256; i=i+1) begin
             DUT.IMEM.mem[i] = 8'h00; // NOP
             DUT.DMEM.mem[i] = 8'h00; // Clear Data
        end

        // ------------------------------------------------
        // Load Test Program
        // ------------------------------------------------
        
        // 00: Boot Jump -> 10
        // 00: LDM R0, 10
        DUT.IMEM.mem[0] = 8'hC0; DUT.IMEM.mem[1] = 8'h10;
        // 02: JMP R0
        DUT.IMEM.mem[2] = 8'hB0;

        // --- TEST 1: Forwarding (R1 accumulates 1+1+1+1) ---
        // 10: LDM R1, 01  (R1 = 1)
        DUT.IMEM.mem[8'h10] = 8'hC1; DUT.IMEM.mem[8'h11] = 8'h01;
        // 12: LDM R2, 01  (R2 = 1)
        DUT.IMEM.mem[8'h12] = 8'hC2; DUT.IMEM.mem[8'h13] = 8'h01;
        // 14: ADD R1, R2  (R1 = 2) - Forwarding from WB
        DUT.IMEM.mem[8'h14] = 8'h26; 
        // 15: ADD R1, R2  (R1 = 3) - Forwarding from MEM
        DUT.IMEM.mem[8'h15] = 8'h26;
        // 16: ADD R1, R2  (R1 = 4) - Forwarding from MEM
        DUT.IMEM.mem[8'h16] = 8'h26;

        // --- TEST 2: Load-Use Hazard ---
        // 20: LDM R0, 30  (Addr = 30)
        DUT.IMEM.mem[8'h20] = 8'hC0; DUT.IMEM.mem[8'h21] = 8'h30;
        // 22: LDM R2, 55  (Data = 55)
        DUT.IMEM.mem[8'h22] = 8'hC2; DUT.IMEM.mem[8'h23] = 8'h55;
        // 24: STI R2, R0  (M[30] = 55)
        DUT.IMEM.mem[8'h24] = 8'hE2;
        // 25: LDI R1, R0  (R1 = 55)
        DUT.IMEM.mem[8'h25] = 8'hD1;
        // 26: ADD R1, R1  (R1 = AA) - Load-Use Hazard
        DUT.IMEM.mem[8'h26] = 8'h25; 
        
        // --- TEST 3: Branch Flushing ---
        // 30: LDM R2, 05
        DUT.IMEM.mem[8'h30] = 8'hC2; DUT.IMEM.mem[8'h31] = 8'h05;
        // 32: LDM R3, 40 (Target)
        DUT.IMEM.mem[8'h32] = 8'hC3; DUT.IMEM.mem[8'h33] = 8'h40;
        // 34: SUB R2, R2 (Z=1) -> Opcode 3. ra=2, rb=2 -> 3A.
        DUT.IMEM.mem[8'h34] = 8'h3A;
        // 35: JZ R3 (Jump to 40)
        DUT.IMEM.mem[8'h35] = 8'h93;
        // 36: LDM R3, EE (Should be FLUSHED)
        DUT.IMEM.mem[8'h36] = 8'hC3; DUT.IMEM.mem[8'h37] = 8'hEE;
        
        // Target at 40:
        // LDM R3, AA
        DUT.IMEM.mem[8'h40] = 8'hC3; DUT.IMEM.mem[8'h41] = 8'hAA;
        
        // 42: JMP 50 (Start Full ISA Test)
        // LDM R0, 50
        DUT.IMEM.mem[8'h42] = 8'hC0; DUT.IMEM.mem[8'h43] = 8'h50;
        // JMP R0
        DUT.IMEM.mem[8'h44] = 8'hB0;
        
        // --- TEST 4: Full ISA Check ---
        // 50: LDM R1, 01
        DUT.IMEM.mem[8'h50] = 8'hC1; DUT.IMEM.mem[8'h51] = 8'h01;
        // 52: INC R1 (R1=2) -> Op 8, ra=2 (INC), rb=1 (R1). 1000 10 01 -> 89.
        DUT.IMEM.mem[8'h52] = 8'h89;
        // 53: MOV R2, R1 (R2=2) -> Op 1, ra=2 (R2), rb=1 (R1). 0001 10 01 -> 19.
        DUT.IMEM.mem[8'h53] = 8'h19;
        // 54: ADD R2, R1 (R2=2+2=4) -> Op 2, ra=2, rb=1. 0010 10 01 -> 29.
        DUT.IMEM.mem[8'h54] = 8'h29;
        // 55: SUB R2, R1 (R2=4-2=2) -> Op 3, ra=2, rb=1. 0011 10 01 -> 39.
        DUT.IMEM.mem[8'h55] = 8'h39;
        // 56: NOT R1 (R1=FD) -> Op 8, ra=0, rb=1. 1000 00 01 -> 81.
        DUT.IMEM.mem[8'h56] = 8'h81;
        // 57: AND R2, R1 (R2 = 02 & FD = 00) -> Op 4, ra=2, rb=1. 0100 10 01 -> 49.
        // Wait, 02 (00000010) & FD (11111101) = 00000000. Correct.
        DUT.IMEM.mem[8'h57] = 8'h49;
        // 58: OR R2, R1 (R2 = 00 | FD = FD) -> Op 5, ra=2, rb=1. 0101 10 01 -> 59.
        DUT.IMEM.mem[8'h58] = 8'h59;
        // 59: SHL R1 (R1 = FD << 1 = FA) -> Op 6, ra=0 (RLC?), rb=1. 0110 00 01 -> 61.
        // Wait, Op 6 ra=0 is RLC. Previous SUB set C=1. NOT/AND/OR preserved C=1.
        // So RLC shifts in 1. FD (1111 1101) -> FB (1111 1011).
        DUT.IMEM.mem[8'h59] = 8'h61;
        
        // 60: PUSH R1 (R1=FB) -> Op 7, ra=0. 0111 00 01 -> 71.
        DUT.IMEM.mem[8'h60] = 8'h71;
        // 61: LDM R2, 00 (Clear R2)
        DUT.IMEM.mem[8'h61] = 8'hC2; DUT.IMEM.mem[8'h62] = 8'h00;
        // 63: POP R2 (R2 should be FB) -> Op 7, ra=1, rb=2. 0111 01 10 -> 76.
        DUT.IMEM.mem[8'h63] = 8'h76;

        // 64: HLT (Loop)
        // LDM R0, 64
        DUT.IMEM.mem[8'h64] = 8'hC0; DUT.IMEM.mem[8'h65] = 8'h64;
        DUT.IMEM.mem[8'h66] = 8'hB0;

        // ------------------------------------------------
        // Run Simulation
        // ------------------------------------------------
        #100; rst_n = 1;

        $display("==================================================");
        $display("   HAZARD & PIPELINE VERIFICATION SUITE");
        $display("==================================================");

        // --- TEST 1: Forwarding ---
        $display("\n[TEST 1] Forwarding Verification");
        wait (DUT.if_pc_out == 8'h16); 
        repeat(8) @(posedge clk);

        $display("DEBUG: Checking Test 1. R1=%h", DUT.RegFile.regs[1]);
        if (DUT.RegFile.regs[1] === 8'h04) begin
            $display("[PASS] Forwarding Logic Verified. R1=04");
        end else begin
            $display("  [FAIL] Forwarding Logic Failed. R1=%h (Expected 04)", DUT.RegFile.regs[1]);
        end

        // --- TEST 2: Load-Use Hazard ---
        $display("\n[TEST 2] Load-Use Hazard Verification");
        wait (DUT.if_pc_out == 8'h26);
        
        fork : monitor_stall
            begin
                repeat(10) @(posedge clk) begin
                    if (DUT.h_pc_write == 0) begin
                        $display("  [PASS] STALL DETECTED at PC=%h", DUT.ex_pc);
                        disable monitor_stall;
                    end
                end
                $display("  [FAIL] NO STALL DETECTED!");
            end
        join

        // Wait for Test 2 to complete, but BEFORE Test 3 overwrites regs.
        // Test 3 starts at 30.
        wait (DUT.if_pc_out == 8'h30); 
        // At this point, ADD R1, R1 (at 26) should be finishing.
        // Wait a bit for WB.
        repeat(4) @(posedge clk);
        
        if (DUT.RegFile.regs[1] === 8'hAA)
            $display("  [PASS] Data Loaded Correctly. R1=AA");
        else
            $display("  [FAIL] Data Load Failed. R1=%h (Expected AA)", DUT.RegFile.regs[1]);

        // --- TEST 3: Branch Flushing ---
        $display("\n[TEST 3] Branch Flushing Verification");
        wait (DUT.if_pc_out == 8'h40); // Wait for Target
        repeat(8) @(posedge clk);

        if (DUT.RegFile.regs[3] === 8'hAA)
            $display("  [PASS] Jump Target Reached. R3=AA");
        else
            $display("  [FAIL] Jump Failed. R3=%h (Expected AA)", DUT.RegFile.regs[3]);

        // --- TEST 4: Full ISA Verification (32 Instructions) ---
        $display("\n[TEST 4] Full ISA Verification");
        
        // Initialize Input Port for IN test
        INPUT_PORT_PINS = 8'h77;

        // ---------------------------------------------------------
        // 50: NOP (Op 0)
        DUT.IMEM.mem[8'h50] = 8'h00;

        // 51: LDM R1, FF (Op 12) -> C1 FF
        DUT.IMEM.mem[8'h51] = 8'hC1; DUT.IMEM.mem[8'h52] = 8'hFF;

        // 53: MOV R2, R1 (Op 1) -> 0001 00 01 -> 11. (R2 = FF)
        DUT.IMEM.mem[8'h53] = 8'h11;

        // 54: LDM R3, 01 -> C3 01
        DUT.IMEM.mem[8'h54] = 8'hC3; DUT.IMEM.mem[8'h55] = 8'h01;

        // 56: ADD R2, R3 (Op 2) -> R2 = FF+1 = 00. C=1, Z=1. 0010 10 11 -> 2B.
        DUT.IMEM.mem[8'h56] = 8'h2B;

        // 57: SUB R2, R3 (Op 3) -> R2 = 00-1 = FF. C=0 (Borrow), N=1. 0011 10 11 -> 3B.
        DUT.IMEM.mem[8'h57] = 8'h3B;

        // 58: INC R2 (Op 8, ra=2) -> R2 = FF+1 = 00. 1000 10 10 -> 8A.
        DUT.IMEM.mem[8'h58] = 8'h8A;

        // 59: DEC R3 (Op 8, ra=3) -> R3 = 1-1 = 00. 1000 11 11 -> 8F.
        DUT.IMEM.mem[8'h59] = 8'h8F;

        // 5A: NEG R1 (Op 8, ra=1) -> R1 (FF) -> -(-1) = 1? Or 2's comp of FF(11111111). ~FF+1 = 00+1 = 01. 1000 01 01 -> 85.
        DUT.IMEM.mem[8'h5A] = 8'h85;

        // 5B: LDM R1, F0 -> C1 F0
        DUT.IMEM.mem[8'h5B] = 8'hC1; DUT.IMEM.mem[8'h5C] = 8'hF0;
        // 5D: LDM R2, 0F -> C2 0F
        DUT.IMEM.mem[8'h5D] = 8'hC2; DUT.IMEM.mem[8'h5E] = 8'h0F;

        // 5F: AND R1, R2 (Op 4) -> 00. 0100 01 10 -> 46.
        DUT.IMEM.mem[8'h5F] = 8'h46;
        
        // 60: OR R1, R2 (Op 5) -> FF. 0101 01 10 -> 56.
        DUT.IMEM.mem[8'h60] = 8'h56;

        // 61: NOT R2 (Op 8, ra=0) -> ~0F = F0. 1000 00 10 -> 82.
        DUT.IMEM.mem[8'h61] = 8'h82;

        // 62: SETC (Op 6, ra=2) -> C=1. 0110 10 00 -> 68.
        DUT.IMEM.mem[8'h62] = 8'h68;

        // 63: LDM R1, 01 -> C1 01
        DUT.IMEM.mem[8'h63] = 8'hC1; DUT.IMEM.mem[8'h64] = 8'h01;

        // 65: RLC R1 (Op 6, ra=0) -> 01<<1 | C(1) = 03. 0110 00 01 -> 61.
        DUT.IMEM.mem[8'h65] = 8'h61;

        // 66: CLRC (Op 6, ra=3) -> C=0. 0110 11 00 -> 6C.
        DUT.IMEM.mem[8'h66] = 8'h6C;

        // 67: RRC R1 (Op 6, ra=1) -> 03>>1 | C(0)<<7 = 01. 0110 01 01 -> 65.
        DUT.IMEM.mem[8'h67] = 8'h65;

        // 68: PUSH R1 (Op 7, ra=0) -> Stack gets 01. 0111 00 01 -> 71.
        DUT.IMEM.mem[8'h68] = 8'h71;

        // 69: LDM R1, AA -> C1 AA
        DUT.IMEM.mem[8'h69] = 8'hC1; DUT.IMEM.mem[8'h6A] = 8'hAA;

        // 6B: POP R2 (Op 7, ra=1) -> R2 = 01. 0111 01 10 -> 76.
        DUT.IMEM.mem[8'h6B] = 8'h76;

        // 6C: IN R3 (Op 7, ra=3) -> R3 = 77. 0111 11 11 -> 7F.
        DUT.IMEM.mem[8'h6C] = 8'h7F;

        // 6D: OUT R3 (Op 7, ra=2) -> Output = 77. 0111 10 11 -> 7B.
        DUT.IMEM.mem[8'h6D] = 8'h7B;

        // 6E: LDM R0, 80 -> C0 80 (Subroutine Addr)
        DUT.IMEM.mem[8'h6E] = 8'hC0; DUT.IMEM.mem[8'h6F] = 8'h80;

        // 70: CALL R0 (Op 11, ra=1) -> Push PC (71), Jump 80. 1011 01 00 -> B4.
        DUT.IMEM.mem[8'h70] = 8'hB4;
        
        // 71: NOP (Return point)
        DUT.IMEM.mem[8'h71] = 8'h00;

        // --- Jump Tests ---
        // 72: LDM R0, 90 (Jump Target)
        DUT.IMEM.mem[8'h72] = 8'hC0; DUT.IMEM.mem[8'h73] = 8'h90;

        // 74: LDM R1, 00
        DUT.IMEM.mem[8'h74] = 8'hC1; DUT.IMEM.mem[8'h75] = 8'h00;

        // 76: ADD R1, R1 -> Z=1.
        DUT.IMEM.mem[8'h76] = 8'h25;

        // 77: JZ R0 (Op 9, ra=0) -> Jump 90. 1001 00 00 -> 90.
        DUT.IMEM.mem[8'h77] = 8'h90;

        // --- Subroutine @ 80 ---
        // 80: LDM R1, 55
        DUT.IMEM.mem[8'h80] = 8'hC1; DUT.IMEM.mem[8'h81] = 8'h55;
        // 82: RET (Op 11, ra=2) -> Pop PC (71). 1011 10 00 -> B8.
        DUT.IMEM.mem[8'h82] = 8'hB8;

        // --- Target @ 90 ---
        // 90: LDM R2, BB
        DUT.IMEM.mem[8'h90] = 8'hC2; DUT.IMEM.mem[8'h91] = 8'hBB;

        // 92: LDM R1, CC
        DUT.IMEM.mem[8'h92] = 8'hC1; DUT.IMEM.mem[8'h93] = 8'hCC;
        
        // 94: STD R1, A0 (Op 12, ra=2) -> M[A0] = R1(CC). 1100 10 01 -> C9.
        DUT.IMEM.mem[8'h94] = 8'hC9; DUT.IMEM.mem[8'h95] = 8'hA0;

        // 96: LDD R3, A0 (Op 12, ra=1) -> R3 = M[A0](CC). 1100 01 11 -> C7.
        DUT.IMEM.mem[8'h96] = 8'hC7; DUT.IMEM.mem[8'h97] = 8'hA0;

        // --- Loop Test ---
        // 98: LDM R1, 02 (Counter)
        DUT.IMEM.mem[8'h98] = 8'hC1; DUT.IMEM.mem[8'h99] = 8'h02;
        // 9A: LDM R0, 9D (Target Loop)
        DUT.IMEM.mem[8'h9A] = 8'hC0; DUT.IMEM.mem[8'h9B] = 8'h9D;
        // 9C: NOP
        DUT.IMEM.mem[8'h9C] = 8'h00;
        // 9D: LOOP R1, R0 (Op 10) -> Dec R1, Jump R0 if != 0. 1010 00 01 -> A1.
        // Wait, Op 10 uses rs/rt? A1 means rs=0(R0?), rt=1(R1?).
        // Decoder: RS_EN=1 (Data1), RT_EN=1 (Target).
        // Loop Logic: Data1 - 1. If != 0, Jump to Target (Data2/Rt).
        // So we want LOOP R1, R0. Rs=1(Counter), Rt=0(Target).
        // 1010 01 00 -> A4.
        DUT.IMEM.mem[8'h9D] = 8'hA4;

        // 9E: HLT (Infinite Loop)
        // LDM R0, 9E
        DUT.IMEM.mem[8'h9E] = 8'hC0; DUT.IMEM.mem[8'h9F] = 8'h9E;
        DUT.IMEM.mem[8'hA0] = 8'hB0;

        // ------------------------------------------------
        // Run Simulation & Verify
        // ------------------------------------------------
        
        wait (DUT.if_pc_out == 8'h9E); // Wait for HLT
        repeat(10) @(posedge clk);
        
        $display("DEBUG: Final State Check:");
        $display("R1 = %h (Expected 00 - Loop Dec)", DUT.RegFile.regs[1]);
        $display("R2 = %h (Expected BB - JZ Target)", DUT.RegFile.regs[2]);
        $display("R3 = %h (Expected CC - LDD)", DUT.RegFile.regs[3]);
        $display("OUT = %h (Expected 77 - IN/OUT)", OUTPUT_PORT_PINS);
        
        if (DUT.RegFile.regs[1] === 8'h00 && 
            DUT.RegFile.regs[2] === 8'hBB && 
            DUT.RegFile.regs[3] === 8'hCC && 
            OUTPUT_PORT_PINS === 8'h77) begin
            $display("  [PASS] Full 32-Instruction ISA Verification Successful");
        end else begin
            $display("  [FAIL] ISA Verification Failed");
        end

        $display("\n==================================================");
        $display("   TEST COMPLETE");
        $display("==================================================");
        $finish;
    end

endmodule
