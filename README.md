# Ibex RISC-V RV32IMC Silicon Tapeout on SkyWater 130nm

[![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm%20(SKY130A)-blue.svg)](https://github.com/google/skywater-pdk)
[![Core](https://img.shields.io/badge/Core-lowRISC%20Ibex%20RV32IMC-orange.svg)](https://github.com/lowRISC/ibex)
[![Flow](https://img.shields.io/badge/Flow-OpenLane%20%7C%20OpenROAD-success.svg)](https://theopenroadproject.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-lightgrey.svg)](LICENSE)

An end-to-end, fully reproducible, silicon-ready physical implementation of the production **lowRISC Ibex RISC-V CPU core** (RV32IMC) targeting the open-source **SkyWater 130nm High-Density standard cell library** (`sky130_fd_sc_hd`) using the **OpenLane / OpenROAD** toolchain.

---

## Architectural Overview

The **Ibex RISC-V Core** is a 2-stage, in-order 32-bit processor developed by lowRISC, featuring:
* **ISA Support:** RV32I base integer instruction set with `M` (hardware multiplier/divider) and `C` (compressed instructions) extensions.
* **Pipeline:** 2-stage execution pipeline (Instruction Fetch, Instruction Decode/Execute/Writeback) with dynamic branch hazard mitigation.
* **Protection & Security:** Physical Memory Protection (PMP) with configurable privilege modes (Machine & User).
* **Control/Status:** Full RISC-V CSR implementation conforming to privileged architecture v1.11.

```mermaid
graph LR
    subgraph Frontend [Instruction Fetch Stage]
        IF_STAGE[Instruction Fetch] --> IF_BUF[Prefetch Buffer]
        IF_BUF --> COMP_DEC[Compressed Decoder]
    end

    subgraph Backend [Execute & Writeback Stage]
        DEC[Instruction Decoder] --> REGFILE[Register File (32x32)]
        REGFILE --> ALU[ALU & Bit Manipulation]
        REGFILE --> MULDIV[Fast Multiplier / Divider]
        ALU --> WB[Writeback Mux]
        MULDIV --> WB
    end

    subgraph Security [Memory & Protection]
        CSR[CSR Registers] --> PMP[Physical Memory Protection]
        PMP --> LSU[Load-Store Unit]
    end

    COMP_DEC --> DEC
    WB --> REGFILE
```

---

## Physical Design Methodology

| Metric | Target Specification |
| :--- | :--- |
| **Process Node** | SkyWater 130nm CMOS (`sky130A`) |
| **Standard Cell Library** | `sky130_fd_sc_hd` (7-track High Density) |
| **Target Clock Frequency** | **66.7 MHz** ($T_{clk} = 15.000\,\text{ns}$) |
| **Target Core Utilization** | 40% (Square aspect ratio 1.0, 20 $\mu\text{m}$ margin) |
| **Metal Stack** | 5 Metal Layers (`li1`, `met1`, `met2`, `met3`, `met4`, `met5`) |
| **Clock Distribution** | TritonCTS balanced H-tree with root buffer tree |
| **Antenna Protection** | Diode insertion strategy 3 + port protection |
| **Physical Signoff** | Magic DRC clean, Netgen LVS match, multi-corner OpenSTA |

---

## Directory Hierarchy

```text
ibex-sky130-openroad-tapeout/
├── README.md                      # Comprehensive project documentation
├── config/
│   ├── config.json                # OpenLane flow configuration
│   ├── constraints.sdc            # SDC timing constraints (66.7 MHz target)
│   ├── fastroute.tcl              # Global routing layer assignment
│   └── mmmc_corners.tcl           # Multi-corner STA configuration
├── rtl/
│   └── ibex_core.v                # Synthesizable AST-hardened SystemVerilog core
├── outputs/                       # Signoff deliverables (GDSII, DEF, SPEF)
│   ├── ibex_core.gds              # Final mask GDSII stream file
│   ├── ibex_core.def              # Final routed design exchange format
│   └── ibex_core.spef             # Parasitic resistance/capacitance extraction
├── reports/                       # Stage reports (synthesis through signoff)
│   ├── 01_synthesis/              # Cell count, area, logic optimization
│   ├── 02_floorplan/              # Die dimensions, pin placement, PDN IR drop
│   ├── 03_placement/              # Density heatmaps, wirelength estimates
│   ├── 04_cts/                    # Clock skew, insertion delay, buffer count
│   ├── 05_routing/                # DRC clean detailed routing, antenna reports
│   └── 06_signoff/                # Multi-corner STA (WNS/TNS), Magic DRC, Netgen LVS
├── docs/
│   ├── IBEX_TIMING_CLOSURE_REPORT.md  # Detailed technical silicon report
│   └── WALKTHROUGH_VIDEO_SCRIPT.md    # 4-5 min narration walkthrough script
└── scripts/
    └── run_pipeline.sh            # Parameterized reproduction script
```

---

## Reproduction & Pipeline Execution

To run the complete physical design flow against any OpenROAD/OpenLane runner:

```bash
# 1. Clone the repository
git clone https://github.com/hemanthkumardm/ibex-sky130-openroad-tapeout.git
cd ibex-sky130-openroad-tapeout

# 2. Configure the runner endpoint
export OPENROAD_RUNNER_URL="http://your-openroad-host:3000"
export OPENROAD_API_KEY="your-api-key"

# 3. Execute the automated tapeout flow
./scripts/run_pipeline.sh
```

The script streams live execution logs across all 37 OpenLane stages and downloads all verified deliverables into `outputs/` and `reports/`.

---

## Physical Signoff Verification

1. **Multi-Corner Static Timing Analysis (OpenSTA):**
   * Slow-Worst corner (`1.60V`, `100°C`, slow models)
   * Typical corner (`1.80V`, `25°C`, typical models)
   * Fast-Best corner (`1.95V`, `-40°C`, fast models)
   * Setup & Hold slacks closed with zero violations at 66.7 MHz.

2. **Design Rule Checking (Magic):**
   * Manufacturing rule checks (DRC) against SkyWater SKY130 design manual. Zero DRC violations.

3. **Layout Versus Schematic (Netgen LVS):**
   * SPICE netlist extracted from final layout geometry compared with synthesized structural gate netlist. Circuits match uniquely with 100% pin correspondence.

---

## License

* **Hardware Design (Ibex):** Apache License 2.0 (lowRISC contributors)
* **Physical Design Flow & Scripts:** Apache License 2.0 (Ace-Seek Team)
