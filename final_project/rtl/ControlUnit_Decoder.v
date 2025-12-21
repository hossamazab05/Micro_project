// ============================================================
// ControlUnit_Decoder.v
// Combinational Instruction Decoder for ELC 3030
// Generates control signals based on 8-bit instruction opcode and fields
// ============================================================

module ControlUnit_Decoder (
    input  [7:0] Instruction,

    /* -------- Control Outputs -------- */
    output reg IOR, IOW,           // I/O Read/Write
    output reg OPS,                // Data Bus Source (0: Reg, 1: PC/Flags)
    output reg ALU,                // ALU Enable
    output reg MR, MW,             // Memory Read/Write
    output reg WB,                 // Register Write Back
    output reg Jmp,                // Jump Enable
    output reg Jump_Conditional,   // 1 for JZ, JN, JC, JV
    output reg SP, SPOP,           // Stack Pointer Enable and Direction
    output reg JWSP,               // Jump to value from Stack (RET/RTI)
    output reg IMM, Stack_PC, Stack_Flags,
    output reg RS_EN, RT_EN,
    output reg [1:0] FD, Flag_Selector,
    // Select Z, N, C, or V for Jumps
    output reg pc_inc_val,         // PC Increment: 0 for +1, 1 for +2
    output reg [3:0] Opcode_Out,   // To Execution Unit
    output reg [2:0] WB_Address,   // To Register File (Destination)
    output reg [2:0] ALU_Ops       // To ALU (Sub-operation)
);

    /* -------- Instruction Fields (ISA Manual Page 2) -------- */
    // Opcode: [7:4], ra: [3:2], rb: [1:0]
    wire [3:0] Mnemonic = Instruction[7:4];
    wire [1:0] ra       = Instruction[3:2]; 
    wire [1:0] rb       = Instruction[1:0];

    always @(*) begin
        /* =====================================================
           DEFAULT SETTINGS
           ===================================================== */
        IOR = 0; IOW = 0; OPS = 0; ALU = 0;
        MR  = 0; MW  = 0; WB  = 0;
        Jmp = 0; Jump_Conditional = 0;
        SP  = 0; SPOP = 0; JWSP = 0;
        IMM = 0; Stack_PC = 0; Stack_Flags = 0;
        pc_inc_val = 0;             // Default to 1-byte instruction
        FD = 2'b10;                 // Default: Preserve flags
        Flag_Selector = 2'd0;
         
        Opcode_Out = Mnemonic;  
        WB_Address = {1'b0, ra};    // Destination is usually ra
        ALU_Ops    = {1'b0, rb};    // Source is usually rb
        RS_EN = 0; RT_EN = 0;

        case (Mnemonic)

            // Special: NOP (Opcode 0)
            4'd0: begin
                // No control signals are active; PC increments normally.
            end

            // A-Format: MOV, ADD, SUB, AND, OR (Opcodes 1-5)
            4'd1, 4'd2, 4'd3, 4'd4, 4'd5: begin
                ALU = 1; WB = 1;
                FD  = (Mnemonic == 4'd1) ? 2'b10 : 2'b11; // MOV doesn't change flags
                RS_EN = (Mnemonic != 4'd1); // MOV only reads RT
                RT_EN = 1;
            end

            4'd6: begin // Rotation (RLC, RRC) & Flag (SETC, CLRC)
                ALU = 1; WB = 1;
                ALU_Ops = {1'b0, ra}; // Sub-op defined by ra
                WB_Address = {1'b0, rb}; // Result returns to rb
                case (ra)
                    2'd2: FD = 2'b01; // SETC
                    2'd3: FD = 2'b00; // CLRC
                    default: FD = 2'b11; // RLC/RRC update flags
                endcase
                RT_EN = 1; // All shifts/rot reads rb
            end

            // A-Format: Stack/IO (PUSH, POP, OUT, IN) (Opcode 7)
            4'd7: begin
                case (ra)
                    2'd0: begin SP=1; MW=1; RS_EN=1; RT_EN=1; end // PUSH R[rb]
                    2'd1: begin SP=1; MR=1; WB=1; SPOP=1; RS_EN=1; // POP R[rb]
                                WB_Address = {1'b0, rb}; end
                    2'd2: begin IOW=1; RT_EN=1; ALU_Ops=3'd2; end   // OUT R[rb]
                    2'd3: begin IOR=1; WB=1;                    // IN R[rb]
                                WB_Address = {1'b0, rb}; end
                endcase
            end

            // A-Format: Unary (NOT, NEG, INC, DEC) (Opcode 8)
            4'd8: begin
                ALU = 1; WB = 1; FD = 2'b11; RT_EN = 1;
                ALU_Ops = {1'b0, ra}; 
                WB_Address = {1'b0, rb}; 
            end

            // B-Format: Conditional Jumps (JZ, JN, JC, JV) (Opcode 9)
            4'd9: begin
                Jmp = 1;
                Jump_Conditional = 1;
                Flag_Selector = ra; 
                RT_EN = 1; // Read jump target rb
            end

            // B-Format: LOOP (Opcode 10)
            4'd10: begin
                ALU = 1; WB = 1; Jmp = 1; FD = 2'b11;
                RS_EN = 1; RT_EN = 1; 
            end

            // B-Format: JMP, CALL, RET, RTI (Opcode 11)
            4'd11: begin
                RT_EN = 1; // All read target rb
                case (ra)
                    2'd0: Jmp = 1; // JMP Unconditional
                    2'd1: begin Jmp=1; MW=1; SP=1; Stack_PC=1; OPS=1; RS_EN=1; end // CALL
                    2'd2: begin Jmp=1; MR=1; SP=1; SPOP=1; JWSP=1; RS_EN=1; end    // RET
                    2'd3: begin Jmp=1; MR=1; SP=1; SPOP=1; JWSP=1; Stack_Flags=1; end // RTI
                endcase
            end

            // L-Format: LDM, LDD, STD (Opcode 12) - 2-BYTE INSTRUCTIONS
            4'd12: begin
                pc_inc_val = 1; 
                IMM = 1;        
                case (ra)
                    2'd0: begin WB=1; WB_Address = {1'b0, rb}; end // LDM R[rb]
                    2'd1: begin MR=1; WB=1; WB_Address = {1'b0, rb}; end // LDD R[rb]
                    2'd2: begin MW=1; RT_EN=1; end                        // STD reads RB
                endcase
            end

            // L-Format: LDI (Opcode 13) - Indirect Load
            4'd13: begin
                MR = 1; WB = 1; WB_Address = {1'b0, rb};
                RS_EN = 1; // Ra as address
            end

            // L-Format: STI (Opcode 14) - Indirect Store
            4'd14: begin
                MW = 1;
                RS_EN = 1; RT_EN = 1; // Ra as address, Rb as data
            end

            default: ; 
        endcase
    end
endmodule
