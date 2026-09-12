# =====================================================================
# Stage 03: Standard Cell Placement & Timing Optimization
# =====================================================================
# Inputs:  outputs/floorplan_top.def (or rerun floorplan), constraints.sdc
# Outputs: outputs/placement_top.def, outputs/placement_ibex_core.odb
# Reports: reports/03_placement/* (Setup, Hold, Slack, Area, Power)
# =====================================================================

source [file join [file dirname [info script]] "helpers" "reporting.tcl"]

ace_log_banner "placement" "Stage 03: Global Placement, Detailed Placement & Resizer Optimization"

set pdk_root [expr {[info exists ::env(PDK_ROOT)] ? $::env(PDK_ROOT) : "sky130A"}]
set tech_lef "$pdk_root/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd.tlef"
set cell_lef "$pdk_root/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set lib_file "$pdk_root/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

set report_dir "reports/03_placement"
ace_ensure_dir $report_dir
ace_ensure_dir "outputs"

ace_log_section "Step 1: Loading Design and Constraints"
read_lef $tech_lef
if { [file exists $cell_lef] } { read_lef $cell_lef }
read_liberty $lib_file

if { [file exists "outputs/floorplan_top.def"] } {
    read_def outputs/floorplan_top.def
} else {
    read_verilog outputs/synthesis_ibex_core.v
    link_design ibex_core
    initialize_floorplan -die_area {0 0 553.84 552.16} -core_area {20 20 533.84 532.16} -site unithd
    catch { place_pins -hor_layers met3 -ver_layers met2 }
}
read_sdc constraints.sdc

ace_log_section "Step 2: Global Placement (RePlace Engine)"
# Target density: 45%, Cell padding: 4 sites for routability
catch {
    set_placement_padding -global -left 4 -right 4
}
global_placement -density 0.45

ace_log_section "Step 3: Resizer Pre-CTS Timing Optimization"
# Buffer long high-fanout nets and size gates to minimize setup slack
catch {
    repair_design -buffer_cell sky130_fd_sc_hd__buf_4
    repair_tie_fanout -separation 5 sky130_fd_sc_hd__conb_1/HI
    repair_tie_fanout -separation 5 sky130_fd_sc_hd__conb_1/LO
}

ace_log_section "Step 4: Detailed Placement (Legalization)"
detailed_placement

ace_log_section "Step 5: Generating Post-Placement STA & Diagnostic Reports"
ace_run_stage_reports "placement" $report_dir

ace_log_section "Step 6: Writing Stage Deliverables"
write_def outputs/placement_top.def
catch { write_db outputs/placement_ibex_core.odb }
catch { write_verilog outputs/placement_ibex_core.nl.v }

ace_log_tip "If setup WNS is negative at placement: check constraints.sdc clock uncertainty, or try reducing target density."
ace_log_tip "Inspect reports/03_placement/slack_histogram.rpt to see the distribution of path delays."
puts "  [SUCCESS] Placement stage complete. Check: $report_dir"
