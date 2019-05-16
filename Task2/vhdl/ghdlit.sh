
ghdl -s AMBA_CTL.vhd TWICtl.vhd ADT7420-Sampler.vhd DSP.vhd 7seg.vhd 
ghdl -a AMBA_CTL.vhd TWICtl.vhd ADT7420-Sampler.vhd DSP.vhd 7seg.vhd 
ghdl -s testbench_utils.vhd 
ghdl -a testbench_utils.vhd
ghdl -s AMBA_Slave_ADT.vhd AMBA_Slave_DSP.vhd AMBA_Slave_Output.vhd AMBA_Slave_Switch.vhd AMBA_Slave_ADT_stub.vhd
ghdl -a AMBA_Slave_ADT.vhd AMBA_Slave_DSP.vhd AMBA_Slave_Output.vhd AMBA_Slave_Switch.vhd AMBA_Slave_ADT_stub.vhd



ghdl -s AMBA_digitherm.vhd 
ghdl -a AMBA_digitherm.vhd 

