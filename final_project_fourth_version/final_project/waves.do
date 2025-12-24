# waves.do
# Professional Signal Grouping for ELC3030 Processor

# ---------------------------------------------------------
# SYSTEM SIGNALS
# ---------------------------------------------------------
add wave -noupdate -divider -color "Yellow" "System Signals"
add wave -noupdate -color "Yellow" -label "Clock" clk
add wave -noupdate -color "Yellow" -label "Reset" rst_n
add wave -noupdate -color "Yellow" -label "IRQ" INTR_IN

# ---------------------------------------------------------
# FETCH STAGE
# ---------------------------------------------------------
add wave -noupdate -divider -color "Cyan" "FETCH Stage"
add wave -noupdate -hex -label "PC" -color "Cyan" DUT/if_pc_out
add wave -noupdate -hex -label "Instruction_Bus" -color "Cyan" DUT/if_instruction
add wave -noupdate -label "PC_Write_En" -color "Cyan" DUT/final_pc_write_en

# ---------------------------------------------------------
# DECODE STAGE
# ---------------------------------------------------------
add wave -noupdate -divider -color "Magenta" "DECODE Stage"
add wave -noupdate -hex -label "ID_Instr" -color "Magenta" DUT/id_instruction
add wave -noupdate -hex -label "CU_State" -color "Magenta" DUT/cu_current_state
add wave -noupdate -hex -label "Decoded_Op" -color "Magenta" DUT/cu_opcode_out

# ---------------------------------------------------------
# REGISTER FILE (GPRs)
# ---------------------------------------------------------
add wave -noupdate -divider -color "Green" "Register File"
add wave -noupdate -hex -label "R0" -color "Green" DUT/RegFile/regs[0]
add wave -noupdate -hex -label "R1" -color "Green" DUT/RegFile/regs[1]
add wave -noupdate -hex -label "R2" -color "Green" DUT/RegFile/regs[2]
add wave -noupdate -hex -label "R3 (SP)" -color "Green" DUT/RegFile/regs[3]

# ---------------------------------------------------------
# PIPELINE STATUS
# ---------------------------------------------------------
add wave -noupdate -divider -color "White" "Pipeline Control"
add wave -noupdate -label "STALL" -color "White" DUT/h_stall
add wave -noupdate -label "FLUSH" -color "White" DUT/intr_pipeline_flush
add wave -noupdate -hex -label "FWD_A" -color "White" DUT/fwd_a_sel
add wave -noupdate -hex -label "FWD_B" -color "White" DUT/fwd_b_sel

# ---------------------------------------------------------
# EXECUTE STAGE
# ---------------------------------------------------------
add wave -noupdate -divider -color "Red" "EXECUTE Stage"
add wave -noupdate -hex -label "ALU_Result" -color "Red" DUT/ex_alu_result
add wave -noupdate -hex -label "Flags (ZNVC)" -color "Red" DUT/ccr_flags_out

# ---------------------------------------------------------
# I/O PORTS
# ---------------------------------------------------------
add wave -noupdate -divider -color "Orange" "Peripheral I/O"
add wave -noupdate -hex -label "PORT_IN" -color "Orange" DUT/INPUT_PORT_PINS
add wave -noupdate -hex -label "PORT_OUT" -color "Orange" DUT/OUTPUT_PORT_PINS

# Window configuration
configure wave -namecolwidth 220
configure wave -valuecolwidth 80
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
