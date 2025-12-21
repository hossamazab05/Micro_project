// ============================================================
// tb_DataMemory.v
// Testbench for Data Memory Module
// ============================================================

`timescale 1ns / 1ps

module tb_DataMemory;

    // ==================== Testbench Signals ====================
    reg        clk;
    reg        rst_n;
    reg        mem_read;
    reg        mem_write;
    reg [7:0]  addr;
    reg [7:0]  data_in;
    wire [7:0] data_out;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // ==================== DUT Instantiation ====================
    DataMemory uut (
        .clk(clk),
        .rst_n(rst_n),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
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
            $display("[FAIL] %s (data_out=%h)", test_name, data_out);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ==================== Main Test Sequence ====================
    initial begin
        $display("\n========================================");
        $display("Data Memory Testbench Started");
        $display("========================================\n");

        // Initialize
        rst_n = 1; mem_read = 0; mem_write = 0;
        addr = 0; data_in = 0;

        // --- TEST 1: Reset ---
        $display("--- TEST 1: Reset Behavior ---");
        rst_n = 0;
        @(posedge clk); @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        
        // Check interrupt vector
        addr = 8'h01; mem_read = 1; #1;
        check_result("Reset: M[1] = 0x80 (interrupt vector)", data_out == 8'h80);
        mem_read = 0;

        // --- TEST 2: Write and Read ---
        $display("\n--- TEST 2: Write and Read Operations ---");
        
        // Write 0xAA to address 0x10
        addr = 8'h10; data_in = 8'hAA; mem_write = 1;
        @(posedge clk);
        mem_write = 0; @(negedge clk);
        
        // Read back
        mem_read = 1; #1;
        check_result("Write/Read: M[0x10] = 0xAA", data_out == 8'hAA);
        mem_read = 0;

        // Write 0xBB to address 0x20
        addr = 8'h20; data_in = 8'hBB; mem_write = 1;
        @(posedge clk);
        mem_write = 0; @(negedge clk);
        
        mem_read = 1; #1;
        check_result("Write/Read: M[0x20] = 0xBB", data_out == 8'hBB);
        mem_read = 0;

        // --- TEST 3: Multiple Locations ---
        $display("\n--- TEST 3: Multiple Locations ---");
        
        // Write to sequential addresses
        addr = 8'h30; data_in = 8'h11; mem_write = 1;
        @(posedge clk); mem_write = 0;
        
        addr = 8'h31; data_in = 8'h22; mem_write = 1;
        @(posedge clk); mem_write = 0;
        
        addr = 8'h32; data_in = 8'h33; mem_write = 1;
        @(posedge clk); mem_write = 0;
        @(negedge clk);
        
        // Read back
        addr = 8'h30; mem_read = 1; #1;
        check_result("Sequential: M[0x30] = 0x11", data_out == 8'h11);
        
        addr = 8'h31; #1;
        check_result("Sequential: M[0x31] = 0x22", data_out == 8'h22);
        
        addr = 8'h32; #1;
        check_result("Sequential: M[0x33] = 0x33", data_out == 8'h33);
        mem_read = 0;

        // --- TEST 4: Stack Operations (SP = 0xFF) ---
        $display("\n--- TEST 4: Stack Operations ---");
        
        // PUSH: Write to SP (0xFF)
        addr = 8'hFF; data_in = 8'h42; mem_write = 1;
        @(posedge clk); mem_write = 0; @(negedge clk);
        
        // POP: Read from SP
        mem_read = 1; #1;
        check_result("Stack: M[0xFF] = 0x42", data_out == 8'h42);
        mem_read = 0;

        // --- TEST 5: Overwrite ---
        $display("\n--- TEST 5: Overwrite Test ---");
        
        addr = 8'h10; data_in = 8'h55; mem_write = 1;
        @(posedge clk); mem_write = 0; @(negedge clk);
        
        mem_read = 1; #1;
        check_result("Overwrite: M[0x10] = 0x55 (was 0xAA)", data_out == 8'h55);
        mem_read = 0;

        // --- TEST 6: Read Without Enable ---
        $display("\n--- TEST 6: Read Without Enable ---");
        
        addr = 8'h10; mem_read = 0; #1;
        check_result("No Read Enable: data_out = 0x00", data_out == 8'h00);

        // --- TEST 7: Write Without Enable ---
        $display("\n--- TEST 7: Write Without Enable ---");
        
        addr = 8'h40; data_in = 8'hFF; mem_write = 0;
        @(posedge clk); @(negedge clk);
        
        mem_read = 1; #1;
        check_result("No Write Enable: M[0x40] = 0x00 (unchanged)", data_out == 8'h00);
        mem_read = 0;

        // --- TEST 8: Boundary Addresses ---
        $display("\n--- TEST 8: Boundary Addresses ---");
        
        // Address 0x00
        addr = 8'h00; data_in = 8'hA0; mem_write = 1;
        @(posedge clk); mem_write = 0; @(negedge clk);
        mem_read = 1; #1;
        check_result("Boundary: M[0x00] = 0xA0", data_out == 8'hA0);
        
        // Address 0xFF
        addr = 8'hFF; data_in = 8'hAF; mem_write = 1;
        @(posedge clk); mem_write = 0; @(negedge clk);
        #1;
        check_result("Boundary: M[0xFF] = 0xAF", data_out == 8'hAF);
        mem_read = 0;

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
        $dumpfile("tb_DataMemory.vcd");
        $dumpvars(0, tb_DataMemory);
    end

endmodule
