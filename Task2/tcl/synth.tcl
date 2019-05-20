create_project -part xc7a100t -force amba_digitherm

set reportsDir ./reports
file mkdir $reportsDir

read_vhdl vhdl/AMBA_digitherm.vhd 
read_vhdl vhdl/AMBA_CTL.vhd
read_vhdl vhdl/AMBA_Slave_ADT.vhd
read_vhdl vhdl/AMBA_Slave_DSP.vhd
read_vhdl vhdl/AMBA_Slave_Output.vhd
read_vhdl vhdl/AMBA_Slave_Switch.vhd
read_vhdl vhdl/TWICtl.vhd
read_vhdl vhdl/ADT7420-Sampler.vhd
read_vhdl vhdl/7seg.vhd
read_vhdl vhdl/DSP.vhd
read_xdc  digitherm.xdc


synth_design -top amba_digitherm

opt_design
place_design
route_design

report_timing_summary -file $reportsDir/post_route_timing_summary.rpt
report_utilization -file $reportsDir/post_route_utilization.rpt

write_bitstream -force amba_digitherm.bit
