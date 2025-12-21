// ============================================================
// InterruptController.v
// Handles external interrupts and restoration sequence (RTI)
// ============================================================

module InterruptController (
    input wire        clk,
    input wire        rst_n,
    input wire        intr_in,          // External interrupt signal
    input wire        rti_instruction,  // RTI instruction detected in ID
    
    // Processor State for Saving
    input wire [7:0]  current_pc,       // PC to save (from ID)
    input wire [3:0]  current_ccr,      // CCR to save
    input wire [7:0]  current_sp,       // Current SP val (from RegFile)
    
    // Memory Interface (for saving/restoring)
    input wire [7:0]  mem_data_in,      // Data from memory for POP
    output reg [7:0]  mem_addr,         // Address for PUSH/POP
    output reg        mem_read_enable,  // Read EN for POP
    output reg        stack_push_enable,// Write EN for PUSH
    output reg [7:0]  stack_data_out,   // Data to write for PUSH
    
    // Stack Pointer Control (passed back to RegFile)
    output reg        sp_dec_enable,    // Decrement SP
    output reg        stack_pop_enable, // (Logical) POP operation
    output reg        sp_inc_enable,    // Increment SP
    
    // Processor Pipeline Control
    output reg        load_pc_enable,   // Force jump to ISR or Restore
    output reg [7:0]  new_pc_value,     // ISR address or Popped PC
    output reg        load_ccr_enable,  // Enable restore of CCR
    output reg [3:0]  saved_ccr,        // CCR value to restore
    output reg        pipeline_flush,   // Flush entire pipeline
    output reg        interrupt_active, // Hardware is in control
    output reg        stall_pipeline,   // Freeze pipeline during sequence
    
    // Debug
    output wire [3:0] current_state_out
);

    // ==================== FSM States ====================
    localparam S_IDLE        = 4'd0;
    localparam S_SAVE_PC     = 4'd1;  // Push PC to stack
    localparam S_SAVE_PC_WAIT = 4'd2;
    localparam S_SAVE_CCR    = 4'd3;  // Push CCR to stack
    localparam S_SAVE_CCR_WAIT = 4'd4;
    localparam S_READ_VECTOR = 4'd5;  // Read ISR address from M[1]
    localparam S_READ_WAIT   = 4'd6;
    localparam S_LOAD_ISR_PC = 4'd7;  // Force PC to ISR address
    
    localparam S_RTI_POP_CCR = 4'd8;  // POP CCR
    localparam S_RTI_CCR_WAIT = 4'd9;
    localparam S_RTI_POP_PC  = 4'd10; // POP PC
    localparam S_RTI_PC_WAIT  = 4'd11;
    localparam S_RTI_RESTORE = 4'd12; // Final restoration jump

    reg [3:0] current_state, next_state;
    reg [7:0] saved_pc_reg;
    reg [3:0] saved_ccr_reg;
    reg [7:0] isr_address;
    reg [7:0] popped_pc;
    reg [7:0] popped_ccr_temp;
    reg       intr_in_q; // Last cycle state

    assign current_state_out = current_state;

    // ==================== State Transition ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= S_IDLE;
            saved_pc_reg  <= 8'h00;
            saved_ccr_reg <= 4'h0;
            isr_address   <= 8'h00;
            popped_pc     <= 8'h00;
            popped_ccr_temp <= 8'h00;
            intr_in_q     <= 1'b0;
        end else begin
            current_state <= next_state;
            intr_in_q     <= intr_in;
            
            // Capture state on entry
            if (current_state == S_IDLE && (intr_in && !intr_in_q)) begin
                saved_pc_reg  <= current_pc;
                saved_ccr_reg <= current_ccr;
            end
            
            // Capture data from memory
            if (current_state == S_READ_WAIT) begin
                isr_address <= mem_data_in;
            end
            if (current_state == S_RTI_CCR_WAIT) begin
                popped_ccr_temp <= mem_data_in;
            end
            if (current_state == S_RTI_PC_WAIT) begin
                popped_pc <= mem_data_in;
            end
        end
    end

    // ==================== Next State Logic ====================
    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_IDLE: begin
                if (intr_in && !intr_in_q) next_state = S_SAVE_PC;
                else if (rti_instruction) next_state = S_RTI_POP_CCR;
            end
            
            S_SAVE_PC:      next_state = S_SAVE_PC_WAIT;
            S_SAVE_PC_WAIT: next_state = S_SAVE_CCR;
            S_SAVE_CCR:     next_state = S_SAVE_CCR_WAIT;
            S_SAVE_CCR_WAIT:next_state = S_READ_VECTOR;
            S_READ_VECTOR:  next_state = S_READ_WAIT;
            S_READ_WAIT:    next_state = S_LOAD_ISR_PC;
            S_LOAD_ISR_PC:  next_state = S_IDLE;
            
            S_RTI_POP_CCR:  next_state = S_RTI_CCR_WAIT;
            S_RTI_CCR_WAIT: next_state = S_RTI_POP_PC;
            S_RTI_POP_PC:   next_state = S_RTI_PC_WAIT;
            S_RTI_PC_WAIT:  next_state = S_RTI_RESTORE;
            S_RTI_RESTORE:  next_state = S_IDLE;
            
            default: next_state = S_IDLE;
        endcase
    end

    // ==================== Output Logic ====================
    always @(*) begin
        // Defaults
        mem_addr          = 8'h00;
        mem_read_enable   = 1'b0;
        stack_push_enable = 1'b0;
        stack_data_out    = 8'h00;
        sp_dec_enable     = 1'b0;
        stack_pop_enable  = 1'b0;
        sp_inc_enable     = 1'b0;
        load_pc_enable    = 1'b0;
        new_pc_value      = 8'h00;
        load_ccr_enable   = 1'b0;
        saved_ccr         = 4'h0;
        pipeline_flush    = 1'b0;
        interrupt_active  = 1'b1;
        stall_pipeline    = 1'b0;

        case (current_state)
            S_IDLE: begin
                interrupt_active = 1'b0;
                stall_pipeline   = 1'b0;
            end
            
            S_SAVE_PC: begin
                mem_addr          = current_sp;
                stack_push_enable = 1'b1;
                stack_data_out    = saved_pc_reg;
                sp_dec_enable     = 1'b1;
                pipeline_flush    = 1'b1;
                interrupt_active  = 1'b1;
                stall_pipeline    = 1'b1;
            end
            
            S_SAVE_PC_WAIT: begin
                interrupt_active = 1'b1;
                stall_pipeline   = 1'b1;
            end
            
            S_SAVE_CCR: begin
                mem_addr          = current_sp;
                stack_push_enable = 1'b1;
                stack_data_out    = {4'h0, saved_ccr_reg};
                sp_dec_enable     = 1'b1;
                interrupt_active  = 1'b1;
                stall_pipeline    = 1'b1;
            end
            
            S_SAVE_CCR_WAIT: begin
                interrupt_active = 1'b1;
                stall_pipeline   = 1'b1;
            end
            
            S_READ_VECTOR: begin
                mem_addr         = 8'h01;
                mem_read_enable  = 1'b1;
                interrupt_active = 1'b1;
                stall_pipeline   = 1'b1;
            end
            
            S_READ_WAIT: begin
                mem_addr         = 8'h01;
                mem_read_enable  = 1'b1;
                interrupt_active = 1'b1;
                stall_pipeline   = 1'b1;
            end
            
            S_LOAD_ISR_PC: begin
                load_pc_enable   = 1'b1;
                new_pc_value     = isr_address;
                pipeline_flush   = 1'b1;
                interrupt_active = 1'b1;
                stall_pipeline   = 1'b1;
            end
            
            S_RTI_POP_CCR: begin
                mem_addr         = current_sp + 8'd1; // Correct POP address
                mem_read_enable  = 1'b1;
                stack_pop_enable = 1'b1;
                sp_inc_enable    = 1'b1;
                stall_pipeline   = 1'b1;
            end
            
            S_RTI_CCR_WAIT: begin
                mem_addr         = current_sp; // Stable address from previous cycle
                mem_read_enable  = 1'b1;
                stall_pipeline   = 1'b1;
            end
            
            S_RTI_POP_PC: begin
                mem_addr         = current_sp + 8'd1; // Correct POP address
                mem_read_enable  = 1'b1;
                stack_pop_enable = 1'b1;
                sp_inc_enable    = 1'b1;
                stall_pipeline   = 1'b1;
            end
            
            S_RTI_PC_WAIT: begin
                mem_addr         = current_sp; 
                mem_read_enable  = 1'b1;
                stall_pipeline   = 1'b1;
            end
            
            S_RTI_RESTORE: begin
                load_pc_enable  = 1'b1;
                new_pc_value    = popped_pc;
                load_ccr_enable = 1'b1;
                saved_ccr       = popped_ccr_temp[3:0];
                pipeline_flush  = 1'b1;
                stall_pipeline  = 1'b1;
            end
            
            default: begin
                interrupt_active = 1'b0;
                stall_pipeline   = 1'b0;
            end
        endcase
    end

endmodule
