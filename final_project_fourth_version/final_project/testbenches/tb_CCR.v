// ============================================================
// tb_CCR.v
// Testbench for Condition Code Register (CCR)
// ============================================================

`timescale 1ns / 1ps

module tb_CCR;

    // ==================== Inputs ====================
    reg clk;
    reg rst_n;
    reg load_from_alu;
    reg [3:0] alu_flags_in;
    reg load_from_stack;
    reg [3:0] stack_flags_in;
    reg set_carry;
    reg clear_carry;

    // ==================== Outputs ====================
    wire flag_z;
    wire flag_n;
    wire flag_c;
    wire flag_v;
    wire [3:0] ccr_out;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // ==================== DUT Instantiation ====================
    CCR uut (
        .clk(clk),
        .rst_n(rst_n),
        .load_from_alu(load_from_alu),
        .alu_flags_in(alu_flags_in),
        .load_from_stack(load_from_stack),
        .stack_flags_in(stack_flags_in),
        .set_carry(set_carry),
        .clear_carry(clear_carry),
        .flag_z(flag_z),
        .flag_n(flag_n),
        .flag_c(flag_c),
        .flag_v(flag_v),
        .ccr_out(ccr_out)
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
            $display("       Current Flags (VCNZ) = %b", ccr_out);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ==================== Main Test Sequence ====================
    initial begin
        $display("\n========================================");
        $display("CCR Testbench Started");
        $display("========================================\n");

        // Initialize
        rst_n = 0;
        load_from_alu = 0; alu_flags_in = 0;
        load_from_stack = 0; stack_flags_in = 0;
        set_carry = 0; clear_carry = 0;
        
        // --- TEST 1: Reset Behavior ---
        @(posedge clk);
        rst_n = 1;
        @(negedge clk);
        check_result("Reset: 0000", ccr_out == 4'b0000);

        // --- TEST 2: ALU Update ---
        load_from_alu = 1;
        alu_flags_in = 4'b1101; // V=1, C=1, N=0, Z=1
        @(posedge clk);
        load_from_alu = 0;
        @(negedge clk);
        check_result("ALU Update: 1101", ccr_out == 4'b1101);
        check_result("Individual Flags", flag_v==1 && flag_c==1 && flag_n==0 && flag_z==1);

        // --- TEST 3: SETC (Set Carry) ---
        set_carry = 1;
        @(posedge clk);
        set_carry = 0;
        @(negedge clk);
        // Only Carry updates, other flags (V,N,Z) remain from previous 1101 -> 1101 (unchanged really, but C=1 forced)
        check_result("SETC: (old V,Z,N preserved)", ccr_out == 4'b1101);

        // --- TEST 4: CLRC (Clear Carry) ---
        clear_carry = 1;
        @(posedge clk);
        clear_carry = 0;
        @(negedge clk);
        // V=1, C=0, N=0, Z=1 -> 1001
        check_result("CLRC: 1001", ccr_out == 4'b1001);

        // --- TEST 5: Stack Restore (RTI) ---
        load_from_stack = 1;
        stack_flags_in = 4'b0110; // New flags
        @(posedge clk);
        load_from_stack = 0;
        @(negedge clk);
        check_result("Stack Restore: 0110", ccr_out == 4'b0110);

        // --- TEST 6: Priority Check (Stack vs ALU) ---
        load_from_stack = 1; stack_flags_in = 4'b1111;
        load_from_alu = 1; alu_flags_in = 4'b0000;
        @(posedge clk);
        load_from_stack = 0; load_from_alu = 0;
        @(negedge clk);
        check_result("Priority: Stack Wins (1111)", ccr_out == 4'b1111);

        // Summary
        $display("\n========================================");
        $display("Total: %0d, Passed: %0d, Failed: %0d", test_count, pass_count, fail_count);
        if (fail_count == 0) $display("Success Rate: 100.0%%");
        $display("========================================\n");

        $finish;
    end

endmodule
