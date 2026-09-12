# =====================================================================
# Stage 04: Clock Tree Synthesis (CTS) & Hold Optimization
# =====================================================================
# Inputs:  outputs/placement_top.def, constraints.sdc
# Outputs: outputs/cts_top.def, outputs/cts_ibex_core.odb, outputs/cts_ibex_core.sdc
# Reports: reports/04_cts/* (Clock Skew, Latency, Setup, Hold)
# =====================================================================

source [file join [file dirname [info script]] "helpers" "reporting.tcl"]

ace_log_banner "cts" "Stage 04: TritonCTS Balanced Tree Insertion & Propagated Clock STA"

set pdk_root [expr {[info exists ::env(PDK_ROOT)] ? $::env(PDK_ROOT) : "sky130A"}]
set tech_lef "$pdk_root/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd.tlef"
set cell_lef "$pdk_root/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set lib_file "$pdk_root/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

set report_dir "reports/04_cts"
ace_ensure_dir $report_dir
ace_ensure_dir "outputs"

ace_log_section "Step 1: Loading Placed Design"
read_lef $tech_lef
if { [file exists $cell_lef] } { read_lef $cell_lef }
read_liberty $lib_file

if { [file exists "outputs/placement_top.def"] } {
    read_def outputs/placement_top.def
} else {
    puts "  [WARNING] outputs/placement_top.def not found; running placement first."
    source [file join [file dirname [info script]] "03_placement.tcl"]
}
read_sdc constraints.sdc

ace_log_section "Step 2: Synthesizing Clock Tree (TritonCTS)"
# Balanced H-tree with SkyWater clock buffers
clock_tree_synthesis \
    -buf_list {sky130_fd_sc_hd__clkbuf_16 sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_4} \
    -root_buf sky130_fd_sc_hd__clkbuf_16

ace_log_section "Step 3: Setting Propagated Clock Mode"
set_propagated_clock [all_clocks]

ace_log_section "Step 4: Post-CTS Resizer Hold Timing Repair"
catch {
    repair_timing -hold -buffer_cell sky130_fd_sc_hd__buf_2
}

ace_log_section "Step 5: Legalizing Buffer Placement"
detailed_placement

ace_log_section "Step 6: Generating Clock Skew & Post-CTS STA Reports"
ace_run_stage_reports "cts" $report_dir

ace_log_section "Step 7: Writing Stage Deliverables"
write_def outputs/cts_top.def
catch { write_db outputs/cts_ibex_core.odb }
catch { write_sdc outputs/cts_ibex_core.sdc }

ace_log_tip "Inspect reports/04_cts/clock_skew.rpt — target clock skew on sky130 should be < 0.35 ns."
ace_log_tip "If hold violations appear post-CTS, repair_timing -hold will insert buffer delay lines."
puts "  [SUCCESS] CTS stage complete. Check: $report_dir"
