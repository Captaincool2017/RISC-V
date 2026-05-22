# Technical Handoff: RISC-V Pipeline Core

## Core Architecture
- **Hazard Detection**: The core uses a combinational `hazard_detection_unit.v` to manage stalls. Load-use hazards are resolved by flushing the ID/EX stage (inserting a NOP bubble) while stalling the PC and IF/ID stages.
- **Forwarding**: The `forwarding_unit.v` implements EX/MEM to EX and MEM/WB to EX bypass paths to resolve data dependencies without stalling.
- **Memory Map**: 
    - 0x0000 - 0x0FFF: 4KB Data Memory.
    - 0x07F8: Testbench Result Register.
    - 0x07FC: Testbench Control Register (Write 1=Pass, 2=Fail, 3=Result).

## Known Implementation Quirks
- **Simulation Timing**: To avoid race conditions, the testbench monitors the `data_memory` array directly in the `tb_core.v` file rather than watching internal wires.
- **Toolchain**: The `build_and_run.ps1` script maps the Windows project directory into the WSL environment, allowing the `riscv64` cross-compiler to generate binaries that are then converted to Verilog-compatible `.mem` files.

## Future Improvements
- [ ] Implement `LUI` and `AUIPC` instructions to support arbitrary memory addressing.
- [ ] Expand data memory to include a dedicated Peripheral bus for UART/IO.
- [ ] Add support for hardware interrupts (CLINT).