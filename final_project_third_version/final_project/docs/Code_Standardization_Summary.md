# ELC3030 Processor - Code Standardization Summary

## Overview
All Verilog modules have been standardized to use consistent naming conventions and coding style.

## Naming Conventions

### Module Names
- **PascalCase**: `RegisterFile`, `ExecutionUnit`, `Control_Unit_FSM`

### Signal Names
- **lowercase_with_underscores**: `rd_addr_a`, `mem_write`, `flag_dest`
- **Consistency**: All signals follow this pattern across all modules

### Reset Signal
- **Standard**: `rst_n` (active-low reset)
- Used consistently across all modules

### Port Naming Patterns
| Signal Type | Pattern | Example |
|-------------|---------|---------|
| Read Address | `rd_addr_x` | `rd_addr_a`, `rd_addr_b` |
| Write Address | `wr_addr` | `wr_addr` |
| Data Input | `data_x` | `data_a`, `data_b` |
| Data Output | `x_out` | `addr_out`, `data_out` |
| Enable Signals | `x_en` | `alu_en`, `sp_en`, `wr_en` |
| Control Signals | `x_y` | `mem_read`, `mem_write`, `reg_write` |

## Standardized Modules

### 1. RegisterFile.v
**Location**: `codes/RegisterFile/RegisterFile.v`

**Features**:
- 4 x 8-bit registers (R0-R3)
- R3 = Stack Pointer (SP), initialized to 0xFF
- 2 async read ports, 1 sync write port
- Write-first forwarding for hazard resolution

**Test Results**: ✅ 14/14 tests passed (100%)

### 2. ExecutionUnit.v
**Location**: `codes/ExecutionUnit/ExecutionUnit.v`

**Features**:
- Full ALU operations (ADD, SUB, AND, OR, etc.)
- Stack addressing (pre-increment/post-decrement)
- Jump condition evaluation
- Flag generation (Z, N, C, V)

**Test Results**: ✅ 17/17 tests passed (100%)

### 3. Control_Unit_FSM.v
**Location**: `codes/FSM_Controller/Control_Unit_FSM.v`

**Features**:
- 8-state FSM (RESET, FETCH, FETCH_OP2, DECODE, MEM, WB, INT_SAVE, INT_JUMP)
- All 32 ISA instructions supported
- Interrupt handling with flag save/restore
- 2-byte instruction support

**Test Results**: ✅ 34/34 tests passed (100%)

## Code Style Guidelines

### Header Comments
```verilog
// ============================================================
// ModuleName.v
// Brief description
// Harvard Architecture - Multi-Cycle FSM Design
// ============================================================
```

### Section Separators
```verilog
// ==================== Section Name ====================
```

### Port Declarations
- Group by function (System, Control, Data, Outputs)
- Align signal names for readability
- Include inline comments for clarity

### Always Blocks
- Use `always @(*)` for combinational logic
- Use `always @(posedge clk or negedge rst_n)` for sequential logic
- Clear default assignments at the start

## File Organization

```
codes/
├── ControlUnit/
│   ├── ControlUnit_ELC3030_FINAL.v (legacy - combinational)
│   └── tb_ControlUnit_ELC3030.v
├── ExecutionUnit/
│   ├── ExecutionUnit.v (standardized)
│   ├── ExecutionUnit_8bit_ELC3030_FINAL.v (legacy)
│   ├── tb_ExecutionUnit.v (standardized)
│   └── tb_ExecutionUnit_8bit_ELC3030.v (legacy)
├── FSM_Controller/
│   ├── Control_Unit_FSM.v (standardized)
│   └── tb_Control_Unit_FSM.v (standardized)
└── RegisterFile/
    ├── RegisterFile.v (standardized)
    ├── regfile.v (legacy)
    ├── tb_RegisterFile.v (standardized)
    └── tb_regfile.v (legacy)
```

## Verification Summary

| Module | Tests | Passed | Status |
|--------|-------|--------|--------|
| RegisterFile | 14 | 14 | ✅ 100% |
| ExecutionUnit | 17 | 17 | ✅ 100% |
| Control_Unit_FSM | 34 | 34 | ✅ 100% |
| **Total** | **65** | **65** | **✅ 100%** |

## Next Steps

1. **Integration**: Connect all standardized modules into top-level processor
2. **Pipeline Registers**: Add IF/ID, ID/EX, EX/MEM, MEM/WB registers
3. **Hazard Detection**: Implement forwarding and stall logic
4. **Memory Modules**: Create instruction and data memory
5. **Top-Level**: Create processor top module with all components

## Compatibility Notes

- All modules use `rst_n` (active-low reset)
- All modules compile without errors or warnings in ModelSim 10.5b
- All testbenches use consistent `#10` clock period (100MHz)
- VCD waveform files generated for all tests
