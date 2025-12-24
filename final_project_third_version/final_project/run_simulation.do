# ============================================================
# run_simulation.do
# Unified Verification Script for ELC3030 Pipelined Processor
# ============================================================

# 1. Create work library
vlib work
vmap work work

# 2. Compile RTL modules
vlog -work work rtl/CCR.v
vlog -work work rtl/InputPort.v
vlog -work work rtl/OutputPort.v
vlog -work work rtl/ProgramCounter.v
vlog -work work rtl/InstructionMemory.v
vlog -work work rtl/DataMemory.v
vlog -work work rtl/RegisterFile.v
vlog -work work rtl/IF_ID_Register.v
vlog -work work rtl/ID_EX_Register.v
vlog -work work rtl/EX_MEM_Register.v
vlog -work work rtl/MEM_WB_Register.v
vlog -work work rtl/ControlUnit_Decoder.v
vlog -work work rtl/ControlUnit.v
vlog -work work rtl/ExecutionUnit.v
vlog -work work rtl/HazardDetectionUnit.v
vlog -work work rtl/ForwardingUnit.v
vlog -work work rtl/InterruptController.v
vlog -work work rtl/Processor.v

# 3. Compile All Testbenches
vlog -work work testbenches/tb_Grand_Final.v
vlog -work work testbenches/tb_Processor_Hazards.v
vlog -work work testbenches/tb_Full_Suite.v
vlog -work work testbenches/tb_Reset_Stress.v

# 4. Load Simulation (Default: tb_Grand_Final)
# To run a different test, change 'tb_Grand_Final' to:
# - tb_Full_Suite
# - tb_Processor_Hazards
# - tb_Reset_Stress
vsim -voptargs=+acc work.tb_Grand_Final

# 5. Setup Waves
add wave -position insertpoint sim:/tb_Grand_Final/DUT/*
add wave -position insertpoint sim:/tb_Grand_Final/DUT/RegFile/regs

# 6. Run
run -all

# 7. Note
# To view simulation logs without GUI, use:
# vsim -c -do "run -all; quit" tb_Grand_Final
