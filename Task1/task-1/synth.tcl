create_project -part xc7a100t -force digitherm

read_vhdl digitherm.vhd 
read_vhdl TWICtl.vhd
read_vhdl ADT7420-Sampler.vhd
read_vhdl 7seg.vhd
read_vhdl DSP.vhd
read_xdc  digitherm.xdc


synth_design -top digitherm

opt_design
place_design
route_design

write_bitstream -force digitherm.bit
