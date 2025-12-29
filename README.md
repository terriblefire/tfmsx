# TFMSX

[![Run Tests](https://github.com/terriblefire/tfmsx/actions/workflows/run-tests.yml/badge.svg)](https://github.com/terriblefire/tfmsx/actions/workflows/run-tests.yml)
[![Build CPLD Firmware](https://github.com/terriblefire/tfmsx/actions/workflows/build-firmware.yml/badge.svg)](https://github.com/terriblefire/tfmsx/actions/workflows/build-firmware.yml)
[![Generate Gerbers](https://github.com/terriblefire/tfmsx/actions/workflows/gerbers.yml/badge.svg)](https://github.com/terriblefire/tfmsx/actions/workflows/gerbers.yml)
[![Generate Schematic PDF](https://github.com/terriblefire/tfmsx/actions/workflows/schematic-pdf.yml/badge.svg)](https://github.com/terriblefire/tfmsx/actions/workflows/schematic-pdf.yml)
[![Generate Assembly Files](https://github.com/terriblefire/tfmsx/actions/workflows/generate_assembly.yml/badge.svg)](https://github.com/terriblefire/tfmsx/actions/workflows/generate_assembly.yml)

A homebrew MSX2 machine using as many of the original chips as possible, with custom CPLD logic to implement the MSX slot system, memory mapper, and bus interface.

## Discord

Join the TF discord for help 

https://discord.gg/Q5zfusgnmH 

## Overview

TFMSX is an open-source hardware implementation of the MSX2 standard that combines authentic MSX chips (VDP, PSG, CPU) with modern programmable logic. The design uses a Xilinx XC95288XL CPLD to handle:

- MSX slot system (4 primary slots + secondary slot expansion)
- Memory mapper (512KB SRAM organized as 32 pages of 16KB)
- I/O address decoding and bus arbitration
- Clock generation and distribution
- Real-time clock (RP5C01A) interface

## Features

- **MSX2 Compatible**: Full MSX2 slot architecture with expansion capability
- **Original Components**: Uses genuine Yamaha V9958 VDP, YM2149 PSG, Z80 CPU
- **512KB RAM**: Memory mapper providing 32 banks of 16KB
- **Real-time Clock**: RP5C01A battery-backed RTC
- **Expansion Slots**: Support for cartridges and expansion boards
- **Multiple Revisions**: Hardware evolved through rev0 → rev1 → rev2 with improvements
- **Comprehensive Testing**: Automated test suite with CI/CD integration

## Hardware Revisions

The current repository contains the **Rev 2** design (see `boards/tfmsxr2/`), which includes:

- Improved audio output and PSG interface
- VDP reset control
- SRAM write enable (SWR pin)
- Fixed WAIT signal generation for proper Z80 timing
- Corrected slot select logic

Previous hardware revisions (Rev 0, Rev 1) are documented in the Eagle design files under `eagle/tfmsx_rev*.brd/sch`.

## Repository Structure

```
tfmsx/
├── rtl/                    # Verilog RTL source code
│   ├── tfmsx_top.v        # Top-level CPLD module
│   ├── clocks.v           # Clock generation (CPU, PSG, slot clocks)
│   └── rp5c01a.v          # Real-time clock module
├── boards/                 # Board-specific build configurations
│   ├── tfmsxr2/           # Revision 2 board (current)
│   ├── Makefile.cpld      # Common CPLD build rules
│   ├── Makefile.inc       # Docker/Xilinx environment setup
│   └── boards.txt         # List of board configurations
├── testsuite/             # Verification test benches
│   ├── bus/               # Bus interface tests (SRAM, ROM, VDP, PSG, slots)
│   │   ├── test_sram_access.v    # SRAM read/write tests
│   │   ├── test_rom_access.v     # ROM access tests
│   │   ├── test_vdp_io.v         # VDP I/O tests
│   │   ├── test_psg_io.v         # PSG I/O tests
│   │   ├── test_slot_access.v    # Slot system tests
│   │   ├── bus_fixture.vinc      # Common test fixture
│   │   ├── bus_tasks.vinc        # Reusable bus cycle tasks
│   │   └── Makefile              # Test build rules
│   ├── rtl/               # Simulation support files (Xilinx primitives)
│   ├── clocks.vinc        # Clock generation for tests
│   ├── unittest.vinc      # Test assertion macros
│   └── Makefile.inc       # Common test environment setup
├── eagle/                 # Eagle CAD hardware designs
│   ├── tfmsx.sch/.brd     # Main board schematic and layout
│   ├── extract_bom.py     # BOM extraction script
│   └── Makefile           # Automated Gerber/PDF/BOM generation
├── roms/                  # MSX system ROM tools
│   ├── Makefile           # Automated ROM download and assembly
│   └── makedefaultroms.sh # Legacy script (deprecated)
└── .github/workflows/        # CI/CD automation
    ├── run-tests.yml         # Automated test execution
    ├── gerbers.yml           # Gerber file generation
    ├── schematic-pdf.yml     # PDF schematic generation
    └── generate_assembly.yml # BOM and CPL generation
```

## Building the CPLD Firmware

### Prerequisites

- **Linux**: Xilinx ISE 10.1 installed at `/opt/Xilinx/10.1/`
- **macOS/Windows**: Docker (automatically builds and uses container)

The build system automatically handles Docker on non-Linux platforms.

### Build All Boards

```bash
cd boards
make all
```

This compiles CPLD firmware for all boards listed in `boards/boards.txt` and generates `.jed` JEDEC programming files.

### Build Specific Board

```bash
cd boards/tfmsxr2
make
```

Output: `tfmsxr2_top.jed` (JEDEC programming file) and `tfmsxr2_top.svf` (Serial Vector Format)

### Clean Build Artifacts

```bash
cd boards
make clean       # Remove intermediate build files
make distclean   # Remove all generated files including .jed
```

### Create Release Package

```bash
cd boards
make zip
```

Generates: `tfmsx_YYYY_MM_DD_<git-hash>.zip` containing all board `.jed` files.

## Programming the CPLD

Flash the CPLD using xc3sprog with an FT232H-based programmer:

```bash
cd boards/tfmsxr2
make flash
```

This requires:
- xc3sprog tool installed
- FT232H USB programmer connected
- Proper JTAG connections to the XC95288XL

## MSX System ROMs

The `roms/` directory contains a Makefile to download and prepare MSX2 system ROMs for use with the TFMSX hardware.

### Building System ROMs

```bash
cd roms
make           # Download ROMs and create default.rom
make -j8       # Parallel download (faster)
make clean     # Remove all generated files
```

The Makefile automatically downloads MSX2 BIOS ROMs from the BlueMSX emulator repository and creates a combined ROM image with multiple banks:

- **Bank 0**: MSX2 (Standard) + MSX2EXT + DISK ROM
- **Bank 1**: MSX2BR (Brazilian) + MSX2BREXT + DISK ROM
- **Bank 2**: MSX2P (MSX2+) + MSX2PEXT + DISK ROM
- **Bank 3**: MSX2SP (Spanish MSX2+) + MSX2SPEXT + DISK ROM

The final output is `default.rom`, which contains all four banks concatenated together. This allows the TFMSX hardware to support multiple MSX2 configurations by bank switching.

**Features**:
- Dependency tracking: Only downloads missing files
- Incremental builds: Only rebuilds changed targets
- Parallel downloads: Use `-j` flag for faster downloads
- Clean target: Easy cleanup with `make clean`

**Note**: These ROMs are copyrighted by their respective manufacturers. Only links are provided. 

## Technical Details

### Memory Map

| Address Range | Function |
|---------------|----------|
| 0x0000-0x3FFF | Page 0 (slot configurable) |
| 0x4000-0x7FFF | Page 1 (slot configurable) |
| 0x8000-0xBFFF | Page 2 (slot configurable) |
| 0xC000-0xFFFF | Page 3 (slot configurable) |

Each page can be mapped to any of 4 slots via the slot register (I/O port 0xA8).

### I/O Port Map

| Port(s) | Device | Function |
|---------|--------|----------|
| 0x98-0x9B | VDP | Yamaha V9958 Video Display Processor |
| 0xA0-0xA3 | PSG | Yamaha YM2149 Programmable Sound Generator |
| 0xA8-0xAB | PPI | 8255 Programmable Peripheral Interface (slot register) |
| 0xB4 | RTC | RP5C01A address latch |
| 0xB5 | RTC | RP5C01A data register |
| 0xFC-0xFF | Mapper | Memory mapper page registers (32 banks × 16KB) |

### Clock Frequencies

- **Master Clock**: 28 MHz (crystal oscillator)
- **CPU Clock (CLKCPU)**: 3.5 MHz (÷8)
- **PSG Clock (PSGCLK)**: 1.75 MHz (÷16)
- **Slot Clock (SLOTCLK)**: 3.5 MHz (÷8)

### CPLD Resources

- **Target Device**: Xilinx XC95288XL-10-TQ144
- **Macrocells**: 288
- **Package**: 144-pin TQFP
- **Speed Grade**: -10 (100 MHz)

Utilization varies by revision but typically uses 70-85% of available macrocells.

## Testing

The `testsuite/` directory contains Verilog testbenches for verifying CPLD functionality. Tests use Icarus Verilog for simulation.

### Running Tests

```bash
cd testsuite/bus
make              # Run all tests
make clean        # Clean generated files
```

### Test Coverage

The test suite includes comprehensive coverage of bus operations:

- **test_sram_access.v**: SRAM read/write operations, chip select timing, mapper control
- **test_rom_access.v**: ROM output enable, address decoding, data bus behavior
- **test_vdp_io.v**: VDP I/O ports (0x98-0x9B), read/write signals, timing
- **test_psg_io.v**: PSG I/O ports (0xA0-0xA2), control signals
- **test_slot_access.v**: MSX slot system, memory mapping, slot registers (0xA8, 0xFC-0xFF)

Each test verifies:
- Correct signal timing and activation
- Proper address decoding
- Bus protocol compliance
- Memory/peripheral access patterns

Tests automatically generate waveform files (`.vcd`) for debugging.

### Continuous Integration

All tests run automatically on push via GitHub Actions. Test status is visible in the badge at the top of this README.

## Development Workflow

1. **Modify RTL**: Edit Verilog files in `rtl/`
2. **Run Tests**: `cd testsuite/bus && make` to verify changes (see [Testing](#testing) section)
3. **Build CPLD**: `cd boards/tfmsxr2 && make`
4. **Flash Hardware**: `make flash` (if hardware available)
5. **Test on Hardware**: Verify functionality on physical board

## VDP Configuration

The TFMSX board supports both V9938 and V9958 video display processors. The VDP chip type is selected using jumpers JP3 and JP4. The CPLD automatically handles all other configuration differences.

### Jumper Settings

| VDP Chip | JP3 (Single Position) | JP4 (Two Position) |
|----------|----------------------|-------------------|
| **V9938** | **Closed** | **Left Position** |
| **V9958** | **Open** | **Right Position** |

**Jumper Types**:
- **JP3**: Single position jumper - either closed (jumper installed) or open (no jumper)
- **JP4**: Two position jumper - set to either left or right position

**Configuration Summary**:
- **V9938**: JP3 closed, JP4 left position
- **V9958**: JP3 open, JP4 right position

The CPLD logic uses these jumper settings to configure timing and control signals appropriately for the installed VDP chip.

## Hardware Design Files

Eagle CAD schematics and board layouts are in `eagle/`:

- **Main Board**: `tfmsx.sch` / `tfmsx.brd` (Rev 2 - current design)
- **Previous Revisions**: `tfmsx_rev0.*`, `tfmsx_rev1.*` (historical reference)

### Generating Gerber Files

The `eagle/` directory includes a Makefile for automated Gerber generation using Docker (no Eagle installation required).

```bash
cd eagle
make               # Generate Gerbers for main TFMSX board
make pdf           # Generate PDF schematic for main board
make bom           # Generate Bill of Materials (BOM) CSV
make cpl           # Generate Component Placement List (CPL) CSV
make assembly      # Generate both BOM and CPL for assembly
```

Output files are named with git commit hash and date (e.g., `tfmsx_a1b2c3d_2025_11_14.zip`).

**Requirements**:
- Docker with `terriblefire78/eagle:v1` and `terriblefire78/eagle-pdf` images (for gerbers and PDF)
- Python 3 (for BOM/CPL generation)

### Assembly Files (BOM and CPL)

Generate assembly files for PCB fabrication and assembly:

```bash
cd eagle
make assembly      # Generate both BOM and CPL
```

This creates two files for JLCPCB/PCBA services:

**BOM (`tfmsx_bom.csv`)** contains:
- **Comment**: Component value/part number
- **Designator**: Reference designators (e.g., C1, C2, R5)
- **Footprint**: PCB footprint package
- **LCSC Part #**: LCSC/JLCPCB part number (if available)

**CPL (`tfmsx_cpl.csv`)** contains:
- **Designator**: Component reference
- **Mid X, Mid Y**: Component center position in mm
- **Layer**: Top or Bottom
- **Rotation**: Component rotation in degrees

The BOM groups identical components together for easy ordering and assembly.

## Contributing

This is an open hardware project. Contributions welcome for:

- RTL improvements and optimizations
- Additional test coverage (please include tests for new features)
- Hardware revision suggestions
- Documentation enhancements
- Bug fixes

When contributing RTL changes, please ensure all tests pass by running `cd testsuite/bus && make`.

## License

This work is licensed under the Creative Commons Attribution-NoDerivatives 4.0 International License.

Copyright (c) 2021-2025 Stephen J. Leary

You are free to:
- **Share** - copy and redistribute the material in any medium or format for any purpose, even commercially

Under the following terms:
- **Attribution** - You must give appropriate credit, provide a link to the license, and indicate if changes were made
- **NoDerivatives** - If you remix, transform, or build upon the material, you may not distribute the modified material

See the [LICENSE](LICENSE) file for the complete license text, or visit:
https://creativecommons.org/licenses/by-nd/4.0/

## References

- [MSX Technical Documentation](https://www.msx.org/)
- [MSX Resource Center](https://www.msx.org/wiki/)
- MSX2 Technical Handbook
- Z80 CPU User Manual
- [Yamaha V9958 VDP Documentation](https://www.msx.org/wiki/Yamaha_V9958)

## Contact

For questions, issues, or contributions, please use the GitHub issue tracker.




