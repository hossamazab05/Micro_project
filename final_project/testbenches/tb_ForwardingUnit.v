// ============================================================
// tb_ForwardingUnit.v
// Testbench for Forwarding Unit
// ============================================================

`timescale 1ns / 1ps

module tb_ForwardingUnit;

    // Inputs
    reg [1:0]  id_rs, id_rt;
    reg [1:0]  ex_rd, mem_rd, wb_rd;
    reg        ex_reg_write, mem_reg_write, wb_reg_write;
    
    // Outputs
    wire [1:0] forward_a, forward_b;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // DUT
    ForwardingUnit uut (
        .id_rs(id_rs), .id_rt(id_rt),
        .ex_rd(ex_rd), .ex_reg_write(ex_reg_write),
        .mem_rd(mem_rd), .mem_reg_write(mem_reg_write),
        .wb_rd(wb_rd), .wb_reg_write(wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    // Helper task
    task check_result;
        input [255:0] test_name;
        input condition;
    begin
        test_count = test_count + 1;
        if (condition) begin
            $display("[PASS] %s", test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s (fwd_a=%b, fwd_b=%b)", test_name, forward_a, forward_b);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        $display("\n========================================");
        $display("Forwarding Unit Testbench");
        $display("========================================\n");

        // Initialize
        id_rs = 0; id_rt = 0;
        ex_rd = 0; mem_rd = 0; wb_rd = 0;
        ex_reg_write = 0; mem_reg_write = 0; wb_reg_write = 0;
        #10;

        // TEST 1: No Forwarding
        $display("--- TEST 1: No Forwarding ---");
        id_rs = 2'b00; id_rt = 2'b01;
        ex_rd = 2'b10; mem_rd = 2'b11; wb_rd = 2'b10;
        ex_reg_write = 1; mem_reg_write = 1; wb_reg_write = 1;
        #10;
        check_result("No Forward: forward_a=00", forward_a == 2'b00);
        check_result("No Forward: forward_b=00", forward_b == 2'b00);

        // TEST 2: Forward from EX (rs)
        $display("\n--- TEST 2: Forward from EX (rs) ---");
        id_rs = 2'b01; id_rt = 2'b00;
        ex_rd = 2'b01; ex_reg_write = 1;
        mem_rd = 2'b10; mem_reg_write = 0;
        #10;
        check_result("EX Forward rs: forward_a=01", forward_a == 2'b01);
        check_result("EX Forward rs: forward_b=00", forward_b == 2'b00);

        // TEST 3: Forward from MEM (rs)
        $display("\n--- TEST 3: Forward from MEM (rs) ---");
        id_rs = 2'b10; id_rt = 2'b00;
        ex_rd = 2'b01; ex_reg_write = 0;
        mem_rd = 2'b10; mem_reg_write = 1;
        #10;
        check_result("MEM Forward rs: forward_a=10", forward_a == 2'b10);

        // TEST 4: EX Priority over MEM
        $display("\n--- TEST 4: EX Priority over MEM ---");
        id_rs = 2'b01; id_rt = 2'b00;
        ex_rd = 2'b01; ex_reg_write = 1;
        mem_rd = 2'b01; mem_reg_write = 1;
        #10;
        check_result("Priority: forward_a=01 (EX wins)", forward_a == 2'b01);

        // TEST 5: Forward Both Operands
        $display("\n--- TEST 5: Forward Both Operands ---");
        id_rs = 2'b01; id_rt = 2'b10;
        ex_rd = 2'b01; ex_reg_write = 1;
        mem_rd = 2'b10; mem_reg_write = 1;
        #10;
        check_result("Both: forward_a=01 (from EX)", forward_a == 2'b01);
        check_result("Both: forward_b=10 (from MEM)", forward_b == 2'b10);

        // TEST 6: No Forward if reg_write=0
        $display("\n--- TEST 6: No Forward if Write Disabled ---");
        id_rs = 2'b01; id_rt = 2'b10;
        ex_rd = 2'b01; ex_reg_write = 0;
        mem_rd = 2'b10; mem_reg_write = 0;
        #10;
        check_result("No Write: forward_a=00", forward_a == 2'b00);
        check_result("No Write: forward_b=00", forward_b == 2'b00);

        // TEST 7: Don't Forward R0 (if used as zero register)
        $display("\n--- TEST 7: R0 Forwarding ---");
        id_rs = 2'b00; id_rt = 2'b00;
        ex_rd = 2'b00; ex_reg_write = 1;
        #10;
        check_result("R0: forward_a=00 (R0 ignored)", forward_a == 2'b00);

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
