// ============================================================
// InstructionMemory.v - ABSOLUTE SPARSE ISA SUITE (v9)
// ============================================================
module InstructionMemory (
    input wire clk, rst_n, mem_read,
    input wire [7:0] addr,
    output reg [7:0] data_out
);
    always @(*) begin
        case (addr)
            8'h00: data_out = 8'h10; // Reset Vector Destination
            8'h01: data_out = 8'hE0; // Interrupt Vector (Points to ISR)
            
            // --- BLOCK 1: DATA (10 - 2F) ---
            8'h10: data_out = 8'hC1; // LDM R1, 42
            8'h11: data_out = 8'h42;
            8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17, 8'h18, 8'h19: data_out = 8'h00; // Buffer
            8'h1A: data_out = 8'h19; // MOV R2, R1
            8'h1B, 8'h1C, 8'h1D, 8'h1E, 8'h1F: data_out = 8'h00;
            8'h20: data_out = 8'h7D; // IN R1
            8'h21, 8'h22, 8'h23, 8'h24, 8'h25: data_out = 8'h00;
            8'h26: data_out = 8'h79; // OUT R1
            8'h27, 8'h28, 8'h29, 8'h2A, 8'h2B, 8'h2C, 8'h2D, 8'h2E, 8'h2F: data_out = 8'h00;

            // --- BLOCK 2: JUMPS (30 - 5F) ---
            8'h30: data_out = 8'h68; // SETC
            8'h31, 8'h32, 8'h33: data_out = 8'h00;
            8'h34: data_out = 8'hC0; // Target 3A
            8'h35: data_out = 8'h3A;
            8'h36, 8'h37, 8'h38: data_out = 8'h00;
            8'h39: data_out = 8'h98; // JC R0 -> 3A
            
            8'h3A: data_out = 8'h6C; // CLRC
            8'h3B, 8'h3C, 8'h3D: data_out = 8'h00;
            8'h3E: data_out = 8'hC0; // Target 44
            8'h3F: data_out = 8'h44;
            8'h40, 8'h41, 8'h42: data_out = 8'h00;
            8'h43: data_out = 8'h90; // JZ R0 -> 44 (via 35 SUB R1,R1 prev)
            
            8'h44: data_out = 8'hC1; // R1=80 (N=1)
            8'h45: data_out = 8'h80;
            8'h46, 8'h47, 8'h48: data_out = 8'h00;
            8'h49: data_out = 8'h41; // AND R1,R1
            8'h4A: data_out = 8'hC0; // Target 50
            8'h4B: data_out = 8'h50;
            8'h4C, 8'h4D, 8'h4E: data_out = 8'h00;
            8'h4F: data_out = 8'h94; // JN R0 -> 50
            
            8'h50: data_out = 8'hC1; // R1=7F
            8'h51: data_out = 8'h7F;
            8'h52, 8'h53, 8'h54: data_out = 8'h00;
            8'h55: data_out = 8'h85; // INC R1 (80, V=1)
            8'h56: data_out = 8'hC0; // Target 5C
            8'h57: data_out = 8'h5C;
            8'h58, 8'h59, 8'h5A: data_out = 8'h00;
            8'h5B: data_out = 8'h9C; // JV R0 -> 5C
            8'h5C: data_out = 8'h00; 

            // --- BLOCK 3: ALU (60 - 8F) ---
            8'h60: data_out = 8'hC1; // R1=5
            8'h61: data_out = 8'h05;
            8'h62: data_out = 8'h00; 
            8'h63: data_out = 8'h25; // ADD R1,R1 (A)
            8'h64: data_out = 8'h55; // OR R1,R1
            8'h65: data_out = 8'h45; // AND R1,R1
            8'h66: data_out = 8'h35; // SUB R1,R1 (0)
            8'h67: data_out = 8'h89; // INC R1 (1)
            8'h68: data_out = 8'hC1; // R1=5
            8'h69: data_out = 8'h05;
            8'h6A, 8'h6B: data_out = 8'h00;
            8'h6C: data_out = 8'h8D; // DEC R1 (4)
            8'h6D: data_out = 8'h85; // NEG R1 (FC)
            8'h6E: data_out = 8'h81; // NOT R1 (03)
            8'h6F: data_out = 8'h61; // RLC R1
            8'h70: data_out = 8'h65; // RRC R1
            8'h71, 8'h72, 8'h73, 8'h74, 8'h75, 8'h76, 8'h77, 8'h78, 8'h79, 8'h7A, 8'h7B, 8'h7C, 8'h7D, 8'h7E, 8'h7F: data_out = 8'h00;

            // --- BLOCK 4: STACK (90 - AF) ---
            8'h90: data_out = 8'hC1; // R1=B7
            8'h91: data_out = 8'hB7;
            8'h92, 8'h93: data_out = 8'h00;
            8'h94: data_out = 8'h71; // PUSH R1
            8'h95, 8'h96: data_out = 8'h00;
            8'h97: data_out = 8'hC0; // Target F0
            8'h98: data_out = 8'hF0;
            8'h99, 8'h9A: data_out = 8'h00;
            8'h9B: data_out = 8'hB4; // CALL R0 -> F0
            8'h9C, 8'h9D, 8'h9E, 8'h9F: data_out = 8'h00;
            8'hA0: data_out = 8'h76; // POP R2 (should be B7)
            8'hA1, 8'hA2, 8'hA3, 8'hA4, 8'hA5, 8'hA6, 8'hA7, 8'hA8, 8'hA9, 8'hAA, 8'hAB, 8'hAC, 8'hAD, 8'hAE, 8'hAF: data_out = 8'h00;

            // --- BLOCK 5: MEMORY (B0 - CF) ---
            8'hB0: data_out = 8'hC1; // R1=01
            8'hB1: data_out = 8'h01;
            8'hB2, 8'hB3: data_out = 8'h00;
            8'hB4: data_out = 8'hD6; // LDI R2, R1
            8'hB5, 8'hB6: data_out = 8'h00;
            8'hB7: data_out = 8'hC1; // R1=A5
            8'hB8: data_out = 8'hA5;
            8'hB9, 8'hBA: data_out = 8'h00;
            8'hBB: data_out = 8'hC2; // R2=1F
            8'hBC: data_out = 8'h1F;
            8'hBD, 8'hBE: data_out = 8'h00;
            8'hBF: data_out = 8'hE9; // STI R1, R2
            8'hC0, 8'hC1, 8'hC2, 8'hC3: data_out = 8'h00;
            8'hC4: data_out = 8'hC0; // R0=1F
            8'hC5: data_out = 8'h1F;
            8'hC6, 8'hC7: data_out = 8'h00;
            8'hC8: data_out = 8'hD1; // LDI R1, R0
            8'hc9, 8'hCA, 8'hCB, 8'hCC, 8'hCD, 8'hCE, 8'hCF: data_out = 8'h00;

            // --- BLOCK 6: LOOPS (D0 - EF) --- (Gap increased)
            8'hD0: data_out = 8'hC1; // R1=2
            8'hD1: data_out = 8'h02;
            8'hD2, 8'hD3: data_out = 8'h00;
            8'hD4: data_out = 8'hC0; // Target D6
            8'hD5: data_out = 8'hD6;
            8'hD6: data_out = 8'hA4; // LOOP R1, R0 (Counter R1, Target R0)
            8'hD7, 8'hD8, 8'hD9: data_out = 8'h00;
            8'hDA: data_out = 8'hC0; // target FF
            8'hDB: data_out = 8'hFF;
            8'hDC: data_out = 8'hB0; // JMP R0
            8'hDD, 8'hDE, 8'hDF, 8'hE0, 8'hE1, 8'hE2, 8'hE3, 8'hE4, 8'hE5, 8'hE6, 8'hE7, 8'hE8, 8'hE9, 8'hEA, 8'hEB, 8'hEC, 8'hED, 8'hEE, 8'hEF: data_out = 8'h00;

            // --- SUBROUTINES ---
            8'hF0: data_out = 8'hC2; // R2=AA
            8'hF1: data_out = 8'hAA;
            8'hF2: data_out = 8'hB8; // RET
            
            8'hFF: data_out = 8'hB0; // SPIN
            
            // --- ISR ---
            8'hE0: data_out = 8'hBC; // RTI

            default: data_out = 8'h00;
        endcase
    end
endmodule
