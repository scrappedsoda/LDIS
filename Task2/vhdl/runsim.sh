#!/bin/bash

# Script to simulate VHDL designs
#
# Usage:
#
#		runsim.sh <design-file> <top-entity>	

# Simulate design

./ghdlit.sh

ghdl -s testbench_utils.vhd 
ghdl -a testbench_utils.vhd

ghdl -s $1
ghdl -a $1
ghdl -e $2
ghdl -r $2 --vcd=$2.vcd


# Show simulation result as wave form
#gtkwave $2.vcd &
#./runsim.sh 7seg_tb.vhdl sevseg_tb
