// ============================================================
// tb_ControlUnit.v
// Testbench for Top-Level Control Unit (FSM)
// ============================================================

`timescale 1ns / 1ps

module tb_ControlUnit;

    // ==================== Inputs ====================
    reg clk;
    reg rst_n;
    reg [7:0] Instruction;      // From ID stage
    reg [7:0] if_instruction;   // From IF stage
    reg stall;
    reg branch_taken;
    reg mem_branch_taken;
    reg INTR_IN;
    reg [3:0] CCR;
    reg Loop_Zero;

    // ==================== Outputs ====================
    wire IOR, IOW, OPS, ALU, MR, MW, WB;
    wire Jmp, Jump_Conditional;
    wire SP, SPOP, JWSP;
    wire IMM, Stack_PC, Stack_Flags;
    wire RS_EN, RT_EN;
    wire [1:0] FD, Flag_Selector;
    wire [3:0] Opcode_Out;
    wire [2:0] WB_Address;
    wire [2:0] ALU_Ops;
    wire [1:0] RA_Out;
    wire [1:0] RB_Out;
    wire [7:0] imm_val;
    wire PC_Write, PC_Src, IR_Write, EX_Write, Fetch_Op2;
    wire [2:0] Current_State;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // ==================== DUT Instantiation ====================
    ControlUnit uut (
        .clk(clk),
        .rst_n(rst_n),
        .Instruction(Instruction),
        .if_instruction(if_instruction),
        .stall(stall),
        .branch_taken(branch_taken),
        .mem_branch_taken(mem_branch_taken),
        .INTR_IN(INTR_IN),
        .CCR(CCR),
        .Loop_Zero(Loop_Zero),

        .IOR(IOR), .IOW(IOW), .OPS(OPS), .ALU(ALU), .MR(MR), .MW(MW), .WB(WB),
        .Jmp(Jmp), .Jump_Conditional(Jump_Conditional),
        .SP(SP), .SPOP(SPOP), .JWSP(JWSP),
        .IMM(IMM), .Stack_PC(Stack_PC), .Stack_Flags(Stack_Flags),
        .RS_EN(RS_EN), .RT_EN(RT_EN),
        .FD(FD), .Flag_Selector(Flag_Selector),
        .Opcode_Out(Opcode_Out),
        .WB_Address(WB_Address),
        .ALU_Ops(ALU_Ops),
        .RA_Out(RA_Out), .RB_Out(RB_Out), .imm_val(imm_val),

        .PC_Write(PC_Write), .PC_Src(PC_Src), .IR_Write(IR_Write),
        .EX_Write(EX_Write), .Fetch_Op2(Fetch_Op2),
        .Current_State(Current_State)
    );

    // ==================== Clock Generation ====================
    initial clk = 0;
    always #5 clk = ~clk;

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
            $display("       Current_State=%b, PC_Write=%b, IR_Write=%b", Current_State, PC_Write, IR_Write);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ==================== Main Test Sequence ====================
    initial begin
        $display("\n========================================");
        $display("Control Unit (FSM) Testbench");
        $display("========================================\n");

        // Initialize
        rst_n = 0; stall = 0; branch_taken = 0; mem_branch_taken = 0;
        Instruction = 0; if_instruction = 0;
        INTR_IN = 0; CCR = 0; Loop_Zero = 0;
        
        // --- TEST 1: Reset Logic ---
        @(posedge clk);
        rst_n = 1;
        @(posedge clk); // Allow transition from RESET -> FETCH
        @(negedge clk);
        check_result("Reset: State=FETCH", Current_State == 3'b001); // S_FETCH

        // --- TEST 2: Single-Cycle Instruction Flow ---
        // Opcode 1 (MOV) in IF
        if_instruction = 8'h10;
        @(posedge clk); @(negedge clk);
        // State should remain FETCH, PC_Write=1
        check_result("Single-Byte: Remains in FETCH", Current_State == 3'b001);
        check_result("Single-Byte: PC_Write=1, IR_Write=1", PC_Write==1 && IR_Write==1);

        // --- TEST 3: Multi-Byte Instruction Flow (LDM Opcode 12) ---
        // Cycle 1: LDM (0xC0) sits in IF
        if_instruction = 8'hC0; // LDM
        @(posedge clk); @(negedge clk);
        
        // Cycle 2: FETCH_OP2
        // IF has 8'hAA (operand), ID has LDM
        Instruction = 8'hC0; 
        if_instruction = 8'hAA; 
        check_result("Multi-Byte: Enter S_FETCH_OP2", Current_State == 3'b010);
        check_result("Multi-Byte Cyc2: EX_Write=0 (Stall ID)", EX_Write==0);
        
        @(posedge clk); @(negedge clk);

        // Cycle 3: EXECUTE_2B
        // Logic latches operand
        check_result("Multi-Byte: Enter S_EXECUTE_2B", Current_State == 3'b011);
        check_result("Multi-Byte Cyc3: Fetch_Op2=1", Fetch_Op2==1);
        check_result("Multi-Byte Cyc3: imm_val=User Val", imm_val == 8'hAA);

        @(posedge clk); @(negedge clk);
        
        // Cycle 4: Return to FETCH
        check_result("Multi-Byte: Return to FETCH", Current_State == 3'b001);

        // --- TEST 4: Branch Taken (Flush Logic) ---
        branch_taken = 1;
        @(posedge clk); @(negedge clk);
        check_result("Branch: Force S_FETCH", Current_State == 3'b001);
        branch_taken = 0;

        // --- TEST 5: Stall Logic ---
        stall = 1;
        @(posedge clk); @(negedge clk);
        check_result("Stall: State Held", Current_State == 3'b001); // Held previous state
        stall = 0;

        // Summary
        $display("\n========================================");
        $display("Total: %0d, Passed: %0d, Failed: %0d", test_count, pass_count, fail_count);
        if (fail_count == 0) $display("Success Rate: 100.0%%");
        $display("========================================\n");

        $finish;
    end

endmodule
