module video_sync (
    input sys_clk, // 24MHz
    output reg row_enable,
    output reg vblank,
    output reg [2:0] sync_signal
);

  reg [6:0] horiz_c = 0; // 0-127 for each line 0-63 for halflines, 0.5uS resolution
  reg [8:0] vert_c = 0;  // vertical counter 
  reg oscilloscope = 0; // For denser osc debug output
  initial vblank = 1;

  reg [4:0] syn_c = 0;
  reg clk_en = 0;

  always @(posedge sys_clk) begin
    syn_c <= syn_c + 1'd1;

    if ( syn_c == 4'd11 )
    begin 
      clk_en <= 1;
      syn_c <= 4'd0;
    end
    else
      clk_en <= 0;
  end

  localparam vert_offset = 31;
  localparam vert_resolution = 256;

  // http://www.batsocks.co.uk/readme/video_timing.htm
  always @(posedge sys_clk) begin
    if ( clk_en ) begin
      horiz_c <= horiz_c+7'd1;
      if ( horiz_c == 7'h7f )
         vert_c <= vert_c + 9'd1;
      if ( vert_c == 9'd311 ) 
         vert_c <= 9'd0;

      oscilloscope <= !oscilloscope;

      if ( vert_c < 9'd2 )
        sync_signal <= horiz_c[5:0] < (64-9) ? video_level.sync : video_level.black;
      else if ( vert_c == 9'd2)
        begin
          if ( !horiz_c[6] )
            sync_signal <= horiz_c[5:0] < (64-9) ? video_level.sync : video_level.black;
          else
            sync_signal <= horiz_c[5:0] < 6'd5 ? video_level.sync : video_level.black;
        end
      else if ( vert_c < 9'd5 )
        begin
          sync_signal <= horiz_c[5:0] < 6'd5 ? video_level.sync : video_level.black;
        end
      else if ( vert_c < 9'd309 )
      begin
        vblank <= 0;
        if ( horiz_c < 7'd9 )
          sync_signal <= video_level.sync;
        else if ( horiz_c < 7'd21 )
          sync_signal <= video_level.black;
        else if ( horiz_c < 7'd125 )
          if ( (vert_c > 9'd5 + vert_offset) && (vert_c <= 9'd5 + vert_offset + vert_resolution) )
            row_enable <= 1;
          else
            row_enable <= 0;
        else
        begin 
          row_enable <= 0;
          sync_signal <= video_level.black;
        end
      end
      else 
      begin
        vblank <= 1;
        sync_signal <= horiz_c[5:0] < 6'd5 ? video_level.sync : video_level.black;
      end  
    end
  end

endmodule


module video_level ();
  localparam [2:0] sync = 3'b000;
  localparam [2:0] black = 3'b001;
  localparam [2:0] gray0 = 3'b010;
  localparam [2:0] gray1 = 3'b100;
  localparam [2:0] gray2 = 3'b011;
  localparam [2:0] gray3 = 3'b101;
  localparam [2:0] gray4 = 3'b110;
  localparam [2:0] gray5 = 3'b111;
endmodule