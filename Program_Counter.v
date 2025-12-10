// Program Counter Module - FIXED VERSION
module program_counter (
    input wire clk,
    input wire rst,
    input wire RESET_IN,           // External reset signal
    input wire INTR_IN,            // Interrupt signal
    input wire pc_write,           // Enable PC update
    input wire [7:0] pc_in,        // New PC value (from branch/jump)
    input wire [7:0] reset_vector, // Address from memory[0] for reset
    input wire [7:0] intr_vector,  // Address from memory[1] for interrupt
    input wire pc_src,             // 0: PC+1 or PC+2, 1: branch/jump address
    input wire pc_increment,       // Increment value: 0 for +1, 1 for +2
    output reg [7:0] PC            // Current program counter
);

    // PC update logic with proper priority handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Asynchronous reset - highest priority
            PC <= reset_vector;
        end
        else begin
            // Synchronous operations - checked in priority order
            if (RESET_IN) begin
                // External reset - highest synchronous priority
                PC <= reset_vector;
            end
            else if (INTR_IN) begin
                // Interrupt - second priority
                PC <= intr_vector;
            end
            else if (pc_write) begin
                // Normal PC update operations
                if (pc_src) begin
                    // Branch/Jump: Load PC with target address
                    PC <= pc_in;
                end
                else begin
                    // Sequential: Increment PC by 1 or 2
                    if (pc_increment)
                        PC <= PC + 8'd2;  // For 2-byte instructions
                    else
                        PC <= PC + 8'd1;  // For 1-byte instructions
                end
            end
            // else: PC holds its value (stall condition)
        end
    end

endmodule

