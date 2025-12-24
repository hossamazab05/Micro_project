// ============================================================
// CCR.v (StatusRegister)
// Condition Code Register for ELC3030 Processor
// Stores flags: {V (Overflow), C (Carry), N (Negative), Z (Zero)}
// ============================================================

module CCR (
    input wire        clk,
    input wire        rst_n,
    
    // Update from ALU
    input wire        load_from_alu,        // Enable update from ALU result
    input wire [3:0]  alu_flags_in,         // Flags from ALU {V, C, N, Z}
    
    // Update from Stack (RTI)
    input wire        load_from_stack,      // Enable update from stack pop
    input wire [3:0]  stack_flags_in,       // Flags from stack
    
    // Individual flag control
    input wire        set_carry,            // SETC instruction
    input wire        clear_carry,          // CLRC instruction
    
    // Flag outputs
    output wire       flag_z,               // Zero flag
    output wire       flag_n,               // Negative flag
    output wire       flag_c,               // Carry flag
    output wire       flag_v,               // Overflow flag
    output wire [3:0] ccr_out               // All flags {V, C, N, Z}
);

    reg [3:0] flags;
    
    // Flag bit positions
    localparam Z_BIT = 0;  // Zero
    localparam N_BIT = 1;  // Negative
    localparam C_BIT = 2;  // Carry
    localparam V_BIT = 3;  // Overflow

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flags <= 4'b0000;
        end else begin
            // Priority: Stack restore > SETC/CLRC > ALU update
            if (load_from_stack) begin
                flags <= stack_flags_in;
            end else if (set_carry) begin
                flags[C_BIT] <= 1'b1;
            end else if (clear_carry) begin
                flags[C_BIT] <= 1'b0;
            end else if (load_from_alu) begin
                flags <= alu_flags_in;
            end
        end
    end
    
    // Individual flag outputs
    assign flag_z  = flags[Z_BIT];
    assign flag_n  = flags[N_BIT];
    assign flag_c  = flags[C_BIT];
    assign flag_v  = flags[V_BIT];
    assign ccr_out = flags;

endmodule
