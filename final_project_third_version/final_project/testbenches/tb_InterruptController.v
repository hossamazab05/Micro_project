// ============================================================
// tb_InterruptController.v
// Testbench for InterruptController Module (Standardized Names)
// ============================================================

`timescale 1ns / 1ps

module tb_InterruptController;

    // ==================== Clock & Reset ====================
    reg clk;
    reg rst_n;
    
    // ==================== Inputs ====================
    reg        intr_in;
    reg        rti_instruction;
    reg [7:0]  current_pc;
    reg [3:0]  current_ccr;
    reg [7:0]  current_sp;
    reg [7:0]  mem_data_in;
    
    // ==================== Outputs ====================
    wire [7:0]  mem_addr;
    wire        mem_read_enable;
    wire        stack_push_enable;
    wire [7:0]  stack_data_out;
    wire        sp_dec_enable;
    wire        stack_pop_enable;
    wire        sp_inc_enable;
    wire        load_pc_enable;
    wire [7:0]  new_pc_value;
    wire        load_ccr_enable;
    wire [3:0]  saved_ccr;
    wire        pipeline_flush;
    wire        interrupt_active;
    wire        stall_pipeline;
    wire [3:0]  current_state_out;

    // ==================== DUT ====================
    InterruptController DUT (
        .clk              (clk),
        .rst_n            (rst_n),
        .intr_in          (intr_in),
        .rti_instruction  (rti_instruction),
        .current_pc       (current_pc),
        .current_ccr      (current_ccr),
        .current_sp       (current_sp),
        .mem_data_in      (mem_data_in),
        .mem_addr         (mem_addr),
        .mem_read_enable  (mem_read_enable),
        .stack_push_enable(stack_push_enable),
        .stack_data_out   (stack_data_out),
        .sp_dec_enable    (sp_dec_enable),
        .stack_pop_enable (stack_pop_enable),
        .sp_inc_enable    (sp_inc_enable),
        .load_pc_enable   (load_pc_enable),
        .new_pc_value     (new_pc_value),
        .load_ccr_enable  (load_ccr_enable),
        .saved_ccr        (saved_ccr),
        .pipeline_flush   (pipeline_flush),
        .interrupt_active (interrupt_active),
        .stall_pipeline   (stall_pipeline),
        .current_state_out(current_state_out)
    );

    // ==================== Clock Generation ====================
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // ==================== Test Variables ====================
    integer errors;
    integer pass_count;
    
    reg saw_pc_push, saw_ccr_push, saw_vector_read, saw_isr_jump;
    reg saw_ccr_pop, saw_pc_pop, saw_restore;
    
    // ==================== Output Monitor ====================
    always @(posedge clk) begin
        if (stack_push_enable && sp_dec_enable && stack_data_out == current_pc && !saw_pc_push) begin
            $display("[PASS] INTR: PC Push detected (Data=0x%h)", stack_data_out);
            saw_pc_push = 1;
        end
        if (stack_push_enable && sp_dec_enable && stack_data_out == {4'h0, current_ccr} && saw_pc_push && !saw_ccr_push) begin
            $display("[PASS] INTR: CCR Push detected (Data=0x%h)", stack_data_out);
            saw_ccr_push = 1;
        end
        if (mem_read_enable && mem_addr == 8'h01 && !saw_vector_read) begin
            $display("[PASS] INTR: Vector read from M[0x01]");
            saw_vector_read = 1;
        end
        if (load_pc_enable && !saw_isr_jump) begin
            $display("[PASS] INTR: PC Load (new_pc=0x%h)", new_pc_value);
            saw_isr_jump = 1;
        end
        if (stack_pop_enable && sp_inc_enable && !saw_ccr_pop) begin
            $display("[PASS] RTI: CCR Pop detected");
            saw_ccr_pop = 1;
        end
        if (stack_pop_enable && sp_inc_enable && saw_ccr_pop && !saw_pc_pop) begin
            $display("[PASS] RTI: PC Pop detected");
            saw_pc_pop = 1;
        end
        if (load_pc_enable && load_ccr_enable && saw_pc_pop && !saw_restore) begin
            $display("[PASS] RTI: Restore (PC=0x%h, CCR=%b)", new_pc_value, saved_ccr);
            saw_restore = 1;
        end
    end

    // ==================== Test Sequence ====================
    initial begin
        errors = 0;
        pass_count = 0;
        saw_pc_push = 0; saw_ccr_push = 0; saw_vector_read = 0; saw_isr_jump = 0;
        saw_ccr_pop = 0; saw_pc_pop = 0; saw_restore = 0;
        
        // Initialize
        rst_n = 0;
        intr_in = 0;
        rti_instruction = 0;
        current_pc = 8'h20;
        current_ccr = 4'b1010;
        current_sp = 8'hFF;
        mem_data_in = 8'h00;
        
        $display("========================================");
        $display("   Interrupt Controller Testbench");
        $display("   (Standardized Naming)");
        $display("========================================");
        
        // Release reset
        #25;
        rst_n = 1;
        #20;
        
        // Test 1: Interrupt Entry
        $display("\n--- Test 1: Interrupt Entry ---");
        @(posedge clk);
        intr_in = 1;
        @(posedge clk);
        intr_in = 0;
        mem_data_in = 8'h80;
        repeat(10) @(posedge clk);
        
        if (saw_pc_push) pass_count = pass_count + 1; else errors = errors + 1;
        if (saw_ccr_push) pass_count = pass_count + 1; else errors = errors + 1;
        if (saw_vector_read) pass_count = pass_count + 1; else errors = errors + 1;
        if (saw_isr_jump) pass_count = pass_count + 1; else errors = errors + 1;
        
        // Test 2: RTI
        $display("\n--- Test 2: RTI ---");
        repeat(3) @(posedge clk);
        rti_instruction = 1;
        @(posedge clk);
        rti_instruction = 0;
        mem_data_in = 8'h0A;
        repeat(3) @(posedge clk);
        mem_data_in = 8'h20;
        repeat(5) @(posedge clk);
        
        if (saw_ccr_pop) pass_count = pass_count + 1; else errors = errors + 1;
        if (saw_pc_pop) pass_count = pass_count + 1; else errors = errors + 1;
        if (saw_restore) pass_count = pass_count + 1; else errors = errors + 1;
        
        // Summary
        $display("\n========================================");
        $display("   RESULTS: %d PASSED, %d FAILED", pass_count, errors);
        if (errors == 0)
            $display("   ALL TESTS PASSED!");
        $display("========================================");
        
        $finish;
    end
    
    initial begin
        #10000;
        $display("ERROR: Timeout!");
        $finish;
    end

endmodule
