set project_dir [pwd]

create_project sim_proj ./sim_proj -force

read_verilog [glob [file join $project_dir "src/*.v"]]
read_verilog [file join $project_dir "tb/tb_core.v"]

set_property top tb_core [get_filesets sim_1]
update_compile_order -fileset sim_1

# Pass the absolute firmware path as a Verilog define
set mem_file [file join $project_dir "firmware/build/firmware.mem"]
set_property -name {xsim.simulate.xsim.more_options} -value "-testplusarg MEMFILE=$mem_file" -objects [get_filesets sim_1]
set_property verilog_define "MEM_FILE=\"$mem_file\"" [get_filesets sim_1]

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

reset_simulation
launch_simulation

close_sim
close_project
exit