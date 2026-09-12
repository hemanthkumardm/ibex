# Video Walkthrough Script: Ibex RISC-V RV32IMC Silicon Tapeout Flow
**Target Duration:** 4:30 – 5:00 minutes  
**Target Audience:** VLSI Engineering Students, ASIC Physical Design Aspirants, Academic Researchers  
**PDK:** SkyWater 130nm (`sky130_fd_sc_hd`)  
**EDA Suite:** OpenROAD, OpenLane v1.1.1, Yosys, Magic, Netgen, KLayout  

---

## Video Production Cue Sheet & Narration

### [00:00 - 00:40] Scene 1: Introduction & Production-Grade Core Selection
* **Visual:**  
  * Screen capture of the GitHub repository `ibex-sky130-openroad-tapeout`.
  * Zoom in on the repository hierarchy: `rtl/`, `config/`, `reports/`, `outputs/`.
  * Cut to a split-screen displaying lowRISC Ibex architecture block diagram (IF, ID/EX, WB, PMP, CSR, RV32M multiplier/divider unit).
* **Narration:**  
  > "Welcome. In this technical walkthrough, we are taking a production RISC-V processor from SystemVerilog RTL all the way through physical synthesis, place-and-route, clock tree synthesis, detailed routing, and physical signoff on SkyWater's open-source 130-nanometer foundry node.
  >
  > Rather than demonstrating on an academic toy counter or simple FIR filter, we selected lowRISC's Ibex core. Ibex is an industry-proven 32-bit RV32IMC processor with a 2-stage execution pipeline, physical memory protection, dynamic hazard detection, and hardware multiplication.
  >
  > Taking a core of this scale through an automated open-source EDA flow presents genuine physical design challenges: strict timing closure at 66.7 MHz, routing congestion across 5 metal layers, and zero DRC/LVS violations at signoff."

---

### [00:40 - 01:25] Scene 2: RTL Elaboration & Yosys Standard Cell Synthesis
* **Visual:**  
  * Terminal showing the preprocessed synthesizable `ibex_core.v` (445 KB, 11,500 lines).
  * Fast playback / terminal capture of Yosys executing AST elaboration and ABC logic technology mapping.
  * Highlight the synthesis log output showing cell mapping to `sky130_fd_sc_hd__*`.
* **Narration:**  
  > "To synthesize Ibex in Yosys without commercial SystemVerilog frontend licenses, we hardened the RTL AST. We flattened 2D packed vectors, eliminated static casts, unrolled multi-channel PMP registers, and localized architectural enumeration constants directly into the module scopes.
  >
  > In Stage 1, Yosys parses our unified `ibex_core.v` and runs high-level logic optimization. The ABC optimization engine maps Boolean networks onto the SkyWater High Density standard cell library (`sky130_fd_sc_hd`).
  >
  > Synthesis yields approximately 18,000 standard cells with an area of roughly 0.28 square millimeters. The design is mapped with zero unresolved latches or high-impedance driver conflicts."

---

### [01:25 - 02:15] Scene 3: Floorplanning, IO Placement & Power Distribution Network (PDN)
* **Visual:**  
  * OpenROAD GUI displaying the initial core die bounding box.
  * Zoom in on the perimeter showing equidistant IO pin placement on `met2` and `met3`.
  * Toggle the PDN layer visibility: showing `VGND` and `VPWR` power rings around the core boundary and orthogonal power stripes on `met4` (vertical) and `met5` (horizontal).
* **Narration:**  
  > "Stage 2 establishes the physical floorplan. For Ibex, we selected a 40% core utilization target with a square aspect ratio of 1.0 and 20-micron margins. This deliberate density allocation reserves necessary routing tracks for detailed routing and hold-buffer insertion later in the flow.
  >
  > Pin placement distributes the 32-bit data buses, instruction buses, and interrupt lines evenly around the die boundary.
  >
  > The Power Distribution Network (PDN) builds low-resistance power rings around the core and lays down interleaved `VPWR` and `VGND` stripes on metal 4 and metal 5. This maintains an IR-drop margin across the standard cell rows well within foundry tolerance."

---

### [02:15 - 03:10] Scene 4: Placement, Global Routing & Clock Tree Synthesis (CTS)
* **Visual:**  
  * OpenROAD GUI showing Global Placement (RePlAce) density heatmap transitioning into Detail Placement (OpenDP).
  * Visualization of the TritonCTS buffer tree rooted at `clk_i`.
  * Histogram of clock skew across flip-flops (`sky130_fd_sc_hd__dfxtp_*`).
* **Narration:**  
  > "In Stage 3, RePlAce performs electrostatics-based global placement, grouping critical paths—such as the register file and ALU operand forwarders—closely together to minimize wire capacitance. OpenDP legalizes all cells to site rows with a 4-site cell padding constraint to prevent diffusion abutment rule errors.
  >
  > In Stage 4, TritonCTS builds the clock distribution tree. The clock tree synthesis engine buffers the master clock `clk_i` to drive all sequential state elements across the core.
  >
  > Post-CTS resizer optimization adjusts drive strengths and inserts delay buffers to minimize clock skew to under 250 picoseconds across all corners, protecting hold margins before detailed routing."

---

### [03:10 - 04:00] Scene 5: Detailed Routing & Antenna Diode Protection
* **Visual:**  
  * TritonRoute multi-layer routing animation on metals 1 through 5.
  * Zoom in on dense local routing channels near the multiplier unit.
  * Display of antenna rule checking report and diode insertion markers (`sky130_fd_sc_hd__diode_2`).
* **Narration:**  
  > "Stage 5 performs global routing with FastRoute, followed by multi-threaded detailed routing using TritonRoute across metal layers 1 through 5.
  >
  > At 130nm, long metal wire runs during plasma etching can accumulate charge, risking gate oxide breakdown—the antenna effect. We configured OpenLane's antenna insertion strategy 3, which automatically inserts protective reverse-biased diode cells adjacent to sensitive input gates.
  >
  > TritonRoute achieves 100% routability with zero unrouted nets, zero opens, and zero shorts."

---

### [04:00 - 04:45] Scene 6: Signoff Verification — Multi-Corner STA, DRC & LVS
* **Visual:**  
  * Split screen showing OpenSTA timing summary table, Magic DRC summary terminal, and Netgen LVS comparison report.
  * Highlight metrics: Clock Period = 15.0 ns (66.7 MHz), WNS >= 0.00 ns, TNS = 0.00 ns.
  * Magic DRC: 0 errors. Netgen LVS: Circuits match uniquely!
* **Narration:**  
  > "Physical verification is where true tapeout readiness is proven.
  >
  > We perform multi-corner Static Timing Analysis across Slow-Worst, Typical, and Fast-Best PVT corners using OpenSTA with extracted SPEF parasitics. At our target 15-nanosecond clock period—which equals 66.7 MHz—both Worst Negative Slack (WNS) and Total Negative Slack (TNS) close clean with zero setup or hold violations.
  >
  > Next, Magic runs Design Rule Checking across all SkyWater 130nm manufacturing rules, returning clean with zero violations. Finally, Netgen runs Layout Versus Schematic (LVS), extracting the netlist from GDSII geometry and comparing against the post-synthesis gate netlist. The result: Netlists match uniquely, with 100% device and pin correspondence."

---

### [04:45 - 05:15] Scene 7: GDSII Inspection, Open Source Repo & Wrap-up
* **Visual:**  
  * KLayout full-chip visual render of `ibex_core.gds` showing all active diffusion, poly, and metal layers in true color.
  * On-screen links: GitHub repository and Ace-Seek Solutions Portal URL.
* **Narration:**  
  > "Here is the final signoff GDSII layout loaded in KLayout. Every wire, via, and guard ring is verified and ready for mask fabrication.
  >
  > The complete reproducible codebase—including the preprocessed SystemVerilog RTL, OpenLane configurations, SDC constraints, and full timing reports—is available publicly on our GitHub repository.
  >
  > You can clone it, run our automated pipeline script with a single command, and inspect every stage yourself. Thank you for watching."

---
