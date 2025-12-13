// Testbench for ExecutionUnit_8bit_v4_fixed
// Tests all instruction types: A-format, B-format, and L-format

`timescale 1ns/1ps

module tb_ExecutionUnit_8bit_v4_fixed;

    // Inputs
    reg IOR, IOW, OPS, ALU, MR, MW, WB, Jmp, SP, SPOP, JWSP, IMM, Stack_PC, Stack_Flags;
    reg [1:0] FD;
    reg [1:0] Flag_Selector;
    reg [3:0] Opcode;
    reg [2:0] WB_Address, ALU_Ops;
    reg [7:0] Data1, Data2, Immediate_Value;
    reg [7:0] Data_From_Forwarding_Unit1, Data_From_Forwarding_Unit2;
    reg [1:0] Forwarding_Unit_Selectors;
    reg [7:0] INPUT_PORT, OUTPUT_PORT_Input;
    reg [7:0] PC_8bit;
    reg [3:0] Flags, Flags_From_Memory;
    reg MEM_Stack_Flags;

    // Outputs
    wire MR_Out, MW_Out, WB_Out, JWSP_Out, Stack_PC_Out, Stack_Flags_Out;
    wire Taken_Jump, To_PC_Selector, SP_Out, SPOP_Out;
    wire [2:0] WB_Address_Out;
    wire [3:0] Final_Flags;
    wire [7:0] OUTPUT_PORT, Data_To_Use;
    wire [7:0] Data_8bit, Address_8bit;

    // Instantiate the Unit Under Test (UUT)
    ExecutionUnit_8bit_v4_fixed uut (
        .IOR(IOR), .IOW(IOW), .OPS(OPS), .ALU(ALU), .MR(MR), .MW(MW), 
        .WB(WB), .Jmp(Jmp), .SP(SP), .SPOP(SPOP), .JWSP(JWSP), .IMM(IMM),
        .Stack_PC(Stack_PC), .Stack_Flags(Stack_Flags),
        .FD(FD), .Flag_Selector(Flag_Selector), .Opcode(Opcode),
        .WB_Address(WB_Address), .ALU_Ops(ALU_Ops),
        .Data1(Data1), .Data2(Data2), .Immediate_Value(Immediate_Value),
        .Data_From_Forwarding_Unit1(Data_From_Forwarding_Unit1),
        .Data_From_Forwarding_Unit2(Data_From_Forwarding_Unit2),
        .Forwarding_Unit_Selectors(Forwarding_Unit_Selectors),
        .INPUT_PORT(INPUT_PORT), .OUTPUT_PORT_Input(OUTPUT_PORT_Input),
        .PC_8bit(PC_8bit), .Flags(Flags), .Flags_From_Memory(Flags_From_Memory),
        .MEM_Stack_Flags(MEM_Stack_Flags),
        .MR_Out(MR_Out), .MW_Out(MW_Out), .WB_Out(WB_Out), .JWSP_Out(JWSP_Out),
        .Stack_PC_Out(Stack_PC_Out), .Stack_Flags_Out(Stack_Flags_Out),
        .Taken_Jump(Taken_Jump), .To_PC_Selector(To_PC_Selector),
        .SP_Out(SP_Out), .SPOP_Out(SPOP_Out), .WB_Address_Out(WB_Address_Out),
        .Final_Flags(Final_Flags), .OUTPUT_PORT(OUTPUT_PORT),
        .Data_To_Use(Data_To_Use), .Data_8bit(Data_8bit), .Address_8bit(Address_8bit)
    );

    // Test counter
    integer test_num;

    // Task to initialize all inputs
    task init_inputs;
    begin
        IOR = 0; IOW = 0; OPS = 0; ALU = 0; MR = 0; MW = 0;
        WB = 0; Jmp = 0; SP = 0; SPOP = 0; JWSP = 0; IMM = 0;
        Stack_PC = 0; Stack_Flags = 0;
        FD = 2'b10; Flag_Selector = 2'b00; Opcode = 4'd0;
        WB_Address = 3'd0; ALU_Ops = 3'd0;
        Data1 = 8'd0; Data2 = 8'd0; Immediate_Value = 8'd0;
        Data_From_Forwarding_Unit1 = 8'd0; Data_From_Forwarding_Unit2 = 8'd0;
        Forwarding_Unit_Selectors = 2'b00;
        INPUT_PORT = 8'd0; OUTPUT_PORT_Input = 8'd0;
        PC_8bit = 8'd0; Flags = 4'b0000; Flags_From_Memory = 4'b0000;
        MEM_Stack_Flags = 0;
    end
    endtask

    // Task to display test results
    task display_result;
        input [255:0] test_name;
    begin
        $display("----------------------------------------");
        $display("Test %0d: %s", test_num, test_name);
        $display("Inputs: Data1=%h, Data2=%h, Imm=%h", Data1, Data2, Immediate_Value);
        $display("Flags_In: {V=%b,C=%b,N=%b,Z=%b}", Flags[3], Flags[2], Flags[1], Flags[0]);
        $display("Outputs: Data_To_Use=%h, Data_8bit=%h, Addr=%h", Data_To_Use, Data_8bit, Address_8bit);
        $display("Final_Flags: {V=%b,C=%b,N=%b,Z=%b}", Final_Flags[3], Final_Flags[2], Final_Flags[1], Final_Flags[0]);
        $display("Control: WB_Out=%b, MR_Out=%b, MW_Out=%b, Taken_Jump=%b", WB_Out, MR_Out, MW_Out, Taken_Jump);
        $display("OUTPUT_PORT=%h", OUTPUT_PORT);
    end
    endtask

    initial begin
        // Initialize VCD dump
        $dumpfile("execution_unit.vcd");
        $dumpvars(0, tb_ExecutionUnit_8bit_v4_fixed);

        test_num = 0;
        init_inputs();
        #10;

        // ============================
        // TEST 1: MOV Instruction (Opcode=1)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd1;      // MOV
        ALU = 1; WB = 1;
        Data1 = 8'h00;
        Data2 = 8'hAB;      // Move 0xAB
        Flags = 4'b0101;    // Preserve C and V
        FD = 2'b11;         // Use new flags
        #10;
        display_result("MOV R[ra] <- R[rb]");
        if (Data_To_Use != 8'hAB || Final_Flags[2] != 1) 
            $display("ERROR: MOV failed!");
        #10;

        // ============================
        // TEST 2: ADD Instruction (Opcode=2)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd2;      // ADD
        ALU = 1; WB = 1;
        Data1 = 8'h0F;      // 15
        Data2 = 8'h11;      // 17
        Flags = 4'b0000;
        FD = 2'b11;         // Update flags
        #10;
        display_result("ADD R[ra] <- R[ra] + R[rb]");
        if (Data_To_Use != 8'h20 || Final_Flags[0] != 0) // Result = 32, Z=0
            $display("ERROR: ADD failed! Expected 0x20, got %h", Data_To_Use);
        #10;

        // ============================
        // TEST 3: ADD with Zero Flag
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd2;      // ADD
        ALU = 1; WB = 1;
        Data1 = 8'hFF;      // -1
        Data2 = 8'h01;      // +1
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("ADD with Zero result");
        if (Data_To_Use != 8'h00 || Final_Flags[0] != 1) // Z flag should be 1
            $display("ERROR: ADD Zero flag failed!");
        #10;

        // ============================
        // TEST 4: ADD with Carry
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd2;      // ADD
        ALU = 1; WB = 1;
        Data1 = 8'hFF;      // 255
        Data2 = 8'h02;      // 2
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("ADD with Carry");
        if (Final_Flags[2] != 1) // C flag should be 1
            $display("ERROR: Carry flag not set!");
        #10;

        // ============================
        // TEST 5: SUB Instruction (Opcode=3)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd3;      // SUB
        ALU = 1; WB = 1;
        Data1 = 8'h20;      // 32
        Data2 = 8'h10;      // 16
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("SUB R[ra] <- R[ra] - R[rb]");
        if (Data_To_Use != 8'h10) // Result = 16
            $display("ERROR: SUB failed! Expected 0x10, got %h", Data_To_Use);
        #10;

        // ============================
        // TEST 6: SUB with Negative Flag
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd3;      // SUB
        ALU = 1; WB = 1;
        Data1 = 8'h05;      // 5
        Data2 = 8'h10;      // 16
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("SUB with Negative result");
        if (Final_Flags[1] != 1) // N flag should be 1
            $display("ERROR: Negative flag not set!");
        #10;

        // ============================
        // TEST 7: AND Instruction (Opcode=4)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd4;      // AND
        ALU = 1; WB = 1;
        Data1 = 8'hF0;
        Data2 = 8'h0F;
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("AND R[ra] <- R[ra] AND R[rb]");
        if (Data_To_Use != 8'h00 || Final_Flags[0] != 1)
            $display("ERROR: AND failed!");
        #10;

        // ============================
        // TEST 8: OR Instruction (Opcode=5)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd5;      // OR
        ALU = 1; WB = 1;
        Data1 = 8'hF0;
        Data2 = 8'h0F;
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("OR R[ra] <- R[ra] OR R[rb]");
        if (Data_To_Use != 8'hFF)
            $display("ERROR: OR failed!");
        #10;

        // ============================
        // TEST 9: RLC - Rotate Left through Carry (Opcode=6, ALU_Ops=00)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd6;      // RLC
        ALU = 1; WB = 1;
        ALU_Ops = 3'b000;   // RLC variant
        Data2 = 8'b10101010;
        Flags = 4'b0100;    // C=1
        FD = 2'b11;
        #10;
        display_result("RLC - Rotate Left through Carry");
        if (Data_To_Use != 8'b01010101 || Final_Flags[2] != 1)
            $display("ERROR: RLC failed!");
        #10;

        // ============================
        // TEST 10: RRC - Rotate Right through Carry (Opcode=6, ALU_Ops=01)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd6;      // RRC
        ALU = 1; WB = 1;
        ALU_Ops = 3'b001;   // RRC variant
        Data2 = 8'b10101011;
        Flags = 4'b0100;    // C=1
        FD = 2'b11;
        #10;
        display_result("RRC - Rotate Right through Carry");
        if (Data_To_Use != 8'b11010101 || Final_Flags[2] != 1)
            $display("ERROR: RRC failed!");
        #10;

        // ============================
        // TEST 11: SETC (Opcode=6, ALU_Ops=10)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd6;      // SETC
        ALU = 1; WB = 0;
        ALU_Ops = 3'b010;   // SETC variant
        Flags = 4'b0000;
        FD = 2'b01;         // Force C=1
        #10;
        display_result("SETC - Set Carry Flag");
        if (Final_Flags[2] != 1)
            $display("ERROR: SETC failed!");
        #10;

        // ============================
        // TEST 12: CLRC (Opcode=6, ALU_Ops=11)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd6;      // CLRC
        ALU = 1; WB = 0;
        ALU_Ops = 3'b011;   // CLRC variant
        Flags = 4'b0111;    // All flags set
        FD = 2'b00;         // Force C=0
        #10;
        display_result("CLRC - Clear Carry Flag");
        if (Final_Flags[2] != 0)
            $display("ERROR: CLRC failed!");
        #10;

        // ============================
        // TEST 13: NOT (Opcode=8, ALU_Ops=00)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd8;      // NOT
        ALU = 1; WB = 1;
        ALU_Ops = 3'b000;
        Data2 = 8'b10101010;
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("NOT - One's Complement");
        if (Data_To_Use != 8'b01010101)
            $display("ERROR: NOT failed!");
        #10;

        // ============================
        // TEST 14: NEG (Opcode=8, ALU_Ops=01)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd8;      // NEG
        ALU = 1; WB = 1;
        ALU_Ops = 3'b001;
        Data2 = 8'd5;
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("NEG - Two's Complement");
        if (Data_To_Use != 8'd251) // -5 in two's complement
            $display("ERROR: NEG failed!");
        #10;

        // ============================
        // TEST 15: INC (Opcode=8, ALU_Ops=10)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd8;      // INC
        ALU = 1; WB = 1;
        ALU_Ops = 3'b010;
        Data2 = 8'hFF;      // Increment 255
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("INC - Increment");
        if (Data_To_Use != 8'h00 || Final_Flags[0] != 1 || Final_Flags[2] != 1)
            $display("ERROR: INC failed!");
        #10;

        // ============================
        // TEST 16: DEC (Opcode=8, ALU_Ops=11)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd8;      // DEC
        ALU = 1; WB = 1;
        ALU_Ops = 3'b011;
        Data2 = 8'h01;      // Decrement 1
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("DEC - Decrement");
        if (Data_To_Use != 8'h00 || Final_Flags[0] != 1)
            $display("ERROR: DEC failed!");
        #10;

        // ============================
        // TEST 17: JZ - Jump if Zero (taken)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd9;      // JZ
        Jmp = 1;
        Flag_Selector = 2'b00; // Test Z flag
        Flags = 4'b0001;    // Z=1
        Data2 = 8'h50;      // Jump address
        FD = 2'b10;         // Preserve flags
        #10;
        display_result("JZ - Jump if Zero (taken)");
        if (Taken_Jump != 1)
            $display("ERROR: JZ not taken when Z=1!");
        #10;

        // ============================
        // TEST 18: JZ - Jump if Zero (not taken)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd9;      // JZ
        Jmp = 1;
        Flag_Selector = 2'b00; // Test Z flag
        Flags = 4'b0000;    // Z=0
        FD = 2'b10;
        #10;
        display_result("JZ - Jump if Zero (not taken)");
        if (Taken_Jump != 0)
            $display("ERROR: JZ taken when Z=0!");
        #10;

        // ============================
        // TEST 19: JN - Jump if Negative (taken)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd9;      // JN
        Jmp = 1;
        Flag_Selector = 2'b01; // Test N flag
        Flags = 4'b0010;    // N=1
        Data2 = 8'h60;
        FD = 2'b10;
        #10;
        display_result("JN - Jump if Negative (taken)");
        if (Taken_Jump != 1)
            $display("ERROR: JN not taken when N=1!");
        #10;

        // ============================
        // TEST 20: JC - Jump if Carry (taken)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd9;      // JC
        Jmp = 1;
        Flag_Selector = 2'b10; // Test C flag
        Flags = 4'b0100;    // C=1
        Data2 = 8'h70;
        FD = 2'b10;
        #10;
        display_result("JC - Jump if Carry (taken)");
        if (Taken_Jump != 1)
            $display("ERROR: JC not taken when C=1!");
        #10;

        // ============================
        // TEST 21: JV - Jump if Overflow (taken)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd9;      // JV
        Jmp = 1;
        Flag_Selector = 2'b11; // Test V flag
        Flags = 4'b1000;    // V=1
        Data2 = 8'h80;
        FD = 2'b10;
        #10;
        display_result("JV - Jump if Overflow (taken)");
        if (Taken_Jump != 1)
            $display("ERROR: JV not taken when V=1!");
        #10;

        // ============================
        // TEST 22: LOOP (continue looping)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd10;     // LOOP
        ALU = 1;
        Jmp = 1;
        Data1 = 8'd5;       // Counter
        Data2 = 8'h10;      // Loop address
        OPS = 1;            // Use Operand2 = 1
        FD = 2'b11;
        #10;
        display_result("LOOP - Counter != 0");
        if (Taken_Jump != 1)
            $display("ERROR: LOOP should continue!");
        #10;

        // ============================
        // TEST 23: LOOP (exit loop)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd10;     // LOOP
        ALU = 1;
        Jmp = 1;
        Data1 = 8'd1;       // Counter = 1, will become 0
        Data2 = 8'h10;
        OPS = 1;
        FD = 2'b11;
        #10;
        display_result("LOOP - Counter == 0");
        if (Taken_Jump != 0)
            $display("ERROR: LOOP should exit!");
        #10;

        // ============================
        // TEST 24: LDM - Load Immediate (Opcode=12)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd12;     // LDM
        ALU = 0; WB = 1;
        IMM = 1;
        Immediate_Value = 8'h42;
        FD = 2'b10;
        #10;
        display_result("LDM - Load Immediate");
        if (Data_To_Use != 8'h42)
            $display("ERROR: LDM failed!");
        #10;

        // ============================
        // TEST 25: Memory Read (MR)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd12;     // LDD
        MR = 1; WB = 1;
        Data1 = 8'h00;
        Data2 = 8'h25;      // Address
        #10;
        display_result("Memory Read - Address Selection");
        if (Address_8bit != 8'h25 || MR_Out != 1)
            $display("ERROR: Memory read failed!");
        #10;

        // ============================
        // TEST 26: Memory Write (MW)
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd12;     // STD
        MW = 1;
        Data1 = 8'h00;
        Data2 = 8'h30;      // Address
        #10;
        display_result("Memory Write - Address Selection");
        if (Address_8bit != 8'h30 || MW_Out != 1)
            $display("ERROR: Memory write failed!");
        #10;

        // ============================
        // TEST 27: IN - Input Port Read
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd7;      // IN
        IOR = 1; WB = 1;
        INPUT_PORT = 8'hCC;
        FD = 2'b10;
        #10;
        display_result("IN - Input Port Read");
        if (Data_To_Use != 8'hCC)
            $display("ERROR: IN failed!");
        #10;

        // ============================
        // TEST 28: OUT - Output Port Write
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd7;      // OUT
        IOW = 1;
        Data2 = 8'hDD;
        #10;
        display_result("OUT - Output Port Write");
        if (OUTPUT_PORT != 8'hDD)
            $display("ERROR: OUT failed!");
        #10;

        // ============================
        // TEST 29: Data Forwarding Unit 1
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd2;      // ADD
        ALU = 1; WB = 1;
        Data1 = 8'h10;
        Data_From_Forwarding_Unit1 = 8'h20;
        Forwarding_Unit_Selectors = 2'b01; // Use forwarded data1
        Data2 = 8'h05;
        FD = 2'b11;
        #10;
        display_result("Data Forwarding Unit 1");
        if (Data_To_Use != 8'h25) // 0x20 + 0x05
            $display("ERROR: Forwarding Unit 1 failed!");
        #10;

        // ============================
        // TEST 30: Data Forwarding Unit 2
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd2;      // ADD
        ALU = 1; WB = 1;
        Data1 = 8'h10;
        Data2 = 8'h05;
        Data_From_Forwarding_Unit2 = 8'h08;
        Forwarding_Unit_Selectors = 2'b10; // Use forwarded data2
        FD = 2'b11;
        #10;
        display_result("Data Forwarding Unit 2");
        if (Data_To_Use != 8'h18) // 0x10 + 0x08
            $display("ERROR: Forwarding Unit 2 failed!");
        #10;

        // ============================
        // TEST 31: Stack Flags Restore
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd11;     // RTI
        MEM_Stack_Flags = 1;
        Flags = 4'b0000;
        Flags_From_Memory = 4'b1111;
        FD = 2'b10;
        #10;
        display_result("Stack Flags Restore");
        if (Final_Flags != 4'b1111)
            $display("ERROR: Flag restore failed!");
        #10;

        // ============================
        // TEST 32: Overflow Detection - ADD
        // ============================
        test_num = test_num + 1;
        init_inputs();
        Opcode = 4'd2;      // ADD
        ALU = 1; WB = 1;
        Data1 = 8'h7F;      // +127
        Data2 = 8'h01;      // +1
        Flags = 4'b0000;
        FD = 2'b11;
        #10;
        display_result("ADD Overflow Detection");
        if (Final_Flags[3] != 1) // V flag should be set
            $display("ERROR: Overflow not detected!");
        #10;

        // ============================
        // TEST 33: Control Signal Passthrough
        // ============================
        test_num = test_num + 1;
        init_inputs();
        WB = 1; SP = 1; SPOP = 1; JWSP = 1;
        Stack_PC = 1; Stack_Flags = 1;
        WB_Address = 3'b101;
        #10;
        display_result("Control Signal Passthrough");
        if (WB_Out != 1 || SP_Out != 1 || SPOP_Out != 1 || 
            JWSP_Out != 1 || Stack_PC_Out != 1 || Stack_Flags_Out != 1 ||
            WB_Address_Out != 3'b101)
            $display("ERROR: Control signals not passed correctly!");
        #10;

        // ============================
        // Summary
        // ============================
        $display("========================================");
        $display("ALL TESTS COMPLETED");
        $display("Total Tests Run: %0d", test_num);
        $display("========================================");
        
        #100;
        $finish;
    end

endmodule
