
// Instruction Memory Module (256 bytes, byte-addressable)
module instruction_memory (
    input wire clk,
    input wire rst,
    input wire [7:0] pc,           // Program counter (address)
    output reg [7:0] instruction   // Instruction fetched
);

    // 256 x 8-bit instruction memory array
    reg [7:0] mem [0:255];
    
    // Initialize instruction memory
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 8'b0;
        end
        
        // Load your test program here
        // Example: Simple program
        // mem[0] = 8'hC0;  // LDM R0, imm
        // mem[1] = 8'h05;  // imm = 5
        // mem[2] = 8'h00;  // NOP
        // Add more instructions as needed for testing
        
        // Initialize reset vector at address 0
        mem[0] = 8'h00;  // First instruction after reset
    end
    
    // Asynchronous read - instruction available immediately
    always @(*) begin
        instruction = mem[pc];
    end
    
    // Optional: Task to load program from external file or array
    task load_program;
        input [7:0] start_addr;
        input [7:0] program_data;
        begin
            mem[start_addr] = program_data;
        end
    endtask

endmodule
