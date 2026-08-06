# holy_soc
# Holy SoC RISC-V Architecture

This repository tracks the development of a 5-stage pipelined RISC-V System-on-Chip. It currently houses two distinct architectural iterations: a stable baseline using a custom interconnect, and a next-generation architecture implementing standard AMBA AXI and a cache hierarchy.

## Directory Structure

*   `/holy_soc_old/` - Fully working soc.
*   `/holy_soc/` - Active development target with AXI interconnect and cache subsystem.


---

## 1. Baseline Architecture (`holy_soc_old`)
**Status:** Verified / Deprecated for new feature development.

This directory contains the original, verified 5-stage pipeline implementation. It is maintained as a stable reference model.

**Architectural Details:**
*   **Memory Topology:** Strict Harvard architecture. Instruction and Data paths are entirely physically isolated, talking directly to dedicated SRAM blocks.
*   **Interconnect:** Utilizes a proprietary, custom-designed system bus.
*   **Routing:** Relies on a custom, hardcoded address decoder for routing memory-mapped I/O (MMIO) to peripherals like UART and AES.
*   **Timing constraints:** Assumes fixed, single-cycle latency for all memory and peripheral accesses.

**Limitations:** The custom bus protocol creates bottlenecks for scaling. Adding new IP blocks requires manually rewriting the centralized address decoder and multiplexing logic, leading to difficult timing closure and messy RTL.

---

## 2. Next-Generation Architecture (`holy_soc`)
**Status:** Active Development / Integration Testing.

This directory represents the modernized SoC. The core pipeline logic remains similar, but the memory interface and system interconnect have been overhauled to meet industry standards.

**Architectural Details:**
*   **Interconnect:** Replaced the custom bus with an **AXI4/AXI4-Lite interconnect**. All memory and peripheral transactions now utilize standardized read/write address, data, and response channels with proper `VALID`/`READY` handshaking.
*   **Memory Subsystem:** Implementation of a cache system (Instruction and Data caches). The core no longer talks directly to SRAM; it requests data from the cache controllers, which handle AXI transactions to main memory on cache misses.
*   **Pipeline Control:** The hazard detection unit has been updated to handle variable-latency memory accesses. The pipeline will now dynamically stall based on cache miss penalties and AXI bus backpressure.

---

## Verification

To run the standard torture tests on either core:

1.  Compile the firmware test suite targeting the specific architecture's memory map.
2.  Run the Verilog simulation (e.g., using Verilator or Icarus Verilog).
3.  Ensure the new AXI wrappers in `holy_soc` pass standard protocol assertion checks during peripheral integration.
