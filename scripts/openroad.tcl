# OpenROAD PnR execution script for ibex_core (OpenROAD Studio)
puts "Ace-Seek OpenROAD · ibex_core · PDK sky130"
read_lef sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd.tlef
read_liberty sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog outputs/synthesis_ibex_core.v
link_design ibex_core
read_sdc constraints.sdc
initialize_floorplan -die_area {0 0 553.84 552.16} -core_area {20 20 533.84 532.16} -site unithd
place_pins -hor_layers met3 -ver_layers met2
global_placement -density 0.45
detailed_placement
clock_tree_synthesis -buf_list {sky130_fd_sc_hd__clkbuf_16 sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_4}
global_route
detailed_route
write_def outputs/placement_top.def
write_verilog outputs/final_ibex_core.v
report_design_area
