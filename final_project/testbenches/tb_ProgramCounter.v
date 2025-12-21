// ============================================================
// tb_ProgramCounter.v
// Testbench for Program Counter Module
// ============================================================

`timescale 1ns / 1ps

module tb_ProgramCounter;

    // ==================== Testbench Signals ====================
    reg        clk;
    reg        rst_n;
    reg        pc_write;
    reg        pc_src;
    reg [7:0]  pc_target;
    reg [7:0]  mem_data;
    reg        load_vector;
    
    wire [7:0] pc_out;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // ==================== DUT Instantiation ====================
    ProgramCounter uut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_write(pc_write),
        .pc_src(pc_src),
        .pc_target(pc_target),
        .mem_data(mem_data),
        .load_vector(load_vector),
        .pc_out(pc_out)
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
            $display("[FAIL] %s (PC=%h)", test_name, pc_out);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ==================== Main Test Sequence ====================
    initial begin
        $display("\n========================================");
        $display("Program Counter Testbench Started");
        $display("========================================\n");

        // Initialize
        rst_n = 1; pc_write = 0; pc_src = 0;
        pc_target = 0; mem_data = 0; load_vector = 0;

        // --- TEST 1: Reset ---
        $display("--- TEST 1: Reset Behavior ---");
        rst_n = 0;
        @(posedge clk); @(posedge clk);
        check_result("Reset: PC = 0x00", pc_out == 8'h00);
        rst_n = 1;
        @(posedge clk);

        // --- TEST 2: Load from M[0] (Reset Vector) ---
        $display("\n--- TEST 2: Load Reset Vector from M[0] ---");
        mem_data = 8'h10;  // Simulated M[0] = 0x10
        load_vector = 1;
        pc_write = 1;
        @(posedge clk);
        pc_write = 0; load_vector = 0;
        @(negedge clk);
        check_result("Load Vector: PC = 0x10", pc_out == 8'h10);

        // --- TEST 3: Sequential Increment (+1) ---
        $display("\n--- TEST 3: Sequential Increment ---");
        pc_write = 1; pc_src = 0;
        @(posedge clk);  // PC = 0x10 + 1 = 0x11
        @(negedge clk);
        check_result("Increment: PC = 0x11", pc_out == 8'h11);
        
        @(posedge clk);  // PC = 0x11 + 1 = 0x12
        @(negedge clk);
        check_result("Increment: PC = 0x12", pc_out == 8'h12);
        
        @(posedge clk);  // PC = 0x12 + 1 = 0x13
        @(negedge clk);
        check_result("Increment: PC = 0x13", pc_out == 8'h13);
        pc_write = 0;

        // --- TEST 4: 2-Byte Instruction (Two Increments) ---
        $display("\n--- TEST 4: 2-Byte Instruction (LDM) ---");
        // Simulate FSM: FETCH (PC++), then FETCH_OP2 (PC++)
        pc_write = 1; pc_src = 0;
        @(posedge clk);  // First increment: PC = 0x14
        @(negedge clk);
        check_result("2-Byte Step 1: PC = 0x14", pc_out == 8'h14);
        
        @(posedge clk);  // Second increment: PC = 0x15
        @(negedge clk);
        check_result("2-Byte Step 2: PC = 0x15 (total +2)", pc_out == 8'h15);
        pc_write = 0;

        // --- TEST 5: Branch/Jump ---
        $display("\n--- TEST 5: Branch/Jump ---");
        pc_target = 8'h50;
        pc_write = 1; pc_src = 1;
        @(posedge clk);
        pc_write = 0; pc_src = 0;
        @(negedge clk);
        check_result("Jump: PC = 0x50", pc_out == 8'h50);

        // --- TEST 6: Conditional Branch (Not Taken) ---
        $display("\n--- TEST 6: Conditional Branch Not Taken ---");
        pc_target = 8'hAA;
        pc_write = 0;  // Branch not taken, PC doesn't write
        @(posedge clk);
        @(negedge clk);
        check_result("No Branch: PC unchanged (0x50)", pc_out == 8'h50);

        // --- TEST 7: PC Hold (Stall) ---
        $display("\n--- TEST 7: PC Hold (Stall) ---");
        pc_write = 0;
        @(posedge clk); @(posedge clk);
        @(negedge clk);
        check_result("Stall: PC unchanged (0x50)", pc_out == 8'h50);

        // --- TEST 8: Interrupt Vector Load ---
        $display("\n--- TEST 8: Interrupt Vector from M[1] ---");
        mem_data = 8'h80;  // Simulated M[1] = 0x80 (ISR address)
        load_vector = 1;
        pc_write = 1;
        @(posedge clk);
        pc_write = 0; load_vector = 0;
        @(negedge clk);
        check_result("Interrupt: PC = 0x80", pc_out == 8'h80);

        // --- TEST 9: Return from Interrupt ---
        $display("\n--- TEST 9: Return from Interrupt ---");
        pc_target = 8'h51;  // Return address from stack
        pc_write = 1; pc_src = 1;
        @(posedge clk);
        pc_write = 0; pc_src = 0;
        @(negedge clk);
        check_result("RTI: PC = 0x51", pc_out == 8'h51);

        // --- TEST 10: Wraparound (0xFF -> 0x00) ---
        $display("\n--- TEST 10: PC Wraparound ---");
        pc_target = 8'hFF;
        pc_write = 1; pc_src = 1;
        @(posedge clk);
        pc_src = 0;  // Now increment
        @(posedge clk);  // 0xFF + 1 = 0x00
        pc_write = 0;
        @(negedge clk);
        check_result("Wraparound: PC = 0x00", pc_out == 8'h00);

        // ==================== Summary ====================
        $display("\n========================================");
        $display("TEST SUMMARY");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        if (fail_count == 0) $display("Success Rate: 100.0%%");
        else $display("Success Rate: %0.1f%%", (pass_count * 100.0) / test_count);
        $display("========================================\n");

        $finish;
    end

    // VCD Dump
    initial begin
        $dumpfile("tb_ProgramCounter.vcd");
        $dumpvars(0, tb_ProgramCounter);
    end

endmodule
