// ============================================================
// IF_ID_Register.v
// Pipeline Register between Instruction Fetch and Decode
// Supports stall and flush for hazard handling
// ============================================================

module IF_ID_Register (
    // ==================== System Signals ====================
    input wire        clk,
    input wire        rst_n,
    
    // ==================== Hazard Control ====================
    input wire        stall,         // Hold current values (from HazardDetectionUnit)
    input wire        flush,         // Clear to NOP (from HazardDetectionUnit)
    
    // ==================== IF Stage Outputs ====================
    input wire [7:0]  if_instruction,
    input wire [7:0]  if_pc,
    input wire [7:0]  if_pc_plus_1,  // PC + 1 for next instruction
    
    // ==================== ID Stage Inputs ====================
    output reg [7:0]  id_instruction,
    output reg [7:0]  id_pc,
    output reg [7:0]  id_pc_plus_1
);

    // ==================== Pipeline Register Logic ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: Insert NOP
            id_instruction <= 8'h00;  // NOP
            id_pc          <= 8'h00;
            id_pc_plus_1   <= 8'h01;
        end else if (flush) begin
            // Flush: Insert NOP (bubble)
            id_instruction <= 8'h00;  // NOP
            id_pc          <= 8'h00;
            id_pc_plus_1   <= 8'h01;
        end else if (!stall) begin
            // Normal operation: Pass values through
            id_instruction <= if_instruction;
            id_pc          <= if_pc;
            id_pc_plus_1   <= if_pc_plus_1;
        end
        // else: Stall - keep current values (no update)
    end

endmodule
