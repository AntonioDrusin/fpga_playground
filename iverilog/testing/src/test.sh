mkdir -p sim && \
iverilog -o sim/design.vvp -c iverilog.txt && \
vvp sim/design.vvp -n -s -lxt2
## gtkwave dump.lx2
