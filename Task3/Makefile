
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

TESTBENCHES = \
	DSP-tb.vhd \
	7seg_tb.vhd \
	tb_all.vhd

.PHONY: sim synth prog doc

sim:
	cd sim && ghdl -s $(FILES) testbench_utils.vhd testbench_utils_dsp.vhd AMBA_Slave_ADT_stub.vhd 
	cd sim && ghdl -a $(FILES) testbench_utils.vhd testbench_utils_dsp.vhd AMBA_Slave_ADT_stub.vhd;
	cd sim && ghdl -s $(TESTBENCHES) && ghdl -a $(TESTBENCHES);
	cd sim;ghdl -e  amba_digitherm_tb 
	cd sim;ghdl -r  amba_digitherm_tb --vcd=amba_digitherm_tb.vcd
	cd sim;ghdl -e  DSP_tb 
	cd sim;ghdl -r  DSP_tb --vcd=DSP_tb.vcd
	cd sim;ghdl -e 	sevseg_tb
	cd sim;ghdl -r 	sevseg_tb --vcd=sevseg_tb.vcd
	mkdir -p ./sim/simout/
	mv ./sim/*.vcd ./sim/simout/
	@echo
	@echo All the .vcd files are located in ./sim/simout
	@echo To view please use gtkwave with the according file
	@#gtkwave sim/amba_digitherm_tb.vcd

synth:
	cd synth;vivado -mode batch -source synth.tcl
	mkdir -p ./bin
	cp ./synth/digitherm.bit ./bin/digitherm.bit

prog: 
	cd synth;vivado -mode batch -source program.tcl

clean:
	rm -rf ./synth/digitherm.cache 
	rm -rf ./synth/digitherm.ip_user_files 
	rm -rf ./synth/digitherm.hw ./synth/.Xil 
	rm -f ./synth/digitherm.xpr 
	rm -f ./synth/vivado.jou 
	rm -f ./synth/vivado.log
	rm -f ./synth/fsm_encoding.os 
	rm -f ./synth/usage_statistics_webtalk.*
	rm -f ./synth/digitherm.bit 
	rm -f ./sim/work-obj93.cf 
	rm -f ./sim/{amba_digitherm_tb,dsp_tb,sevseg_tb}
	rm -rf ./sim/simout
	rm -rf ./sim/*.o
	rm -rf ./bin
	rm -rf ./doc/Digitherm.aux
	rm -rf ./doc/Digitherm.bbl
	rm -rf ./doc/Digitherm.bcf
	rm -rf ./doc/Digitherm.blg
	rm -rf ./doc/Digitherm.glo
	rm -rf ./doc/Digitherm.ist
	rm -rf ./doc/Digitherm.log
	rm -rf ./doc/Digitherm.out
	rm -rf ./doc/Digitherm.run.xml
	rm -rf ./doc/Digitherm.toc
	rm -rf ./doc/Digitherm.pdf
	
doc:
	cd doc;pdflatex Digitherm.tex;biber Digitherm;pdflatex Digitherm.tex;pdflatex Digitherm.tex
	@echo Cleaning up ...
	rm -r ./doc/Digitherm.aux
	rm -r ./doc/Digitherm.bbl
	rm -r ./doc/Digitherm.bcf
	rm -r ./doc/Digitherm.blg
	rm -r ./doc/Digitherm.glo
	rm -r ./doc/Digitherm.ist
	rm -r ./doc/Digitherm.log
	rm -r ./doc/Digitherm.out
	rm -r ./doc/Digitherm.run.xml
	rm -r ./doc/Digitherm.toc
	@echo The documentation is in ./doc/Digitherm.pdf

