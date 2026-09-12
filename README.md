# lowRISC Ibex RISC-V RV32IMC — OpenROAD Studio Physical Implementation

[![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm%20(SKY130A)-blue.svg)](https://github.com/google/skywater-pdk)
[![Core](https://img.shields.io/badge/Core-lowRISC%20Ibex%20RV32IMC-orange.svg)](https://github.com/lowRISC/ibex)
[![Studio](https://img.shields.io/badge/Studio-OpenROAD%20Studio%20%7C%20Ace--Seek-emerald.svg)](https://openroad.ace-seek.com)
[![Flow](https://img.shields.io/badge/Flow-OpenLane%20%7C%20OpenROAD-success.svg)](https://theopenroadproject.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-lightgrey.svg)](LICENSE)

An OpenROAD Studio physical implementation and silicon tapeout pack for the **lowRISC Ibex 32-bit RISC-V CPU core** (RV32IMC specification) targeting the open-source **SkyWater 130nm High-Density CMOS PDK** (`sky130_fd_sc_hd`).

This repository contains the complete OpenROAD Studio project configuration, synthesizable RTL, SDC constraints, automated stage reports, and tapeout deliverables (GDSII, DEF, gate-level netlists).

---

## Physical Design Summary

| Parameter | Specification / Result | Status |
| :--- | :--- | :--- |
| **Foundry & Node** | SkyWater 130nm High-Density (`sky130A`) | Validated |
| **Standard Cell Library** | `sky130_fd_sc_hd` (7-track standard cells) | Validated |
| **Target Clock Frequency** | **66.7 MHz** ($T_{clk} = 15.000\,\text{ns}$) | **Target Met** |
| **Die Dimensions** | **553.84 μm × 552.16 μm** ($305,808\,\mu\text{m}^2$) | Optimal |
| **Core Dimensions** | **513.84 μm × 512.16 μm** ($263,168\,\mu\text{m}^2$) | 20 μm margin |
| **Standard Cell Area** | **128,125 μm²** | Optimal |
| **Die Utilization** | **41.9%** (OpenROAD floorplan metric: 42%) | Optimal |
| **Core Utilization** | **48.7%** (Standard cell / core area) | Optimal |
| **Routing Layers** | 5 Metal Layers (`li1`, `met1`, `met2`, `met3`, `met4`, `met5`) | Complete |
| **Diode Strategy** | Diode insertion strategy 3 + port protection | Antenna Clean |
| **Physical Verification** | Magic DRC & Netgen LVS | Passed |

---

## OpenROAD Studio Stage Status

The physical design flow was executed through all 12 stages tracked in `ace-seek-flow.json`:

```text
[✓] 01. Lint         — Verilator syntax and semantic linting
[✓] 02. Simulation   — Icarus Verilog functional testbench execution
[✓] 03. Synthesis    — Yosys logic synthesis & ABC technology mapping (AREA 0)
[✓] 04. IO Planner   — Boundary pin placement across metal 2 / metal 3
[✓] 05. Floorplan    — Die/core boundary sizing (553.84 x 552.16 um) & tap insertion
[✓] 06. Powerplan    — Dual-layer PDN power grid & strap generation
[✓] 07. Placement    — Global placement, detailed placement, and timing optimization
[✓] 08. CTS          — TritonCTS balanced clock tree buffer insertion
[✓] 09. Route        — FastRoute global routing & TritonRoute detailed routing
[✓] 10. DRC          — Magic full-mask design rule checking
[✓] 11. LVS          — Netgen device and netlist correspondence verification
[✓] 12. GDS          — Mask stream generation via Magic and KLayout
```

---

## Project Structure

```text
├── ace-seek-flow.json         # OpenROAD Studio flow configuration & stage parameters
├── ace-seek-openroad.json     # OpenROAD Studio project manifest
├── constraints.sdc            # Primary SDC timing constraints (66.7 MHz / 15.0 ns)
├── Makefile                   # Flow execution targets (synth, sta, pnr, pipeline)
├── docker-run.sh              # Containerized local execution helper
├── rtl/
│   └── ibex_core.v            # lowRISC synthesizable RV32IMC top module
├── config/
│   ├── config.json            # OpenLane physical design configuration
│   ├── constraints.sdc        # Base timing constraints
│   ├── fastroute.tcl          # Global routing layer assignment
│   └── mmmc_corners.tcl       # Multi-corner STA PVT configuration
├── outputs/                   # Physical signoff deliverables
│   ├── final_ibex_core.gds    # Signoff GDSII mask stream (35.6 MB)
│   ├── placement_top.def      # Placed design exchange format (DEF)
│   ├── final_ibex_core.v      # Final gate-level netlist
│   ├── final_ibex_core.nl.v   # Powered gate-level netlist
│   ├── final_ibex_core.sdc    # Signoff timing constraints
│   ├── signoff_ibex_core.gds  # Signoff mask stream
│   ├── signoff_ibex_core.magic.gds
│   └── signoff_ibex_core.klayout.gds
├── reports/                   # Tool-generated reports across stages
│   ├── 02_floorplan/          # Floorplan ODB, IO, tapcell, and PDN logs
│   ├── 03_placement/          # Timing bundle, power bundle, and area utilization reports
│   ├── 04_cts/                # Clock tree synthesis database
│   ├── 05_routing/            # Post-routing physical database
│   └── 06_signoff/            # Signoff run metadata
├── logs/                      # Execution logs
│   ├── run.log                # Primary pipeline log
│   └── ol_ibex_core_ibex_core_mty98xin.log
└── scripts/                   # Tool and flow scripts
    ├── run_pipeline.sh        # Parameterized reproduction script
    ├── harvest_results.py     # Automated report and artifact harvester
    ├── synth.ys               # Yosys synthesis script
    ├── opensta.tcl            # OpenSTA static timing analysis script
    └── openroad.tcl           # OpenROAD PnR script
```

---

## Reproduction

### Option A: Open in OpenROAD Studio (Web)
1. Navigate to [openroad.ace-seek.com](https://openroad.ace-seek.com)
2. Open the **Project** tab and import this repository or upload a zip export
3. All stage configurations and inputs will automatically populate from `ace-seek-flow.json`

### Option B: Run via Makefile
```bash
# Run synthesis and OpenSTA timing checks
make all

# Run full physical design flow via pipeline script
make pipeline
```

### Option C: Run in Container
```bash
# Uses official OpenLane/OpenROAD container
./docker-run.sh
```

### Option D: Run with Custom Runner
```bash
export OPENROAD_RUNNER_URL="http://<your-runner-ip>"
export OPENROAD_OWNER_ID="ibex_tapeout_run_1"
bash scripts/run_pipeline.sh
```

---

## License

* **Hardware Design (Ibex Core):** Copyright lowRISC contributors. Licensed under the Apache License, Version 2.0.
* **Flow Scripts & Configurations:** Apache 2.0.
