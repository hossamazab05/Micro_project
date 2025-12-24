// ============================================================
// InstructionMemory.v - RAM Implementation for Testing
// ============================================================
module InstructionMemory (
    input wire clk, rst_n, mem_read,
    input wire [7:0] addr,
    output reg [7:0] data_out
);

    reg [7:0] mem [255:0];

    // Read Logic (Asynchronous Read)
    always @(*) begin
        data_out = mem[addr];
    end

    // Initialization for synthesis (optional, but good for simulation start)
    integer i;
    initial begin
        for (i=0; i<256; i=i+1) mem[i] = 8'h00;
    end

endmodule
