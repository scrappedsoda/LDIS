create_project -part xc7a100t -force digitherm

read_vhdl digitherm.vhd
read_xdc  digitherm.xdc


synth_design -top digitherm

opt_design
place_design
route_design

write-bitstream -force digitherm.bit
