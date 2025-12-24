// testbench for MEM_WB Register
// Updated to silence all port warnings
`timescale 1ns / 1ps

module tb_MEM_WB_Register;

    // ==================== Inputs ====================
    reg clk, rst_n, flush, stall;

    // MEM Stage Data
    reg [7:0] mem_alu_result;
    reg [7:0] mem_data;
    reg [3:0] mem_flags;

    // MEM Stage Control
    reg [1:0] mem_rd;
    reg       mem_reg_write;
    reg       mem_mem_to_reg;
    reg       mem_sp_en;
    reg       mem_sp_op;
    reg [1:0] mem_flag_dest;

    // ==================== Outputs ====================
    // WB Stage Data
    wire [7:0] wb_alu_result;
    wire [7:0] wb_mem_data;
    wire [3:0] wb_flags;

    // WB Stage Control
    wire [1:0] wb_rd;
    wire       wb_reg_write;
    wire       wb_mem_to_reg;
    wire       wb_sp_en;
    wire       wb_sp_op;
    wire [1:0] wb_flag_dest;

    // ==================== DUT Instantiation ====================
    MEM_WB_Register uut (
        .clk(clk), .rst_n(rst_n),
        .flush(flush), .stall(stall),

        // Inputs
        .mem_alu_result(mem_alu_result), .mem_data(mem_data), .mem_flags(mem_flags),
        .mem_rd(mem_rd), .mem_reg_write(mem_reg_write), .mem_mem_to_reg(mem_mem_to_reg),
        .mem_sp_en(mem_sp_en), .mem_sp_op(mem_sp_op), .mem_flag_dest(mem_flag_dest),

        // Outputs
        .wb_alu_result(wb_alu_result), .wb_mem_data(wb_mem_data), .wb_flags(wb_flags),
        .wb_rd(wb_rd), .wb_reg_write(wb_reg_write), .wb_mem_to_reg(wb_mem_to_reg),
        .wb_sp_en(wb_sp_en), .wb_sp_op(wb_sp_op), .wb_flag_dest(wb_flag_dest)
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
        mem_alu_result=0; mem_data=0; mem_flags=0;
        mem_rd=0; mem_reg_write=0; mem_mem_to_reg=0;
        mem_sp_en=0; mem_sp_op=0; mem_flag_dest=0;

        // TEST 1: Reset
        @(posedge clk); #1;
        rst_n = 1;
        check(wb_alu_result == 0 && wb_reg_write == 0);

        // TEST 2: Normal Flow
        mem_alu_result = 8'hCC; mem_reg_write = 1; mem_data = 8'hDD;
        @(posedge clk); #1;
        check(wb_alu_result == 8'hCC);
        check(wb_mem_data == 8'hDD);
        check(wb_reg_write == 1);

        // TEST 3: Stall Behavior
        stall = 1;
        mem_alu_result = 8'hFF; // Change input
        @(posedge clk); #1;
        check(wb_alu_result == 8'hCC); // Should hold CC
        
        // TEST 4: Flush Behavior
        stall = 0; flush = 1;
        @(posedge clk); #1;
        check(wb_alu_result == 0);
        check(wb_reg_write == 0);

        $display("MEM_WB: %0d Pass, %0d Fail", pass_count, fail_count);
        $finish;
    end

endmodule
