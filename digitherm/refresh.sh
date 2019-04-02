cp ../Sampling/try2/i2c_master.vhd .
cp ../Sampling/try2/ADT7420.vhd .
cp ../DSP/DSP.vhd .
cp ../Output/7seg.vhd .

ghdl -s i2c_master.vhd ADT7420.vhd DSP.vhd 7seg.vhd
ghdl -a i2c_master.vhd ADT7420.vhd DSP.vhd 7seg.vhd
