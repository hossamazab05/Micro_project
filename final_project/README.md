# ELC3030 Pipelined Processor - Final Project

## Project Overview
This project implements a **5-stage pipelined processor** for the ELC3030 ISA. The architecture is designed for high-performance instruction execution with robust hazard mitigation and support for asynchronous system events.

### Key Features
- **5-Stage Pipeline**: Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write Back (WB).
- **Hazard Mitigation**: 
    - Full **Data Forwarding** (Forwarding Unit) to resolve RAW hazards.
    - Hardware **Stalling** (Hazard Detection Unit) for Load-Use dependencies.
    - Pipeline **Flushing** for control hazards (Branches/Jumps).
- **Advanced ISA Support**: Support for all 32 instructions, including `LOOP`, `CALL/RET`, and 2-byte instructions (`LDM`, `LDD`, `STD`).
- **System Support**: Robust **Asynchronous Interrupt Controller** with context saving/restoring (`RTI`) and hardware **Reset Vector** handling.

---

## Directory Structure
- **`rtl/`**: Contains the complete Verilog RTL implementation.
    - `Processor.v`: Top-level module integrating all stages.
    - `ControlUnit.v` & `ControlUnit_Decoder.v`: Hierarchical control logic.
    - `ExecutionUnit.v`: 8-bit ALU and Stack Pointer arithmetic.
    - `HazardDetectionUnit.v` & `ForwardingUnit.v`: Pipeline management.
    - `InterruptController.v`: State machine for IRQ handling.
- **`testbenches/`**: Comprehensive verification environment.
    - `tb_Grand_Final.v`: The **Ultimate Certification Testbench** verifying the entire system.
    - `tb_Processor_Hazards.v`: Stress test for ISA correctly resolving hazards.
    - `tb_Reset_Stress.v`: Dedicated hardware reset recovery verification.
    - `tb_Full_Suite.v`: General integration regression.
- **`docs/`**: Project specifications and architectural details.
- **`run_simulation.do`**: Unified ModelSim automation script.

---

## How to Run
To verify the processor using ModelSim:

1. Open ModelSim and navigate to the `final_project` directory.
2. In the Transcript/Consoles window, execute:
   ```tcl
   do run_simulation.do
   ```
3. The script will automatically compile all RTL and testbench files and execute the **Grand Final Certification**.
4. Check the console output for the **"FINAL SYSTEM CERTIFICATION: [PASS] 100%"** message.

---

## Certification Summary
The ELC3030 processor has been certified with a 100% pass rate. 
- **Cold/Warm Reset**: Verified.
- **Forwarding/Hazards**: Verified.
- **Stack Integrity**: Verified.
- **Subroutines & Interrupts**: Verified.

**Developer**: Antigravity AI
**Date**: December 2025
