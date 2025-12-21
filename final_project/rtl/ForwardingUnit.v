// ============================================================
// ForwardingUnit.v
// Standard Data Forwarding for 5-Stage Pipeline
// Resolves RAW Hazards by bypassing Data Memory and Register File
// ============================================================

module ForwardingUnit (
    // Destination Stage (Data needed here)
    input wire [1:0]  ex_rs,         // RS of instruction in EX stage
    input wire [1:0]  ex_rt,         // RT of instruction in EX stage
    
    // Potential Sources (Data available here)
    input wire [1:0]  mem_rd,        // RD of instruction in MEM stage
    input wire        mem_reg_write, // MEM instruction writes to RegFile
    
    input wire [1:0]  wb_rd,         // RD of instruction in WB stage
    input wire        wb_reg_write,  // WB instruction writes to RegFile
    
    // Outputs (Control selects for EX-stage Muxes)
    // 00: Register File
    // 01: From MEM stage (ALU Result)
    // 10: From WB stage (Final Data)
    output reg [1:0]  forward_a,
    output reg [1:0]  forward_b
);

    always @(*) begin
        // Default: Source from Register File
        forward_a = 2'b00;
        forward_b = 2'b00;
        
        // --- Forwarding for Operand RS ---
        
        // MEM Hazard (Highest Priority: Data is in the MEM stage)
        if (mem_reg_write && (mem_rd == ex_rs)) begin
            forward_a = 2'b01;
        end
        // WB Hazard (Lower Priority: Data is in the WB stage)
        else if (wb_reg_write && (wb_rd == ex_rs)) begin
            forward_a = 2'b10;
        end
        
        // --- Forwarding for Operand RT ---
        
        if (mem_reg_write && (mem_rd == ex_rt)) begin
            forward_b = 2'b01;
        end
        else if (wb_reg_write && (wb_rd == ex_rt)) begin
            forward_b = 2'b10;
        end
    end

endmodule
