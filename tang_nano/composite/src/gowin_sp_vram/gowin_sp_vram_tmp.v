//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.01
//Part Number: GW1N-LV1QN48C6/I5
//Device: GW1N-1
//Created Time: Tue Dec 28 08:29:42 2021

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_SP_VRAM your_instance_name(
        .dout(dout_o), //output [3:0] dout
        .clk(clk_i), //input clk
        .oce(oce_i), //input oce
        .ce(ce_i), //input ce
        .reset(reset_i), //input reset
        .wre(wre_i), //input wre
        .ad(ad_i), //input [6:0] ad
        .din(din_i) //input [3:0] din
    );

//--------Copy end-------------------
