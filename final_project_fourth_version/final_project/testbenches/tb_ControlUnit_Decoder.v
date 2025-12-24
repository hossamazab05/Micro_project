// ============================================================
// tb_ControlUnit_Decoder.v
// Testbench for combinational Control Unit Decoder
// ============================================================

`timescale 1ns / 1ps

module tb_ControlUnit_Decoder;

    // ==================== Inputs ====================
    reg [7:0] Instruction;

    // ==================== Outputs ====================
    wire IOR, IOW;
    wire OPS, ALU;
    wire MR, MW, WB;
    wire Jmp, Jump_Conditional;
    wire SP, SPOP, JWSP;
    wire IMM, Stack_PC, Stack_Flags;
    wire RS_EN, RT_EN;
    wire [1:0] FD, Flag_Selector;
    wire pc_inc_val;
    wire [3:0] Opcode_Out;
    wire [2:0] WB_Address;
    wire [2:0] ALU_Ops;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // ==================== DUT Instantiation ====================
    ControlUnit_Decoder uut (
        .Instruction(Instruction),
        .IOR(IOR), .IOW(IOW), .OPS(OPS), .ALU(ALU),
        .MR(MR), .MW(MW), .WB(WB), .Jmp(Jmp),
        .Jump_Conditional(Jump_Conditional),
        .SP(SP), .SPOP(SPOP), .JWSP(JWSP),
        .IMM(IMM), .Stack_PC(Stack_PC), .Stack_Flags(Stack_Flags),
        .RS_EN(RS_EN), .RT_EN(RT_EN),
        .FD(FD), .Flag_Selector(Flag_Selector),
        .pc_inc_val(pc_inc_val),
        .Opcode_Out(Opcode_Out),
        .WB_Address(WB_Address), .ALU_Ops(ALU_Ops)
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
            // $display("       Debug: Opcode=%h, ALU=%b, WB=%b, Imm=%b", Opcode_Out, ALU, WB, IMM);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ==================== Main Test Sequence ====================
    initial begin
        $display("\n========================================");
        $display("Control Unit Decoder Testbench");
        $display("========================================\n");

        // --- TEST 1: NOP ---
        Instruction = 8'h00;
        #1;
        check_result("NOP: No signals", ALU==0 && WB==0 && MR==0 && MW==0);

        // --- TEST 2: ADD R1, R2 (Opcode 2) ---
        Instruction = {4'd2, 2'd1, 2'd2};
        #1;
        check_result("ADD: ALU=1, WB=1", ALU==1 && WB==1);
        check_result("ADD: Opcode=2", Opcode_Out==4'd2);
        check_result("ADD: RS_EN=1, RT_EN=1", RS_EN==1 && RT_EN==1);

        // --- TEST 3: MOV R1, R2 (Opcode 1) ---
        Instruction = {4'd1, 2'd1, 2'd2};
        #1;
        check_result("MOV: ALU=1, WB=1", ALU==1 && WB==1);
        check_result("MOV: FD=10 (Preserve)", FD==2'b10);
        check_result("MOV: RS_EN=0", RS_EN==0);

        // --- TEST 4: PUSH R0 (Opcode 7, ra=0) ---
        Instruction = {4'd7, 2'd0, 2'd0}; // PUSH R0
        #1;
        check_result("PUSH: SP=1, MW=1", SP==1 && MW==1);
        check_result("PUSH: RS_EN=1, RT_EN=1", RS_EN==1 && RT_EN==1);

        // --- TEST 5: POP R2 (Opcode 7, ra=1) ---
        Instruction = {4'd7, 2'd1, 2'd2}; // POP R2
        #1;
        check_result("POP: SP=1, SPOP=1, MR=1, WB=1", SP==1 && SPOP==1 && MR==1 && WB==1);
        check_result("POP: WB_Addr=R2", WB_Address==3'd2);

        // --- TEST 6: INC R1 (Opcode 8, ra=2) ---
        Instruction = {4'd8, 2'd2, 2'd1}; // INC R1 (Stored in R1)
        #1;
        check_result("INC: OPS=1", OPS==1);
        check_result("INC: ALU=1, WB=1", ALU==1 && WB==1);

        // --- TEST 7: LDM R3, #imm (Opcode 12, ra=0) ---
        Instruction = {4'd12, 2'd0, 2'd3};
        #1;
        check_result("LDM: IMM=1, pc_inc=1 (2-byte)", IMM==1 && pc_inc_val==1);
        check_result("LDM: WB=1, WB_Addr=R3", WB==1 && WB_Address==3'd3);

        // --- TEST 8: JMP Unconditional (Opcode 11, ra=0) ---
        Instruction = {4'd11, 2'd0, 2'd0};
        #1;
        check_result("JMP: Jmp=1, Cond=0", Jmp==1 && Jump_Conditional==0);

        // --- TEST 9: CALL (Opcode 11, ra=1) ---
        Instruction = {4'd11, 2'd1, 2'd0};
        #1;
        check_result("CALL: Stack_PC=1, SP=1, MW=1", Stack_PC==1 && SP==1 && MW==1);

        // --- TEST 10: RET (Opcode 11, ra=2) ---
        Instruction = {4'd11, 2'd2, 2'd0};
        #1;
        check_result("RET: JWSP=1, SPOP=1, MR=1", JWSP==1 && SPOP==1 && MR==1);

        // --- TEST 11: LOOP (Opcode 10) ---
        Instruction = {4'd10, 2'd0, 2'd0};
        #1;
        check_result("LOOP: OPS=1, Jmp=1, ALU=1", OPS==1 && Jmp==1 && ALU==1);

        // --- TEST 12: LDI (Indirect) (Opcode 13) ---
        Instruction = {4'd13, 2'd0, 2'd1}; // LDI R1, [R0]
        #1;
        check_result("LDI: MR=1, RS_EN=1", MR==1 && RS_EN==1);

        // Summary
        $display("\n========================================");
        $display("Total: %0d, Passed: %0d, Failed: %0d", test_count, pass_count, fail_count);
        if (fail_count == 0) $display("Success Rate: 100.0%%");
        $display("========================================\n");

        $finish;
    end

endmodule
