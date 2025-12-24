// testbench for Output Port
`timescale 1ns / 1ps
module tb_OutputPort;
    reg clk, rst_n, enable;
    reg [7:0] data_in;
    wire [7:0] pins_out;

    OutputPort uut (.clk(clk), .rst_n(rst_n), .enable(enable), .data_in(data_in), .pins_out(pins_out));

    always #5 clk = ~clk;
    integer pass_count=0; integer fail_count=0; integer test_count=0; 
    task check(input cond); 
        begin
            test_count=test_count+1; 
            if(cond) pass_count=pass_count+1; else fail_count=fail_count+1; 
        end
    endtask

    initial begin
        clk=0; rst_n=0; enable=0; data_in=0;
        #10 rst_n=1;

        // TEST 1: Reset
        check(pins_out == 0);

        // TEST 2: Write Enable
        data_in = 8'h5A; enable = 1;
        @(posedge clk); #1; enable = 0;
        check(pins_out == 8'h5A);

        // TEST 3: No Write
        data_in = 8'hFF;
        @(posedge clk); #1;
        check(pins_out == 8'h5A); // Should hold value

        $display("OutputPort: %0d Pass, %0d Fail", pass_count, fail_count);
        $finish;
    end
endmodule
