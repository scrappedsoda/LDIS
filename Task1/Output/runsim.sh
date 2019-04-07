#!/bin/bash

# Script to simulate VHDL designs
#
# Usage:
#
#		runsim.sh <design-file> <top-entity>	

# Simulate design

ghdl -s 7seg.vhd
ghdl -a 7seg.vhd

ghdl -s $1
ghdl -a $1
ghdl -e $2
ghdl -r $2 --vcd=$2.vcd


# Show simulation result as wave form
#gtkwave $2.vcd &
