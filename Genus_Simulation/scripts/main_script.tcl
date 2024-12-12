source ./scripts/config_script.tcl

# Directory to search for .lib files
set_attr init_lib_search_path ./lib/$tech_node/

# Directory to search RTL files
set_attr hdl_search_path ./RTL/Mohammad_Saeed/M16_6/

# unflatten: individual optimization
set_attribute auto_ungroup none

# Verbose info level 0-9 (Recommended-6, Max-9)
set_attribute information_level 6

# Write log file for each run
set_attribute stdout_log ./${hdl_file}_log.txt

# Stop genus from executing when it encounters error
set_attribute fail_on_error_mesg true

# This attribute enables Genus to keep track of filenames, line numbers, and column numbers
# for all instances before optimization. Genus also uses this information in subsequent error
# and warning messages.
set_attribute hdl_track_filename_row_col true


# This is for timing optimization read genus legacy UI documentation if results are worst
set_attribute tns_opto true /

# Choose the lib cell type
set_attr library $cell_types 

# Naming style used in rtl
set_attribute hdl_parameter_naming_style _%s%d 

# Check DRC & force Genus to fix DRCs, even at the expense of timing, with the drc_first attribute.
set_attribute drc_first true 

# Read verilog file ( if it is sv just replace the extension)
read_hdl -mixvlog ./RTL/Mohammad_Saeed/M16_6/M16_6.v


# Elaborate the design
elaborate

# Read the constraint file
# read_sdc ./constraints/$hdl_file/$hdl_file.sdc

# Set the top module name in hierarchical design if the modules are not in same rtl file
set top_module M16_6

# Automatically partition the design and run fast in genus
set_attribute auto_partition true

# Analytical optimization identifies connected, cross-hierarchy regions of the datapath logic, and
# selects the best architecture for each region within the context of the full design. This optimization
# explores multiple architectures for each region by applying a range of constraints

# The best area results are obtained, at the possible expense of timing.
set_attr dp_analytical_opt extreme

# To turn off carry-save transformations
# set_attr dp_csa none


# If the user_sub_arch attribute is specified on a multiplier, it will take precedence over the
# apply_booth_encoding setting.

# Booth encoding options {nonbooth | auto_bitwidth | auto_togglerate | manual | inherited}
set_attribute apply_booth_encoding auto_togglerate

# Report Datapath Operators
report_dp -all -print_inferred > ./reports/$hdl_file/$tech_node/post_elaboration/syn_generic_datapath_report.txt

# Generic Synthesis
set_attr syn_generic_effort $generic_effort
syn_generic 
write_hdl > ./synthesis/$hdl_file/$tech_node/generic/verilog/syn_generic.v
write_sdc > ./synthesis/$hdl_file/$tech_node/generic/constraints/syn_generic.sdc
report_gates > ./reports/$hdl_file/$tech_node/generic/syn_generic_gates.txt
report_area > ./reports/$hdl_file/$tech_node/generic/syn_generic_area.txt
report_timing > ./reports/$hdl_file/$tech_node/generic/syn_generic_timing.txt
report_power > ./reports/$hdl_file/$tech_node/generic/syn_generic_power.txt
#report_dp -all > ./reports/$hdl_file/$tech_node/generic/syn_generic_datapath_report.txt
report_dp -all -print_inferred > ./reports/$hdl_file/$tech_node/generic/syn_generic_datapath_report.txt


# Mapping 
set_attr syn_map_effort $map_effort
syn_map
write_hdl > ./synthesis/$hdl_file/$tech_node/mapped/verilog/syn_unopt.v
 > ./synthesis/$hdl_file/$tech_node/mapped/constraints/syn_generic.sdc
report_gates > ./reports/$hdl_file/$tech_node/mapped/syn_map_gates.txt
report_area > ./reports/$hdl_file/$tech_node/mapped/syn_map_area.txt
report_timing > ./reports/$hdl_file/$tech_node/mapped/syn_map_timing.txt
report_power > ./reports/$hdl_file/$tech_node/mapped/syn_map_power.txt



# Incremental performs area and power optimization

# Optimized
set_attr syn_opt_effort $opt_effort
syn_opt -incr
write_hdl > ./synthesis/$hdl_file/$tech_node/opt/verilog/syn_opt.v
write_sdc > ./synthesis/$hdl_file/$tech_node/opt/constraints/syn_generic.sdc
report_gates > ./reports/$hdl_file/$tech_node/opt/syn_opt_gates.txt
report_area > ./reports/$hdl_file/$tech_node/opt/syn_opt_area.txt
report_timing > ./reports/$hdl_file/$tech_node/opt/syn_opt_timing.txt
report_power > ./reports/$hdl_file/$tech_node/opt/syn_opt_power.txt


#To generate all files needed to be loaded in an Innovus session, use the followingcommand:
write_design -innovus -base_name ./innovus/$hdl_file/$hdl_file

