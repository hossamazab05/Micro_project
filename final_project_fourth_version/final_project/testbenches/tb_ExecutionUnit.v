// ============================================================
// tb_ExecutionUnit.v
// Testbench for Execution Unit (ALU + Address Generation + Branch)
// ============================================================

`timescale 1ns / 1ps

module tb_ExecutionUnit;

    // ==================== Inputs ====================
    reg IOR, IOW, OPS, ALU;
    reg MR, MW, WB;
    reg Jmp, Jump_Conditional;
    reg SP, SPOP, JWSP;
    reg IMM;
    reg Stack_PC, Stack_Flags;
    reg [1:0] FD;
    reg [1:0] Flag_Selector;
    reg [3:0] Opcode;
    reg [2:0] ALU_Ops;
    reg [2:0] WB_Address;
    reg [7:0] Data1;
    reg [7:0] Data2;
    reg [7:0] Immediate_Value;
    reg [7:0] INPUT_PORT;
    reg [7:0] PC_8bit;
    reg [7:0] PC_plus_1;
    reg [3:0] Flags;
    reg [3:0] Flags_From_Memory;
    reg MEM_Stack_Flags;

    // ==================== Outputs ====================
    wire Taken_Jump;
    wire To_PC_Selector;
    wire MR_Out, MW_Out, WB_Out;
    wire JWSP_Out;
    wire SP_Out, SPOP_Out;
    wire Stack_PC_Out, Stack_Flags_Out;
    wire [2:0] WB_Address_Out;
    wire [3:0] Final_Flags;
    wire [7:0] Address_8bit;
    wire [7:0] Data_8bit;
    wire [7:0] OUTPUT_PORT;
    wire [7:0] Branch_Target_Out;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // ==================== DUT Instantiation ====================
    ExecutionUnit uut (
        .IOR(IOR), .IOW(IOW), .OPS(OPS), .ALU(ALU),
        .MR(MR), .MW(MW), .WB(WB),
        .Jmp(Jmp), .Jump_Conditional(Jump_Conditional),
        .SP(SP), .SPOP(SPOP), .JWSP(JWSP),
        .IMM(IMM),
        .Stack_PC(Stack_PC), .Stack_Flags(Stack_Flags),
        .FD(FD), .Flag_Selector(Flag_Selector),
        .Opcode(Opcode), .ALU_Ops(ALU_Ops), .WB_Address(WB_Address),
        .Data1(Data1), .Data2(Data2), .Immediate_Value(Immediate_Value),
        .INPUT_PORT(INPUT_PORT), .PC_8bit(PC_8bit), .PC_plus_1(PC_plus_1),
        .Flags(Flags), .Flags_From_Memory(Flags_From_Memory),
        .MEM_Stack_Flags(MEM_Stack_Flags),
        .Taken_Jump(Taken_Jump), .To_PC_Selector(To_PC_Selector),
        .MR_Out(MR_Out), .MW_Out(MW_Out), .WB_Out(WB_Out),
        .JWSP_Out(JWSP_Out), .SP_Out(SP_Out), .SPOP_Out(SPOP_Out),
        .Stack_PC_Out(Stack_PC_Out), .Stack_Flags_Out(Stack_Flags_Out),
        .WB_Address_Out(WB_Address_Out), .Final_Flags(Final_Flags),
        .Address_8bit(Address_8bit), .Data_8bit(Data_8bit),
        .OUTPUT_PORT(OUTPUT_PORT), .Branch_Target_Out(Branch_Target_Out)
    );

    // ==================== Helper Task ====================
    task check_result;
        input [255:0] test_name;
        input condition;
    begin
        test_count = test_count + 1;
        if (condition) begin
            $display("[PASS] %s", test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s", test_name);
            $display("       Data1=%h, Data2=%h, Result=%h, Flags=%b", Data1, Data2, Data_8bit, Final_Flags);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ==================== Main Test Sequence ====================
    initial begin
        $display("\n========================================");
        $display("Execution Unit Testbench");
        $display("========================================\n");

        // Initialize
        IOR=0; IOW=0; OPS=0; ALU=0; MR=0; MW=0; WB=0;
        Jmp=0; Jump_Conditional=0; SP=0; SPOP=0; JWSP=0; IMM=0;
        Stack_PC=0; Stack_Flags=0; FD=0; Flag_Selector=0;
        Opcode=0; ALU_Ops=0; WB_Address=0;
        Data1=0; Data2=0; Immediate_Value=0; INPUT_PORT=0;
        PC_8bit=0; PC_plus_1=0; Flags=0; Flags_From_Memory=0; MEM_Stack_Flags=0;
        #10;

        // --- TEST 1: Basic Arithmetic (ADD) ---
        $display("--- TEST 1: ADD R1, R2 ---");
        Opcode = 4'd2; ALU = 1; WB = 1; FD = 2'b11;
        Data1 = 8'h10; Data2 = 8'h20;
        #10;
        check_result("ADD: 0x10 + 0x20 = 0x30", Data_8bit == 8'h30 && Final_Flags[2] == 0);

        // --- TEST 2: Arithmetic Overflow (ADD) ---
        $display("\n--- TEST 2: ADD Overflow ---");
        Data1 = 8'hFF; Data2 = 8'h01;
        #10;
        check_result("ADD: 0xFF + 0x01 = 0x00 (Z=1, C=1)", Data_8bit == 8'h00 && Final_Flags[0]==1 && Final_Flags[2]==1);

        // --- TEST 3: Logic (OR) ---
        $display("\n--- TEST 3: OR Logic ---");
        Opcode = 4'd5; Data1 = 8'hAA; Data2 = 8'h55;
        #10;
        check_result("OR: AA | 55 = FF", Data_8bit == 8'hFF);

        // --- TEST 4: Immediate Load (LDM) ---
        $display("\n--- TEST 4: LDM Immediate ---");
        Opcode = 4'd12; IMM = 1; Immediate_Value = 8'h77;
        #10;
        check_result("LDM: Load 0x77", Data_8bit == 8'h77);

        // --- TEST 5: Increment (INC) -> Using OPS ---
        $display("\n--- TEST 5: INC (OPS) ---");
        Opcode = 4'd8; ALU_Ops = 3'd2; OPS = 1; IMM = 0; ALU = 1;
        Data2 = 8'h10; // Input to INC is usually Data2 for single operand? RTA logic varies.
                       // Based on RTL: case 8, logic is Data2 + ALU_Operand2. 
                       // Where ALU_Operand2 = 1 (OPS).
        #10;
        check_result("INC: 0x10 + 1 = 0x11", Data_8bit == 8'h11);

        // --- TEST 6: Address Generation (Indirect) ---
        $display("\n--- TEST 6: Address Generation (LDI) ---");
        Opcode = 4'd13; MR = 1; Data1 = 8'h80; // Pointer in R1
        #10;
        check_result("AGU: LDI from 0x80", Address_8bit == 8'h80);

        // --- TEST 7: Branch Taken (Unconditional) ---
        $display("\n--- TEST 7: JMP Unconditional ---");
        Jmp = 1; Jump_Conditional = 0; JWSP = 0;
        #10;
        check_result("JMP: Taken_Jump = 1", Taken_Jump == 1);
        check_result("JMP: PC Selector = 1", To_PC_Selector == 1);
        Jmp = 0;

        // --- TEST 8: Conditional Branch (JZ - Not Taken) ---
        $display("\n--- TEST 8: JZ Not Taken (Z=0) ---");
        Jmp = 1; Jump_Conditional = 1; Flag_Selector = 2'd0; // Check Z
        FD = 2'b10; // Preserve Input Flags
        Flags = 4'b0000; // Z=0
        #10;
        check_result("JZ: Not Taken when Z=0", Taken_Jump == 0);

        // --- TEST 9: Conditional Branch (JZ - Taken) ---
        $display("\n--- TEST 9: JZ Taken (Z=1) ---");
        Flags = 4'b0001; // Z=1
        #10;
        check_result("JZ: Taken when Z=1", Taken_Jump == 1);

        // --- TEST 10: Stack Ops (POP Address) ---
        $display("\n--- TEST 10: POP Address (SP+1) ---");
        Opcode = 4'd0; SP = 1; SPOP = 1; Data1 = 8'hFE; // SP = FE
        MR = 1; // POP reads memory
        #10;
        check_result("POP: Addr = SP+1 = FF", Address_8bit == 8'hFF);

        // Summary
        $display("\n========================================");
        $display("TEST SUMMARY");
        $display("========================================");
        $display("Total: %0d, Passed: %0d, Failed: %0d", test_count, pass_count, fail_count);
        if (fail_count == 0) $display("Success Rate: 100.0%%");
        $display("========================================\n");

        $finish;
    end

endmodule
