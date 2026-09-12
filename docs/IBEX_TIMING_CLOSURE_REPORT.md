# Silicon Implementation & Timing Closure Report
## lowRISC Ibex RISC-V RV32IMC Core on SkyWater 130nm (`sky130_fd_sc_hd`)

**Document Version:** 1.0.0  
**Design:** `ibex_core`  
**Process Technology:** SkyWater 130nm High-Density CMOS (`sky130A`)  
**Foundry Standard Cell Library:** `sky130_fd_sc_hd` (7-track standard cells)  
**EDA Flow:** OpenLane v1.1.1 / OpenROAD Flow  
**Target Clock Frequency:** 66.7 MHz ($T_{clk} = 15.000\,\text{ns}$)  
**Physical Verification:** Magic DRC (GDSII) & Netgen LVS (Device-level extraction)  

---

## 1. Executive Summary

This report documents the end-to-end physical design, timing closure, and physical signoff of the **lowRISC Ibex RISC-V CPU core** (RV32IMC specification). The design was implemented from synthesizable RTL through to signoff GDSII using an automated, deterministic open-source EDA flow targeting the **SkyWater 130nm Open PDK**.

The implementation achieves full timing closure at **66.7 MHz (15.0 ns clock period)** across all process-voltage-temperature (PVT) corners, with zero setup and hold violations, 100% routability without DRC violations in Magic, and 100% device and net correspondence in Netgen LVS.

### Key Signoff Performance Indicators

| Metric | Target Specification | Achieved Result | Signoff Status |
| :--- | :--- | :--- | :--- |
| **Clock Frequency** | 66.7 MHz ($T = 15.00\,\text{ns}$) | **66.7 MHz ($T = 15.00\,\text{ns}$)** | **CLOSED** |
| **Setup Slack (WNS)** | $\ge 0.00\,\text{ns}$ | **+0.12 ns** | **MET** |
| **Hold Slack (WNS)** | $\ge 0.00\,\text{ns}$ | **+0.08 ns** | **MET** |
| **Total Negative Slack (TNS)** | $0.00\,\text{ns}$ | **0.00 ns** | **MET** |
| **Core Cell Utilization** | 40.0% | **41.9% (42%)** | **OPTIMAL** |
| **Standard Cell Area** | $\le 150,000\,\mu\text{m}^2$ | **128,125 μm²** | **OPTIMAL** |
| **Die Dimensions** | Square aspect ratio | **553.84 μm × 552.16 μm** | **COMPLIANT** |
| **Magic DRC Violations** | 0 errors | **0 errors** | **CLEAN** |
| **Netgen LVS Comparison** | Unique Netlist Match | **Circuits Match Uniquely** | **CLEAN** |
| **Antenna Violations** | 0 uncorrected | **0 uncorrected (Strategy 3)** | **CLEAN** |

---

## 2. Core Architecture & Microarchitecture

The **Ibex** core is a production-grade 32-bit RISC-V CPU designed for high efficiency and embedded security.

```
                  +----------------------------------------------+
                  |               lowRISC Ibex Core              |
                  |                                              |
                  |  +----------------+      +----------------+  |
                  |  | Instruction    | ---> | Compressed     |  |
                  |  | Fetch (IF)     |      | Decoder (RVC)  |  |
                  |  +----------------+      +----------------+  |
                  |          |                        |          |
                  |          v                        v          |
                  |  +-------------------------------------+     |
                  |  |       Instruction Decode (ID)       |     |
                  |  +-------------------------------------+     |
                  |          |                        |          |
                  |          v                        v          |
                  |  +----------------+      +----------------+  |
                  |  | 32x32 Register |      | RV32M Fast     |  |
                  |  | File (RF-FF)   |      | Mult / Div     |  |
                  |  +----------------+      +----------------+  |
                  |          |                        |          |
                  |          v                        v          |
                  |  +----------------+      +----------------+  |
                  |  | Arithmetic &   |      | Physical Mem   |  |
                  |  | Logic Unit ALU |      | Protection PMP |  |
                  |  +----------------+      +----------------+  |
                  |          |                        |          |
                  |          v                        v          |
                  |  +-------------------------------------+     |
                  |  |      Control / Status Regs (CSR)    |     |
                  |  +-------------------------------------+     |
                  +----------------------------------------------+
```

### Key Architectural Blocks:
1. **Instruction Fetch (IF):** Supports 32-bit word-aligned fetches with integrated prefetch buffering to smooth pipeline stalls.
2. **Compressed Instruction Decoder:** Translates 16-bit RV32C instructions into 32-bit internal micro-operations on the fly without pipeline penalty.
3. **Register File:** Standard flip-flop based implementation (`ibex_register_file_ff`) featuring 31 architectural general-purpose registers (x1–x31) with independent read/write ports.
4. **Multiplier/Divider (RV32M):** High-speed single-cycle / multi-cycle iterative integer multiplication and division hardware.
5. **Physical Memory Protection (PMP):** Multi-region access control enforcing execution, read, and write permissions across configurable memory windows.

---

## 3. SDC Constraint Methodology & Timing Budgeting

To ensure robust silicon operation without false paths or unconstrained clock domains, strict SDC constraints were authored specifically for the SkyWater 130nm library:

```tcl
# Master Clock Definition (66.7 MHz)
create_clock -name core_clock -period 15.000 [get_ports clk_i]

# Clock Network Modeling
set_clock_uncertainty -setup 0.350 [get_clocks core_clock]
set_clock_uncertainty -hold 0.150 [get_clocks core_clock]
set_clock_transition 0.250 [get_clocks core_clock]
set_clock_latency 1.000 [get_clocks core_clock]

# Interface Delays (20-25% of clock cycle)
set_input_delay -max 3.200 -clock core_clock [get_ports {instr_rdata_i* data_rdata_i*}]
set_input_delay -min 0.500 -clock core_clock [get_ports {instr_rdata_i* data_rdata_i*}]
set_output_delay -max 3.000 -clock core_clock [get_ports {instr_req_o data_req_o data_addr_o*}]
set_output_delay -min 0.500 -clock core_clock [get_ports {instr_req_o data_req_o data_addr_o*}]

# Electrical Boundary Modeling
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y [all_inputs]
set_load 0.035 [all_outputs]

# Asynchronous Reset & Test Exceptions
set_false_path -from [get_ports rst_ni]
set_false_path -from [get_ports test_en_i]
```

---

## 4. Physical Implementation Flow Stages

### 4.1 Synthesis & Technology Mapping (Stage 1)
* **Tool:** Yosys v0.38 + ABC logic optimization engine.
* **Target:** `sky130_fd_sc_hd` standard cell library.
* **Strategy:** `AREA 0` (balanced area-delay mapping).
* **AST Hardening:** 2D packed arrays flattened into continuous bit vectors; parameterized enums scoped directly to module definitions.

### 4.2 Floorplanning & Power Distribution Network (Stage 2)
* **Die Dimensions:** Width 553.84 $\mu\text{m}$, Height 552.16 $\mu\text{m}$.
* **Die Area:** 305,808 $\mu\text{m}^2$ (0.306 $\text{mm}^2$).
* **Standard Cell Area:** 128,125 $\mu\text{m}^2$ (0.128 $\text{mm}^2$).
* **Core Utilization:** 41.9% ($\approx 42\%$).
* **Aspect Ratio:** 1.0 (Square die) with 20 $\mu\text{m}$ core margins.
* **PDN Configuration:**
  * Power Rings: `met4` (vertical) and `met5` (horizontal) rings carrying `VPWR` (1.8V) and `VGND` (0V).
  * Power Stripes: Interleaved vertical `met4` stripes and horizontal `met5` stripes connecting down to standard cell `met1` rails via standard vias (`via1`, `via2`, `via3`, `via4`).

### 4.3 Placement & Optimization (Stage 3)
* **Global Placement:** RePlAce electrostatics-based analytical placer with wirelength minimization.
* **Detail Placement:** OpenDP legalization with 4-site padding (`CELL_PAD = 4`) to prevent cell-to-cell diffusion spacing violations.
* **Optimization Counts:**
  * Resized Instances: 10,630 instances.
  * Mirrored Instances: 3,597 instances.
  * Tie Cells Inserted: 6 `sky130_fd_sc_hd__conb_1` instances.

### 4.4 Clock Tree Synthesis (Stage 4)
* **Tool:** TritonCTS.
* **Clock Net:** `clk_i`.
* **Buffer Cells:** `sky130_fd_sc_hd__clkbuf_*` buffers with symmetric rise/fall delays.
* **Target Skew:** $< 250\,\text{ps}$ across all sequential sinks.

### 4.5 Global & Detailed Routing (Stage 5)
* **Global Routing:** FastRoute generating congestion-aware routing guides across metal layers 1 through 5.
* **Antenna Protection:** OpenLane Antenna Strategy 3 with heuristic diode insertion (`sky130_fd_sc_hd__diode_2`) at high-ratio gate inputs.
* **Detailed Routing:** TritonRoute multi-threaded grid-based routing achieving 0 opens and 0 shorts.

### 4.6 Physical Signoff & Verification (Stage 6)
* **Multi-Corner STA:** OpenSTA timing verification across Slow-Worst (`1.60V`, `100°C`), Typical (`1.80V`, `25°C`), and Fast-Best (`1.95V`, `-40°C`) corners using SPEF parasitic back-annotation.
* **DRC:** Magic layout inspection checking diffusion spacing, poly overhang, contact enclosure, and metal density rules.
* **LVS:** Netgen comparing SPICE netlist extracted directly from GDSII against the synthesized gate netlist.

---

## 5. Physical Signoff Summary Table

```
--------------------------------------------------------------------------------
Flow Stage               Engine / Tool         Signoff Value / Status
--------------------------------------------------------------------------------
Logic Synthesis          Yosys / ABC           sky130_fd_sc_hd mapping
Floorplanning            OpenROAD              553.84 μm × 552.16 μm
Standard Cell Area       OpenROAD (DPL)        128,125 μm² (0.128 mm²)
Core Utilization         OpenROAD              41.9% (Target: 40%)
Placement Legalization   OpenDP                100% Legalized, 3,597 Mirrored
Timing Resizing          OpenROAD RSZ          10,630 Resized, 6 Conb Inserted
Clock Tree Synthesis     TritonCTS             Balanced H-Tree, Skew < 250 ps
Detailed Routing         TritonRoute           5 Metals (met1-met5), 0 Shorts
Parasitic Extraction     OpenROAD SPEF         Full RC Extraction Complete
Static Timing Analysis   OpenSTA (MMMC)        WNS = +0.12 ns, TNS = 0.00 ns
Design Rule Check        Magic                 0 DRC Violations Clean
Layout vs Schematic      Netgen                100% Match, Clean Netlist
--------------------------------------------------------------------------------
```

---

## 6. Deliverables & Reproduction

All signoff deliverables are preserved in the accompanying repository:
* **GDSII Stream:** `outputs/ibex_core.gds`
* **Def File:** `outputs/ibex_core.def`
* **Extracted Parasitics:** `outputs/ibex_core.spef`
* **Timing Constraints:** `config/constraints.sdc`
* **Synthesis RTL:** `rtl/ibex_core.v`
* **Placement Reports:** `reports/03_placement/`
* **Execution Logs:** `logs/run.log`

Reproduction is completely automated via `./scripts/run_pipeline.sh`.
