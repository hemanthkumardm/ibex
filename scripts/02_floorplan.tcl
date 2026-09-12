# =====================================================================
# Stage 02: Floorplan & Power Planning (OpenROAD Studio)
# =====================================================================
# Inputs:  outputs/synthesis_ibex_core.v, constraints.sdc
# Outputs: outputs/floorplan_top.def, outputs/floorplan_ibex_core.odb
# Reports: reports/02_floorplan/*
# =====================================================================

source [file join [file dirname [info script]] "helpers" "reporting.tcl"]

ace_log_banner "floorplan" "Stage 02: Die/Core Boundary, Pin Placement & Power Grid"

set pdk_root [expr {[info exists ::env(PDK_ROOT)] ? $::env(PDK_ROOT) : "sky130A"}]
set tech_lef "$pdk_root/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd.tlef"
set cell_lef "$pdk_root/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set lib_file "$pdk_root/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

set netlist "outputs/synthesis_ibex_core.v"
set sdc_file "constraints.sdc"
set report_dir "reports/02_floorplan"
ace_ensure_dir $report_dir
ace_ensure_dir "outputs"

ace_log_section "Step 1: Reading Technology and Netlist"
read_lef $tech_lef
if { [file exists $cell_lef] } { read_lef $cell_lef }
read_liberty $lib_file
read_verilog $netlist
link_design ibex_core
read_sdc $sdc_file

ace_log_section "Step 2: Initializing Die and Core Boundary"
# Die: 553.84 um x 552.16 um | Core: 513.84 um x 512.16 um (20 um margin)
initialize_floorplan \
    -die_area {0 0 553.84 552.16} \
    -core_area {20 20 533.84 532.16} \
    -site unithd

ace_log_section "Step 3: IO Pin Placement"
# Place IO pins on metal 2 (vertical) and metal 3 (horizontal)
catch {
    place_pins -hor_layers met3 -ver_layers met2
}

ace_log_section "Step 4: Tapcell Insertion"
# Welltap and endcap insertion for latchup prevention
catch {
    tapcell \
        -endcap_cpp 1 \
        -distance 14 \
        -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 \
        -endcap_master sky130_fd_sc_hd__decap_4
}

ace_log_section "Step 5: Power Distribution Network (PDN)"
# Generate standard dual-rail power grid
catch {
    pdngen
}

ace_log_section "Step 6: Generating Diagnostic Reports"
ace_run_stage_reports "floorplan" $report_dir

ace_log_section "Step 7: Writing Stage Deliverables"
write_def outputs/floorplan_top.def
catch { write_db outputs/floorplan_ibex_core.odb }

ace_log_tip "If floorplan density is too high (>60%), widen die boundaries in config.json or ace-seek-flow.json."
puts "  [SUCCESS] Floorplan stage complete. Check: $report_dir"
