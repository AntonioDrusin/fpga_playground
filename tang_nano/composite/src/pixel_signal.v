module video_signal (
  input sys_clk,
  input row_enable,             // 1, during row output, 0 otherwise
  input [8:0] vert_c,
  output reg [2:0] pixel_signal
);

  localparam [2:0] sync = 3'b000;
  localparam [2:0] black = 3'b001;
  localparam [2:0] gray0 = 3'b010;
  localparam [2:0] gray1 = 3'b100;
  localparam [2:0] gray2 = 3'b011;
  localparam [2:0] gray3 = 3'b101;
  localparam [2:0] gray4 = 3'b110;
  localparam [2:0] gray5 = 3'b111;

  reg [15:0] counter;

  always @(posedge sys_clk) 
  begin
    if ( row_enable )
    begin
      counter <= counter + 1'd1;

      if ( vert_c[4] )
      begin
        if ( counter[4] ) 
          pixel_signal = gray2;
        else  
          pixel_signal = black;
      end
      else    
      begin 
        if ( counter[4] ) 
          pixel_signal = black;
        else  
          pixel_signal = gray2;
      end

    end
    else
    begin
      counter <= 16'd0;
    end
  end

endmodule