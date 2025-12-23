// ============================================================
// tb_HazardDetectionUnit.v
// Testbench for Hazard Detection Unit
// ============================================================

`timescale 1ns / 1ps

module tb_HazardDetectionUnit;

    // Inputs
    reg [1:0]  id_rs, id_rt;
    reg [1:0]  ex_rd;
    reg        ex_mem_read;
    reg        branch_taken;
    
    // Outputs
    wire       pc_write;
    wire       if_id_write;
    wire       id_ex_flush;
    wire       if_id_flush;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // DUT
    HazardDetectionUnit uut (
        .id_rs(id_rs), .id_rt(id_rt),
        .ex_rd(ex_rd), .ex_mem_read(ex_mem_read),
        .branch_taken(branch_taken),
        .pc_write(pc_write), .if_id_write(if_id_write),
        .id_ex_flush(id_ex_flush), .if_id_flush(if_id_flush)
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
            $display("[FAIL] %s", test_name);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        $display("\n========================================");
        $display("Hazard Detection Unit Testbench");
        $display("========================================\n");

        // Initialize
        id_rs = 0; id_rt = 0; ex_rd = 0;
        ex_mem_read = 0; branch_taken = 0;
        #10;

        // TEST 1: No Hazard
        $display("--- TEST 1: No Hazard ---");
        id_rs = 2'b00; id_rt = 2'b01; ex_rd = 2'b10;
        ex_mem_read = 0; branch_taken = 0;
        #10;
        check_result("No Hazard: pc_write=1", pc_write == 1);
        check_result("No Hazard: if_id_write=1", if_id_write == 1);
        check_result("No Hazard: id_ex_flush=0", id_ex_flush == 0);
        check_result("No Hazard: if_id_flush=0", if_id_flush == 0);

        // TEST 2: Load-Use Hazard (rs)
        $display("\n--- TEST 2: Load-Use Hazard (rs) ---");
        id_rs = 2'b01; id_rt = 2'b00; ex_rd = 2'b01;
        ex_mem_read = 1; branch_taken = 0;
        #10;
        check_result("Load-Use: pc_write=0 (stall)", pc_write == 0);
        check_result("Load-Use: if_id_write=0 (stall)", if_id_write == 0);
        check_result("Load-Use: id_ex_flush=1 (bubble)", id_ex_flush == 1);

        // TEST 3: Load-Use Hazard (rt)
        $display("\n--- TEST 3: Load-Use Hazard (rt) ---");
        id_rs = 2'b00; id_rt = 2'b10; ex_rd = 2'b10;
        ex_mem_read = 1; branch_taken = 0;
        #10;
        check_result("Load-Use rt: pc_write=0", pc_write == 0);
        check_result("Load-Use rt: id_ex_flush=1", id_ex_flush == 1);

        // TEST 4: Branch Taken (Flush)
        $display("\n--- TEST 4: Branch Taken ---");
        id_rs = 2'b00; id_rt = 2'b01; ex_rd = 2'b10;
        ex_mem_read = 0; branch_taken = 1;
        #10;
        check_result("Branch: if_id_flush=1", if_id_flush == 1);
        check_result("Branch: pc_write=1 (update)", pc_write == 1);

        // TEST 5: Branch Priority over Load-Use
        $display("\n--- TEST 5: Branch Priority ---");
        id_rs = 2'b01; id_rt = 2'b00; ex_rd = 2'b01;
        ex_mem_read = 1; branch_taken = 1;
        #10;
        check_result("Priority: if_id_flush=1 (branch wins)", if_id_flush == 1);
        check_result("Priority: id_ex_flush=0 (no stall)", id_ex_flush == 0);

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
