#!/bin/bash

# Script to simulate VHDL designs
#
# Usage:
#
#		runsim.sh <design-file> <top-entity>	

# Simulate design

ghdl -s 7seg.vhd DSP.vhd TWICtl.vhd ADT7420-Sampler.vhd digitherm.vhd
ghdl -a 7seg.vhd DSP.vhd TWICtl.vhd ADT7420-Sampler.vhd digitherm.vhd

ghdl -s testbench_utils.vhd 
ghdl -a testbench_utils.vhd

ghdl -s DSP-tb.vhdl
ghdl -a DSP-tb.vhdl
ghdl -e DSP_tb
ghdl -r DSP_tb --vcd=DSP_tb.vcd

ghdl -s 7seg_tb.vhdl
ghdl -a 7seg_tb.vhdl
ghdl -e sevseg_tb
ghdl -r sevseg_tb --vcd=sevseg_tb.vcd

gtkwave DSP_tb.vcd &
gtkwave sevseg_tb.vcd &
