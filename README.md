# RISC-V Custom Processor (RV32I Pipeline)

A custom 5-stage pipelined RISC-V (RV32I) processor implemented in Verilog. This project includes a complete simulation environment and an automated build toolchain for running bare-metal C applications.

## Features
* **5-Stage Pipeline**: IF, ID, EX, MEM, WB stages.
* **Hazard Handling**: Full support for Load-Use and Branch hazards with forwarding logic and stall units.
* **Automated Toolchain**: Cross-compiles C/Assembly code using `riscv64-unknown-elf-gcc` and executes via Vivado XSim.
* **Bare-Metal Support**: Minimal startup code (`crt0.S`) and a custom test API for immediate simulation feedback.

## Project Structure
* `/src`: Verilog hardware source code.
* `/tb`: Simulation testbench.
* `/firmware`: C/Assembly source code and build scripts.
* `/scripts`: Automation utilities for Windows/WSL interoperability.

## Getting Started

### Prerequisites
* **Windows** with Vivado installed.
* **WSL (Windows Subsystem for Linux)** with the [RISC-V GNU Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain) installed.

### Running a Simulation
1. Write your code in `/firmware/src/`.
2. Open PowerShell in the project root.
3. Run the automation script:
   `.\scripts\build_and_run.ps1`

The script will compile the firmware, generate the memory initialization file, and launch the Vivado simulation automatically.

## Testing
The testbench uses Memory-Mapped I/O (MMIO). Your C code can signal the simulator by writing to specific reserved addresses (0x07FC):

* `test_pass()`: Ends simulation with a PASS status.
* `test_done_with_result(int)`: Ends simulation and prints the value.