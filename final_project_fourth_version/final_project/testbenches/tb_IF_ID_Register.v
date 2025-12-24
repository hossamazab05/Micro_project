// testbench for IF_ID Register
`timescale 1ns / 1ps
module tb_IF_ID_Register;
    reg clk, rst_n, stall, flush;
    reg [7:0] if_instruction, if_pc, if_pc_plus_1;
    wire [7:0] id_instruction, id_pc, id_pc_plus_1;

    IF_ID_Register uut (.*);

    integer pass_count=0; integer fail_count=0; integer test_count=0; 
    task check(input cond); 
        begin
            test_count=test_count+1; 
            if(cond) pass_count=pass_count+1; else fail_count=fail_count+1; 
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        clk=0; rst_n=0; stall=0; flush=0;
        if_instruction=0; if_pc=0; if_pc_plus_1=0;
        
        // TEST 1: Reset
        @(posedge clk); #1;
        rst_n = 1;
        check(id_instruction==0);

        // TEST 2: Normal Flow
        if_instruction=8'hAA; if_pc=8'h10; if_pc_plus_1=8'h11;
        @(posedge clk); #1;
        check(id_instruction==8'hAA && id_pc==8'h10);

        // TEST 3: Stall (Hold Value)
        stall = 1;
        if_instruction=8'hBB; 
        @(posedge clk); #1;
        check(id_instruction==8'hAA); // Should hold AA
        
        // TEST 4: Flush (Clear to NOP)
        stall = 0; flush = 1;
        @(posedge clk); #1;
        check(id_instruction==8'h00 && id_pc==8'h00);

        $display("IF_ID: %0d Pass, %0d Fail", pass_count, fail_count);
        $finish;
    end
endmodule
