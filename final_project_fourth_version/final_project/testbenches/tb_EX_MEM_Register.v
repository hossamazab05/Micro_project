// testbench for EX_MEM Register
// Updated to silence all port warnings
`timescale 1ns / 1ps

module tb_EX_MEM_Register;

    // ==================== Inputs ====================
    reg clk, rst_n, flush, stall;

    // EX Stage Data
    reg [7:0] ex_alu_result;
    reg [7:0] ex_mem_addr;
    reg [7:0] ex_data_b;
    reg [7:0] ex_pc_plus_1;
    reg [3:0] ex_flags;

    // EX Stage Control
    reg [1:0] ex_rd;
    reg       ex_reg_write;
    reg       ex_mem_read;
    reg       ex_mem_write;
    reg       ex_mem_to_reg;
    reg       ex_branch_taken;
    reg [7:0] ex_branch_target;
    reg [1:0] ex_flag_dest;
    reg       ex_sp_en;
    reg       ex_sp_op;
    reg       ex_stack_pc;
    reg       ex_stack_flags;
    reg       ex_jwsp;
    reg       ex_rti;

    // ==================== Outputs ====================
    // MEM Stage Data
    wire [7:0] mem_alu_result;
    wire [7:0] mem_mem_addr;
    wire [7:0] mem_data_b;
    wire [7:0] mem_pc_plus_1;
    wire [3:0] mem_flags;

    // MEM Stage Control
    wire [1:0] mem_rd;
    wire       mem_reg_write;
    wire       mem_mem_read;
    wire       mem_mem_write;
    wire       mem_mem_to_reg;
    wire       mem_branch_taken;
    wire [7:0] mem_branch_target;
    wire [1:0] mem_flag_dest;
    wire       mem_sp_en;
    wire       mem_sp_op;
    wire       mem_stack_pc;
    wire       mem_stack_flags;
    wire       mem_jwsp;
    wire       mem_rti;

    // ==================== DUT Instantiation ====================
    EX_MEM_Register uut (
        .clk(clk), .rst_n(rst_n),
        .flush(flush), .stall(stall),

        // Inputs
        .ex_alu_result(ex_alu_result), .ex_mem_addr(ex_mem_addr), .ex_data_b(ex_data_b),
        .ex_pc_plus_1(ex_pc_plus_1), .ex_flags(ex_flags),
        .ex_rd(ex_rd), .ex_reg_write(ex_reg_write), .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write), .ex_mem_to_reg(ex_mem_to_reg),
        .ex_branch_taken(ex_branch_taken), .ex_branch_target(ex_branch_target),
        .ex_flag_dest(ex_flag_dest), .ex_sp_en(ex_sp_en), .ex_sp_op(ex_sp_op),
        .ex_stack_pc(ex_stack_pc), .ex_stack_flags(ex_stack_flags),
        .ex_jwsp(ex_jwsp), .ex_rti(ex_rti),

        // Outputs
        .mem_alu_result(mem_alu_result), .mem_mem_addr(mem_mem_addr), .mem_data_b(mem_data_b),
        .mem_pc_plus_1(mem_pc_plus_1), .mem_flags(mem_flags),
        .mem_rd(mem_rd), .mem_reg_write(mem_reg_write), .mem_mem_read(mem_mem_read),
        .mem_mem_write(mem_mem_write), .mem_mem_to_reg(mem_mem_to_reg),
        .mem_branch_taken(mem_branch_taken), .mem_branch_target(mem_branch_target),
        .mem_flag_dest(mem_flag_dest), .mem_sp_en(mem_sp_en), .mem_sp_op(mem_sp_op),
        .mem_stack_pc(mem_stack_pc), .mem_stack_flags(mem_stack_flags),
        .mem_jwsp(mem_jwsp), .mem_rti(mem_rti)
    );

    // ==================== Test Tasks ====================
    integer pass_count=0; integer fail_count=0; integer test_count=0; 
    task check(input cond); 
        begin
            test_count=test_count+1; 
            if(cond) pass_count=pass_count+1; else fail_count=fail_count+1; 
        end
    endtask

    always #5 clk = ~clk;

    // ==================== Main Test Sequence ====================
    initial begin
        clk=0; rst_n=0; flush=0; stall=0;
        
        // Zero Inputs
        ex_alu_result=0; ex_mem_addr=0; ex_data_b=0; ex_pc_plus_1=0; ex_flags=0;
        ex_rd=0; ex_reg_write=0; ex_mem_read=0; ex_mem_write=0; ex_mem_to_reg=0;
        ex_branch_taken=0; ex_branch_target=0; ex_flag_dest=0; ex_sp_en=0;
        ex_sp_op=0; ex_stack_pc=0; ex_stack_flags=0; ex_jwsp=0; ex_rti=0;

        // TEST 1: Reset
        @(posedge clk); #1;
        rst_n = 1;
        check(mem_alu_result == 0 && mem_mem_write == 0);

        // TEST 2: Normal Flow
        ex_alu_result = 8'hA5; ex_mem_write = 1; ex_mem_addr = 8'hFF;
        @(posedge clk); #1;
        check(mem_alu_result == 8'hA5);
        check(mem_mem_write == 1);
        check(mem_mem_addr == 8'hFF);

        // TEST 3: Stall Behavior
        stall = 1;
        ex_alu_result = 8'h00; // Change input
        @(posedge clk); #1;
        check(mem_alu_result == 8'hA5); // Should hold A5
        
        // TEST 4: Flush Behavior
        stall = 0; flush = 1;
        @(posedge clk); #1;
        check(mem_alu_result == 0);
        check(mem_mem_write == 0);

        $display("EX_MEM: %0d Pass, %0d Fail", pass_count, fail_count);
        $finish;
    end

endmodule
