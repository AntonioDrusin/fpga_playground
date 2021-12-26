module test (
  input sys_rst_n,
  output reg [2:0] sig
);

  wire clk;
  
  // A 2Mhz clock is going to work great to express all PAL and NTSC timings.
  // I might use the PLL for the pixel clock

  // State machine for 312 lines (fake progressive ITU System I)
  // 5 half lines broad sync
  // 5 half lines short sync
  // OR 2 broad, 1 bs, 2 short
  // 18 full black lines
  // 286 full lines with data
  // 6 short sync half lines
  

  localparam [2:0] sync = 3'b11;
  localparam [2:0] black = 3'b110;
  localparam [2:0] gray = 3'b100;
  localparam [2:0] gray2 = 3'b001;

  reg [6:0] horiz_c; // 0-127 for each line 0-63 for halflines, 0.5uS resolution
  reg [8:0] vert_c;  // vertical counter 
  reg oscilloscope;

  always @(posedge clk) begin
      horiz_c <= horiz_c+7'd1;
      if ( horiz_c == 7'h7f )      
         vert_c <= vert_c + 9'd1;
      if ( vert_c == 9'd311 ) 
         vert_c <= 9'd0;

      oscilloscope <= !oscilloscope;
  end

  always @(*)
  begin
    if ( vert_c < 150 )
        sig <= 1;
    else    
        sig <= 0;
         
  end   
  
endmodule