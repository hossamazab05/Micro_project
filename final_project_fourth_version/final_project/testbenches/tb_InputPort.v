// testbench for Input Port
`timescale 1ns / 1ps
module tb_InputPort;
    reg [7:0] pins_in;
    reg enable;
    wire [7:0] data_out;

    InputPort uut (.pins_in(pins_in), .enable(enable), .data_out(data_out));

    integer pass_count=0; integer fail_count=0; integer test_count=0; 
    task check(input cond); 
        begin
            test_count=test_count+1; 
            if(cond) pass_count=pass_count+1; else fail_count=fail_count+1; 
        end
    endtask

    initial begin
        // TEST 1: Read Enable
        pins_in = 8'hA5; enable = 1; #5;
        check(data_out == 8'hA5);

        // TEST 2: No Enable
        enable = 0; #5;
        check(data_out == 8'h00);

        $display("InputPort: %0d Pass, %0d Fail", pass_count, fail_count);
        $finish;
    end
endmodule
