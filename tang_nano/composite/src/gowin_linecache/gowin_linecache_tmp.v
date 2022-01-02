//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.01
//Part Number: GW1N-LV1QN48C6/I5
//Device: GW1N-1
//Created Time: Tue Dec 28 10:13:50 2021

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    gowin_linecache your_instance_name(
        .dout(dout_o), //output [0:0] dout
        .clka(clka_i), //input clka
        .cea(cea_i), //input cea
        .reseta(reseta_i), //input reseta
        .clkb(clkb_i), //input clkb
        .ceb(ceb_i), //input ceb
        .resetb(resetb_i), //input resetb
        .oce(oce_i), //input oce
        .ada(ada_i), //input [6:0] ada
        .din(din_i), //input [3:0] din
        .adb(adb_i) //input [8:0] adb
    );

//--------Copy end-------------------
