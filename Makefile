# =====================================================================
# Ace-Seek OpenROAD Studio — Flow Makefile (ibex_core)
# =====================================================================
# Comprehensive, stage-by-stage targets for physical design & debugging
# =====================================================================

TOP       ?= ibex_core
PDK       ?= sky130
YOSYS     ?= yosys
OPENSTA   ?= sta
OPENROAD  ?= openroad

.PHONY: all synth floorplan placement cts route signoff pnr sta-pvt reports pipeline docker-run help clean

help:
	@echo "====================================================================="
	@echo "ACE-SEEK OPENROAD STUDIO :: ASIC WORKFLOW & DEBUGGING TARGETS"
	@echo "====================================================================="
	@echo "Design: $(TOP) | PDK: $(PDK)"
	@echo ""
	@echo "Stage Execution Targets:"
	@echo "  make synth       - Run Yosys RTL synthesis & generate gate stats"
	@echo "  make floorplan   - Run die/core sizing, IO pin placement & PDN grid"
	@echo "  make placement   - Run global/detailed placement & post-place STA"
	@echo "  make cts         - Run TritonCTS balanced clock tree synthesis"
	@echo "  make route       - Run FastRoute & TritonRoute with antenna repair"
	@echo "  make signoff     - Run parasitic extraction & multi-corner PVT STA"
	@echo "  make all         - Run full flow from synthesis through signoff"
	@echo ""
	@echo "Diagnostics & Analysis Targets:"
	@echo "  make sta-pvt     - Run standalone multi-corner PVT STA (Slow/Typ/Fast)"
	@echo "  make reports     - List all diagnostic reports across stages"
	@echo "  make pnr         - Run Master OpenROAD coordinator (scripts/openroad.tcl)"
	@echo "  make pipeline    - Run automated reproduction pipeline script"
	@echo "  make docker-run  - Run complete flow inside OpenLane Docker container"
	@echo "  make clean       - Remove temporary files"
	@echo "====================================================================="

all: synth pnr

synth:
	@mkdir -p outputs reports/01_synthesis
	@echo ">>> [Stage 01] Running Logic Synthesis (Yosys)..."
	$(YOSYS) -c scripts/synth.ys

floorplan:
	@mkdir -p outputs reports/02_floorplan
	@echo ">>> [Stage 02] Running Floorplan & Power Planning..."
	STAGE=floorplan $(OPENROAD) -exit scripts/openroad.tcl

placement:
	@mkdir -p outputs reports/03_placement
	@echo ">>> [Stage 03] Running Standard Cell Placement & STA..."
	STAGE=placement $(OPENROAD) -exit scripts/openroad.tcl

cts:
	@mkdir -p outputs reports/04_cts
	@echo ">>> [Stage 04] Running Clock Tree Synthesis (CTS)..."
	STAGE=cts $(OPENROAD) -exit scripts/openroad.tcl

route:
	@mkdir -p outputs reports/05_routing
	@echo ">>> [Stage 05] Running Routing & Antenna Diode Repair..."
	STAGE=routing $(OPENROAD) -exit scripts/openroad.tcl

signoff:
	@mkdir -p outputs reports/06_signoff
	@echo ">>> [Stage 06] Running Multi-Corner PVT Signoff..."
	STAGE=signoff $(OPENROAD) -exit scripts/openroad.tcl

pnr:
	@mkdir -p outputs reports logs
	@echo ">>> Running Master OpenROAD Pipeline..."
	$(OPENROAD) -exit scripts/openroad.tcl

sta-pvt:
	@mkdir -p reports/sta_analysis
	@echo ">>> Running Comprehensive Multi-Corner PVT Static Timing Analysis..."
	$(OPENSTA) -exit scripts/opensta.tcl

pipeline:
	@bash scripts/run_pipeline.sh

docker-run:
	@./docker-run.sh

reports:
	@echo "====================================================================="
	@echo "ACE-SEEK OPENROAD STUDIO :: GENERATED DIAGNOSTIC REPORTS"
	@echo "====================================================================="
	@find reports -type f -name "*.rpt" | sort | sed 's/^/  [REPORT] /'
	@echo "====================================================================="

clean:
	rm -rf outputs/*.tmp reports/*/*.tmp
