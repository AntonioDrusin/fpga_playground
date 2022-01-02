module video_signal (
  input pixel_clk,
  input row_enable,             // 1, during row output, 0 otherwise
  input vblank,

  output reg cache_readen,
  input reg cache_out,
  output reg [8:0] cache_addrout,

  output reg [15:0] mem_addrout,
  input mem_ready,
  output reg mem_readstrobe,

  output reg [2:0] pixel_signal
);
  reg fetchdone = 0;
  reg [3:0] delaycounter = 0;

  always @(posedge pixel_clk) 
  begin
    if (row_enable)
    begin
      // fetch at the beginning of the row
      if ( !fetchdone ) begin 
        if ( mem_ready ) begin
          mem_addrout <= mem_addrout + 7'd80; // skip 80 bytes and read the next row
          mem_readstrobe <= 1;
          fetchdone <= 1;
        end
      end
      else mem_readstrobe <= 0;

      // Write pixel out after a 16 pixel initial delay
      if ( &delaycounter ) begin
        cache_readen <= 1;
        if ( cache_readen ) cache_addrout <= cache_addrout + 1'd1;
        // Visible between d24 and d280
        pixel_signal <= cache_out  ? video_level.gray3 : video_level.black; //cache_out ? gray3 : black;
      end
      else
        delaycounter <= delaycounter + 1'd1;
    end
    else if ( vblank ) begin
      mem_addrout <= 0;
    end
    else
    begin
      cache_readen <= 0;
      fetchdone <= 0;
      delaycounter <= 0;
      cache_addrout <= 9'd0;
    end
  end

endmodule
