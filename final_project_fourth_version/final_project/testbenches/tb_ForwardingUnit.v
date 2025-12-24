// ============================================================
// tb_ForwardingUnit.v
// Testbench for Forwarding Unit
// ============================================================

`timescale 1ns / 1ps

module tb_ForwardingUnit;

    // Inputs
    reg [1:0]  ex_rs, ex_rt;  // Renamed from id_rs/id_rt to match RTL context
    reg        ex_rs_en, ex_rt_en; // Added enable signals
    reg [1:0]  mem_rd, wb_rd; // Removed ex_rd (not used in RTL inputs directly like this)
    reg        mem_reg_write, wb_reg_write; // Removed ex_reg_write
    
    // Outputs
    wire [1:0] forward_a, forward_b;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // DUT
    ForwardingUnit uut (
        .ex_rs(ex_rs), .ex_rt(ex_rt),
        .ex_rs_en(ex_rs_en), .ex_rt_en(ex_rt_en),
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
        // Initialize
        ex_rs = 0; ex_rt = 0; ex_rs_en = 0; ex_rt_en = 0;
        mem_rd = 0; wb_rd = 0;
        mem_reg_write = 0; wb_reg_write = 0;
        #10;

        // TEST 1: No Forwarding
        $display("--- TEST 1: No Forwarding ---");
        ex_rs = 2'b00; ex_rt = 2'b01; ex_rs_en = 1; ex_rt_en = 1;
        mem_rd = 2'b10; wb_rd = 2'b10;
        mem_reg_write = 1; wb_reg_write = 1;
        // Conflict is on R2 (10), but we are reading R0 and R1
        #10;
        check_result("No Forward: forward_a=00", forward_a == 2'b00);
        check_result("No Forward: forward_b=00", forward_b == 2'b00);

        // TEST 2: Forward from MEM (ex_rs dependency)
        // RTL logic: MEM Forwarding gets 2'b01
        $display("\n--- TEST 2: Forward from MEM (rs) ---");
        ex_rs = 2'b01; ex_rt = 2'b00; ex_rs_en = 1;
        mem_rd = 2'b01; mem_reg_write = 1;
        wb_rd = 2'b10; wb_reg_write = 0;
        #10;
        check_result("EX Forward rs: forward_a=01", forward_a == 2'b01);
        check_result("EX Forward rs: forward_b=00", forward_b == 2'b00);

        // TEST 3: Forward from WB (ex_rs dependency)
        // RTL logic: WB Forwarding gets 2'b10
        $display("\n--- TEST 3: Forward from WB (rs) ---");
        ex_rs = 2'b01; ex_rt = 2'b00; ex_rs_en = 1;
        mem_rd = 2'b10; mem_reg_write = 0;
        wb_rd = 2'b01; wb_reg_write = 1;
        #10;
        check_result("WB Forward rs: forward_a=10", forward_a == 2'b10);

        // TEST 4: MEM Priority over WB
        $display("\n--- TEST 4: MEM Priority over WB ---");
        ex_rs = 2'b01; ex_rt = 2'b00;
        mem_rd = 2'b01; mem_reg_write = 1;
        wb_rd = 2'b01; wb_reg_write = 1;
        #10;
        check_result("Priority: forward_a=01 (MEM wins)", forward_a == 2'b01);

        // TEST 5: Forward Both Operands
        $display("\n--- TEST 5: Forward Both Operands ---");
        ex_rs = 2'b01; ex_rt = 2'b10; ex_rs_en = 1; ex_rt_en = 1;
        mem_rd = 2'b01; mem_reg_write = 1; // MEM -> RS
        wb_rd = 2'b10; wb_reg_write = 1;  // WB -> RT
        #10;
        check_result("Both: forward_a=01 (from MEM)", forward_a == 2'b01);
        check_result("Both: forward_b=10 (from WB)", forward_b == 2'b10);

        // TEST 6: No Forward if reg_write=0
        $display("\n--- TEST 6: No Forward if Write Disabled ---");
        // TEST 6: No Forward if reg_write=0
        $display("\n--- TEST 6: No Forward if Write Disabled ---");
        ex_rs = 2'b01; ex_rt = 2'b10;
        mem_rd = 2'b01; mem_reg_write = 0;
        wb_rd = 2'b10; wb_reg_write = 0;
        #10;
        check_result("No Write: forward_a=00", forward_a == 2'b00);
        check_result("No Write: forward_b=00", forward_b == 2'b00);

        // TEST 7: Disable Forwarding if not reading RS/RT
        $display("\n--- TEST 7: Read Enable Check ---");
        ex_rs = 2'b01; ex_rt = 2'b01; ex_rs_en = 0; ex_rt_en = 0;
        mem_rd = 2'b01; mem_reg_write = 1;
        wb_rd = 2'b01; wb_reg_write = 1;
        #10;
        check_result("No Read: forward_a=00", forward_a == 2'b00);

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
