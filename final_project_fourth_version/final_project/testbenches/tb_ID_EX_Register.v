// testbench for ID_EX Register
// Updated to silence all port warnings
`timescale 1ns / 1ps

module tb_ID_EX_Register;

    // ==================== Inputs ====================
    reg clk;
    reg rst_n;
    reg flush;
    reg stall;

    // ID Stage Data Outputs
    reg [7:0] id_data_a;
    reg [7:0] id_data_b;
    reg [7:0] id_imm;
    reg [7:0] id_pc;
    reg [7:0] id_pc_plus_1;

    // ID Stage Register Addresses
    reg [1:0] id_rs;
    reg [1:0] id_rt;
    reg       id_rs_en;
    reg       id_rt_en;
    reg [1:0] id_rd;

    // ID Stage Control Signals
    reg       id_reg_write;
    reg       id_mem_read;
    reg       id_mem_write;
    reg       id_mem_to_reg;
    reg       id_alu_src;
    reg [3:0] id_alu_op;
    reg [2:0] id_alu_sub;
    reg       id_branch;
    reg       id_jmp_cond;
    reg       id_jump;
    reg [1:0] id_flag_dest;
    reg [1:0] id_flag_sel;
    reg       id_ior;
    reg       id_iow;
    reg       id_ops;
    reg       id_sp_en;
    reg       id_sp_op;
    reg       id_stack_pc;
    reg       id_stack_flags;
    reg       id_rti;

    // ==================== Outputs ====================
    // EX Stage Data Inputs
    wire [7:0] ex_data_a;
    wire [7:0] ex_data_b;
    wire [7:0] ex_imm;
    wire [7:0] ex_pc;
    wire [7:0] ex_pc_plus_1;

    // EX Stage Register Addresses
    wire [1:0] ex_rs;
    wire [1:0] ex_rt;
    wire       ex_rs_en;
    wire       ex_rt_en;
    wire [1:0] ex_rd;

    // EX Stage Control Signals
    wire       ex_reg_write;
    wire       ex_mem_read;
    wire       ex_mem_write;
    wire       ex_mem_to_reg;
    wire       ex_alu_src;
    wire [3:0] ex_alu_op;
    wire [2:0] ex_alu_sub;
    wire       ex_branch;
    wire       ex_jmp_cond;
    wire       ex_jump;
    wire [1:0] ex_flag_dest;
    wire [1:0] ex_flag_sel;
    wire       ex_ior;
    wire       ex_iow;
    wire       ex_ops;
    wire       ex_sp_en;
    wire       ex_sp_op;
    wire       ex_stack_pc;
    wire       ex_stack_flags;
    wire       ex_rti;

    // ==================== DUT Instantiation ====================
    ID_EX_Register uut (
        .clk(clk), .rst_n(rst_n),
        .flush(flush), .stall(stall),

        // Inputs
        .id_data_a(id_data_a), .id_data_b(id_data_b), .id_imm(id_imm),
        .id_pc(id_pc), .id_pc_plus_1(id_pc_plus_1),
        .id_rs(id_rs), .id_rt(id_rt), .id_rs_en(id_rs_en), .id_rt_en(id_rt_en), .id_rd(id_rd),
        .id_reg_write(id_reg_write), .id_mem_read(id_mem_read), .id_mem_write(id_mem_write),
        .id_mem_to_reg(id_mem_to_reg), .id_alu_src(id_alu_src), .id_alu_op(id_alu_op),
        .id_alu_sub(id_alu_sub), .id_branch(id_branch), .id_jmp_cond(id_jmp_cond),
        .id_jump(id_jump), .id_flag_dest(id_flag_dest), .id_flag_sel(id_flag_sel),
        .id_ior(id_ior), .id_iow(id_iow), .id_ops(id_ops), .id_sp_en(id_sp_en),
        .id_sp_op(id_sp_op), .id_stack_pc(id_stack_pc), .id_stack_flags(id_stack_flags),
        .id_rti(id_rti),

        // Outputs
        .ex_data_a(ex_data_a), .ex_data_b(ex_data_b), .ex_imm(ex_imm),
        .ex_pc(ex_pc), .ex_pc_plus_1(ex_pc_plus_1),
        .ex_rs(ex_rs), .ex_rt(ex_rt), .ex_rs_en(ex_rs_en), .ex_rt_en(ex_rt_en), .ex_rd(ex_rd),
        .ex_reg_write(ex_reg_write), .ex_mem_read(ex_mem_read), .ex_mem_write(ex_mem_write),
        .ex_mem_to_reg(ex_mem_to_reg), .ex_alu_src(ex_alu_src), .ex_alu_op(ex_alu_op),
        .ex_alu_sub(ex_alu_sub), .ex_branch(ex_branch), .ex_jmp_cond(ex_jmp_cond),
        .ex_jump(ex_jump), .ex_flag_dest(ex_flag_dest), .ex_flag_sel(ex_flag_sel),
        .ex_ior(ex_ior), .ex_iow(ex_iow), .ex_ops(ex_ops), .ex_sp_en(ex_sp_en),
        .ex_sp_op(ex_sp_op), .ex_stack_pc(ex_stack_pc), .ex_stack_flags(ex_stack_flags),
        .ex_rti(ex_rti)
    );

    // ==================== Test Tasks ====================
    integer pass_count=0; integer fail_count=0; integer test_count=0; 
    task check(input cond); 
        begin
            test_count=test_count+1; 
            if(cond) pass_count=pass_count+1; else fail_count=fail_count+1; 
        end
    endtask

    // Clock gen
    always #5 clk = ~clk;

    // ==================== Main Test Sequence ====================
    initial begin
        clk=0; rst_n=0; flush=0; stall=0;
        
        // Zero all inputs
        id_data_a=0; id_data_b=0; id_imm=0; id_pc=0; id_pc_plus_1=0;
        id_rs=0; id_rt=0; id_rs_en=0; id_rt_en=0; id_rd=0;
        id_reg_write=0; id_mem_read=0; id_mem_write=0; id_mem_to_reg=0;
        id_alu_src=0; id_alu_op=0; id_alu_sub=0; id_branch=0; id_jmp_cond=0;
        id_jump=0; id_flag_dest=0; id_flag_sel=0; id_ior=0; id_iow=0; id_ops=0;
        id_sp_en=0; id_sp_op=0; id_stack_pc=0; id_stack_flags=0; id_rti=0;

        // TEST 1: Reset Behavior
        @(posedge clk); #1;
        rst_n = 1;
        check(ex_data_a == 0 && ex_reg_write == 0);

        // TEST 2: Normal Flow (Pass Data)
        id_data_a = 8'hAA; id_data_b = 8'hBB;
        id_reg_write = 1; id_alu_op = 4'h2; // ADD
        @(posedge clk); #1;
        check(ex_data_a == 8'hAA);
        check(ex_data_b == 8'hBB);
        check(ex_reg_write == 1);
        check(ex_alu_op == 4'h2);

        // TEST 3: Stall Behavior (Hold Data)
        stall = 1;
        id_data_a = 8'hFF; // Change input
        @(posedge clk); #1;
        check(ex_data_a == 8'hAA); // Should hold old value 8'hAA
        
        // TEST 4: Flush Behavior (Clear to 0)
        stall = 0; flush = 1;
        @(posedge clk); #1;
        check(ex_data_a == 0);
        check(ex_reg_write == 0);

        $display("ID_EX: %0d Pass, %0d Fail", pass_count, fail_count);
        $finish;
    end

endmodule
