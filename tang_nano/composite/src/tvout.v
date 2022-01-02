module top (
  input sys_rst_n,
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

  reg pix_clk = 0;
  reg syn_clk = 0;
  wire work_clk;
  reg [2:0] syn_c = 0;   // clock divider counter
  reg [2:0] pix_c = 0;
   
  wire mem_ready;


    Gowin_rPLL pll (
        .clkout(work_clk), //output clkout
        .clkin(sys_clk) //input clkin
    );

  
  // Clock generator
  always @(posedge sys_clk) begin
    syn_c <= syn_c + 3'd1;
    pix_c <= pix_c + 3'd1;

    if ( syn_c == 5 )
    begin 
      syn_clk <= ~syn_clk;        // 2MHz
      syn_c <= 3'd0;
    end

    if ( pix_c == 1 )
    begin 
      pix_clk <= ~pix_clk; // 6MHz
      pix_c <= 3'd0;
    end
  end


  wire cache_writeen;
  wire [3:0] cache_in;
  wire [6:0] cache_addrin;

  wire cache_readen;
  wire cache_out;
  wire [8:0] cache_addrout;
  
  gowin_linecache vcache(
      .dout(cache_out),     //output [0:0] dout (read)
      .clka(work_clk),      //input clka (write)
      .cea(cache_writeen),  //input cea (write)
      .reseta(1'd0),        //input reseta (write)
      .clkb(pix_clk),     //input clkb (read)
      .ceb(cache_readen),   //input ceb (read)
      .resetb(1'd0),        //input resetb (read)
      .oce(1'd1),           //input oce 
      .ada(cache_addrin),   //input [6:0] ada (write)
      .din(cache_in),       //input [3:0] din (write)
      .adb(cache_addrout)   //input [8:0] adb (read)
  );

  wire [15:0] mem_addrout;
  reg mem_write_strobe = 0;

  memory memory (
    work_clk,     // 60MHz
    mem_ready,
 
    mem_addrout, // address to read from

    mem_read_strobe,
    mem_write_strobe,

    cache_writeen,
    cache_in,
    cache_addrin,

    8'h47,  // init delay * 256

    mem_sio,
    mem_ce_n,
    mem_clk
  );

  wire row_enable;
  wire vblank;

  // reads from bsram line 1 bit at a time for each row
  video_signal video_signal(
    pix_clk,    // 6MHz
    row_enable, // 1, during row output, 0 otherwise
    vblank,     // 1, during vblank, 0 when row_enable is going to turn on

    cache_readen,
    cache_out,
    cache_addrout,

    mem_addrout,
    mem_ready,
    mem_read_strobe,

    pixel_signal
  );

  video_sync video_sync(
    syn_clk, // 2MHz
    row_enable,
    vblank,
    sync_signal
  );

  always @(row_enable or pixel_signal or sync_signal)
    if ( row_enable ) 
      sig <= pixel_signal;
    else
      sig <= sync_signal;

endmodule

