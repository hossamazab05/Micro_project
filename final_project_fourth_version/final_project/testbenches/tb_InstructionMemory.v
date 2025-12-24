// testbench for Instruction Memory
`timescale 1ns / 1ps
module tb_InstructionMemory;
    reg clk, rst_n, mem_read;
    reg [7:0] addr;
    wire [7:0] data_out;

    InstructionMemory uut (.clk(clk), .rst_n(rst_n), .mem_read(mem_read), .addr(addr), .data_out(data_out));

    integer pass_count=0; integer fail_count=0; integer test_count=0; 
    task check(input cond); 
        begin
            test_count=test_count+1; 
            if(cond) pass_count=pass_count+1; else fail_count=fail_count+1; 
        end
    endtask

    initial begin
        clk=0; rst_n=1; mem_read=1; addr=0;
        
        // Initialize memory content for testing via backdoor
        uut.mem[0] = 8'hAA;
        uut.mem[1] = 8'hBB;
        uut.mem[255] = 8'hFF;

        // TEST 1: Read Address 0
        addr = 0; #5;
        check(data_out == 8'hAA);

        // TEST 2: Read Address 1
        addr = 1; #5;
        check(data_out == 8'hBB);

        // TEST 3: Read Address 255
        addr = 255; #5;
        check(data_out == 8'hFF);

        // TEST 4: Read Uninitialized (Should be 0)
        addr = 10; #5;
        check(data_out == 8'h00);

        $display("InstructionMemory: %0d Pass, %0d Fail", pass_count, fail_count);
        $finish;
    end
endmodule
