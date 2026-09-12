# lowRISC Ibex RISC-V RV32IMC — OpenROAD Studio Physical Implementation

[![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm%20(SKY130A)-blue.svg)](https://github.com/google/skywater-pdk)
[![Core](https://img.shields.io/badge/Core-lowRISC%20Ibex%20RV32IMC-orange.svg)](https://github.com/lowRISC/ibex)
[![Studio](https://img.shields.io/badge/Studio-OpenROAD%20Studio%20%7C%20Ace--Seek-emerald.svg)](https://openroad.ace-seek.com)
[![Flow](https://img.shields.io/badge/Flow-OpenLane%20%7C%20OpenROAD-success.svg)](https://theopenroadproject.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-lightgrey.svg)](LICENSE)

An OpenROAD Studio physical implementation and silicon tapeout pack for the **lowRISC Ibex 32-bit RISC-V CPU core** (RV32IMC specification) targeting the open-source **SkyWater 130nm High-Density CMOS PDK** (`sky130_fd_sc_hd`).

This repository provides a fully modular, stage-by-stage physical design suite with comprehensive diagnostics at every phase:
* **Multi-Corner PVT Timing:** Slow (SS, 100°C, 1.60V), Typical (TT, 25°C, 1.80V), and Fast (FF, -40°C, 1.95V) setup & hold analysis.
* **Electrical & SDC Integrity:** Slew, load capacitance, fanout limits, and unconstrained endpoint checks.
* **Clock Network Verification:** TritonCTS skew distribution, latency profiles, and propagated clock STA.
* **Routability & Physical Verification:** Global routing congestion heatmaps, antenna diode protection, Magic DRC, and Netgen LVS.

---

## Physical Design Summary

| Parameter | Specification / Result | Signoff Status |
| :--- | :--- | :--- |
| **Foundry & Node** | SkyWater 130nm High-Density (`sky130A`) | Validated |
| **Standard Cell Library** | `sky130_fd_sc_hd` (7-track standard cells) | Validated |
| **Target Clock Frequency** | **66.7 MHz** ($T_{clk} = 15.000\,\text{ns}$) | **Target Met** |
| **Die Dimensions** | **553.84 μm × 552.16 μm** ($305,808\,\mu\text{m}^2$) | Optimal |
| **Core Dimensions** | **513.84 μm × 512.16 μm** ($263,168\,\mu\text{m}^2$) | 20 μm margin |
| **Standard Cell Area** | **128,125 μm²** | Optimal |
| **Die Utilization** | **41.9%** (OpenROAD floorplan metric: 42%) | Optimal |
| **Core Utilization** | **48.7%** (Standard cell area / core area) | Optimal |
| **Routing Layers** | 5 Metal Layers (`li1`, `met1`, `met2`, `met3`, `met4`, `met5`) | Complete |
| **Antenna Protection** | Diode insertion strategy 3 + port protection | Antenna Clean |
| **Physical Signoff** | Magic DRC (0 errors) & Netgen LVS (Unique match) | Passed |

---

## Stage-by-Stage Debugging & Diagnostic Matrix

Every stage produces dedicated diagnostic reports and metrics under `reports/<stage>/` to make design debugging effortless:

| Stage | Command | Key Diagnostic Reports | What to Debug / Inspect |
| :--- | :--- | :--- | :--- |
| **01. Synthesis** | `make synth` | `synth_check.rpt`<br>`synth_stat.rpt` | Inferred latches, combinational loops, gate count, sequential vs combinational area. |
| **02. Floorplan** | `make floorplan` | `sta_setup.rpt`<br>`sta_hold.rpt`<br>`area_utilization.rpt` | Die/core boundary fit, IO pin spacing on met2/met3, PDN grid IR drop, tapcell spacing. |
| **03. Placement** | `make placement` | `sta_setup.rpt`<br>`slack_histogram.rpt`<br>`electrical_checks.rpt` | Cell density distribution, HPWL wirelength, setup WNS/TNS, max slew/cap violations. |
| **04. CTS** | `make cts` | `clock_skew.rpt`<br>`sta_hold.rpt`<br>`power.rpt` | Balanced clock skew (< 0.35 ns), root buffer insertion, clock latency, hold violations. |
| **05. Routing** | `make route` | `congestion.rpt`<br>`tritonroute_drc.rpt`<br>`electrical_checks.rpt` | Global routing overflow, short/spacing DRCs, antenna ratio violations per net. |
| **06. Signoff** | `make signoff` | `pvt_timing_closure.rpt`<br>`power_signoff.rpt`<br>`signoff_summary.rpt` | Multi-corner PVT matrix (SS/TT/FF), dynamic + leakage power, tapeout scorecard. |

---

## Project Structure

```text
├── ace-seek-flow.json             # OpenROAD Studio flow configuration (tracks all 12 stages)
├── ace-seek-openroad.json         # OpenROAD Studio project manifest
├── constraints.sdc                # Primary SDC timing constraints (66.7 MHz / 15.0 ns)
├── Makefile                       # Comprehensive workflow & debugging targets
├── docker-run.sh                  # Containerized execution wrapper (supports stage args)
├── rtl/
│   └── ibex_core.v                # lowRISC synthesizable RV32IMC top module
├── config/
│   ├── config.json                # OpenLane flow configuration
│   ├── constraints.sdc            # Base timing constraints
│   ├── fastroute.tcl              # Global routing layer assignment
│   └── mmmc_corners.tcl           # Multi-corner STA configuration
├── outputs/                       # Tapeout deliverables
│   ├── final_ibex_core.gds        # Signoff GDSII mask stream (35.6 MB)
│   ├── placement_top.def          # Placed design exchange format (DEF)
│   ├── final_ibex_core.v          # Final gate-level netlist
│   ├── final_ibex_core.nl.v       # Powered gate-level netlist
│   ├── final_ibex_core.sdc        # Signoff timing constraints
│   ├── signoff_ibex_core.gds
│   ├── signoff_ibex_core.magic.gds
│   └── signoff_ibex_core.klayout.gds
├── reports/                       # Tool-generated reports across stages
│   ├── 01_synthesis/              # Cell count, gate statistics, latch checks
│   ├── 02_floorplan/              # Floorplan ODB, IO, tapcell, and PDN logs
│   ├── 03_placement/              # Setup/hold STA, slack histograms, area & power
│   ├── 04_cts/                    # Clock skew, latency profiles, post-CTS timing
│   ├── 05_routing/                # Congestion heatmaps, DRC, antenna violations
│   └── 06_signoff/                # Multi-corner PVT matrix, power, signoff scorecard
├── logs/                          # Execution logs
│   ├── run.log                    # Primary pipeline log
│   └── ol_ibex_core_ibex_core_mty98xin.log
└── scripts/                       # Modular EDA scripts
    ├── helpers/
    │   ├── reporting.tcl          # Unified diagnostic & reporting procedures
    │   └── pvt_corners.tcl        # Multi-corner PVT timing analysis
    ├── 02_floorplan.tcl           # Floorplanning & PDN execution script
    ├── 03_placement.tcl           # Placement & timing optimization script
    ├── 04_cts.tcl                 # Clock tree synthesis script
    ├── 05_routing.tcl             # FastRoute & TritonRoute execution script
    ├── 06_signoff.tcl             # Parasitic extraction & PVT signoff script
    ├── synth.ys                   # Yosys synthesis script
    ├── opensta.tcl                # Standalone multi-corner STA script
    ├── openroad.tcl               # Master multi-stage coordinator script
    ├── run_pipeline.sh            # Parameterized reproduction script
    └── harvest_results.py         # Automated report & artifact harvester
```

---

## User Guide & Workflow Execution

### 1. Interactive Help Menu
```bash
make help
```
Displays all available execution targets, stage commands, and diagnostic targets.

### 2. Run Individual Stages for Debugging
```bash
# Run logic synthesis
make synth

# Run floorplanning & PDN
make floorplan

# Run standard cell placement & post-place STA
make placement

# Run clock tree synthesis & clock skew analysis
make cts

# Run routing & antenna diode repair
make route

# Run physical signoff & multi-corner PVT STA
make signoff
```

### 3. Multi-Corner PVT Static Timing Analysis
To run a standalone timing evaluation across **Slow (SS)**, **Typical (TT)**, and **Fast (FF)** corners:
```bash
make sta-pvt
```
Generates a side-by-side timing scorecard at `reports/sta_analysis/pvt_timing_closure.rpt`.

### 4. Open in OpenROAD Studio (Web)
1. Navigate to [openroad.ace-seek.com](https://openroad.ace-seek.com)
2. Open the **Project** tab and import this repository
3. All stage configurations and inputs automatically load from `ace-seek-flow.json`
4. Use the bottom tabs (**Logs**, **Reports**, **Layout**, **Metrics**) for visual inspection and interactive debugging.

### 5. Run Inside Container
```bash
# Full flow
./docker-run.sh

# Run specific stage (e.g. placement)
./docker-run.sh placement

# Run multi-corner STA
./docker-run.sh sta-pvt
```

### 6. Cloud Runner Pipeline
```bash
export OPENROAD_RUNNER_URL="http://<runner-ip>"
export OPENROAD_OWNER_ID="ibex_tapeout_run_1"
bash scripts/run_pipeline.sh
```

---

## License

* **Hardware Design (Ibex Core):** Copyright lowRISC contributors. Licensed under the Apache License, Version 2.0.
* **Flow Scripts & Configurations:** Apache 2.0.
