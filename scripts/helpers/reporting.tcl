# =====================================================================
# Ace-Seek OpenROAD Studio — Unified Diagnostic & Reporting Procedures
# =====================================================================
# Provides friendly, standardized reporting across all physical design stages:
#  - Multi-corner STA (Setup / Hold / Slack Histograms)
#  - Design Rule Checks (Slew, Cap, Fanout, Unconstrained)
#  - Power Analysis (Internal, Switching, Leakage)
#  - Area & Density Metrics (Standard cell, Macro, Utilization)
#  - Clock Network Analysis (Skew, Latency, Insertion Delay)
#  - Congestion & Routability Evaluation
# =====================================================================

# ── Terminal Logging Banner ──────────────────────────────────────────
proc ace_log_banner {stage title} {
    set width 72
    set sep [string repeat "=" $width]
    set sub [string repeat "-" $width]
    set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    puts ""
    puts $sep
    puts "  ACE-SEEK OPENROAD STUDIO :: [string toupper $stage]"
    puts "  $title"
    puts "  Timestamp: $ts"
    puts $sep
    puts ""
}

proc ace_log_section {title} {
    puts ""
    puts "  ------------------------------------------------------------------"
    puts "  >> $title"
    puts "  ------------------------------------------------------------------"
}

proc ace_log_tip {msg} {
    puts "  [DEBUG TIP] $msg"
}

# ── Ensure Directory Exists ──────────────────────────────────────────
proc ace_ensure_dir {dir} {
    if { ![file isdirectory $dir] } {
        file mkdir $dir
    }
}

# ── Setup Timing Report (Max Delay / Slow Corner) ────────────────────
proc ace_report_timing_setup {report_file {max_paths 20}} {
    ace_ensure_dir [file dirname $report_file]
    puts "  -> Generating Setup STA Report: $report_file"
    
    set fh [open $report_file w]
    puts $fh "====================================================================="
    puts $fh "ACE-SEEK OPENROAD STUDIO: SETUP TIMING REPORT (MAX DELAY)"
    puts $fh "Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts $fh "====================================================================="
    puts $fh ""
    close $fh

    # Append OpenSTA outputs directly
    if { [catch {
        # Worst slack and total negative slack
        set wns [sta::worst_slack -max]
        set tns [sta::total_negative_slack -max]
        set f_stat [open $report_file a]
        puts $f_stat [format "Summary: Setup WNS = %8.3f ns | Setup TNS = %8.3f ns" $wns $tns]
        if { $wns < 0 } {
            puts $f_stat "Status:  VIOLATING SETUP TIMING (Closure Required)"
        } else {
            puts $f_stat "Status:  MET (Zero Setup Violations)"
        }
        puts $f_stat "---------------------------------------------------------------------"
        close $f_stat
    } err] } {
        # Fallback for generic STA
    }

    # Detailed path checks
    catch {
        tee -a $report_file report_checks -path_delay max -fields {slew cap input_pins fanout} -digits 3 -endpoint_count $max_paths
    }
    
    # Also log brief summary to console
    catch {
        puts "  -> Setup WNS: [sta::worst_slack -max] ns | Setup TNS: [sta::total_negative_slack -max] ns"
    }
}

# ── Hold Timing Report (Min Delay / Fast Corner) ─────────────────────
proc ace_report_timing_hold {report_file {max_paths 20}} {
    ace_ensure_dir [file dirname $report_file]
    puts "  -> Generating Hold STA Report: $report_file"
    
    set fh [open $report_file w]
    puts $fh "====================================================================="
    puts $fh "ACE-SEEK OPENROAD STUDIO: HOLD TIMING REPORT (MIN DELAY)"
    puts $fh "Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts $fh "====================================================================="
    puts $fh ""
    close $fh

    if { [catch {
        set wns [sta::worst_slack -min]
        set tns [sta::total_negative_slack -min]
        set f_stat [open $report_file a]
        puts $f_stat [format "Summary: Hold WNS  = %8.3f ns | Hold TNS  = %8.3f ns" $wns $tns]
        if { $wns < 0 } {
            puts $f_stat "Status:  VIOLATING HOLD TIMING (Buffer Insertion / Delay Pad Required)"
        } else {
            puts $f_stat "Status:  MET (Zero Hold Violations)"
        }
        puts $f_stat "---------------------------------------------------------------------"
        close $f_stat
    } err] } {
        # Fallback
    }

    catch {
        tee -a $report_file report_checks -path_delay min -fields {slew cap input_pins fanout} -digits 3 -endpoint_count $max_paths
    }

    catch {
        puts "  -> Hold WNS:  [sta::worst_slack -min] ns | Hold TNS:  [sta::total_negative_slack -min] ns"
    }
}

# ── Slack Distribution Histogram ─────────────────────────────────────
proc ace_report_slack_histogram {report_file} {
    ace_ensure_dir [file dirname $report_file]
    puts "  -> Generating Timing Slack Histogram: $report_file"
    
    set fh [open $report_file w]
    puts $fh "====================================================================="
    puts $fh "ACE-SEEK OPENROAD STUDIO: SLACK DISTRIBUTION HISTOGRAM"
    puts $fh "Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts $fh "====================================================================="
    puts $fh ""
    close $fh

    catch {
        set fh [open $report_file a]
        puts $fh "--- SETUP SLACK HISTOGRAM (MAX) ---"
        close $fh
        tee -a $report_file report_worst_slack -max
    }

    catch {
        set fh [open $report_file a]
        puts $fh ""
        puts $fh "--- HOLD SLACK HISTOGRAM (MIN) ---"
        close $fh
        tee -a $report_file report_worst_slack -min
    }
}

# ── Design Rule Checks (Slew, Cap, Fanout, Unconstrained) ────────────
proc ace_report_design_checks {report_file} {
    ace_ensure_dir [file dirname $report_file]
    puts "  -> Generating Electrical & SDC Sanity Report: $report_file"

    set fh [open $report_file w]
    puts $fh "====================================================================="
    puts $fh "ACE-SEEK OPENROAD STUDIO: ELECTRICAL CHECKS & SDC INTEGRITY"
    puts $fh "Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts $fh "====================================================================="
    puts $fh ""
    puts $fh "1. Unconstrained Endpoints Check:"
    close $fh

    catch {
        tee -a $report_file check_setup
    }

    catch {
        set fh [open $report_file a]
        puts $fh ""
        puts $fh "2. Slew (Transition Time) Violations:"
        close $fh
        tee -a $report_file report_check_types -max_slew -violators
    }

    catch {
        set fh [open $report_file a]
        puts $fh ""
        puts $fh "3. Load Capacitance Violations:"
        close $fh
        tee -a $report_file report_check_types -max_capacitance -violators
    }

    catch {
        set fh [open $report_file a]
        puts $fh ""
        puts $fh "4. Fanout Violations:"
        close $fh
        tee -a $report_file report_check_types -max_fanout -violators
    }
}

# ── Power Dissipation Analysis ───────────────────────────────────────
proc ace_report_power {report_file} {
    ace_ensure_dir [file dirname $report_file]
    puts "  -> Generating Power Analysis Report: $report_file"

    set fh [open $report_file w]
    puts $fh "====================================================================="
    puts $fh "ACE-SEEK OPENROAD STUDIO: POWER DISSIPATION ANALYSIS"
    puts $fh "Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts $fh "====================================================================="
    puts $fh ""
    close $fh

    catch {
        tee -a $report_file report_power
    }
}

# ── Area, Density & Cell Breakdown ───────────────────────────────────
proc ace_report_area {report_file} {
    ace_ensure_dir [file dirname $report_file]
    puts "  -> Generating Physical Area & Utilization Report: $report_file"

    set fh [open $report_file w]
    puts $fh "====================================================================="
    puts $fh "ACE-SEEK OPENROAD STUDIO: PHYSICAL AREA & UTILIZATION REPORT"
    puts $fh "Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts $fh "====================================================================="
    puts $fh ""
    close $fh

    catch {
        tee -a $report_file report_design_area
    }
}

# ── Clock Network Skew & Latency ─────────────────────────────────────
proc ace_report_clock_skew {report_file} {
    ace_ensure_dir [file dirname $report_file]
    puts "  -> Generating Clock Network Analysis Report: $report_file"

    set fh [open $report_file w]
    puts $fh "====================================================================="
    puts $fh "ACE-SEEK OPENROAD STUDIO: CLOCK TREE SKEW & LATENCY REPORT"
    puts $fh "Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts $fh "====================================================================="
    puts $fh ""
    close $fh

    catch {
        tee -a $report_file report_clock_skew
    }
    catch {
        set fh [open $report_file a]
        puts $fh ""
        puts $fh "Clock Tree Properties:"
        close $fh
        tee -a $report_file report_clock_properties
    }
}

# ── Global Routing Congestion ────────────────────────────────────────
proc ace_report_congestion {report_file} {
    ace_ensure_dir [file dirname $report_file]
    puts "  -> Generating Routing Congestion Report: $report_file"

    set fh [open $report_file w]
    puts $fh "====================================================================="
    puts $fh "ACE-SEEK OPENROAD STUDIO: ROUTING CONGESTION & TRACK CAPACITY"
    puts $fh "Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts $fh "====================================================================="
    puts $fh ""
    close $fh

    catch {
        tee -a $report_file report_congestion
    }
}

# ── Stage Comprehensive Bundle ───────────────────────────────────────
proc ace_run_stage_reports {stage report_dir} {
    ace_ensure_dir $report_dir
    puts ""
    puts "  >> Generating Full Diagnostic Report Bundle for: [string toupper $stage]"
    
    # 1. Setup Timing
    ace_report_timing_setup "$report_dir/sta_setup.rpt" 20
    
    # 2. Hold Timing
    ace_report_timing_hold "$report_dir/sta_hold.rpt" 20

    # 3. Slack Histogram
    ace_report_slack_histogram "$report_dir/slack_histogram.rpt"

    # 4. Electrical Checks (Slew, Cap, Fanout)
    ace_report_design_checks "$report_dir/electrical_checks.rpt"

    # 5. Power Analysis
    ace_report_power "$report_dir/power.rpt"

    # 6. Physical Area
    ace_report_area "$report_dir/area_utilization.rpt"

    # 7. Clock Network (Post-CTS and onwards)
    if { $stage eq "cts" || $stage eq "routing" || $stage eq "signoff" } {
        ace_report_clock_skew "$report_dir/clock_skew.rpt"
    }

    # 8. Congestion (Routing stage)
    if { $stage eq "routing" } {
        ace_report_congestion "$report_dir/congestion.rpt"
    }

    puts "  >> Stage [string toupper $stage] Reports Completed in: $report_dir"
}
