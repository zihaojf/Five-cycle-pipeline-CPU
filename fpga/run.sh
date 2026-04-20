#!/usr/bin/env bash
set -e

rm -f sim.out wave.vcd
iverilog -g2012 -o sim.out *.v
vvp sim.out
gtkwave wave.vcd