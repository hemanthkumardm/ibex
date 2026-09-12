# lowRISC Ibex RISC-V RV32IMC — OpenROAD Studio Project & Results Pack

[![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm%20(SKY130A)-blue.svg)](https://github.com/google/skywater-pdk)
[![Core](https://img.shields.io/badge/Core-lowRISC%20Ibex%20RV32IMC-orange.svg)](https://github.com/lowRISC/ibex)
[![Studio](https://img.shields.io/badge/Studio-OpenROAD%20Studio%20%7C%20Ace--Seek-emerald.svg)](https://openroad.ace-seek.com)
[![Flow](https://img.shields.io/badge/Flow-OpenLane%20%7C%20OpenROAD-success.svg)](https://theopenroadproject.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-lightgrey.svg)](LICENSE)

An authentic **OpenROAD Studio ASIC Project & Run Results Pack** for the **lowRISC Ibex 32-bit RISC-V CPU core** (RV32IMC specification) targeting the open-source **SkyWater 130nm High-Density CMOS PDK** (`sky130_fd_sc_hd`).

In OpenROAD Studio, user repositories contain design specifications and the resulting physical deliverables—the orchestration, tools, and execution scripts are managed seamlessly by the platform engine.

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
| **Core Utilization** | **48.7%** (Standard cell area / core area) | Optimal |
| **Routing Layers** | 5 Metal Layers (`li1`, `met1`, `met2`, `met3`, `met4`, `met5`) | Complete |
| **Antenna Protection** | Diode insertion strategy 3 + port protection | Antenna Clean |
| **Physical Signoff** | Magic DRC (0 errors) & Netgen LVS (Unique match) | Passed |

---

## Repository Layout

```text
├── ace-seek-flow.json         # OpenROAD Studio flow config (filled based on design spec)
├── ace-seek-openroad.json     # OpenROAD Studio project manifest
├── constraints.sdc            # Primary SDC timing constraints (66.7 MHz / 15.0 ns period)
├── rtl/                       # User synthesizable RTL source
│   ├── ibex_core.v            # Synthesizable RV32IMC top module
│   └── ...
├── config/                    # Physical design configuration tailored to spec
│   ├── config.json            # OpenLane parameter configuration
│   ├── constraints.sdc        # Base timing constraints
│   ├── fastroute.tcl          # Global routing layer assignment
│   └── mmmc_corners.tcl       # Multi-corner PVT STA configuration
├── outputs/                   # Results: Physical signoff deliverables
│   ├── final_ibex_core.gds    # Signoff GDSII mask stream (35.6 MB)
│   ├── placement_top.def      # Placed design exchange format (DEF)
│   ├── final_ibex_core.v      # Final gate-level netlist
│   ├── final_ibex_core.nl.v   # Powered gate-level netlist
│   ├── final_ibex_core.sdc    # Signoff timing constraints
│   ├── signoff_ibex_core.gds
│   ├── signoff_ibex_core.magic.gds
│   └── signoff_ibex_core.klayout.gds
├── reports/                   # Results: Tool-generated stage reports
│   ├── 02_floorplan/          # Floorplan database (ODB)
│   ├── 03_placement/          # Post-place STA, power, and area utilization reports
│   ├── 04_cts/                # Clock tree synthesis database
│   ├── 05_routing/            # Detailed routing physical database
│   └── 06_signoff/            # Signoff run metadata
└── logs/                      # Results: EDA tool execution logs
    ├── 02_floorplan/          # Floorplan sub-step logs
    │   ├── 4-io.log           # IO pin placement engine log (OpenROAD)
    │   ├── 5-tap.log          # Welltap/decap insertion log
    │   └── 6-pdn.log          # Power distribution network (PDN) log
    ├── run.log                # Master pipeline log
    └── ol_ibex_core_ibex_core_mty98xin.log
```

---

## OpenROAD Studio Architecture & Workflow

OpenROAD Studio provides an intuitive, cloud-native ASIC physical design workflow:

1. **Project Input & Template:**
   * The user inputs a project directory or links a GitHub repository.
   * OpenROAD Studio supplies the project template structure (`rtl/`, `constraints.sdc`, `config/`, and `ace-seek-flow.json`).
   * Required configurations are filled based on the design specifications (target clock, density, aspect ratio, PDK).

2. **Platform Execution:**
   * The user clicks the **Run** button in OpenROAD Studio.
   * All heavy EDA toolchains (Yosys, OpenROAD, TritonCTS, FastRoute, TritonRoute, Magic, Netgen) run on isolated platform runners with real-time log streaming and interactive visual layout.

3. **Results Persistence:**
   * When a Git repository is connected, results (`outputs/`, `reports/`, `logs/`) are committed and stored directly in the repository.
   * If run without a repository, results are securely stored in Supabase with a 2-day download lifespan so users can inspect metrics in Studio and download their artifact pack.

---

## License

* **Hardware Design (Ibex Core):** Copyright lowRISC contributors. Licensed under the Apache License, Version 2.0.
* **Flow Configurations:** Apache 2.0.
