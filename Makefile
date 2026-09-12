# Ace-Seek OpenROAD Studio Makefile — design ibex_core
TOP ?= ibex_core
PDK ?= sky130
YOSYS ?= yosys
OPENSTA ?= sta
OPENROAD ?= openroad

.PHONY: all synth sta pnr pipeline docker-hint clean

all: synth sta

synth:
	mkdir -p outputs
	$(YOSYS) -c scripts/synth.ys

sta: synth
	$(OPENSTA) -exit scripts/opensta.tcl

pnr: synth
	$(OPENROAD) -exit scripts/openroad.tcl

pipeline:
	bash scripts/run_pipeline.sh

docker-hint:
	@echo 'Local Docker: docker run --rm -v $$PWD:/work -w /work efabless/openlane:v0.9 bash -lc "scripts/run_pipeline.sh"'
	@echo 'Ace-Seek Studio: upload project on openroad.ace-seek.com -> Project'

clean:
	rm -rf outputs/*.tmp
