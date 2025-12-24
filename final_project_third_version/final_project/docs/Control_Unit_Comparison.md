# Control Unit Comparison: Combinational vs FSM

## Architecture Comparison

| Feature | Combinational (ControlUnit_ELC3030_FINAL) | FSM (Control_Unit_FSM) | Best Choice |
|---------|------------------------------------------|----------------------|-------------|
| **Design Type** | Pure combinational logic | Sequential FSM with 8 states | **FSM** - Required by spec |
| **Inputs** | Instruction only | Instruction + clk + rst_n | **FSM** - Multi-cycle support |
| **State Management** | None (single cycle assumed) | 8 states (RESET, FETCH, etc.) | **FSM** - Proper multi-cycle |
| **2-byte Instructions** | Uses `pc_inc_val` signal | Dedicated FETCH_OP2 state | **FSM** - Explicit state |
| **Interrupt Handling** | Basic signals only | Full INT_SAVE/INT_JUMP states | **FSM** - Complete support |
| **Memory Access** | Assumes instant | MEM and WB states | **FSM** - Realistic timing |
| **Instruction Decoding** | Clean case statement | Case statement in DECODE state | **Combinational** - Cleaner |
| **Signal Naming** | Mixed (MR/MW, IOR/IOW) | Consistent (mem_read, io_read) | **FSM** - Standardized |
| **Reset Handling** | None | S_RESET state, loads PC from M[0] | **FSM** - Per specification |

## Strengths of Each

### Combinational Control Unit ✅
1. **Simpler instruction decode logic** - Very clean case statement structure
2. **Clear signal assignments** - Easy to understand what each instruction does
3. **Compact code** - Only 136 lines
4. **Good comments** - Well-documented instruction formats

### FSM Control Unit ✅
1. **Specification compliant** - Implements required FSM design
2. **Multi-cycle support** - Proper state transitions for complex operations
3. **Complete interrupt handling** - Saves PC and flags correctly
4. **Reset from M[0]** - Per specification requirement
5. **2-byte instruction support** - Explicit FETCH_OP2 state
6. **Memory access states** - Realistic MEM and WB stages
7. **Standardized naming** - Consistent lowercase_underscore convention

## Hybrid Design Decision

**Winner: FSM Control Unit with Combinational Decode Logic**

The FSM is required by the specification ("design of a Finite State Machine (FSM) Control Unit"), but we can improve it by incorporating the cleaner instruction decode structure from the combinational version.

## Recommended Hybrid Features

1. **Keep FSM states** - Required for multi-cycle operation
2. **Improve DECODE state** - Use cleaner case structure from combinational version
3. **Standardize all naming** - Use lowercase_underscore throughout
4. **Add better comments** - Incorporate instruction format comments
5. **Optimize state transitions** - Reduce unnecessary states where possible

## Final Decision

**Use Control_Unit_FSM.v as the base** with these enhancements:
- ✅ Already has all required FSM states
- ✅ Handles interrupts correctly
- ✅ Supports 2-byte instructions
- ✅ Implements reset from M[0]
- ✅ 100% test pass rate (34/34 tests)

The combinational version will be kept as reference but not used in final integration.
