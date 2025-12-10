
// Data Memory Module (256 bytes, byte-addressable)
module data_memory (
    input wire clk,
    input wire rst,
    input wire mem_read,           // Read enable signal
    input wire mem_write,          // Write enable signal
    input wire [7:0] address,      // 8-bit address (0-255)
    input wire [7:0] data_in,      // Data to write
    output reg [7:0] data_out      // Data read from memory
);

    // 256 x 8-bit memory array
    reg [7:0] memory [0:255];
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 8'b0;
        end
        // Initialize interrupt vector at address 1
        memory[1] = 8'h00;  // Default interrupt handler address
    end
    
    // Memory read operation (asynchronous read)
    always @(*) begin
        if (mem_read)
            data_out = memory[address];
        else
            data_out = 8'b0;
    end
    
    // Memory write operation (synchronous write)
    always @(posedge clk) begin
        if (rst) begin
            // Reset only critical locations if needed
            memory[1] <= 8'h00;  // Reset interrupt vector
        end
        else if (mem_write) begin
            memory[address] <= data_in;
        end
    end

endmodule
