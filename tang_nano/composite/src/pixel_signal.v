module video_signal (
  input sys_clk,
  input row_enable,             // 1, during row output, 0 otherwise
  input [8:0] vert_c,
  output [2:0] pixel_signal,
  input button0
);

  localparam [2:0] sync = 3'b000;
  localparam [2:0] black = 3'b001;
  localparam [2:0] gray0 = 3'b010;
  localparam [2:0] gray1 = 3'b100;
  localparam [2:0] gray2 = 3'b011;
  localparam [2:0] gray3 = 3'b101;
  localparam [2:0] gray4 = 3'b110;
  localparam [2:0] gray5 = 3'b111;

  wire pixel_clk;
  reg [2:0] pixelsc;
  reg [2:0] pixelsp;

  Gowin_rPLL pixel_clock_generator(
      .clkout(pixel_clk), //output clkout
      //.reset(!row_enable), //input reset
      .clkin(sys_clk) //input clkin
  );

  reg [15:0] counterc;
  reg [15:0] counterp;

  always @(posedge pixel_clk) 
  begin
    if ( row_enable)
    begin
      counterp <= counterp + 1'd1;
      if ( vert_c[4] )
        pixelsp = counterp[4] ? gray2 : black;
      else    
        pixelsp = counterp[4] ? black : gray2;
    end
    else
      counterp <= 16'd0;
  end

  always @(posedge sys_clk) 
  begin
    if ( row_enable)
    begin
      counterc <= counterc + 1'd1;
      if ( vert_c[4] )
        pixelsc = counterc[4] ? gray2 : black;
      else    
        pixelsc = counterc[4] ? black : gray2;
    end
    else
      counterc <= 16'd0;
  end

  assign pixel_signal = button0 ? pixelsp : pixelsc;

endmodule
