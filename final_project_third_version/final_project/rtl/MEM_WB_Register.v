// ============================================================
// MEM_WB_Register.v
// Pipeline Register between Memory and Write-Back
// ============================================================

module MEM_WB_Register (
    // ==================== System Signals ====================
    input wire        clk,
    input wire        rst_n,
    input wire        stall,
    input wire        flush,
    
    // ==================== MEM Stage Outputs (Data) ====================
    input wire [7:0]  mem_alu_result, // ALU result (for ALU instructions)
    input wire [7:0]  mem_data,       // Data from memory (for loads)
    input wire [3:0]  mem_flags,      // Flags to update
    
    // ==================== MEM Stage Outputs (Control) ====================
    input wire [1:0]  mem_rd,         // Destination register
    input wire        mem_reg_write,  // Write to register file
    input wire        mem_mem_to_reg, // Select memory data vs ALU result
    input wire        mem_sp_en,      // SP operation 
    input wire        mem_sp_op,      // Increment/Decrement
    input wire [1:0]  mem_flag_dest,  // Flag destination control
    
    // ==================== WB Stage Inputs (Data) ====================
    output reg [7:0]  wb_alu_result,
    output reg [7:0]  wb_mem_data,
    output reg [3:0]  wb_flags,
    
    // ==================== WB Stage Inputs (Control) ====================
    output reg [1:0]  wb_rd,
    output reg        wb_reg_write,
    output reg        wb_mem_to_reg,
    output reg        wb_sp_en,
    output reg        wb_sp_op,
    output reg [1:0]  wb_flag_dest
);

    // ==================== Pipeline Register Logic ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: Clear all signals
            wb_alu_result  <= 8'h00;
            wb_mem_data    <= 8'h00;
            wb_flags       <= 4'h0;
            wb_rd          <= 2'b00;
            wb_reg_write   <= 1'b0;
            wb_mem_to_reg  <= 1'b0;
            wb_sp_en       <= 1'b0;
            wb_sp_op       <= 1'b0;
            wb_flag_dest   <= 2'b10;
        end else if (flush) begin
            wb_alu_result  <= 8'h00;
            wb_mem_data    <= 8'h00;
            wb_flags       <= 4'h0;
            wb_rd          <= 2'b00;
            wb_reg_write   <= 1'b0;
            wb_mem_to_reg  <= 1'b0;
            wb_sp_en       <= 1'b0;
            wb_sp_op       <= 1'b0;
            wb_flag_dest   <= 2'b10;
        end else if (!stall) begin
            // Normal operation: Pass all signals through
            wb_alu_result  <= mem_alu_result;
            wb_mem_data    <= mem_data;
            wb_flags       <= mem_flags;
            wb_rd          <= mem_rd;
            wb_reg_write   <= mem_reg_write;
            wb_mem_to_reg  <= mem_mem_to_reg;
            wb_sp_en       <= mem_sp_en;
            wb_sp_op       <= mem_sp_op;
            wb_flag_dest   <= mem_flag_dest;
        end
    end

endmodule
