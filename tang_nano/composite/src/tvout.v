module top (
  input sys_rst_n,
  input sys_clk,
  output reg [2:0] sig
);

  localparam [2:0] sync = 3'b000;
  localparam [2:0] black = 3'b001;
  localparam [2:0] gray = 3'b101;
  localparam [2:0] gray2 = 3'b011;

  reg clk;
  reg row_enable;
  wire [2:0] pixel_signal;
  reg [2:0] sync_signal;
  reg pix_clk;
  
 
  reg [6:0] horiz_c; // 0-127 for each line 0-63 for halflines, 0.5uS resolution
  reg [8:0] vert_c;  // vertical counter 
  reg [2:0] clk_c;   // clock divider counter
  reg [2:0] pix_c;
  reg oscilloscope;

  video_signal video_signal(
    pix_clk,
    row_enable,             // 1, during row output, 0 otherwise
    vert_c,
    pixel_signal
  );

  // http://www.batsocks.co.uk/readme/video_timing.htm

  // 2MHz generator
  always @(posedge sys_clk) begin
    clk_c <= clk_c + 3'd1;
    pix_c <= pix_c + 3'd1;

    if ( clk_c == 5 )
    begin 
      clk <= ~clk;
      clk_c <= 3'd0;
    end

    if ( pix_c == 1 )
    begin 
      pix_clk <= ~pix_clk;
      pix_c <= 3'd0;
    end

  end

  always @(posedge clk) begin
    horiz_c <= horiz_c+7'd1;
    if ( horiz_c == 7'h7f )      
       vert_c <= vert_c + 9'd1;
    if ( vert_c == 9'd311 ) 
       vert_c <= 9'd0;

    oscilloscope <= !oscilloscope;

    if ( vert_c < 9'd2 )      
      if ( horiz_c[5:0] < (64-9) ) 
        sync_signal <= sync;
      else
        sync_signal <= black;
    else if ( vert_c == 9'd2)
      begin
        if ( !horiz_c[6] )   
          if ( horiz_c[5:0] < (64-9) ) 
            sync_signal <= sync;
          else
            sync_signal <= black;
        else
          if ( horiz_c[5:0] < 6'd5 ) 
            sync_signal <= sync;
          else
            sync_signal <= black;
      end
    else if ( vert_c < 9'd5 )
      begin
        if ( horiz_c[5:0] < 6'd5 ) 
          sync_signal <= sync;
        else
          sync_signal <= black;
      end
    else if ( vert_c < 9'd309 )
    begin
      if ( horiz_c < 7'd9 )
      begin
        sync_signal <= sync;
      end
      else if ( horiz_c < 7'd21 )
      begin
        sync_signal <= black;
      end
      else if ( horiz_c < 7'd125 )
      begin
        // This is me generating the clock interference right here....
          row_enable <= 1;
      end
      else
      begin 
        row_enable <= 0;
        sync_signal <= black;
      end
    end
    else 
    begin      
      if ( horiz_c[5:0] < 6'd5 ) 
        sync_signal <= sync;
      else
        sync_signal <= black;   
    end  
  end

  always @(*)
    if ( row_enable ) 
      sig <= pixel_signal;
    else
      sig <= sync_signal;
  begin    
    
  end   
  
endmodule

