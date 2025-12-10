// Comprehensive Testbench for Data Memory, Instruction Memory, and Program Counter
// FULLY FIXED VERSION - All tests should pass
`timescale 1ns/1ps

module tb_memory_pc;

    // Clock and Reset
    reg clk;
    reg rst;
    reg RESET_IN;
    reg INTR_IN;
    
    // Program Counter signals
    reg pc_write;
    reg [7:0] pc_in;
    reg pc_src;
    reg pc_increment;
    wire [7:0] PC;
    
    // Instruction Memory signals
    wire [7:0] instruction;
    
    // Data Memory signals
    reg mem_read;
    reg mem_write;
    reg [7:0] data_mem_address;
    reg [7:0] data_mem_data_in;
    wire [7:0] data_mem_data_out;
    
    // Vectors
    reg [7:0] reset_vector;
    reg [7:0] intr_vector;
    
    // Test counter
    integer test_num;
    integer errors;
    
    // ============ Module Instantiations ============
    
    // Program Counter
    program_counter uut_pc (
        .clk(clk),
        .rst(rst),
        .RESET_IN(RESET_IN),
        .INTR_IN(INTR_IN),
        .pc_write(pc_write),
        .pc_in(pc_in),
        .reset_vector(reset_vector),
        .intr_vector(intr_vector),
        .pc_src(pc_src),
        .pc_increment(pc_increment),
        .PC(PC)
    );
    
    // Instruction Memory
    instruction_memory uut_imem (
        .clk(clk),
        .rst(rst),
        .pc(PC),
        .instruction(instruction)
    );
    
    // Data Memory
    data_memory uut_dmem (
        .clk(clk),
        .rst(rst),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(data_mem_address),
        .data_in(data_mem_data_in),
        .data_out(data_mem_data_out)
    );
    
    // ============ Clock Generation ============
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period (100MHz)
    end
    
    // ============ Initialize Instruction Memory with Test Program ============
    initial begin
        // Wait for memory to be initialized
        #1;
        
        // Load a simple test program into instruction memory
        uut_imem.mem[0]  = 8'h00;  // NOP
        uut_imem.mem[1]  = 8'h05;  // MOV R1, R1 (opcode=1, ra=1, rb=1)
        uut_imem.mem[2]  = 8'h29;  // ADD R2, R1 (opcode=2, ra=2, rb=1)
        uut_imem.mem[3]  = 8'h3A;  // SUB R2, R2 (opcode=3, ra=2, rb=2)
        uut_imem.mem[4]  = 8'hC0;  // LDM R0, imm (opcode=12, ra=0, rb=0)
        uut_imem.mem[5]  = 8'h42;  // imm = 0x42
        uut_imem.mem[6]  = 8'h70;  // PUSH R0 (opcode=7, ra=0, rb=0)
        uut_imem.mem[7]  = 8'h75;  // POP R1 (opcode=7, ra=1, rb=1)
        uut_imem.mem[8]  = 8'hB0;  // JMP R0 (opcode=11, brx=0, rb=0)
        uut_imem.mem[9]  = 8'h00;  // NOP
        uut_imem.mem[10] = 8'hFF;  // Invalid instruction for testing
        
        $display("=================================================");
        $display("Instruction Memory loaded with test program");
        $display("=================================================");
    end
    
    // ============ Initialize Data Memory ============
    initial begin
        #1;
        // Initialize some data memory locations
        uut_dmem.memory[0] = 8'h00;  // Reset vector points to address 0
        uut_dmem.memory[1] = 8'h50;  // Interrupt vector points to address 0x50
        uut_dmem.memory[10] = 8'hAA; // Test data
        uut_dmem.memory[11] = 8'h55; // Test data
        uut_dmem.memory[254] = 8'hDE; // Near top of memory
        uut_dmem.memory[255] = 8'hAD; // Top of memory (initial SP)
        
        $display("Data Memory initialized with test values");
    end
    
    // ============ Test Stimulus ============
    initial begin
        // Initialize signals
        rst = 1;
        RESET_IN = 0;
        INTR_IN = 0;
        pc_write = 0;
        pc_in = 8'h00;
        pc_src = 0;
        pc_increment = 0;
        mem_read = 0;
        mem_write = 0;
        data_mem_address = 8'h00;
        data_mem_data_in = 8'h00;
        reset_vector = 8'h00;
        intr_vector = 8'h50;
        test_num = 0;
        errors = 0;
        
        // Generate VCD file for waveform viewing
        $dumpfile("tb_memory_pc.vcd");
        $dumpvars(0, tb_memory_pc);
        
        $display("\n");
        $display("=================================================");
        $display("Starting Testbench for Memory and PC Modules");
        $display("=================================================");
        $display("\n");
        
        // Apply reset
        #20;
        rst = 0;
        #10;
        
        // ========================================
        // TEST 1: Program Counter Reset
        // ========================================
        test_num = 1;
        $display("TEST %0d: Program Counter Reset", test_num);
        reset_vector = 8'h00;
        rst = 1;
        #10;
        rst = 0;
        #10;
        if (PC == 8'h00) begin
            $display("  [PASS] PC reset to 0x%0h", PC);
        end else begin
            $display("  [FAIL] PC = 0x%0h, expected 0x00", PC);
            errors = errors + 1;
        end
        #10;
        
        // ========================================
        // TEST 2: PC Sequential Increment (+1)
        // ========================================
        test_num = 2;
        $display("\nTEST %0d: PC Sequential Increment by 1", test_num);
        pc_write = 1;
        pc_src = 0;
        pc_increment = 0;  // +1
        #10;
        if (PC == 8'h01) begin
            $display("  [PASS] PC incremented to 0x%0h", PC);
        end else begin
            $display("  [FAIL] PC = 0x%0h, expected 0x01", PC);
            errors = errors + 1;
        end
        
        #10;
        if (PC == 8'h02) begin
            $display("  [PASS] PC incremented to 0x%0h", PC);
        end else begin
            $display("  [FAIL] PC = 0x%0h, expected 0x02", PC);
            errors = errors + 1;
        end
        
        // ========================================
        // TEST 3: PC Sequential Increment (+2) - FULLY FIXED
        // ========================================
        test_num = 3;
        $display("\nTEST %0d: PC Sequential Increment by 2", test_num);
        
        // Reset PC to a known even address first
        pc_src = 1;      // Jump mode
        pc_in = 8'h02;   // Set PC to 0x02
        #10;
        $display("  Reset PC to known value: 0x%0h", PC);
        
        // Now test +2 increment
        $display("  Current PC before test: 0x%0h", PC);
        pc_src = 0;        // Sequential mode
        pc_write = 1;      // Enable PC write
        pc_increment = 1;  // +2 mode
        #10;
        $display("  After first +2: PC = 0x%0h (expected 0x04)", PC);
        if (PC == 8'h04) begin
            $display("  [PASS] PC incremented to 0x%0h", PC);
        end else begin
            $display("  [FAIL] PC = 0x%0h, expected 0x04", PC);
            errors = errors + 1;
        end
        #10;
        $display("  After second +2: PC = 0x%0h (expected 0x06)", PC);
        if (PC == 8'h06) begin
            $display("  [PASS] PC incremented to 0x%0h", PC);
        end else begin
            $display("  [FAIL] PC = 0x%0h, expected 0x06", PC);
            errors = errors + 1;
        end
        
        // ========================================
        // TEST 4: PC Branch/Jump
        // ========================================
        test_num = 4;
        $display("\nTEST %0d: PC Branch/Jump", test_num);
        pc_src = 1;  // Load from pc_in
        pc_in = 8'h20;
        #10;
        if (PC == 8'h20) begin
            $display("  [PASS] PC jumped to 0x%0h", PC);
        end else begin
            $display("  [FAIL] PC = 0x%0h, expected 0x20", PC);
            errors = errors + 1;
        end
        #10;
        
        // ========================================
        // TEST 5: PC Hold (stall)
        // ========================================
        test_num = 5;
        $display("\nTEST %0d: PC Hold (stall)", test_num);
        pc_write = 0;  // Disable PC write
        #20;
        if (PC == 8'h20) begin
            $display("  [PASS] PC held at 0x%0h", PC);
        end else begin
            $display("  [FAIL] PC = 0x%0h, expected 0x20 (hold)", PC);
            errors = errors + 1;
        end
        pc_write = 1;  // Re-enable
        #10;
        
        // ========================================
        // TEST 6: Instruction Memory Read
        // ========================================
        test_num = 6;
        $display("\nTEST %0d: Instruction Memory Read", test_num);
        pc_src = 1;
        pc_in = 8'h00;
        #10;
        $display("  PC=0x%0h, Instruction=0x%0h (expected 0x00 - NOP)", PC, instruction);
        if (instruction == 8'h00) $display("  [PASS]");
        else begin
            $display("  [FAIL]");
            errors = errors + 1;
        end
        
        pc_in = 8'h02;
        #10;
        $display("  PC=0x%0h, Instruction=0x%0h (expected 0x29 - ADD)", PC, instruction);
        if (instruction == 8'h29) $display("  [PASS]");
        else begin
            $display("  [FAIL]");
            errors = errors + 1;
        end
        
        pc_in = 8'h04;
        #10;
        $display("  PC=0x%0h, Instruction=0x%0h (expected 0xC0 - LDM)", PC, instruction);
        if (instruction == 8'hC0) $display("  [PASS]");
        else begin
            $display("  [FAIL]");
            errors = errors + 1;
        end
        
        pc_in = 8'h05;
        #10;
        $display("  PC=0x%0h, Instruction=0x%0h (expected 0x42 - imm)", PC, instruction);
        if (instruction == 8'h42) $display("  [PASS]");
        else begin
            $display("  [FAIL]");
            errors = errors + 1;
        end
        
        // ========================================
        // TEST 7: Data Memory Write
        // ========================================
        test_num = 7;
        $display("\nTEST %0d: Data Memory Write", test_num);
        mem_write = 1;
        mem_read = 0;
        data_mem_address = 8'h10;
        data_mem_data_in = 8'hAB;
        #10;
        
        data_mem_address = 8'h11;
        data_mem_data_in = 8'hCD;
        #10;
        
        data_mem_address = 8'h12;
        data_mem_data_in = 8'hEF;
        #10;
        mem_write = 0;
        $display("  [INFO] Written 0xAB to addr 0x10, 0xCD to addr 0x11, 0xEF to addr 0x12");
        
        // ========================================
        // TEST 8: Data Memory Read
        // ========================================
        test_num = 8;
        $display("\nTEST %0d: Data Memory Read", test_num);
        mem_read = 1;
        
        data_mem_address = 8'h10;
        #10;
        $display("  Read addr 0x%0h: 0x%0h (expected 0xAB)", data_mem_address, data_mem_data_out);
        if (data_mem_data_out == 8'hAB) $display("  [PASS]");
        else begin
            $display("  [FAIL]");
            errors = errors + 1;
        end
        
        data_mem_address = 8'h11;
        #10;
        $display("  Read addr 0x%0h: 0x%0h (expected 0xCD)", data_mem_address, data_mem_data_out);
        if (data_mem_data_out == 8'hCD) $display("  [PASS]");
        else begin
            $display("  [FAIL]");
            errors = errors + 1;
        end
        
        data_mem_address = 8'h12;
        #10;
        $display("  Read addr 0x%0h: 0x%0h (expected 0xEF)", data_mem_address, data_mem_data_out);
        if (data_mem_data_out == 8'hEF) $display("  [PASS]");
        else begin
            $display("  [FAIL]");
            errors = errors + 1;
        end
        
        // ========================================
        // TEST 9: Data Memory - Stack Operations
        // ========================================
        test_num = 9;
        $display("\nTEST %0d: Data Memory - Stack Operations", test_num);
        
        // Write to stack locations (simulating PUSH)
        mem_write = 1;
        mem_read = 0;
        data_mem_address = 8'hFF;  // SP initial value
        data_mem_data_in = 8'h11;
        #10;
        
        data_mem_address = 8'hFE;
        data_mem_data_in = 8'h22;
        #10;
        
        data_mem_address = 8'hFD;
        data_mem_data_in = 8'h33;
        #10;
        mem_write = 0;
        
        // Read from stack (simulating POP)
        mem_read = 1;
        data_mem_address = 8'hFD;
        #10;
        $display("  Stack read addr 0x%0h: 0x%0h (expected 0x33)", data_mem_address, data_mem_data_out);
        if (data_mem_data_out == 8'h33) $display("  [PASS]");
        else begin
            $display("  [FAIL]");
            errors = errors + 1;
        end
        
        data_mem_address = 8'hFE;
        #10;
        $display("  Stack read addr 0x%0h: 0x%0h (expected 0x22)", data_mem_address, data_mem_data_out);
        if (data_mem_data_out == 8'h22) $display("  [PASS]");
        else begin
            $display("  [FAIL]");
            errors = errors + 1;
        end
        
        // ========================================
        // TEST 10: Interrupt Handling
        // ========================================
        test_num = 10;
        $display("\nTEST %0d: Interrupt Handling", test_num);
        
        // Set PC to a known value first
        pc_src = 1;
        pc_in = 8'h10;
        #10;
        
        // Now do normal sequential execution
        pc_src = 0;
        pc_increment = 0;
        #10;
        
        // Normal execution
        $display("  Normal execution: PC=0x%0h", PC);
        #10;
        $display("  Normal execution: PC=0x%0h", PC);
        
        // Trigger interrupt
        INTR_IN = 1;
        #10;
        INTR_IN = 0;
        $display("  After interrupt: PC=0x%0h (expected 0x50)", PC);
        if (PC == 8'h50) begin
            $display("  [PASS] PC loaded with interrupt vector");
        end else begin
            $display("  [FAIL] PC = 0x%0h, expected 0x50", PC);
            errors = errors + 1;
        end
        #10;
        
        // ========================================
        // TEST 11: External Reset - FULLY FIXED
        // ========================================
        test_num = 11;
        $display("\nTEST %0d: External Reset", test_num);
        $display("  Current PC before reset: 0x%0h", PC);
        
        // Apply external reset
        reset_vector = 8'h00;
        RESET_IN = 1;
        #10;  // Wait for clock edge
        $display("  During RESET_IN=1: PC = 0x%0h (should be 0x00)", PC);
        
        // Release RESET_IN but keep pc_write disabled to hold PC at 0
        RESET_IN = 0;
        pc_write = 0;  // Prevent PC from incrementing
        #10;
        
        $display("  After external reset: PC=0x%0h (expected 0x00)", PC);
        if (PC == 8'h00) begin
            $display("  [PASS] PC reset via RESET_IN");
        end else begin
            $display("  [FAIL] PC = 0x%0h, expected 0x00", PC);
            errors = errors + 1;
        end
        
        // Re-enable pc_write for any future tests
        pc_write = 1;
        
        // ========================================
        // Test Summary
        // ========================================
        #50;
        $display("\n");
        $display("=================================================");
        $display("Test Summary");
        $display("=================================================");
        $display("Total Tests: %0d", test_num);
        $display("Errors: %0d", errors);
        if (errors == 0) begin
            $display("Status: ALL TESTS PASSED ?");
        end else begin
            $display("Status: SOME TESTS FAILED ?");
        end
        $display("=================================================");
        $display("\n");
        
        // End simulation
        #100;
        $finish;
    end
    
    // Monitor important signals
    initial begin
        $monitor("Time=%0t | PC=0x%0h | Instruction=0x%0h | DataMem[0x%0h]=0x%0h", 
                 $time, PC, instruction, data_mem_address, data_mem_data_out);
    end

endmodule

