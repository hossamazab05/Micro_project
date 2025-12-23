// ============================================================
// ProgramCounter.v
// Program Counter for ELC3030 Processor
// Synchronized with FSM Control Unit (always +1 increment)
// ============================================================

module ProgramCounter (
    // ==================== System Signals ====================
    input wire        clk,           // System clock
    input wire        rst_n,         // Active-low reset
    
    // ==================== Control Signals ====================
    input wire        pc_write,      // Enable PC update
    input wire        pc_src,        // 0: PC+1, 1: Jump/Branch target
    
    // ==================== Data Inputs ====================
    input wire [7:0]  pc_target,     // Jump/Branch target address
    input wire [7:0]  mem_data,      // Data from memory (for reset/interrupt vectors)
    
    // ==================== Special Inputs ====================
    input wire        load_vector,   // Load PC from mem_data (reset/interrupt)
    
    // ==================== Output ====================
    output reg [7:0]  pc_out         // Current program counter
);

    // ==================== PC Update Logic ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset - PC will be loaded from M[0] by FSM
            pc_out <= 8'h00;
        end else begin
            if (pc_write) begin
                if (load_vector) begin
                    // Load from memory (Reset: M[0], Interrupt: M[1])
                    pc_out <= mem_data;
                end else if (pc_src) begin
                    // Branch/Jump: Load target address
                    pc_out <= pc_target;
                end else begin
                    // Sequential: Always increment by 1
                    // (FSM calls this twice for 2-byte instructions)
                    pc_out <= pc_out + 8'd1;
                end
            end
            // else: PC holds value (stall/no write)
        end
    end

endmodule
