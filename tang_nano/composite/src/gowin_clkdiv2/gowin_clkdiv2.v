//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.8.01
//Part Number: GW1N-LV1QN48C6/I5
//Device: GW1N-1
//Created Time: Sun Dec 19 13:11:09 2021

module gw_clkdiv2 (clkout, hclkin, resetn);

output clkout;
input hclkin;
input resetn;

CLKDIV2 clkdiv2_inst (
    .CLKOUT(clkout),
    .HCLKIN(hclkin),
    .RESETN(resetn)
);

endmodule //gw_clkdiv2
