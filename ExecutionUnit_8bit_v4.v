// ExecutionUnit_8bit_v4_fixed.v
// 8-bit Execution Unit for EL3030 Architecture
// Note: port names aligned to CU outputs: ALU_Ops (3), Flag_Selector (2), FD (2).
// Flags mapping: Flags[3:0] = {V, C, N, Z}  (Flags[3]=V, Flags[2]=C, Flags[1]=N, Flags[0]=Z)

module ExecutionUnit_8bit_v4_fixed(
    /* Inputs From Buffer (ID/EX Register) */
    input IOR, IOW, OPS, ALU, MR, MW, WB, Jmp, SP, SPOP, JWSP, IMM, Stack_PC, Stack_Flags,
    input [1:0] FD,                 // FD: Flag Decision (00,01,10,11)
    input [1:0] Flag_Selector,      // selects which flag for conditional branch (0->Z,1->N,2->C,3->V)
    input [3:0] Opcode,             // Instruction mnemonic (0–14)
    input [2:0] WB_Address, ALU_Ops,     // ALU_Ops: forwarded 3-bit sub-op (used as your SRC_Address)
    input [7:0] Data1, Data2, Immediate_Value,
    input [7:0] Data_From_Forwarding_Unit1, Data_From_Forwarding_Unit2,
    input [1:0] Forwarding_Unit_Selectors,
    input [7:0] INPUT_PORT, OUTPUT_PORT_Input,
    input [7:0] PC_8bit,

    // Flags: Flags[3:0] = {V, C, N, Z}
    input [3:0] Flags, Flags_From_Memory,
    input MEM_Stack_Flags,

    /* Outputs to MEM/WB Buffer */
    output reg MR_Out, MW_Out, WB_Out, JWSP_Out, Stack_PC_Out, Stack_Flags_Out,
    output reg Taken_Jump, To_PC_Selector, SP_Out, SPOP_Out,
    output reg [2:0] WB_Address_Out,
    output reg [3:0] Final_Flags,
    output reg [7:0] OUTPUT_PORT, Data_To_Use,
    output reg [7:0] Data_8bit, Address_8bit
);

    // -- internal regs kept same as before --
    reg [7:0] Operand1, Operand2, Immediate_Or_Register, Data_Or_One;
    reg Temp_CF;
    reg Overflow_V;
    reg [7:0] ALU_Result;
    reg [3:0] Flags_New;    // freshly calculated flags {V,C,N,Z}
    reg [3:0] Flags_Decided;
    reg Jump_On_Which_Flag;

    // Level 1 — operand selection/forwarding (unchanged)
    always @(*) begin
        Operand1 = Forwarding_Unit_Selectors[0] ? Data_From_Forwarding_Unit1 : Data1;
        Immediate_Or_Register = (IMM ? Immediate_Value : Data2);
        Data_Or_One = (Forwarding_Unit_Selectors[1] && !IMM) ?
                      Data_From_Forwarding_Unit2 :
                      Immediate_Or_Register;
        Operand2 = (OPS || Opcode == 4'd10) ? 8'd1 : Data_Or_One;
        OUTPUT_PORT = 8'h00;
    end

    // Level 2 — ALU operations (kept your logic but using ALU_Ops instead of SRC_Address)
    always @(*) begin
        ALU_Result = 8'h00;
        Temp_CF = 1'b0;
        Overflow_V = 1'b0;

        case (Opcode)
            4'd1: begin // MOV - preserve C/V
                ALU_Result = Operand2;
                Temp_CF = Flags[2];
                Overflow_V = Flags[3];
            end
            4'd2: begin // ADD
                {Temp_CF, ALU_Result} = Operand1 + Operand2;
                Overflow_V = (Operand1[7] & Operand2[7] & ~ALU_Result[7]) |
                             (~Operand1[7] & ~Operand2[7] & ALU_Result[7]);
            end
            4'd3: begin // SUB
                {Temp_CF, ALU_Result} = Operand1 - Operand2;
                Overflow_V = (Operand1[7] & ~Operand2[7] & ~ALU_Result[7]) |
                             (~Operand1[7] & Operand2[7] & ALU_Result[7]);
            end
            4'd4: begin // AND
                ALU_Result = Operand1 & Operand2;
                Overflow_V = Flags[3]; Temp_CF = Flags[2];
            end
            4'd5: begin // OR
                ALU_Result = Operand1 | Operand2;
                Overflow_V = Flags[3]; Temp_CF = Flags[2];
            end
            4'd6: begin // RLC / RRC / SETC / CLRC -> use ALU_Ops[1:0] to select variant
                case (ALU_Ops[1:0])
                    2'd0: begin // RLC
                        Temp_CF = Data_Or_One[7];
                        ALU_Result = {Data_Or_One[6:0], Flags[2]};
                    end
                    2'd1: begin // RRC
                        Temp_CF = Data_Or_One[0];
                        ALU_Result = {Flags[2], Data_Or_One[7:1]};
                    end
                    2'd2: begin // SETC
                        Temp_CF = 1'b1; ALU_Result = Data_Or_One;
                    end
                    2'd3: begin // CLRC
                        Temp_CF = 1'b0; ALU_Result = Data_Or_One;
                    end
                    default: ALU_Result = Data_Or_One;
                endcase
                Overflow_V = Flags[3];
            end
            4'd8: begin // NOT/NEG/INC/DEC using ALU_Ops[1:0]
                case (ALU_Ops[1:0])
                    2'd0: begin // NOT
                        ALU_Result = ~Data_Or_One; Temp_CF = Flags[2]; Overflow_V = Flags[3];
                    end
                    2'd1: begin // NEG
                        {Temp_CF, ALU_Result} = 8'd0 - Data_Or_One;
                        Overflow_V = Data_Or_One[7] & ALU_Result[7];
                    end
                    2'd2: begin // INC
                        {Temp_CF, ALU_Result} = Data_Or_One + 8'd1;
                        Overflow_V = (~Data_Or_One[7] & ALU_Result[7]);
                    end
                    2'd3: begin // DEC
                        {Temp_CF, ALU_Result} = Data_Or_One - 8'd1;
                        Overflow_V = (Data_Or_One[7] & ~ALU_Result[7]);
                    end
                endcase
            end
            4'd10: begin // LOOP
                {Temp_CF, ALU_Result} = Operand1 - 8'd1;
                Overflow_V = (Operand1[7] & ~ALU_Result[7]);
            end
            default: begin
                ALU_Result = Operand1;
                Temp_CF = Flags[2];
                Overflow_V = Flags[3];
            end
        endcase

        // Pack NEW flags {V,C,N,Z} where Flags_New[3]=V, [2]=C, [1]=N, [0]=Z
        Flags_New[0] = (ALU_Result == 8'd0); // Z
        Flags_New[1] = ALU_Result[7];       // N
        Flags_New[2] = Temp_CF;             // C
        Flags_New[3] = Overflow_V;          // V
    end

    // Level 3 — Final flags, data selection, jump decision
    always @(*) begin
        Data_To_Use = 8'h00;
        Flags_Decided = 4'b0000;
        Final_Flags = 4'b0000;
        Taken_Jump = 1'b0;
        Address_8bit = 8'h00;
        Data_8bit = 8'h00;
        To_PC_Selector = 1'b0;
        Jump_On_Which_Flag = 1'b0;

        if (MW || IOW)
            Data_To_Use = Operand2;
        else if (IOR && WB)
            Data_To_Use = INPUT_PORT;
        else if (ALU && WB)
            Data_To_Use = ALU_Result;
        else
            Data_To_Use = Operand2;

        case (FD)
            2'b00: Flags_Decided = {Flags[3], 1'b0, Flags[1:0]}; // CLRC: C=0
            2'b01: Flags_Decided = {Flags[3], 1'b1, Flags[1:0]}; // SETC: C=1
            2'b10: Flags_Decided = Flags;                        // preserve
            2'b11: Flags_Decided = Flags_New;                    // new flags
            default: Flags_Decided = Flags;
        endcase

        Final_Flags = MEM_Stack_Flags ? Flags_From_Memory : Flags_Decided;

        // choose which flag to test for jumps: Flag_Selector maps 0->Z,1->N,2->C,3->V
        case (Flag_Selector)
            2'd0: Jump_On_Which_Flag = Final_Flags[0]; // Z
            2'd1: Jump_On_Which_Flag = Final_Flags[1]; // N
            2'd2: Jump_On_Which_Flag = Final_Flags[2]; // C
            2'd3: Jump_On_Which_Flag = Final_Flags[3]; // V
        endcase

        if (Opcode == 4'd10) begin // LOOP
            Taken_Jump = (ALU && (Flags_New[0] == 0));
        end else begin
            Taken_Jump = Jmp && Jump_On_Which_Flag;
        end

        // Memory address selection
        if (MR || MW) begin
            if (Opcode == 4'd12)
                Address_8bit = Operand2;
            else
                Address_8bit = Operand1;
        end else Address_8bit = 8'h00;

        Data_8bit = Data_To_Use;
        To_PC_Selector = Taken_Jump && !JWSP;
        OUTPUT_PORT = (IOW ? Operand2 : 8'h00);

        MR_Out = MR; MW_Out = MW; WB_Out = WB; JWSP_Out = JWSP;
        Stack_PC_Out = Stack_PC; Stack_Flags_Out = Stack_Flags;
        WB_Address_Out = WB_Address; SP_Out = SP; SPOP_Out = SPOP;
    end

endmodule