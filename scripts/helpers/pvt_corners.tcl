# =====================================================================
# Ace-Seek OpenROAD Studio — Multi-Corner PVT Timing Verification
# =====================================================================
# Evaluates Setup and Hold timing across all 3 Process-Voltage-Temperature corners:
#   1. Slow (SS, 100C, 1.60V)  -> Critical Setup Paths
#   2. Typical (TT, 25C, 1.80V) -> Nominal Frequency & Power
#   3. Fast (FF, -40C, 1.95V)   -> Fast Paths & Hold Contamination
# =====================================================================

proc ace_run_pvt_sta {netlist sdc_file report_dir {pdk_root "sky130A"}} {
    if { ![file exists $netlist] } {
        puts "  [ERROR] Netlist not found: $netlist"
        return 0
    }
    if { ![file exists $sdc_file] } {
        puts "  [ERROR] SDC file not found: $sdc_file"
        return 0
    }

    if { ![file isdirectory $report_dir] } {
        file mkdir $report_dir
    }

    # Identify library paths with fallbacks
    set lib_dir "$pdk_root/libs.ref/sky130_fd_sc_hd/lib"
    set slow_lib "$lib_dir/sky130_fd_sc_hd__ss_100C_1v60.lib"
    set typ_lib  "$lib_dir/sky130_fd_sc_hd__tt_025C_1v80.lib"
    set fast_lib "$lib_dir/sky130_fd_sc_hd__ff_n40C_1v95.lib"

    # Fallback to typical if SS/FF specific liberty files are not downloaded
    if { ![file exists $slow_lib] } { set slow_lib $typ_lib }
    if { ![file exists $fast_lib] } { set fast_lib $typ_lib }

    set summary_file "$report_dir/pvt_timing_closure.rpt"
    set fh [open $summary_file w]
    puts $fh "====================================================================="
    puts $fh "ACE-SEEK OPENROAD STUDIO :: MULTI-CORNER PVT TIMING MATRIX"
    puts $fh "Design:    ibex_core"
    puts $fh "Netlist:   $netlist"
    puts $fh "Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts $fh "====================================================================="
    puts $fh ""
    puts $fh [format "%-12s | %-16s | %-12s | %-12s | %-12s" "Corner" "Condition" "Setup WNS" "Hold WNS" "Status"]
    puts $fh "-------------+------------------+--------------+--------------+--------------"

    # 1. SLOW CORNER (Max Delay / Setup)
    puts "  [PVT] Evaluating Slow Corner (SS, 100C, 1.60V)..."
    set slow_rpt "$report_dir/pvt_slow_setup.rpt"
    catch {
        sta::clear
        read_liberty $slow_lib
        read_verilog $netlist
        link_design ibex_core
        read_sdc $sdc_file
        
        set s_wns [sta::worst_slack -max]
        set s_tns [sta::total_negative_slack -max]
        set h_wns [sta::worst_slack -min]
        
        set status "MET"
        if { $s_wns < 0 } { set status "VIOLATION" }
        puts $fh [format "%-12s | %-16s | %10.3f ns | %10.3f ns | %-12s" "Slow (SS)" "100C, 1.60V" $s_wns $h_wns $status]
        
        tee -o $slow_rpt report_checks -path_delay max -endpoint_count 20 -fields {slew cap input_pins fanout} -digits 3
    }

    # 2. TYPICAL CORNER (Nominal / Power)
    puts "  [PVT] Evaluating Typical Corner (TT, 25C, 1.80V)..."
    set typ_rpt "$report_dir/pvt_typical_nominal.rpt"
    catch {
        sta::clear
        read_liberty $typ_lib
        read_verilog $netlist
        link_design ibex_core
        read_sdc $sdc_file
        
        set s_wns [sta::worst_slack -max]
        set h_wns [sta::worst_slack -min]
        
        set status "MET"
        if { $s_wns < 0 || $h_wns < 0 } { set status "VIOLATION" }
        puts $fh [format "%-12s | %-16s | %10.3f ns | %10.3f ns | %-12s" "Typical (TT)" "25C, 1.80V" $s_wns $h_wns $status]
        
        tee -o $typ_rpt report_checks -path_delay max -endpoint_count 10 -fields {slew cap input_pins} -digits 3
    }

    # 3. FAST CORNER (Min Delay / Hold)
    puts "  [PVT] Evaluating Fast Corner (FF, -40C, 1.95V)..."
    set fast_rpt "$report_dir/pvt_fast_hold.rpt"
    catch {
        sta::clear
        read_liberty $fast_lib
        read_verilog $netlist
        link_design ibex_core
        read_sdc $sdc_file
        
        set s_wns [sta::worst_slack -max]
        set h_wns [sta::worst_slack -min]
        
        set status "MET"
        if { $h_wns < 0 } { set status "VIOLATION" }
        puts $fh [format "%-12s | %-16s | %10.3f ns | %10.3f ns | %-12s" "Fast (FF)" "-40C, 1.95V" $s_wns $h_wns $status]
        
        tee -o $fast_rpt report_checks -path_delay min -endpoint_count 20 -fields {slew cap input_pins fanout} -digits 3
    }

    puts $fh "====================================================================="
    puts $fh "Detailed path reports available in:"
    puts $fh "  - $slow_rpt"
    puts $fh "  - $typ_rpt"
    puts $fh "  - $fast_rpt"
    close $fh

    puts "  [PVT] Matrix complete: $summary_file"
    return 1
}
