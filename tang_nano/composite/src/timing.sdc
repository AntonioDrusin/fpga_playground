//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8 
//Created Time: 2022-01-05 22:01:16
create_clock -name sys_clk -period 41.667 -waveform {0 20.833} [get_ports {sys_clk}]
