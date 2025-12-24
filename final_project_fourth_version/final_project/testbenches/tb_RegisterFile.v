// ============================================================
// tb_RegisterFile.v
// Testbench for RegisterFile Module (ELC3030 Processor)
// ============================================================

`timescale 1ns / 1ps

module tb_RegisterFile;

    // ==================== Testbench Signals ====================
    reg         clk;
    reg         rst_n;
    reg  [1:0]  rd_addr_a, rd_addr_b;
    reg         wr_en;
    reg  [1:0]  wr_addr;
    reg  [7:0]  wr_data;
    
    wire [7:0]  rd_data_a, rd_data_b;
    wire [7:0]  sp_out;
    wire [7:0]  raw_sp;

    // Stack Controls
    reg sp_en;
    reg sp_op;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // ==================== DUT Instantiation ====================
    RegisterFile uut (
        .clk(clk),
        .rst_n(rst_n),
        .rd_addr_a(rd_addr_a),
        .rd_data_a(rd_data_a),
        .rd_addr_b(rd_addr_b),
        .rd_data_b(rd_data_b),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .sp_out(sp_out),
        .sp_en(sp_en),
        .sp_op(sp_op),
        .raw_sp(raw_sp)
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
            $display("       rd_data_a=%h, rd_data_b=%h, sp_out=%h", rd_data_a, rd_data_b, sp_out);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ==================== Main Test Sequence ====================
    initial begin
        $display("\n========================================");
        $display("RegisterFile Testbench Started");
        $display("========================================\n");

        // Initialize
        rst_n = 1; rd_addr_a = 0; rd_addr_b = 0;
        wr_en = 0; wr_addr = 0; wr_data = 0;
        sp_en = 0; sp_op = 0;

        // --- TEST 1: Reset ---
        $display("--- TEST 1: Reset Behavior ---");
        rst_n = 0;
        @(posedge clk); @(posedge clk);
        rst_n = 1;
        @(negedge clk);
        
        rd_addr_a = 2'd0; #1;
        check_result("Reset: R0 = 0x00", rd_data_a == 8'h00);
        rd_addr_a = 2'd1; #1;
        check_result("Reset: R1 = 0x00", rd_data_a == 8'h00);
        rd_addr_a = 2'd2; #1;
        check_result("Reset: R2 = 0x00", rd_data_a == 8'h00);
        rd_addr_a = 2'd3; #1;
        check_result("Reset: R3 (SP) = 0xFE", rd_data_a == 8'hFE);
        check_result("Reset: sp_out = 0xFE", sp_out == 8'hFE);

        // --- TEST 2: Write Operations ---
        $display("\n--- TEST 2: Write Operations ---");
        
        wr_en = 1; wr_addr = 2'd0; wr_data = 8'hAA;
        @(posedge clk); wr_en = 0; @(negedge clk);
        rd_addr_a = 2'd0; #1;
        check_result("Write: R0 = 0xAA", rd_data_a == 8'hAA);

        wr_en = 1; wr_addr = 2'd1; wr_data = 8'hBB;
        @(posedge clk); wr_en = 0; @(negedge clk);
        rd_addr_a = 2'd1; #1;
        check_result("Write: R1 = 0xBB", rd_data_a == 8'hBB);

        wr_en = 1; wr_addr = 2'd2; wr_data = 8'hCC;
        @(posedge clk); wr_en = 0; @(negedge clk);
        rd_addr_a = 2'd2; #1;
        check_result("Write: R2 = 0xCC", rd_data_a == 8'hCC);

        wr_en = 1; wr_addr = 2'd3; wr_data = 8'hDD;
        @(posedge clk); wr_en = 0; @(negedge clk);
        rd_addr_a = 2'd3; #1;
        check_result("Write: R3 = 0xDD", rd_data_a == 8'hDD);
        check_result("Write: sp_out = 0xDD", sp_out == 8'hDD);

        // --- TEST 3: Dual Read ---
        $display("\n--- TEST 3: Dual Read Ports ---");
        rd_addr_a = 2'd0; rd_addr_b = 2'd1; #1;
        check_result("Dual Read: A=R0(0xAA), B=R1(0xBB)", rd_data_a == 8'hAA && rd_data_b == 8'hBB);

        // --- TEST 4: Write-First Forwarding ---
        $display("\n--- TEST 4: Write-First Forwarding ---");
        wr_en = 1; wr_addr = 2'd0; wr_data = 8'h55;
        rd_addr_a = 2'd0; rd_addr_b = 2'd1; #1;
        check_result("Forward: Read R0 during write = 0x55", rd_data_a == 8'h55);
        check_result("Forward: Read R1 during R0 write = 0xBB", rd_data_b == 8'hBB);
        @(posedge clk); wr_en = 0;

        // --- TEST 5: Write Disable ---
        $display("\n--- TEST 5: Write Disable ---");
        wr_en = 0; wr_addr = 2'd0; wr_data = 8'hFF;
        @(posedge clk); @(negedge clk);
        rd_addr_a = 2'd0; #1;
        check_result("No Write: R0 unchanged (0x55)", rd_data_a == 8'h55);

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
        $dumpfile("tb_RegisterFile.vcd");
        $dumpvars(0, tb_RegisterFile);
    end

endmodule
