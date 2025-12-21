// ============================================================
// EX_MEM_Register.v
// Pipeline Register between Execute and Memory
// Supports all control signals for memory and stack operations
// ============================================================

module EX_MEM_Register (
    // ==================== System Signals ====================
    input wire        clk,
    input wire        rst_n,
    input wire        flush,
    input wire        stall,
    
    // ==================== EX Stage Outputs (Data) ====================
    input wire [7:0]  ex_alu_result, // ALU computation result (for WB)
    input wire [7:0]  ex_mem_addr,   // Memory address (from Execution Unit)
    input wire [7:0]  ex_data_b,     // Data for store operations
    input wire [7:0]  ex_pc_plus_1,  // PC + 1 (for CALL)
    input wire [3:0]  ex_flags,      // Updated flags from ALU
    
    // ==================== EX Stage Outputs (Control) ====================
    input wire [1:0]  ex_rd,         // Destination register
    input wire        ex_reg_write,  // Write to register file
    input wire        ex_mem_read,   // Read from memory
    input wire        ex_mem_write,  // Write to memory
    input wire        ex_mem_to_reg, // Select memory data for WB
    input wire        ex_branch_taken, // Branch was taken
    input wire [7:0]  ex_branch_target, // Branch target address
    input wire [1:0]  ex_flag_dest,  // Flag destination control
    input wire        ex_sp_en,      // SP operation in MEM stage
    input wire        ex_sp_op,      // Increment/Decrement
    input wire        ex_stack_pc,   // Push PC
    input wire        ex_stack_flags,// Push flags
    input wire        ex_jwsp,       // Jump with Stack Pointer (RET/RTI)
    input wire        ex_rti,
    
    // ==================== MEM Stage Inputs (Data) ====================
    output reg [7:0]  mem_alu_result,
    output reg [7:0]  mem_mem_addr,
    output reg [7:0]  mem_data_b,
    output reg [7:0]  mem_pc_plus_1,
    output reg [3:0]  mem_flags,
    
    // ==================== MEM Stage Inputs (Control) ====================
    output reg [1:0]  mem_rd,
    output reg        mem_reg_write,
    output reg        mem_mem_read,
    output reg        mem_mem_write,
    output reg        mem_mem_to_reg,
    output reg        mem_branch_taken,
    output reg [7:0]  mem_branch_target,
    output reg [1:0]  mem_flag_dest,
    output reg        mem_sp_en,
    output reg        mem_sp_op,
    output reg        mem_stack_pc,
    output reg        mem_stack_flags,
    output reg        mem_jwsp,
    output reg        mem_rti
);

    // ==================== Pipeline Register Logic ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_alu_result    <= 8'h00;
            mem_mem_addr      <= 8'h00;
            mem_data_b        <= 8'h00;
            mem_pc_plus_1     <= 8'h01;
            mem_flags         <= 4'h0;
            mem_rd            <= 2'b00;
            mem_reg_write     <= 1'b0;
            mem_mem_read      <= 1'b0;
            mem_mem_write     <= 1'b0;
            mem_mem_to_reg    <= 1'b0;
            mem_branch_taken  <= 1'b0;
            mem_branch_target <= 8'h00;
            mem_flag_dest     <= 2'b10;
            mem_sp_en         <= 1'b0;
            mem_sp_op         <= 1'b0;
            mem_stack_pc      <= 1'b0;
            mem_stack_flags   <= 1'b0;
            mem_jwsp          <= 1'b0;
            mem_rti           <= 1'b0;
        end else if (flush) begin
            mem_alu_result    <= 8'h00;
            mem_mem_addr      <= 8'h00;
            mem_data_b        <= 8'h00;
            mem_pc_plus_1     <= 8'h01;
            mem_flags         <= 4'h0;
            mem_rd            <= 2'b00;
            mem_reg_write     <= 1'b0;
            mem_mem_read      <= 1'b0;
            mem_mem_write     <= 1'b0;
            mem_mem_to_reg    <= 1'b0;
            mem_branch_taken  <= 1'b0;
            mem_branch_target <= 8'h00;
            mem_flag_dest     <= 2'b10;
            mem_sp_en         <= 1'b0;
            mem_sp_op         <= 1'b0;
            mem_stack_pc      <= 1'b0;
            mem_stack_flags   <= 1'b0;
            mem_jwsp          <= 1'b0;
            mem_rti           <= 1'b0;
        end else if (!stall) begin
            mem_alu_result    <= ex_alu_result;
            mem_mem_addr      <= ex_mem_addr;
            mem_data_b        <= ex_data_b;
            mem_pc_plus_1     <= ex_pc_plus_1;
            mem_flags         <= ex_flags;
            mem_rd            <= ex_rd;
            mem_reg_write     <= ex_reg_write;
            mem_mem_read      <= ex_mem_read;
            mem_mem_write     <= ex_mem_write;
            mem_mem_to_reg    <= ex_mem_to_reg;
            mem_branch_taken  <= ex_branch_taken;
            mem_branch_target <= ex_branch_target;
            mem_flag_dest     <= ex_flag_dest;
            mem_sp_en         <= ex_sp_en;
            mem_sp_op         <= ex_sp_op;
            mem_stack_pc      <= ex_stack_pc;
            mem_stack_flags   <= ex_stack_flags;
            mem_jwsp          <= ex_jwsp;
            mem_rti           <= ex_rti;
        end
    end

endmodule
