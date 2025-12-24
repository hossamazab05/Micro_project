// ============================================================
// ControlUnit.v
// Top-Level Pipeline Control Unit with multi-byte instruction support
// Fully compatible with ELC3030 Top-Level Processor
// ============================================================

module ControlUnit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  Instruction,    // From IF_ID (Stable in Decode)
    input  wire [7:0]  if_instruction, // From IF stage bus (Live in Fetch)
    input  wire        stall,          // From Hazard Unit
    input  wire        branch_taken,   // From Execute
    input  wire        mem_branch_taken,// From Memory
    input  wire        INTR_IN,         // From Top-Level
    input  wire [3:0]  CCR,             // Flags for Interrupt handling
    input  wire        Loop_Zero,       // Terminal count signal

    /* -------- Logic Layer Outputs -------- */
    output wire IOR, IOW, OPS, ALU, MR, MW, WB, Jmp, Jump_Conditional,
    output wire SP, SPOP, JWSP, IMM, Stack_PC, Stack_Flags, RS_EN, RT_EN,
    output wire [1:0] FD, Flag_Selector,
    output wire [3:0] Opcode_Out,
    output wire [2:0] WB_Address,
    output wire [2:0] ALU_Ops,
    output wire [1:0] RA_Out,         // Current Ra field
    output wire [1:0] RB_Out,         // Current Rb field
    output wire [7:0] imm_val,        // Buffered/Shadow Operand

    /* -------- State Machine Outputs (Front-end Control) -------- */
    output reg  PC_Write,
    output reg  PC_Src,
    output reg  IR_Write,             // Write enable for IF_ID
    output reg  EX_Write,             // Write enable for ID_EX
    output reg  Fetch_Op2,            // High when fetching operand byte
    output reg [2:0] Current_State
);

    localparam [2:0]
        S_RESET       = 3'b000, 
        S_FETCH       = 3'b001, 
        S_FETCH_OP2   = 3'b010,
        S_EXECUTE_2B  = 3'b011;

    reg [2:0] Next_State;
    reg [7:0] shadow_imm;
    reg [7:0] latched_opcode;

    // ---------------------------------------------------------
    // ASSIGNMENTS
    // ---------------------------------------------------------
    assign imm_val = shadow_imm;
    
    // Ra/Rb fields are always derived from the ACTIVE opcode being decoded
    wire [7:0] active_id_instr = (Current_State == S_EXECUTE_2B) ? latched_opcode : Instruction;
    
    // Corrected Mapping: Stack operations always read R3/SP on Port A
    assign RA_Out = (SP) ? 2'd3 : active_id_instr[3:2];
    assign RB_Out = active_id_instr[1:0];

    // ---------------------------------------------------------
    // FRONTEND LOGIC (High-Agility: uses live if_instruction)
    // ---------------------------------------------------------
    wire [3:0] if_op = if_instruction[7:4];
    
    // FSM State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            Current_State <= S_RESET;
        else if (branch_taken || mem_branch_taken)
            Current_State <= S_FETCH; 
        else if (!stall) 
            Current_State <= Next_State;
    end

    // Sequential Latches
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latched_opcode <= 8'h00;
            shadow_imm     <= 8'h00;
        end else if (!stall) begin
            // Latch Opcode when Opcode 12 is in IF stage
            if ((Current_State == S_FETCH || Current_State == S_EXECUTE_2B) && if_op == 4'd12)
                latched_opcode <= if_instruction;
            // Latch Operand when Operand is in IF stage
            if (Current_State == S_FETCH_OP2)
                shadow_imm <= if_instruction;
        end
    end
    
    // Next State & Frontend Control Logic
    always @(*) begin
        Next_State = Current_State;
        PC_Write = 1; PC_Src = 0; IR_Write = 1; EX_Write = 1; Fetch_Op2 = 0; 
        
        case (Current_State)
            S_RESET: begin
                PC_Write = 1; PC_Src = 0; 
                IR_Write = 1; EX_Write = 0;
                Next_State = S_FETCH;
            end
            
            S_FETCH: begin
                if (if_op == 4'd12) begin 
                    IR_Write = 1;   // Latch Opcode 12 into ID
                    EX_Write = 1;   // Let previous instruction move to EX
                    PC_Write = 1;   // Move PC to Operand
                    Next_State = S_FETCH_OP2;
                end else begin
                    Next_State = S_FETCH;
                end
            end
            
            S_FETCH_OP2: begin
                // In this cycle, Opcode 12 is in ID. Operand is in IF.
                EX_Write = 0;       // Stall Opcode 12 in ID
                IR_Write = 0;       // Don't overwrite ID with Operand
                PC_Write = 1;       // Move PC to Next Instruction
                Next_State = S_EXECUTE_2B;
            end

            S_EXECUTE_2B: begin
                // In this cycle, Operand is in shadow_imm. Next Instr is in IF.
                Fetch_Op2 = 1;      // Signals datapath to use shadow_imm
                EX_Write  = 1;      // Move Opcode (from latch) + Operand (shadow) to EX
                IR_Write  = 1;      // Latch Next Instr into ID
                PC_Write  = 1;      // Correctly move to next-next instruction
                
                // Handle Back-to-Back 2-Byte Instructions
                if (if_op == 4'd12) 
                    Next_State = S_FETCH_OP2;
                else
                    Next_State = S_FETCH;
            end
            
            default: Next_State = S_FETCH;
        endcase
    end

    // ---------------------------------------------------------
    // DECODER CONNECTION
    // ---------------------------------------------------------
    wire [7:0] gated_id_instr  = (rst_n) ? active_id_instr : 8'h00;

    ControlUnit_Decoder comb_cu (
        .Instruction(gated_id_instr),
        .IOR(IOR), .IOW(IOW), .OPS(OPS), .ALU(ALU),
        .MR(MR), .MW(MW), .WB(WB),
        .Jmp(Jmp), .Jump_Conditional(Jump_Conditional),
        .SP(SP), .SPOP(SPOP), .JWSP(JWSP),
        .IMM(IMM), .Stack_PC(Stack_PC), .Stack_Flags(Stack_Flags),
        .RS_EN(RS_EN), .RT_EN(RT_EN),
        .FD(FD), .Flag_Selector(Flag_Selector),
        .pc_inc_val(),
        .Opcode_Out(Opcode_Out),
        .WB_Address(WB_Address),
        .ALU_Ops(ALU_Ops)
    );

endmodule
