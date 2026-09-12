# =====================================================================
# Stage 05: Global & Detailed Routing (FastRoute + TritonRoute)
# =====================================================================
# Inputs:  outputs/cts_top.def, constraints.sdc
# Outputs: outputs/routing_top.def, outputs/routing_ibex_core.odb
# Reports: reports/05_routing/* (Congestion, Antenna, DRC, Post-Route STA)
# =====================================================================

source [file join [file dirname [info script]] "helpers" "reporting.tcl"]

ace_log_banner "routing" "Stage 05: FastRoute, Antenna Diode Protection & TritonRoute"

set pdk_root [expr {[info exists ::env(PDK_ROOT)] ? $::env(PDK_ROOT) : "sky130A"}]
set tech_lef "$pdk_root/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd.tlef"
set cell_lef "$pdk_root/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set lib_file "$pdk_root/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

set report_dir "reports/05_routing"
ace_ensure_dir $report_dir
ace_ensure_dir "outputs"

ace_log_section "Step 1: Loading CTS Design"
read_lef $tech_lef
if { [file exists $cell_lef] } { read_lef $cell_lef }
read_liberty $lib_file

if { [file exists "outputs/cts_top.def"] } {
    read_def outputs/cts_top.def
} elseif { [file exists "outputs/placement_top.def"] } {
    read_def outputs/placement_top.def
} else {
    puts "  [WARNING] Placement/CTS DEF not found; running previous stages."
    source [file join [file dirname [info script]] "04_cts.tcl"]
}
read_sdc constraints.sdc
set_propagated_clock [all_clocks]

ace_log_section "Step 2: Global Routing (FastRoute)"
global_route \
    -guide_file outputs/route.guide \
    -congestion_iterations 50 \
    -verbose

ace_log_section "Step 3: Antenna Diode Insertion (Strategy 3)"
# Insert antenna diodes to prevent gate oxide breakdown during fabrication
catch {
    repair_antennas -iterations 5 sky130_fd_sc_hd__diode_2/DIODE
    detailed_placement
}

ace_log_section "Step 4: Detailed Routing (TritonRoute)"
catch {
    detailed_route \
        -output_drc reports/05_routing/tritonroute_drc.rpt \
        -output_maze reports/05_routing/tritonroute_maze.log \
        -verbose 1
}

ace_log_section "Step 5: Generating Post-Route Diagnostic Reports"
ace_run_stage_reports "routing" $report_dir

ace_log_section "Step 6: Writing Stage Deliverables"
write_def outputs/routing_top.def
catch { write_db outputs/routing_ibex_core.odb }
catch { write_verilog outputs/routing_ibex_core.nl.v }

ace_log_tip "Inspect reports/05_routing/congestion.rpt — tile overflow must be 0 for detailed route completion."
ace_log_tip "If detailed route encounters spacing or short DRCs, check macro margins or cell padding."
puts "  [SUCCESS] Routing stage complete. Check: $report_dir"
