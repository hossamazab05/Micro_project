// ============================================================
// tb_ExecutionUnit.v
// Testbench for ExecutionUnit Module (ELC3030 Processor)
// ============================================================

`timescale 1ns / 1ps

module tb_ExecutionUnit;

    // ==================== Control Inputs ====================
    reg        alu_en, mem_read, mem_write, reg_write;
    reg        io_read, io_write;
    reg        sp_en, sp_op, imm_sel;
    reg        branch, branch_cond, jwsp;
    reg        stack_pc, stack_flags;
    reg [1:0]  flag_dest, flag_sel;
    
    // ==================== Instruction Fields ====================
    reg [3:0]  opcode;
    reg [1:0]  alu_sub;
    reg [2:0]  wb_addr;
    
    // ==================== Data Inputs ====================
    reg [7:0]  data_a, data_b, imm_value, pc_in, io_in;
    reg [3:0]  flags_in, flags_mem;
    reg        flags_restore;
    
    // ==================== Outputs ====================
    wire       branch_taken, pc_sel;
    wire [7:0] addr_out, data_out, io_out;
    wire [3:0] flags_out;
    wire [2:0] wb_addr_out;
    wire       mem_read_out, mem_write_out, reg_write_out;
    wire       sp_en_out, sp_op_out;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // ==================== DUT Instantiation ====================
    ExecutionUnit uut (
        .alu_en(alu_en), .mem_read(mem_read), .mem_write(mem_write),
        .reg_write(reg_write), .io_read(io_read), .io_write(io_write),
        .sp_en(sp_en), .sp_op(sp_op), .imm_sel(imm_sel),
        .branch(branch), .branch_cond(branch_cond), .jwsp(jwsp),
        .stack_pc(stack_pc), .stack_flags(stack_flags),
        .flag_dest(flag_dest), .flag_sel(flag_sel),
        .opcode(opcode), .alu_sub(alu_sub), .wb_addr(wb_addr),
        .data_a(data_a), .data_b(data_b), .imm_value(imm_value),
        .pc_in(pc_in), .io_in(io_in),
        .flags_in(flags_in), .flags_mem(flags_mem), .flags_restore(flags_restore),
        .branch_taken(branch_taken), .pc_sel(pc_sel),
        .addr_out(addr_out), .data_out(data_out), .io_out(io_out),
        .flags_out(flags_out), .wb_addr_out(wb_addr_out),
        .mem_read_out(mem_read_out), .mem_write_out(mem_write_out),
        .reg_write_out(reg_write_out),
        .sp_en_out(sp_en_out), .sp_op_out(sp_op_out)
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
            fail_count = fail_count + 1;
        end
    end
    endtask

    task reset_signals;
    begin
        alu_en = 0; mem_read = 0; mem_write = 0; reg_write = 0;
        io_read = 0; io_write = 0; sp_en = 0; sp_op = 0; imm_sel = 0;
        branch = 0; branch_cond = 0; jwsp = 0;
        stack_pc = 0; stack_flags = 0;
        flag_dest = 2'b10; flag_sel = 0;
        opcode = 0; alu_sub = 0; wb_addr = 0;
        data_a = 0; data_b = 0; imm_value = 0; pc_in = 0; io_in = 0;
        flags_in = 0; flags_mem = 0; flags_restore = 0;
    end
    endtask

    // ==================== Main Test Sequence ====================
    initial begin
        $display("\n========================================");
        $display("ExecutionUnit Testbench Started");
        $display("========================================\n");

        reset_signals;
        #10;

        // --- TEST 1: ADD ---
        $display("--- TEST 1: ADD ---");
        alu_en = 1; reg_write = 1; opcode = 4'd2; flag_dest = 2'b11;
        data_a = 8'h10; data_b = 8'h05;
        #10;
        check_result("ADD: 0x10 + 0x05 = 0x15", data_out == 8'h15);
        check_result("ADD: Z=0 (not zero)", flags_out[0] == 0);

        // --- TEST 2: SUB ---
        $display("\n--- TEST 2: SUB ---");
        reset_signals; alu_en = 1; reg_write = 1; opcode = 4'd3; flag_dest = 2'b11;
        data_a = 8'h20; data_b = 8'h10;
        #10;
        check_result("SUB: 0x20 - 0x10 = 0x10", data_out == 8'h10);
        check_result("SUB: C=1 (no borrow)", flags_out[2] == 1);

        // --- TEST 3: SUB with Zero ---
        $display("\n--- TEST 3: SUB Zero Result ---");
        reset_signals; alu_en = 1; reg_write = 1; opcode = 4'd3; flag_dest = 2'b11;
        data_a = 8'h05; data_b = 8'h05;
        #10;
        check_result("SUB: 0x05 - 0x05 = 0x00", data_out == 8'h00);
        check_result("SUB: Z=1 (zero)", flags_out[0] == 1);

        // --- TEST 4: AND ---
        $display("\n--- TEST 4: AND ---");
        reset_signals; alu_en = 1; reg_write = 1; opcode = 4'd4; flag_dest = 2'b11;
        data_a = 8'hF0; data_b = 8'h0F;
        #10;
        check_result("AND: 0xF0 & 0x0F = 0x00", data_out == 8'h00);

        // --- TEST 5: OR ---
        $display("\n--- TEST 5: OR ---");
        reset_signals; alu_en = 1; reg_write = 1; opcode = 4'd5; flag_dest = 2'b11;
        data_a = 8'hF0; data_b = 8'h0F;
        #10;
        check_result("OR: 0xF0 | 0x0F = 0xFF", data_out == 8'hFF);

        // --- TEST 6: INC ---
        $display("\n--- TEST 6: INC ---");
        reset_signals; alu_en = 1; reg_write = 1; opcode = 4'd8; alu_sub = 2'd2; flag_dest = 2'b11;
        data_b = 8'h0A;
        #10;
        check_result("INC: 0x0A + 1 = 0x0B", data_out == 8'h0B);

        // --- TEST 7: DEC ---
        $display("\n--- TEST 7: DEC ---");
        reset_signals; alu_en = 1; reg_write = 1; opcode = 4'd8; alu_sub = 2'd3; flag_dest = 2'b11;
        data_b = 8'h01;
        #10;
        check_result("DEC: 0x01 - 1 = 0x00", data_out == 8'h00);
        check_result("DEC: Z=1", flags_out[0] == 1);

        // --- TEST 8: Stack PUSH Address ---
        $display("\n--- TEST 8: PUSH Address ---");
        reset_signals; mem_write = 1; sp_en = 1; sp_op = 0;
        data_a = 8'hFE; data_b = 8'hAA;
        #10;
        check_result("PUSH: addr = SP (0xFE)", addr_out == 8'hFE);
        check_result("PUSH: data = R[rb] (0xAA)", data_out == 8'hAA);

        // --- TEST 9: Stack POP Address ---
        $display("\n--- TEST 9: POP Address ---");
        reset_signals; mem_read = 1; sp_en = 1; sp_op = 1;
        data_a = 8'hFE;
        #10;
        check_result("POP: addr = SP+1 (0xFF)", addr_out == 8'hFF);

        // --- TEST 10: Branch Taken ---
        $display("\n--- TEST 10: Branch (Z=1) ---");
        reset_signals; branch = 1; branch_cond = 1; flag_sel = 0;
        flags_in = 4'b0001; // Z=1
        #10;
        check_result("JZ: branch_taken=1 when Z=1", branch_taken == 1);

        // --- TEST 11: Branch Not Taken ---
        $display("\n--- TEST 11: Branch (Z=0) ---");
        reset_signals; branch = 1; branch_cond = 1; flag_sel = 0;
        flags_in = 4'b0000; // Z=0
        #10;
        check_result("JZ: branch_taken=0 when Z=0", branch_taken == 0);

        // --- TEST 12: I/O Output ---
        $display("\n--- TEST 12: I/O Output ---");
        reset_signals; io_write = 1;
        data_b = 8'h42;
        #10;
        check_result("OUT: io_out = 0x42", io_out == 8'h42);

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
        $dumpfile("tb_ExecutionUnit.vcd");
        $dumpvars(0, tb_ExecutionUnit);
    end

endmodule
