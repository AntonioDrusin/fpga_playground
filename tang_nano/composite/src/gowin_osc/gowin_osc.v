//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.8.01
//Part Number: GW1N-LV1QN48C6/I5
//Device: GW1N-1
//Created Time: Mon Dec 20 13:08:47 2021

module gw_osc (oscout);

output oscout;

OSCH osc_inst (
    .OSCOUT(oscout)
);

defparam osc_inst.FREQ_DIV = 4;

endmodule //gw_osc
