//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8 
//Created Time: 2022-01-01 21:41:01
create_clock -name sys_clk -period 41.667 -waveform {0 20.834} [get_ports {sys_clk}]
create_generated_clock -name pix_clk -source [get_ports {sys_clk}] -master_clock sys_clk -divide_by 4 [get_nets {pix_clk_4}]
create_generated_clock -name syn_clk -source [get_ports {sys_clk}] -master_clock sys_clk -divide_by 12 [get_nets {syn_clk_6}]
