# OpenSTA timing verification for ibex_core (OpenROAD Studio)
puts "Ace-Seek OpenSTA · design=ibex_core"
read_liberty sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog outputs/synthesis_ibex_core.v
link_design ibex_core
read_sdc constraints.sdc
report_checks -path_delay max -fields {slew cap input_pins} -digits 3
report_wns
report_tns
report_power
