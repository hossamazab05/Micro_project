// ============================================================
// DataMemory.v
// Data Memory for ELC3030 Processor (Harvard Architecture)
// 256 bytes, byte-addressable
// ============================================================

module DataMemory (
    // ==================== System Signals ====================
    input wire        clk,           // System clock
    input wire        rst_n,         // Active-low reset
    
    // ==================== Control Signals ====================
    input wire        mem_read,      // Read enable
    input wire        mem_write,     // Write enable
    
    // ==================== Data Signals ====================
    input wire [7:0]  addr,          // Memory address (0-255)
    input wire [7:0]  data_in,       // Data to write
    output reg [7:0]  data_out       // Data read from memory
);

    // ==================== Memory Array ====================
    reg [7:0] mem [0:255];
    
    // ==================== Initialization ====================
    integer i;
    initial begin
        // Initialize all memory to zero
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 8'h00;
        end
        
        // Initialize interrupt vector at address 1
        // This will be loaded by FSM during interrupt
        mem[1] = 8'h50;  // ISR address at 0x50
    end
    
    // ==================== Asynchronous Read ====================
    // Combinational read for faster access
    always @(*) begin
        if (mem_read) begin
            data_out = mem[addr];
        end else begin
            data_out = 8'h00;
        end
    end
    
    // ==================== Synchronous Write ====================
    // Write on positive clock edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // On reset, reinitialize critical vectors
            mem[1] <= 8'h50;  // Interrupt vector
        end else begin
            if (mem_write) begin
                mem[addr] <= data_in;
            end
        end
    end

endmodule
