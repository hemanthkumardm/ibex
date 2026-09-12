# ==============================================================================
# lowRISC Ibex RV32IMC Core — Production SDC Constraints for SkyWater SKY130
# Target: 66.7 MHz (Clock Period = 15.000 ns)
# ==============================================================================

current_design ibex_core

# 1. Master Clock Definition (Single create_clock with explicit numeric period)
create_clock -name core_clock -period 15.000 [get_ports clk_i]

# 2. Clock Uncertainties & Transitions
set_clock_uncertainty -setup 0.350 [get_clocks core_clock]
set_clock_uncertainty -hold 0.150 [get_clocks core_clock]
set_clock_transition 0.250 [get_clocks core_clock]
set_clock_latency 1.000 [get_clocks core_clock]

# 3. Input Delays (20% to 25% of clock period)
set_input_delay -max 3.000 -clock core_clock [get_ports {rst_ni test_en_i hart_id_i* boot_addr_i*}]
set_input_delay -min 0.600 -clock core_clock [get_ports {rst_ni test_en_i hart_id_i* boot_addr_i*}]

# Instruction memory bus inputs
set_input_delay -max 3.200 -clock core_clock [get_ports {instr_gnt_i instr_rvalid_i instr_rdata_i* instr_err_i}]
set_input_delay -min 0.500 -clock core_clock [get_ports {instr_gnt_i instr_rvalid_i instr_rdata_i* instr_err_i}]

# Data memory bus inputs
set_input_delay -max 3.200 -clock core_clock [get_ports {data_gnt_i data_rvalid_i data_rdata_i* data_err_i}]
set_input_delay -min 0.500 -clock core_clock [get_ports {data_gnt_i data_rvalid_i data_rdata_i* data_err_i}]

# Interrupts & Debug
set_input_delay -max 3.000 -clock core_clock [get_ports {irq_software_i irq_timer_i irq_external_i irq_fast_i* irq_nm_i debug_req_i fetch_enable_i}]
set_input_delay -min 0.600 -clock core_clock [get_ports {irq_software_i irq_timer_i irq_external_i irq_fast_i* irq_nm_i debug_req_i fetch_enable_i}]

# 4. Output Delays
# Instruction memory bus outputs
set_output_delay -max 3.000 -clock core_clock [get_ports {instr_req_o instr_addr_o*}]
set_output_delay -min 0.500 -clock core_clock [get_ports {instr_req_o instr_addr_o*}]

# Data memory bus outputs
set_output_delay -max 3.000 -clock core_clock [get_ports {data_req_o data_we_o data_be_o* data_addr_o* data_wdata_o*}]
set_output_delay -min 0.500 -clock core_clock [get_ports {data_req_o data_we_o data_be_o* data_addr_o* data_wdata_o*}]

# Core status outputs
set_output_delay -max 3.000 -clock core_clock [get_ports {core_sleep_o alert_minor_o alert_major_o}]
set_output_delay -min 0.500 -clock core_clock [get_ports {core_sleep_o alert_minor_o alert_major_o}]

# 5. Environment & Electrical Attributes (sky130_fd_sc_hd)
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y [all_inputs]
set_load 0.035 [all_outputs]

# 6. Timing Exceptions
set_false_path -from [get_ports rst_ni]
set_false_path -from [get_ports test_en_i]
