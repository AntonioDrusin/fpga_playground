module top (
  input sys_rst_n,
  input sys_clk,
  output reg [2:0] sig,
  input button0
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
    pixel_signal,
    button0
  );

  // http://www.batsocks.co.uk/readme/video_timing.htm

  // 2MHz generator
  always @(posedge sys_clk) begin
    clk_c <= clk_c + 3'd1;
    pix_c <= pix_c + 3'd1;

    if ( clk_c == 5 )
    begin 
      clk <= ~clk;        // 2MHz
      clk_c <= 3'd0;
    end

    if ( pix_c == 1 )
    begin 
      pix_clk <= ~pix_clk; // 6MHz
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
      sync_signal <= horiz_c[5:0] < (64-9) ? sync : black;
    else if ( vert_c == 9'd2)
      begin
        if ( !horiz_c[6] )             
          sync_signal <= horiz_c[5:0] < (64-9) ? sync : black;
        else
          sync_signal <= horiz_c[5:0] < 6'd5 ? sync : black;
      end
    else if ( vert_c < 9'd5 )
      begin
        sync_signal <= horiz_c[5:0] < 6'd5 ? sync : black;
      end
    else if ( vert_c < 9'd309 )
    begin
      if ( horiz_c < 7'd9 )
        sync_signal <= sync;
      else if ( horiz_c < 7'd21 )
        sync_signal <= black;
      else if ( horiz_c < 7'd125 )
          row_enable <= 1;
      else
      begin 
        row_enable <= 0;
        sync_signal <= black;
      end
    end
    else 
    begin      
      sync_signal <= horiz_c[5:0] < 6'd5 ? sync : black;
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

