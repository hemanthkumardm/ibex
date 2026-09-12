# =====================================================================
# Ace-Seek OpenROAD Studio — Master Flow Coordinator
# =====================================================================
# Can execute full end-to-end PnR or individual stages on demand:
#   Usage:
#     openroad -exit scripts/openroad.tcl
#     STAGE=placement openroad -exit scripts/openroad.tcl
#     UNTIL=cts openroad -exit scripts/openroad.tcl
# =====================================================================

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir "helpers" "reporting.tcl"]

ace_log_banner "MASTER" "Ace-Seek OpenROAD Studio: Physical Implementation Pipeline"

# Resolve target stage from command line arguments or environment
set target_stage "all"
set until_stage ""

if { [info exists ::env(STAGE)] && $::env(STAGE) ne "" } {
    set target_stage [string tolower $::env(STAGE)]
}
if { [info exists ::env(UNTIL)] && $::env(UNTIL) ne "" } {
    set until_stage [string tolower $::env(UNTIL)]
}

# Parse command line flags if provided
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    if { $arg eq "-stage" && $i + 1 < [llength $argv] } {
        set target_stage [string tolower [lindex $argv [incr i]]]
    } elseif { $arg eq "-until" && $i + 1 < [llength $argv] } {
        set until_stage [string tolower [lindex $argv [incr i]]]
    }
}

puts "  Target Stage Mode: $target_stage"
if { $until_stage ne "" } {
    puts "  Until Stage Stop:  $until_stage"
}

set stages_list {floorplan placement cts routing signoff}

proc ace_run_single_stage {stage script_dir} {
    set stage_map [dict create \
        floorplan "02_floorplan.tcl" \
        placement "03_placement.tcl" \
        cts       "04_cts.tcl" \
        routing   "05_routing.tcl" \
        route     "05_routing.tcl" \
        signoff   "06_signoff.tcl" \
        gds       "06_signoff.tcl" \
    ]

    if { ![dict exists $stage_map $stage] } {
        puts "  [ERROR] Unknown stage requested: '$stage'. Valid: [dict keys $stage_map]"
        exit 1
    }

    set script_file [file join $script_dir [dict get $stage_map $stage]]
    if { ![file exists $script_file] } {
        puts "  [ERROR] Script file does not exist: $script_file"
        exit 1
    }

    puts ""
    puts "========================================================================"
    puts "  >>> EXECUTING STAGE: [string toupper $stage] ($script_file)"
    puts "========================================================================"
    source $script_file
}

if { $target_stage ne "all" } {
    # Run only the explicitly requested stage
    ace_run_single_stage $target_stage $script_dir
} else {
    # Sequential execution through stages
    set step_num 1
    set total_steps [llength $stages_list]

    foreach stg $stages_list {
        puts ""
        puts "  [Step $step_num/$total_steps] Progressing to stage: [string toupper $stg]"
        ace_run_single_stage $stg $script_dir
        
        if { $until_stage ne "" && ($until_stage eq $stg || ($until_stage eq "route" && $stg eq "routing")) } {
            puts ""
            puts "  [CHECKPOINT] Reached stop boundary UNTIL=$until_stage. Flow stopped as requested."
            break
        }
        incr step_num
    }
}

puts ""
puts "========================================================================"
puts "  ACE-SEEK OPENROAD STUDIO: Pipeline execution completed successfully."
puts "  Check directory: 'reports/' for detailed STA, PVT, Power, and DRC files."
puts "  Check directory: 'outputs/' for DEF, GDS, and netlist deliverables."
puts "========================================================================"
