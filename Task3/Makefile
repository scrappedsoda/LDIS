
FILES = \
../src/AMBA_CTL.vhd \
../src/TWICtl.vhd \
../src/ADT7420-Sampler.vhd \
../src/DSP.vhd \
../src/7seg.vhd \
../src/AMBA_Slave_ADT.vhd \
../src/AMBA_Slave_DSP.vhd \
../src/AMBA_Slave_Output.vhd \
../src/AMBA_Slave_Switch.vhd 


.PHONY: sim synth prog

sim:
	cd sim && ghdl -s $(FILES) testbench_utils.vhd AMBA_Slave_ADT_stub.vhd && ghdl -a $(FILES) testbench_utils.vhd AMBA_Slave_ADT_stub.vhd;
	cd sim && ghdl -s tb_all.vhd && ghdl -a tb_all.vhd;
	cd sim;ghdl -e  amba_digitherm_tb 
	cd sim;ghdl -r  amba_digitherm_tb --vcd=amba_digitherm_tb.vcd
	gtkwave sim/amba_digitherm_tb.vcd

synth:
	cd synth;vivado -mode batch -source synth.tcl
	cp ./synth/digitherm.bit ./bin/digitherm.bit

prog: 
	cd synth;vivado -mode batch -source program.tcl

clean:
	rm -rf ./synth/digitherm.cache ./synth/digitherm.ip_user_files ./synth/digitherm.hw ./synth/.Xil \
			./synth/digitherm.xpr ./synth/vivado.* ./synth/fsm_encoding.os ./synth/usage_statistics_webtalk.*
	rm -f ./synth/digitherm.bit 
	rm -f ./sim/work-obj93.cf 
	
doc:

