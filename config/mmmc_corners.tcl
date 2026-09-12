# ==============================================================================
# OpenSTA / OpenROAD Multi-Corner Multi-Mode (MMMC) Configuration
# Technology: SkyWater SKY130 (130nm CMOS)
# Standard Cell: sky130_fd_sc_hd
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Corner Definitions & Liberty Mapping
# ------------------------------------------------------------------------------

# Slow Corner (Setup Signoff — Max Delay):
# Process: Slow-Slow (SS), Voltage: 1.60V, Temperature: 100°C
define_process_corner -ext_model_corner ss_100C_1v60 \
  -liberty_file sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib

# Fast Corner (Hold Signoff — Min Delay):
# Process: Fast-Fast (FF), Voltage: 1.95V, Temperature: -40°C
define_process_corner -ext_model_corner ff_n40C_1v95 \
  -liberty_file sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ff_n40C_1v95.lib

# Typical Corner (Power & Nominal Analysis):
# Process: Typical-Typical (TT), Voltage: 1.80V, Temperature: 25°C
define_process_corner -ext_model_corner tt_025C_1v80 \
  -liberty_file sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# ------------------------------------------------------------------------------
# 2. Constraint Modes
# ------------------------------------------------------------------------------
create_constraint_mode -name default_functional_mode \
  -sdc_files [list config/constraints.sdc]

# ------------------------------------------------------------------------------
# 3. Analysis Views (Scenario Binding)
# ------------------------------------------------------------------------------
create_analysis_view -name view_setup_slow \
  -constraint_mode default_functional_mode \
  -corner ss_100C_1v60

create_analysis_view -name view_hold_fast \
  -constraint_mode default_functional_mode \
  -corner ff_n40C_1v95

create_analysis_view -name view_power_typ \
  -constraint_mode default_functional_mode \
  -corner tt_025C_1v80

# ------------------------------------------------------------------------------
# 4. Set Active Analysis Views
# ------------------------------------------------------------------------------
set_analysis_view \
  -setup [list view_setup_slow] \
  -hold  [list view_hold_fast]
