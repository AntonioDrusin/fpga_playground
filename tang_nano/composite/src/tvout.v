module top (
  input button1,
  input sys_clk,
  output reg [2:0] sig,
  input button0,

 // These are connected to the mem chip. Pinout is for Sipeed TANG Nano
  inout wire [3:0] mem_sio,   // sio[0] pin 22, sio[1] pin 23, sio[2] pin 24, sio[3] pin 21
  output wire mem_ce_n,       // pin 19
  output wire mem_clk         // pin 
);

  wire [2:0] pixel_signal;
  wire [2:0] sync_signal;
  wire mem_ready;

  wire vbsram_writeen;
  wire [3:0] vbsram_datain;
  wire [6:0] vbsram_addrin;

  wire cache_readen;
  wire cache_out;
  wire [8:0] cache_addrout;
  
  gowin_linecache vcache(
      .dout(cache_out),     //output [0:0] dout (read)
      .clka(sys_clk),      //input clka (write)
      .cea(vbsram_writeen), //input cea (write)
      .reseta(1'd0),        //input reseta (write)
      .clkb(sys_clk),       //input clkb (read)
      .ceb(cache_readen),   //input ceb (read)
      .resetb(1'd0),        //input resetb (read)
      .oce(1'd1),           //input oce 
      .ada(vbsram_addrin),  //input [6:0] ada (write)
      .din(vbsram_datain),  //input [3:0] din (write)
      .adb(cache_addrout)   //input [8:0] adb (read)
  );

  wire cbsram_ce; // clock enable
  wire cbsram_wre; // write enable
  wire [7:0] cbsram_datain;
  wire [7:0] cbsram_dataout;
  wire [7:0] cbsram_addrin;

  wire [8:0] mem_wbsram_addr;
  wire wbsram_ce;
  wire wbsram_writeen;
  wire [3:0] wbsram_datain;
  wire [3:0] wbsram_dataout;
  wire [8:0] wbsram_addrin;

  Gowin_DPB wram(
      .douta(cbsram_dataout), //output [7:0] douta
      .doutb(wbsram_dataout), //output [3:0] doutb
      .clka(sys_clk), //input clka
      .ocea(cbsram_ce), //input ocea
      .cea(cbsram_ce), //input cea
      .reseta(1'b0), //input reseta
      .wrea(cbsram_wre), //input wrea
      .clkb(sys_clk), //input clkb
      .oceb(wbsram_ce), //input oceb
      .ceb(wbsram_ce), //input ceb
      .resetb(1'b0), //input resetb
      .wreb(wbsram_writeen), //input wreb
      .ada(cbsram_addrin), //input [7:0] ada
      .dina(cbsram_datain), //input [7:0] dina
      .adb(wbsram_addrin), //input [8:0] adb
      .dinb(wbsram_datain) //input [3:0] dinb
  );


  wire [15:0] mem_vaddrin;
  wire [15:0] mem_caddrin;
  reg mem_write_strobe = 0;
  wire mem_vread_strobe;
  wire mem_wread_strobe;
  wire mem_wwrite_strobe;

  memory memory (
    sys_clk,     // 60MHz
    mem_ready,
 
    mem_vaddrin, // PSRAM address to read/write from (video)
    mem_caddrin, // PSRAM address to read/write from (conway)

    mem_vread_strobe,
    mem_wread_strobe,
    mem_wwrite_strobe,

    vbsram_writeen,
    vbsram_datain,
    vbsram_addrin,

    mem_wbsram_addr, // bsram address to read/write from/to
    wbsram_ce,
    wbsram_writeen,
    wbsram_datain,
    wbsram_addrin,
    wbsram_dataout, 

    8'h47,  // init delay * 256

    mem_sio,
    mem_ce_n,
    mem_clk
  );

  wire row_enable;
  wire vblank;
  wire preload_done;

  // reads from bsram line 1 bit at a time for each row
  pixel_signal video_signal(
    sys_clk,    // 6MHz
    row_enable, // 1, during row output, 0 otherwise
    vblank,     // 1, during vblank, 0 when row_enable is going to turn on

    cache_readen,
    cache_out,
    cache_addrout,

    mem_vaddrin,
    mem_ready,
    mem_vread_strobe,

    pixel_signal,
    preload_done
  );

  video_sync video_sync(
    sys_clk, // 24MHz
    row_enable,
    vblank,
    sync_signal
  );


  // implement the game of life
  conway conway(
    sys_clk,
    row_enable,
    vblank,

    cbsram_ce,
    cbsram_wre,
    cbsram_datain,
    cbsram_dataout,
    cbsram_addrin,

    mem_wbsram_addr,
    mem_caddrin, 
    mem_ready,
    mem_wread_strobe,
    mem_wwrite_strobe,
    preload_done,
    button0,
    button1
  );

  always @(row_enable or pixel_signal or sync_signal)
    if ( row_enable ) 
      sig <= pixel_signal;
    else
      sig <= sync_signal;

endmodule

