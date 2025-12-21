// ============================================================
// Processor.v
// Top-Level ELC3030 Pipelined Processor
// Integrated with Unified Stalling, Flag Forwarding, and Piped RTI
// ============================================================

module Processor (
    input wire        clk,
    input wire        rst_n,
    input wire        INTR_IN,          // External Interrupt
    input wire [7:0]  INPUT_PORT_PINS,  // Input Port Physical Pins
    output wire [7:0] OUTPUT_PORT_PINS  // Output Port Physical Pins
);

    // ============================================================
    // INTERNAL WIRES & BUSES
    // ============================================================

    // --- Interrupt Controller Signals ---
    wire        intr_load_pc_en, intr_load_ccr_en, intr_pipeline_flush, intr_active, intr_stall;
    wire [7:0]  intr_new_pc, intr_mem_addr, intr_stack_data;
    wire [3:0]  intr_saved_ccr;
    wire        intr_mem_read_enable, intr_stack_push, intr_sp_dec, intr_stack_pop, intr_sp_inc;
    wire [3:0]  intr_current_state;

    // --- IF Stage ---
    wire [7:0]  if_pc_out;
    wire [7:0]  if_pc_plus_1;
    wire [7:0]  if_instruction;
    
    // --- IF/ID Register Outputs ---
    wire [7:0]  id_pc, id_pc_plus_1, id_instruction;
    
    // --- ID Stage ---
    wire [3:0]  id_opcode   = id_instruction[7:4];
    wire [1:0]  id_ra, id_rb;
    
    // Control Unit Outputs
    wire        id_ior, id_iow, id_ops, id_alu_en;
    wire        id_mr, id_mw, id_wb;
    wire        id_jmp, id_jmp_cond;
    wire        id_sp_en, id_sp_op, id_jwsp;
    wire        id_imm_sel;
    wire        id_stack_pc, id_stack_flags;
    wire [1:0]  id_fd, id_flag_sel;
    wire [3:0]  id_opcode_out;
    wire [2:0]  id_wb_addr_sel, id_alu_ops;
    wire        id_rs_en, id_rt_en;
    wire        cu_pc_write, cu_pc_src, cu_ir_write, cu_ex_write, cu_fetch_op2;
    wire [2:0]  cu_current_state;
    
    // --- MEM Stage ---
    wire [1:0]  mem_flag_dest;
    wire [3:0]  mem_flags;
    wire        mem_rti; 
    
    // --- WB Stage ---
    wire [1:0]  wb_flag_dest;
    wire [3:0]  wb_flags;
    
    wire [7:0]  cu_imm_val; // Shadow operand from CU
    wire [7:0]  id_imm_val = (cu_fetch_op2) ? cu_imm_val : id_instruction;
    
    // Register File Outputs
    wire [7:0]  id_reg_data1, id_reg_data2, id_sp_val, id_raw_sp;
    
    // Hazard Unit Outputs
    wire        h_pc_write, h_if_id_write, h_id_ex_flush, h_if_id_flush, h_ex_mem_flush;

    // --- ID/EX Register Outputs ---
    wire [7:0]  ex_pc, ex_pc_plus_1, ex_data_a, ex_data_b, ex_imm;
    wire [1:0]  ex_rs, ex_rt, ex_rd;
    wire        ex_reg_write, ex_mem_read, ex_mem_write, ex_mem_to_reg;
    wire        ex_alu_src, ex_branch, ex_jmp_cond, ex_jump, ex_rti;
    wire [3:0]  ex_alu_op;
    wire [2:0]  ex_alu_sub;
    wire [1:0]  ex_flag_dest, ex_flag_sel;
    wire        ex_ior, ex_iow, ex_ops, ex_sp_en, ex_sp_op, ex_stack_pc, ex_stack_flags;
    
    // --- EX Stage ---
    wire [7:0]  alu_operand1_fwd, alu_operand2_fwd;
    wire [1:0]  fwd_a_sel, fwd_b_sel;
    wire        ex_branch_taken;
    wire [3:0]  ex_final_flags;
    wire [7:0]  ex_alu_result;
    wire [7:0]  ex_mem_addr;
    wire [7:0]  ex_output_port_val; 
    wire [7:0]  ex_branch_target;

    // --- EX/MEM Register Outputs ---
    wire [7:0]  mem_alu_result, mem_mem_addr, mem_data_b, mem_pc_plus_1, mem_branch_target;
    wire [1:0]  mem_rd;
    wire        mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg;
    wire        mem_sp_en, mem_sp_op, mem_stack_pc, mem_stack_flags, mem_jwsp, mem_branch_taken;

    // --- MEM Stage ---
    wire [7:0]  mem_read_data, inpp_data;
    wire [3:0]  ccr_flags_out;
    
    // Explicit Memory Bus Control (Priority to Hardware Interrupt Controller)
    wire [7:0]  final_mem_addr  = (intr_active) ? intr_mem_addr        : mem_mem_addr;
    wire [7:0]  final_mem_data  = (intr_active) ? intr_stack_data      : mem_alu_result;
    wire        final_mem_read  = (intr_active) ? intr_mem_read_enable : mem_mem_read;
    wire        final_mem_write = (intr_active) ? intr_stack_push      : mem_mem_write;

    // --- MEM/WB Register Outputs ---
    wire [7:0]  wb_alu_result, wb_mem_data;
    wire [1:0]  wb_rd;
    wire        wb_reg_write, wb_mem_to_reg, wb_sp_en, wb_sp_op;

    // --- WB Stage ---
    wire [7:0]  wb_final_data = wb_mem_to_reg ? wb_mem_data : wb_alu_result;
    
    // RTI Detection Logic (Direct probe for IC trigger)
    wire id_rti = (id_opcode == 4'd11 && id_instruction[3:2] == 2'd3);

    // ============================================================
    // CONTROL LOGIC: PROGRAM COUNTER & BRANCHES
    // ============================================================

    // Corrected PC Mux Selection: Pipeline jumps (RET/Branch) are GATED by !intr_active
    // to prevent corruption during interrupt save sequence.
    wire pc_source_jump = (intr_load_pc_en) || ((ex_branch_taken || mem_jwsp) && !intr_active);
    
    // Final Write Enable for PC
    wire final_pc_write_en = (h_pc_write && cu_pc_write && !intr_stall) || pc_source_jump;
    
    // PC Target Multiplexer (Strict Priority)
    wire [7:0] final_pc_target = (intr_load_pc_en) ? intr_new_pc :
                                 (ex_branch_taken) ? ex_branch_target :
                                 (mem_jwsp)        ? mem_read_data : 
                                 ex_branch_target; 

    // Flag Forwarding Logic (Hardware Bypassing)
    wire [3:0]  effective_flags_for_ex = (mem_flag_dest == 2'b11 || mem_flag_dest[1] == 1'b0) ? mem_flags :
                                          (wb_flag_dest  == 2'b11 || wb_flag_dest[1]  == 1'b0) ? wb_flags  :
                                          ccr_flags_out;

    // Debug Probe for Trace Analysis
    assign final_pc_src = pc_source_jump;

    // ============================================================
    // CORE MODULES
    // ============================================================

    ProgramCounter PC_Mod (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_write   (final_pc_write_en),
        .pc_src     (pc_source_jump),
        .pc_target  (final_pc_target),
        .mem_data   (if_instruction),
        .load_vector(cu_current_state == 3'b000), // Enable Reset Vector fetch during state 0
        .pc_out     (if_pc_out)
    );

    assign if_pc_plus_1 = if_pc_out + 8'd1;

    // --- IMEM Address Multiplexing for Vectors ---
    // Force IMEM to read vector M[1] during the entire interrupt sequence
    wire [7:0] final_imem_addr = (intr_active) ? 8'h01 : if_pc_out;

    InstructionMemory IMEM (
        .clk        (clk),
        .rst_n      (rst_n),
        .mem_read   (1'b1),
        .addr       (final_imem_addr),
        .data_out   (if_instruction)
    );

    IF_ID_Register IF_ID (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (!h_if_id_write || !cu_ir_write || intr_stall),
        .flush          (h_if_id_flush || intr_pipeline_flush),
        .if_instruction (if_instruction),
        .if_pc          (if_pc_out),
        .if_pc_plus_1   (if_pc_plus_1),
        .id_instruction (id_instruction),
        .id_pc          (id_pc),
        .id_pc_plus_1   (id_pc_plus_1)
    );

    ControlUnit CU (
        .clk             (clk),
        .rst_n           (rst_n),
        .stall           (!h_if_id_write || intr_stall),
        .branch_taken    (pc_source_jump), // Unified Sync
        .mem_branch_taken (1'b0),          // Handled by pc_source_jump
        .INTR_IN         (INTR_IN),
        .if_instruction  (if_instruction),
        .Instruction     (id_instruction),
        .CCR             (ccr_flags_out),
        .Loop_Zero       (1'b0),
        .IOR(id_ior), .IOW(id_iow), .OPS(id_ops), .ALU(id_alu_en),
        .MR(id_mr), .MW(id_mw), .WB(id_wb),
        .Jmp(id_jmp), .Jump_Conditional(id_jmp_cond),
        .SP(id_sp_en), .SPOP(id_sp_op), .JWSP(id_jwsp),
        .IMM(id_imm_sel),
        .Stack_PC(id_stack_pc), .Stack_Flags(id_stack_flags),
        .FD(id_fd), .Flag_Selector(id_flag_sel),
        .Opcode_Out(id_opcode_out),
        .WB_Address      (id_wb_addr_sel),
        .ALU_Ops         (id_alu_ops),
        .imm_val         (cu_imm_val),
        .RS_EN           (id_rs_en),
        .RT_EN           (id_rt_en),
        .RA_Out          (id_ra),
        .RB_Out          (id_rb),
        .PC_Write        (cu_pc_write),
        .PC_Src          (cu_pc_src),
        .IR_Write        (cu_ir_write),
        .EX_Write        (cu_ex_write),
        .Fetch_Op2       (cu_fetch_op2),
        .Current_State   (cu_current_state)
    );

    RegisterFile RegFile (
        .clk        (clk),
        .rst_n      (rst_n),
        .rd_addr_a  (id_ra),        
        .rd_addr_b  (id_rb),        
        .wr_addr    (wb_rd), 
        .wr_data    (wb_final_data),
        .wr_en      (wb_reg_write),
        .sp_en      ((id_sp_en && h_if_id_write && !intr_stall && !id_rti && !pc_source_jump) || intr_sp_dec || intr_sp_inc),
        .sp_op      (id_sp_en ? id_sp_op : (intr_sp_inc)),
        .rd_data_a  (id_reg_data1),
        .rd_data_b  (id_reg_data2),
        .sp_out     (id_sp_val),
        .raw_sp     (id_raw_sp)
    );

    HazardDetectionUnit HazardUnit (
        .id_opcode       (id_opcode_out),
        .id_rs           (id_ra),
        .id_rt           (id_rb),
        .id_rs_en        (id_rs_en),
        .id_rt_en        (id_rt_en),
        .ex_rd           (ex_rd),
        .ex_mem_read     (ex_mem_read),
        .ex_sp_en        (ex_sp_en),
        .mem_sp_en       (mem_sp_en),
        .branch_taken    (ex_branch_taken),
        .mem_branch_taken (mem_jwsp), 
        .current_state   (cu_current_state),
        .pc_write        (h_pc_write),
        .if_id_write     (h_if_id_write),
        .id_ex_flush     (h_id_ex_flush),
        .if_id_flush     (h_if_id_flush),
        .ex_mem_flush    (h_ex_mem_flush)
    );

    wire dest_is_rb = ((id_opcode_out == 4'd12) && (id_ra == 2'd0 || id_ra == 2'd1)) ||
                      (id_opcode_out == 4'd13) ||
                      (id_opcode_out == 4'd6)  ||
                      (id_opcode_out == 4'd8)  ||
                      ((id_opcode_out == 4'd7) && (id_ra == 2'd1 || id_ra == 2'd3));

    wire [1:0] id_dest_reg = dest_is_rb ? id_rb : id_ra;

    // PC Mux for ID_EX Register (Sync with Phase-Aware Decoder)
    // S_FETCH_OP2 (2): Use LATCHED PC (Operand Address)
    // S_FETCH (1): Use LIVE PC (Zero-Latency Instruction)
    wire [7:0] muxed_id_pc = (cu_current_state == 3'd2) ? id_pc : if_pc_out;
    wire [7:0] muxed_id_pc_plus_1 = (cu_current_state == 3'd2) ? id_pc_plus_1 : if_pc_plus_1;

    ID_EX_Register ID_EX (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (intr_stall),
        .flush          (h_id_ex_flush || !cu_ex_write || intr_pipeline_flush || pc_source_jump),
        .id_data_a      (id_reg_data1),
        .id_data_b      (id_reg_data2),
        .id_imm         (id_imm_val),
        .id_pc          (muxed_id_pc),
        .id_pc_plus_1   (muxed_id_pc_plus_1),
        .id_rs          (id_ra),
        .id_rt          (id_rb),
        .id_rd          (id_dest_reg),
        .id_reg_write   (id_wb),
        .id_mem_read    (id_mr),
        .id_mem_write   (id_mw),
        .id_mem_to_reg  (id_mr),
        .id_alu_src     (id_imm_sel),
        .id_alu_op      (id_opcode_out),
        .id_alu_sub     (id_alu_ops),
        .id_branch      (id_jmp),
        .id_jmp_cond    (id_jmp_cond),
        .id_jump        (id_jwsp),
        .id_flag_dest   (id_fd),
        .id_flag_sel    (id_flag_sel),
        .id_ior         (id_ior),
        .id_iow         (id_iow),
        .id_ops         (id_ops),
        .id_sp_en       (id_sp_en),
        .id_sp_op       (id_sp_op),
        .id_stack_pc    (id_stack_pc),
        .id_stack_flags (id_stack_flags),
        .id_rti         (id_rti),
        .ex_data_a      (ex_data_a),
        .ex_data_b      (ex_data_b),
        .ex_imm         (ex_imm),
        .ex_pc          (ex_pc),
        .ex_pc_plus_1   (ex_pc_plus_1),
        .ex_rs          (ex_rs),
        .ex_rt          (ex_rt),
        .ex_rd          (ex_rd),
        .ex_reg_write   (ex_reg_write),
        .ex_mem_read    (ex_mem_read),
        .ex_mem_write   (ex_mem_write),
        .ex_mem_to_reg  (ex_mem_to_reg),
        .ex_alu_src     (ex_alu_src),
        .ex_alu_op      (ex_alu_op),
        .ex_alu_sub     (ex_alu_sub),
        .ex_branch      (ex_branch),
        .ex_jmp_cond    (ex_jmp_cond),
        .ex_jump        (ex_jump),
        .ex_flag_dest   (ex_flag_dest),
        .ex_flag_sel    (ex_flag_sel),
        .ex_ior         (ex_ior),
        .ex_iow         (ex_iow),
        .ex_ops         (ex_ops),
        .ex_sp_en       (ex_sp_en),
        .ex_sp_op       (ex_sp_op),
        .ex_stack_pc    (ex_stack_pc),
        .ex_stack_flags (ex_stack_flags),
        .ex_rti         (ex_rti)
    );

    ForwardingUnit FwdUnit (
        .ex_rs          (ex_rs),
        .ex_rt          (ex_rt),
        .mem_rd         (mem_rd),
        .mem_reg_write  (mem_reg_write),
        .wb_rd          (wb_rd),
        .wb_reg_write   (wb_reg_write),
        .forward_a      (fwd_a_sel),
        .forward_b      (fwd_b_sel)
    );

    // --- Forwarding Muxes (EX Stage) ---
    assign alu_operand1_fwd = (fwd_a_sel == 2'b01) ? mem_alu_result :
                              (fwd_a_sel == 2'b10) ? wb_final_data  :
                              ex_data_a;

    assign alu_operand2_fwd = (fwd_b_sel == 2'b01) ? mem_alu_result :
                              (fwd_b_sel == 2'b10) ? wb_final_data  :
                              ex_data_b;

    ExecutionUnit EU (
        .IOR          (ex_ior), 
        .IOW          (ex_iow), 
        .OPS          (ex_ops), 
        .ALU          (1'b1), 
        .MR           (ex_mem_read), 
        .MW           (ex_mem_write), 
        .WB           (ex_reg_write),
        .Jmp          (ex_branch), 
        .Jump_Conditional(ex_jmp_cond), 
        .SP           (ex_sp_en), 
        .SPOP         (ex_sp_op), 
        .JWSP         (ex_jump),
        .IMM          (ex_alu_src),
        .Stack_PC     (ex_stack_pc), 
        .Stack_Flags  (ex_stack_flags),
        .FD           (ex_flag_dest),
        .Flag_Selector(ex_flag_sel), 
        .Opcode       (ex_alu_op),
        .ALU_Ops      (ex_alu_sub),
        .WB_Address   ({1'b0, ex_rd}), 
        .Data1        (alu_operand1_fwd),
        .Data2        (alu_operand2_fwd),
        .Immediate_Value (ex_imm),
        .INPUT_PORT   (inpp_data),
        .PC_8bit      (ex_pc),
        .PC_plus_1    (ex_pc_plus_1),
        .Flags        (effective_flags_for_ex), 
        .Flags_From_Memory (mem_read_data[3:0]), 
        .MEM_Stack_Flags (ex_mem_read && ex_rti), 
        .Taken_Jump   (),
        .To_PC_Selector (ex_branch_taken),
        .Final_Flags  (ex_final_flags),
        .Address_8bit (ex_mem_addr),
        .Data_8bit    (ex_alu_result), 
        .OUTPUT_PORT  (ex_output_port_val),
        .Branch_Target_Out(ex_branch_target),
        // Fix missing connections
        .MR_Out(), .MW_Out(), .WB_Out(), .JWSP_Out(), .SP_Out(), .SPOP_Out(),
        .Stack_PC_Out(), .Stack_Flags_Out(), .WB_Address_Out()
    );

    EX_MEM_Register EX_MEM (
        .clk            (clk),
        .rst_n          (rst_n),
        .flush          (h_ex_mem_flush || intr_pipeline_flush),
        .stall          (intr_stall),
        .ex_alu_result  (ex_alu_result),
        .ex_mem_addr    (ex_mem_addr),
        .ex_data_b      (alu_operand2_fwd), 
        .ex_pc_plus_1   (ex_pc_plus_1),
        .ex_flags       (ex_final_flags),
        .ex_rd          (ex_rd),
        .ex_reg_write   (ex_reg_write),
        .ex_mem_read    (ex_mem_read),
        .ex_mem_write   (ex_mem_write),
        .ex_mem_to_reg  (ex_mem_to_reg),
        .ex_branch_taken(ex_branch_taken),
        .ex_branch_target(ex_branch_target),
        .ex_flag_dest   (ex_flag_dest),
        .ex_sp_en       (ex_sp_en),
        .ex_sp_op       (ex_sp_op),
        .ex_stack_pc    (ex_stack_pc),
        .ex_stack_flags (ex_stack_flags),
        .ex_jwsp        (ex_jump),
        .ex_rti         (ex_rti),
        .mem_alu_result (mem_alu_result),
        .mem_mem_addr   (mem_mem_addr),
        .mem_data_b     (mem_data_b),
        .mem_pc_plus_1  (mem_pc_plus_1),
        .mem_flags      (mem_flags),
        .mem_rd         (mem_rd),
        .mem_reg_write  (mem_reg_write),
        .mem_mem_read   (mem_mem_read),
        .mem_mem_write  (mem_mem_write),
        .mem_mem_to_reg (mem_mem_to_reg),
        .mem_branch_taken(mem_branch_taken),
        .mem_branch_target(mem_branch_target),
        .mem_flag_dest  (mem_flag_dest),
        .mem_sp_en      (mem_sp_en),
        .mem_sp_op      (mem_sp_op),
        .mem_stack_pc   (mem_stack_pc),
        .mem_stack_flags(mem_stack_flags),
        .mem_jwsp       (mem_jwsp),
        .mem_rti        (mem_rti)
    );

    DataMemory DMEM (
        .clk        (clk),
        .rst_n      (rst_n),
        .addr       (final_mem_addr),
        .data_in    (final_mem_data),
        .mem_read   (final_mem_read),
        .mem_write  (final_mem_write),
        .data_out   (mem_read_data)
    );

    CCR FlagsReg (
        .clk            (clk),
        .rst_n          (rst_n),
        .load_from_alu  (mem_reg_write && !intr_active && (mem_flag_dest == 2'b11)),
        .alu_flags_in   (mem_flags),
        .load_from_stack(intr_load_ccr_en),
        .stack_flags_in (intr_saved_ccr),
        .set_carry      (mem_reg_write && mem_flag_dest == 2'b01),  
        .clear_carry    (mem_reg_write && mem_flag_dest == 2'b00),  
        .ccr_out        (ccr_flags_out),
        // Fix missing connections
        .flag_z(), .flag_n(), .flag_c(), .flag_v()
    );

    MEM_WB_Register MEM_WB (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (intr_stall),
        .flush          (1'b0), // Do not flush WB on jump
        .mem_alu_result (mem_alu_result),
        .mem_data       (mem_read_data),
        .mem_flags      (mem_flags),
        .mem_rd         (mem_rd),
        .mem_reg_write  (mem_reg_write),
        .mem_mem_to_reg (mem_mem_to_reg),
        .mem_sp_en      (mem_sp_en),
        .mem_sp_op      (mem_sp_op),
        .mem_flag_dest  (mem_flag_dest),
        .wb_alu_result  (wb_alu_result),
        .wb_mem_data    (wb_mem_data),
        .wb_flags       (wb_flags),
        .wb_rd          (wb_rd),
        .wb_reg_write   (wb_reg_write),
        .wb_mem_to_reg  (wb_mem_to_reg),
        .wb_sp_en       (wb_sp_en),
        .wb_sp_op       (wb_sp_op),
        .wb_flag_dest   (wb_flag_dest)
    );

    OutputPort OUTP (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (ex_iow),
        .data_in    (ex_output_port_val),
        .pins_out   (OUTPUT_PORT_PINS)
    );

    InputPort INPP (
        .enable     (ex_ior),
        .pins_in    (INPUT_PORT_PINS),
        .data_out   (inpp_data)
    );

    InterruptController IntCtrl (
        .clk              (clk),
        .rst_n            (rst_n),
        .intr_in          (INTR_IN),
        .rti_instruction  (mem_rti),
        .current_pc       (if_pc_out), // Using live if_pc_out to avoid flushing race
        .current_ccr      (ccr_flags_out),
        .current_sp       (id_raw_sp),
        .mem_data_in      ((intr_current_state == 4'd5 || intr_current_state == 4'd6) ? if_instruction : mem_read_data),
        .mem_addr         (intr_mem_addr),
        .mem_read_enable  (intr_mem_read_enable),
        .stack_push_enable(intr_stack_push),
        .stack_data_out   (intr_stack_data),
        .sp_dec_enable    (intr_sp_dec),
        .stack_pop_enable (intr_stack_pop),
        .sp_inc_enable    (intr_sp_inc),
        .load_pc_enable   (intr_load_pc_en),
        .new_pc_value     (intr_new_pc),
        .load_ccr_enable  (intr_load_ccr_en),
        .saved_ccr        (intr_saved_ccr),
        .pipeline_flush   (intr_pipeline_flush),
        .interrupt_active (intr_active),
        .stall_pipeline   (intr_stall),
        .current_state_out(intr_current_state)
    );

endmodule
