# =====================================================================
# Ace-Seek OpenROAD Studio — Standalone Timing & PVT Signoff Analysis
# =====================================================================
# Usage:
#   sta -exit scripts/opensta.tcl
#   NETLIST=outputs/final_ibex_core.v sta -exit scripts/opensta.tcl
# =====================================================================

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir "helpers" "reporting.tcl"]
source [file join $script_dir "helpers" "pvt_corners.tcl"]

ace_log_banner "STA" "Ace-Seek OpenROAD Studio :: Comprehensive Static Timing Analysis"

set pdk_root [expr {[info exists ::env(PDK_ROOT)] ? $::env(PDK_ROOT) : "sky130A"}]
set lib_file "$pdk_root/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Determine netlist (final routed netlist preferred, fallback to synthesis)
set netlist "outputs/final_ibex_core.v"
if { [info exists ::env(NETLIST)] && $::env(NETLIST) ne "" } {
    set netlist $::env(NETLIST)
} elseif { ![file exists $netlist] } {
    set netlist "outputs/synthesis_ibex_core.v"
}

set sdc_file "constraints.sdc"
set report_dir "reports/sta_analysis"
ace_ensure_dir $report_dir

puts "  Target Netlist:    $netlist"
puts "  Constraints File:  $sdc_file"
puts "  Report Directory:  $report_dir"

ace_log_section "Step 1: Reading Liberty, Netlist and SDC"
read_liberty $lib_file
read_verilog $netlist
link_design ibex_core
read_sdc $sdc_file

ace_log_section "Step 2: Nominal Timing & Power Analysis"
ace_report_timing_setup "$report_dir/sta_setup_nominal.rpt" 25
ace_report_timing_hold "$report_dir/sta_hold_nominal.rpt" 25
ace_report_slack_histogram "$report_dir/slack_histogram.rpt"
ace_report_design_checks "$report_dir/electrical_checks.rpt"
ace_report_power "$report_dir/power_nominal.rpt"

ace_log_section "Step 3: Multi-Corner PVT Timing Verification"
# Evaluates Slow, Typical, Fast corners side-by-side
ace_run_pvt_sta $netlist $sdc_file $report_dir $pdk_root

ace_log_section "Step 4: Timing Scorecard Summary"
puts ""
puts "========================================================================"
puts "  STA VERIFICATION FINISHED"
puts "  Reports generated in: $report_dir"
puts "    - sta_setup_nominal.rpt     (Worst 25 setup paths with slew/cap)"
puts "    - sta_hold_nominal.rpt      (Worst 25 hold paths)"
puts "    - slack_histogram.rpt       (Distribution of slack values)"
puts "    - electrical_checks.rpt     (Slew, capacitance & fanout violators)"
puts "    - power_nominal.rpt         (Dynamic and leakage power breakdown)"
puts "    - pvt_timing_closure.rpt    (Side-by-side Slow/Typical/Fast matrix)"
puts "========================================================================"
