`timescale 1ns/1ps

module tb_regfile;

    // Clock & reset
    reg clk;
    reg rst_n;

    // Read ports
    reg  [1:0] rd_addr1;
    reg  [1:0] rd_addr2;
    wire [7:0] rd_data1;
    wire [7:0] rd_data2;

    // Write port
    reg        wr_en;
    reg  [1:0] wr_addr;
    reg  [7:0] wr_data;

    // SP output
    wire [7:0] sp_out;

    // Instantiate DUT (Device Under Test)
    regfile dut (
        .clk(clk),
        .rst_n(rst_n),
        .rd_addr1(rd_addr1),
        .rd_addr2(rd_addr2),
        .rd_data1(rd_data1),
        .rd_data2(rd_data2),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .sp_out(sp_out)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    initial begin
        // -----------------------------
        // INITIAL VALUES
        // -----------------------------
        clk = 0;
        rst_n = 0;

        rd_addr1 = 0;
        rd_addr2 = 0;

        wr_en   = 0;
        wr_addr = 0;
        wr_data = 0;

        // -----------------------------
        // RESET TEST
        // -----------------------------
        #20;
        rst_n = 1;   // release reset
        #10;

        $display("RESET CHECK:");
        $display("SP (R3) = %h (expected FF)", sp_out);

        // -----------------------------
        // WRITE R1 = 0x55
        // -----------------------------
        wr_en   = 1;
        wr_addr = 2'b01;   // R1
        wr_data = 8'h55;
        #10;               // one clock edge

        wr_en = 0;
        #10;

        // READ R1
        rd_addr1 = 2'b01;
        #1;
        $display("READ R1 = %h (expected 55)", rd_data1);

        // -----------------------------
        // WRITE R2 = 0xAA
        // -----------------------------
        wr_en   = 1;
        wr_addr = 2'b10;   // R2
        wr_data = 8'hAA;
        #10;

        wr_en = 0;
        #10;

        // READ R1 & R2 simultaneously
        rd_addr1 = 2'b01;
        rd_addr2 = 2'b10;
        #1;
        $display("READ R1 = %h (expected 55)", rd_data1);
        $display("READ R2 = %h (expected AA)", rd_data2);

        // -----------------------------
        // WRITE-FIRST TEST
        // Write & read same cycle
        // -----------------------------
        wr_en   = 1;
        wr_addr = 2'b00;   // R0
        wr_data = 8'h77;

        rd_addr1 = 2'b00;
        #1;
        $display("WRITE-FIRST READ R0 = %h (expected 77)", rd_data1);

        #10;
        wr_en = 0;

        // -----------------------------
        // SP UPDATE TEST
        // -----------------------------
        wr_en   = 1;
        wr_addr = 2'b11;   // R3 (SP)
        wr_data = 8'hF0;
        #10;

        wr_en = 0;
        #10;
        $display("SP UPDATED = %h (expected F0)", sp_out);

        // -----------------------------
        // FINISH
        // -----------------------------
        #20;
        $display("REGISTER FILE TEST COMPLETE");
        $finish;
    end

endmodule

