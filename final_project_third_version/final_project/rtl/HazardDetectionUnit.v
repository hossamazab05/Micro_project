// ============================================================
// HazardDetectionUnit.v
// Hazard Detection for ELC3030 Pipelined Processor
// Handles Load-Use Hazards (Stall) and Control Hazards (Flush)
// ============================================================

module HazardDetectionUnit (
    // ==================== Inputs from Pipeline Stages ====================
    // ID Stage (Decode)
    input wire [3:0]  id_opcode,     // Opcode to check for reg usage
    input wire [1:0]  id_rs,         // Source register 1 (ra or rb) muxed
    input wire [1:0]  id_rt,         // Source register 2 (rb) muxed
    input wire        id_rs_en,      // Instruction reads Rs
    input wire        id_rt_en,      // Instruction reads Rt
    
    // EX Stage (Execute)
    input wire [1:0]  ex_rd,         // Destination register
    input wire        ex_mem_read,   // EX stage is doing load (LDD, LDI, POP)
    
    // Control Signals
    input wire        ex_sp_en,      // EX is updating Stack Pointer
    input wire        mem_sp_en,     // MEM is updating Stack Pointer
    input wire        branch_taken,  // Branch/Jump resolution in EX
    input wire        mem_branch_taken, // Branch/Jump was taken in MEM
    input wire [2:0]  current_state, // Current FSM state of Control Unit
    
    // ==================== Outputs to Pipeline Control ====================
    output reg        pc_write,      // Enable PC update (0 = stall)
    output reg        if_id_write,   // Enable IF/ID register write (0 = stall)
    output reg        id_ex_flush,   // Insert NOP into ID/EX (bubble)
    output reg        if_id_flush,   // Flush IF/ID on branch
    output reg        ex_mem_flush   // Flush EX/MEM on MEM-stage jump
);

    // ==================== Hazard Detection Logic ====================
    always @(*) begin
        // ==================== Default: No Hazard ====================
        pc_write     = 1'b1;  // PC updates normally
        if_id_write  = 1'b1;  // IF/ID updates normally
        id_ex_flush  = 1'b0;  // No bubble insertion
        if_id_flush  = 1'b0;  // No flush
        ex_mem_flush = 1'b0;  // No flush
        
        // ==================== Priority 1: Control Hazard (MEM Stage) ====================
        // RET / RTI jump resolved in MEM stage. Flush everything before it.
        if (mem_branch_taken) begin
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
            ex_mem_flush = 1'b1;
        end
        
        // ==================== Priority 2: Control Hazard (EX Stage) ====================
        // Branch / Jump / LOOP resolved in EX stage. Flush IF/ID.
        else if (branch_taken) begin
            if_id_flush = 1'b1;
        end
        
        // ==================== Priority 3: Pipeline Flow Control ====================
        // Control when instructions are allowed to move from Decode to Execute.
        // Single-cycle: allowed in S_FETCH (state 1)
        // Two-cycle: allowed in S_FETCH_OP2 (state 2)
        // Default: flush ID_EX (insert bubble)
        if (!((current_state == 3'b001 && id_opcode != 4'd12) || 
              (current_state == 3'b011 && id_opcode == 4'd12))) begin
            id_ex_flush = 1'b1;
        end
        
        // ==================== Priority 4: Load-Use Hazard ====================
        // Condition: Instruction in EX is a load AND
        //            Instruction in ID needs the loaded value
        // Action: Stall pipeline for 1 cycle
        else if (ex_mem_read) begin
            if ((id_rs_en && (ex_rd == id_rs)) || (id_rt_en && (ex_rd == id_rt))) begin
                pc_write    = 1'b0;  // Freeze PC (don't fetch next)
                if_id_write = 1'b0;  // Freeze IF/ID (keep current instruction)
                id_ex_flush = 1'b1;  // Insert NOP into ID_EX (bubble)
            end
        end
    end

endmodule
