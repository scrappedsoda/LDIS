create_project -part xc7a100t -force digitherm

read_vhdl vhd/digitherm.vhd 
read_vhdl vhd/TWICtl.vhd
read_vhdl vhd/ADT7420-Sampler.vhd
read_vhdl vhd/7seg.vhd
read_vhdl vhd/DSP.vhd
read_xdc  digitherm.xdc


synth_design -top digitherm

opt_design
place_design
route_design

write_bitstream -force digitherm.bit
