create_project -part xc7a100t -force digitherm

read_vhdl ../src/AMBA_digitherm.vhd 
read_vhdl ../src/AMBA_CTL.vhd
read_vhdl ../src/AMBA_Slave_ADT.vhd
read_vhdl ../src/AMBA_Slave_DSP.vhd
read_vhdl ../src/AMBA_Slave_Output.vhd
read_vhdl ../src/AMBA_Slave_Switch.vhd
read_vhdl ../src/TWICtl.vhd
read_vhdl ../src/ADT7420-Sampler.vhd
read_vhdl ../src/7seg.vhd
read_vhdl ../src/DSP.vhd
read_xdc  digitherm.xdc


synth_design -top digitherm

opt_design
place_design
route_design

write_bitstream -force digitherm.bit
