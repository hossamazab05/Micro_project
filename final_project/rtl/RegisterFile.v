// ============================================================
// RegisterFile.v
// 4 x 8-bit Register File for ELC3030 Processor
// Harvard Architecture - Multi-Cycle FSM Design
// ============================================================
// Features:
// - 4 general purpose registers: R0, R1, R2, R3
// - R3 doubles as Stack Pointer (SP), initialized to 0xFF
// - 2 async read ports, 1 sync write port
// - Write-first forwarding for data hazard resolution
// ============================================================

module RegisterFile (
    // ==================== System Signals ====================
    input wire        clk,           // System clock
    input wire        rst_n,         // Active-low reset
    
    // ==================== Read Port A ====================
    input wire [1:0]  rd_addr_a,     // Read address port A
    output wire [7:0] rd_data_a,     // Read data port A
    
    // ==================== Read Port B ====================
    input wire [1:0]  rd_addr_b,     // Read address port B
    output wire [7:0] rd_data_b,     // Read data port B
    
    // ==================== Write Port ====================
    input wire        wr_en,         // Write enable
    input wire [1:0]  wr_addr,       // Write address
    input wire [7:0]  wr_data,       // Write data
    
    // ==================== Stack Pointer Control ====================
    input wire        sp_en,         // Enable SP update
    input wire        sp_op,         // 0: Decrement (Push), 1: Increment (Pop)
    
    // ==================== Special Outputs ====================
    output wire [7:0] sp_out,        // Stack Pointer (R3) value (Bypassed)
    output wire [7:0] raw_sp         // Stack Pointer (R3) value (Stable)
);

    // ==================== Register Array ====================
    reg [7:0] regs [0:3];

    // ==================== Reset & Write Logic ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regs[0] <= 8'h00;
            regs[1] <= 8'h00;
            regs[2] <= 8'h00;
            regs[3] <= 8'hFF;  // SP default
        end else begin
            if (wr_en) begin
                regs[wr_addr] <= wr_data;
            end
            
            // Handle SP (R3) specific updates for PUSH/POP
            if (sp_en) begin
                // Only update R3 if it's not already being written to by wr_en
                // (e.g. POP R3). If it is, the explicit write takes precedence.
                if (!(wr_en && wr_addr == 2'd3)) begin
                    if (sp_op) regs[3] <= regs[3] + 8'd1; // Increment (POP)
                    else       regs[3] <= regs[3] - 8'd1; // Decrement (PUSH)
                end
            end
        end
    end

    // ==================== Read Logic (Combinational) ====================
    // Stack Pointer forwarding for same-cycle operations:
    // - PUSH (sp_op=0): Return CURRENT SP (write happens before decrement)
    // - POP (sp_op=1): Return CURRENT SP (read happens after increment, which is already in regs[3])
    // The RegisterFile updates regs[3] on the clock edge, so the read port sees the updated value.
    
    // For PUSH, we need the pre-decrement value, but sp_en triggers the update,
    // so we must return the old value: regs[3] (before the update takes effect on next edge)
    // Actually, the sp_en update is synchronous, so combinational reads see the OLD value.
    // But with write-first forwarding, we need to return what WILL be the new value.
    
    // Simplified: Don't forward SP at all for stack operations. Let the pipeline handle it.
    // For POP, the EX stage uses the ID-latched value anyway.
    
    assign rd_data_a = (wr_en && (wr_addr == rd_addr_a)) ? wr_data : regs[rd_addr_a];                       
    assign rd_data_b = (wr_en && (wr_addr == rd_addr_b)) ? wr_data : regs[rd_addr_b];

    // ==================== Stack Pointer Output ====================
    assign sp_out = regs[3];
    assign raw_sp = regs[3];

endmodule
