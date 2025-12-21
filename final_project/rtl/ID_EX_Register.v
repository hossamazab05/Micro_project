// ============================================================
// ID_EX_Register.v
// Pipeline Register between Decode and Execute
// Supports flush for hazard handling and full control propagation
// ============================================================

module ID_EX_Register (
    // ==================== System Signals ====================
    input wire        clk,
    input wire        rst_n,
    
    // ==================== Hazard Control ====================
    input wire        flush,         // Insert NOP (from HazardDetectionUnit)
    input wire        stall,         // Freeze EX stage (for multi-cycle sync)
    
    // ==================== ID Stage Outputs (Data) ====================
    input wire [7:0]  id_data_a,     // Register read data A
    input wire [7:0]  id_data_b,     // Register read data B
    input wire [7:0]  id_imm,        // Immediate value
    input wire [7:0]  id_pc,         // Current PC
    input wire [7:0]  id_pc_plus_1,  // PC + 1
    
    // ==================== ID Stage Outputs (Register Addresses) ====================
    input wire [1:0]  id_rs,         // Source register 1
    input wire [1:0]  id_rt,         // Source register 2
    input wire [1:0]  id_rd,         // Destination register
    
    // ==================== ID Stage Outputs (Control Signals) ====================
    input wire        id_reg_write,  // Write to register file
    input wire        id_mem_read,   // Read from memory
    input wire        id_mem_write,  // Write to memory
    input wire        id_mem_to_reg, // Select memory data for write-back
    input wire        id_alu_src,    // ALU source: 0=reg, 1=imm
    input wire [3:0]  id_alu_op,     // ALU operation
    input wire [2:0]  id_alu_sub,    // ALU sub-operation 
    input wire        id_branch,     // Branch instruction
    input wire        id_jmp_cond,   // Conditional jump (JZ, etc)
    input wire        id_jump,       // Jump with SP (RET, RTI)
    input wire [1:0]  id_flag_dest,  // Flag destination control (FD)
    input wire [1:0]  id_flag_sel,   // Condition selector for branches
    input wire        id_ior,        // IO Read
    input wire        id_iow,        // IO Write
    input wire        id_ops,        // OPS (Operand selection)
    input wire        id_sp_en,      // SP enable
    input wire        id_sp_op,      // SP operation (0=dec, 1=inc)
    input wire        id_stack_pc,   // Push PC to stack
    input wire        id_stack_flags,// Push flags to stack
    input wire        id_rti,        // RTI instruction detected
    
    // ==================== EX Stage Inputs (Data) ====================
    output reg [7:0]  ex_data_a,
    output reg [7:0]  ex_data_b,
    output reg [7:0]  ex_imm,
    output reg [7:0]  ex_pc,
    output reg [7:0]  ex_pc_plus_1,
    
    // ==================== EX Stage Inputs (Register Addresses) ====================
    output reg [1:0]  ex_rs,
    output reg [1:0]  ex_rt,
    output reg [1:0]  ex_rd,
    
    // ==================== EX Stage Inputs (Control Signals) ====================
    output reg        ex_reg_write,
    output reg        ex_mem_read,
    output reg        ex_mem_write,
    output reg        ex_mem_to_reg,
    output reg        ex_alu_src,
    output reg [3:0]  ex_alu_op,
    output reg [2:0]  ex_alu_sub,
    output reg        ex_branch,
    output reg        ex_jmp_cond,
    output reg        ex_jump,
    output reg [1:0]  ex_flag_dest,
    output reg [1:0]  ex_flag_sel,
    output reg        ex_ior,
    output reg        ex_iow,
    output reg        ex_ops,
    output reg        ex_sp_en,
    output reg        ex_sp_op,
    output reg        ex_stack_pc,
    output reg        ex_stack_flags,
    output reg        ex_rti
);

    // ==================== Pipeline Register Logic ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_data_a      <= 8'h00;
            ex_data_b      <= 8'h00;
            ex_imm         <= 8'h00;
            ex_pc          <= 8'h00;
            ex_pc_plus_1   <= 8'h01;
            ex_rs          <= 2'b00;
            ex_rt          <= 2'b00;
            ex_rd          <= 2'b00;
            ex_reg_write   <= 1'b0;
            ex_mem_read    <= 1'b0;
            ex_mem_write   <= 1'b0;
            ex_mem_to_reg  <= 1'b0;
            ex_alu_src     <= 1'b0;
            ex_alu_op      <= 4'h0;
            ex_alu_sub     <= 3'b000;
            ex_branch      <= 1'b0;
            ex_jmp_cond    <= 1'b0;
            ex_jump        <= 1'b0;
            ex_flag_dest   <= 2'b10;
            ex_flag_sel    <= 2'b00;
            ex_ior         <= 1'b0;
            ex_iow         <= 1'b0;
            ex_ops         <= 1'b0;
            ex_sp_en       <= 1'b0;
            ex_sp_op       <= 1'b0;
            ex_stack_pc    <= 1'b0;
            ex_stack_flags <= 1'b0;
            ex_rti         <= 1'b0;
        end else if (flush) begin
            ex_data_a      <= 8'h00;
            ex_data_b      <= 8'h00;
            ex_imm         <= 8'h00;
            ex_pc          <= 8'h00;
            ex_pc_plus_1   <= 8'h01;
            ex_rs          <= 2'b00;
            ex_rt          <= 2'b00;
            ex_rd          <= 2'b00;
            ex_reg_write   <= 1'b0;
            ex_mem_read    <= 1'b0;
            ex_mem_write   <= 1'b0;
            ex_mem_to_reg  <= 1'b0;
            ex_alu_src     <= 1'b0;
            ex_alu_op      <= 4'h0;
            ex_alu_sub     <= 3'b000;
            ex_branch      <= 1'b0;
            ex_jmp_cond    <= 1'b0;
            ex_jump        <= 1'b0;
            ex_flag_dest   <= 2'b10;
            ex_flag_sel    <= 2'b00;
            ex_ior         <= 1'b0;
            ex_iow         <= 1'b0;
            ex_ops         <= 1'b0;
            ex_sp_en       <= 1'b0;
            ex_sp_op       <= 1'b0;
            ex_stack_pc    <= 1'b0;
            ex_stack_flags <= 1'b0;
            ex_rti         <= 1'b0;
        end else if (!stall) begin
            ex_data_a      <= id_data_a;
            ex_data_b      <= id_data_b;
            ex_imm         <= id_imm;
            ex_pc          <= id_pc;
            ex_pc_plus_1   <= id_pc_plus_1;
            ex_rs          <= id_rs;
            ex_rt          <= id_rt;
            ex_rd          <= id_rd;
            ex_reg_write   <= id_reg_write;
            ex_mem_read    <= id_mem_read;
            ex_mem_write   <= id_mem_write;
            ex_mem_to_reg  <= id_mem_to_reg;
            ex_alu_src     <= id_alu_src;
            ex_alu_op      <= id_alu_op;
            ex_alu_sub     <= id_alu_sub;
            ex_branch      <= id_branch;
            ex_jmp_cond    <= id_jmp_cond;
            ex_jump        <= id_jump;
            ex_flag_dest   <= id_flag_dest;
            ex_flag_sel    <= id_flag_sel;
            ex_ior         <= id_ior;
            ex_iow         <= id_iow;
            ex_ops         <= id_ops;
            ex_sp_en       <= id_sp_en;
            ex_sp_op       <= id_sp_op;
            ex_stack_pc    <= id_stack_pc;
            ex_stack_flags <= id_stack_flags;
            ex_rti         <= id_rti;
        end
    end

endmodule
