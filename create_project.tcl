# Chay: vivado -mode batch -source create_project.tcl
# Hoac trong Vivado: Tools > Run Tcl Script...
# Project duoc tao trong thu muc vivado/ (da .gitignore). File nguon duoc THAM CHIEU
# tai cho (khong copy) nen sua file trong rtl/ hoac testbench/ la Vivado thay ngay.
set root [file normalize [file dirname [info script]]]
create_project RISCV_Single_Cycle $root/vivado -part xc7a35tcpg236-1 -force

set_property target_language Verilog [current_project]

# Design sources
add_files -norecurse [glob $root/rtl/core/*.sv $root/rtl/memory/*.sv]
set_property file_type SystemVerilog [get_files *.sv]
set_property top riscv_single_cycle_top [get_filesets sources_1]

# Simulation sources
add_files -fileset sim_1 -norecurse [glob $root/testbench/unit_tests/*.sv]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1] *.sv]
set_property top ALU_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Xong. Doi testbench: chuot phai tb trong Simulation Sources > Set as Top."
