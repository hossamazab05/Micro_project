// ============================================================
// ExecutionUnit_8bit_ELC3030_FINAL.v
// Corrected to support Indirect Addressing and ISA Stack Logic
// ============================================================

module ExecutionUnit(
    /* -------- Control Inputs -------- */
    input IOR, IOW, OPS, ALU,
    input MR, MW, WB,
    input Jmp, Jump_Conditional,
    input SP, SPOP, JWSP,
    input IMM,
    input Stack_PC, Stack_Flags,
    input [1:0] FD,
    input [1:0] Flag_Selector,

    /* -------- Instruction Info -------- */
    input [3:0] Opcode,
    input [2:0] ALU_Ops,
    input [2:0] WB_Address,

    /* -------- Data Inputs -------- */
    input [7:0] Data1,        // Typically R[ra]
    input [7:0] Data2,        // Typically R[rb]
    input [7:0] Immediate_Value,
    input [7:0] INPUT_PORT,
    input [7:0] PC_8bit,
    input [7:0] PC_plus_1,     // Pre-computed PC+1 for CALL return address

    /* -------- Flags -------- */
    input [3:0] Flags,
    input [3:0] Flags_From_Memory,
    input MEM_Stack_Flags,

    /* -------- Outputs -------- */
    output reg Taken_Jump,
    output reg To_PC_Selector,
    output reg MR_Out, MW_Out, WB_Out,
    output reg JWSP_Out,
    output reg SP_Out, SPOP_Out,
    output reg Stack_PC_Out, Stack_Flags_Out,
    output reg [2:0] WB_Address_Out,
    output reg [3:0] Final_Flags,
    output reg [7:0] Address_8bit,
    output reg [7:0] Data_8bit,
    output reg [7:0] OUTPUT_PORT,
    output reg [7:0] Branch_Target_Out
);

    /* -------- Internal -------- */
    reg [7:0] ALU_Operand2;
    reg [7:0] ALU_Result;
    reg [3:0] Flags_New;
    reg Jump_Flag_Value;
    reg Carry, Overflow;

    /* =====================================================
       OPERAND SELECTION
       ===================================================== */
    always @(*) begin
        if (OPS) 
            ALU_Operand2 = 8'd1;
        else 
            ALU_Operand2 = IMM ? Immediate_Value : Data2;
    end

    /* =====================================================
       ALU OPERATIONS (Opcodes 1-5, 6, 8, 10)
       ===================================================== */
    always @(*) begin
        ALU_Result = 8'h00;
        Carry = Flags[2];
        Overflow = Flags[3];

        case (Opcode)
            4'd1: begin // MOV
                ALU_Result = ALU_Operand2;
            end
            4'd2: begin // ADD
                {Carry, ALU_Result} = Data1 + ALU_Operand2;
                Overflow = (~(Data1[7] ^ ALU_Operand2[7])) & (Data1[7] ^ ALU_Result[7]);
            end
            4'd3: begin // SUB
                ALU_Result = Data1 - ALU_Operand2;
                Carry = (Data1 >= ALU_Operand2); // C=1 means No Borrow
                Overflow = (Data1[7] ^ ALU_Operand2[7]) & (Data1[7] ^ ALU_Result[7]);
            end
            4'd4: begin // AND
                ALU_Result = Data1 & ALU_Operand2;
            end
            4'd5: begin // OR
                ALU_Result = Data1 | ALU_Operand2;
            end
            4'd6: begin // RLC / RRC / SETC / CLRC
                case (ALU_Ops[1:0])
                    2'd0: begin 
                        ALU_Result = {Data2[6:0], Flags[2]}; Carry = Data2[7]; 
                    end // RLC
                    2'd1: begin 
                        ALU_Result = {Flags[2], Data2[7:1]}; Carry = Data2[0]; 
                    end // RRC
                    2'd2: begin ALU_Result = Data2; Carry = 1'b1; end // SETC
                    2'd3: begin ALU_Result = Data2; Carry = 1'b0; end // CLRC
                endcase
            end
            4'd8: begin // UNARY (NOT, NEG, INC, DEC)
                case (ALU_Ops[1:0])
                    2'd0: ALU_Result = ~Data2; // NOT
                    2'd1: {Carry, ALU_Result} = 8'd0 - Data2; // NEG
                    2'd2: {Carry, ALU_Result} = Data2 + ALU_Operand2; // INC
                    2'd3: {Carry, ALU_Result} = Data2 - ALU_Operand2; // DEC
                endcase
                Overflow = (ALU_Ops[1:0] == 2'd2) ? ((~Data2[7] & ~ALU_Operand2[7] & ALU_Result[7]) | (Data2[7] & ALU_Operand2[7] & ~ALU_Result[7])) :
                           (ALU_Ops[1:0] == 2'd3) ? ((Data2[7] & ~ALU_Operand2[7] & ~ALU_Result[7]) | (~Data2[7] & ALU_Operand2[7] & ALU_Result[7])) : Flags[3];
            end
            4'd10: begin // LOOP
                {Carry, ALU_Result} = Data1 - ALU_Operand2;
                Overflow = (Data1[7] & ~ALU_Operand2[7] & ~ALU_Result[7]) | (~Data1[7] & ALU_Operand2[7] & ALU_Result[7]);
            end
            4'd12: begin // LDM (Load Immediate)
                ALU_Result = ALU_Operand2;
            end
            default: ALU_Result = Data1;
        endcase

        Flags_New = {Overflow, Carry, ALU_Result[7], (ALU_Result == 8'd0)};
    end

    /* =====================================================
       FLAG SELECTION & JUMP LOGIC
       ===================================================== */
    always @(*) begin
        case (FD)
            2'b00:   Final_Flags = {Flags[3], 1'b0, Flags[1:0]}; // CLRC
            2'b01:   Final_Flags = {Flags[3], 1'b1, Flags[1:0]}; // SETC
            2'b11:   Final_Flags = Flags_New;
            default: Final_Flags = Flags; // Preserve (MOV, etc)
        endcase

        if (MEM_Stack_Flags) Final_Flags = Flags_From_Memory;

        // Jump condition evaluation
        case (Flag_Selector)
            2'd0: Jump_Flag_Value = Final_Flags[0]; // Z
            2'd1: Jump_Flag_Value = Final_Flags[1]; // N
            2'd2: Jump_Flag_Value = Final_Flags[2]; // C
            2'd3: Jump_Flag_Value = Final_Flags[3]; // V
        endcase

        if (Opcode == 4'd10 && Jmp) Taken_Jump = (ALU_Result != 8'h00);
        else if (Jmp && !JWSP) Taken_Jump = Jump_Conditional ? Jump_Flag_Value : 1'b1;
        else                 Taken_Jump = 1'b0;

        To_PC_Selector = Taken_Jump & ~JWSP;
    end

    /* =====================================================
       ADDRESS & DATA BUS SELECTION (ISA Corrected)
       ===================================================== */
    always @(*) begin
        // 1. Address Generation
        if (MR || MW) begin
            if (Opcode == 4'd12)       Address_8bit = Immediate_Value; // LDD/STD Direct 
            else if (Opcode >= 4'd13) Address_8bit = Data1;           // LDI/STI Indirect 
            else if (SP || JWSP) begin
                if (SPOP || JWSP) Address_8bit = Data1 + 8'd1; // POP/RET uses incremented SP
                else              Address_8bit = Data1;        // PUSH uses current SP
            end
            else                      Address_8bit = Data1;
        end else begin
            Address_8bit = 8'h00;
        end

        // 2. Data Selection
        if (IOR) begin
            Data_8bit = INPUT_PORT;                           // IN (Highest priority)
        end else if (MW) begin
            if (Stack_PC)          Data_8bit = PC_plus_1;             // CALL: Push Return Addr
            else if (Stack_Flags)  Data_8bit = {4'b0000, Flags};  // Interrupt
            else                   Data_8bit = Data2;             // STD/STI/PUSH
        end else if (IMM) begin
            Data_8bit = Immediate_Value;                          // LDM
        end else if (ALU && WB) begin
            Data_8bit = ALU_Result;
        end else if (MR && Opcode == 4'd11 && JWSP) begin
            Data_8bit = 8'h00; // Value comes from Memory directly to PC
        end else begin
            Data_8bit = ALU_Result;
        end

        // 3. Output Port
        OUTPUT_PORT = IOW ? Data2 : 8'h00;                   // OUT 

        // Control Pass-through
        MR_Out = MR; MW_Out = MW; WB_Out = WB;
        JWSP_Out = JWSP; SP_Out = SP; SPOP_Out = SPOP;
        Stack_PC_Out = Stack_PC; Stack_Flags_Out = Stack_Flags;
        WB_Address_Out = WB_Address;
        
        // Target MUST always be the real register/imm value, regardless of OPS injection 
        Branch_Target_Out = IMM ? Immediate_Value : Data2;
    end

endmodule
