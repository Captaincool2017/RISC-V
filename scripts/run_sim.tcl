set project_dir [pwd]

create_project sim_proj ./sim_proj -force

read_verilog [glob [file join $project_dir "src/*.v"]]
read_verilog [file join $project_dir "tb/tb_core.v"]

set_property top tb_core [get_filesets sim_1]
update_compile_order -fileset sim_1

# Tell Vivado to run indefinitely until it hits a $finish command
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

# Run simulation
reset_simulation
launch_simulation

close_sim
close_project
exit