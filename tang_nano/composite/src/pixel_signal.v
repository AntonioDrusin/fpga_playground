module pixel_signal (
  input sys_clk,
  input row_enable,             // 1, during row output, 0 otherwise
  input vblank,

  output reg cache_readen,
  input cache_out,
  output reg [8:0] cache_addrout,

  output reg [15:0] mem_addrin,
  input mem_ready,
  output reg mem_readstrobe,

  output reg [2:0] pixel_signal,
  output reg preload_done   // Preload is completed on posedge
);
  reg fetchdone = 0;
  reg [4:0] delaycounter = 0;

  reg [1:0] pix_c = 0;
  reg clk_en = 0;
  initial preload_done = 0;

  always @(posedge sys_clk) begin
    pix_c <= pix_c + 1'd1;

    if ( pix_c == 2'd3 )
    begin 
      clk_en <= 1;
      pix_c <= 2'd0;
    end
    else
      clk_en <= 0;
  end

  reg [7:0] row_counter = 0;

  always @(posedge sys_clk) 
  begin
    if ( clk_en ) begin
      if (row_enable)
      begin
        // fetch at the beginning of the row
        if ( !fetchdone ) begin 
          if ( mem_ready ) begin
            row_counter <= row_counter + 1'd1;
            mem_addrin <= { 3'b000, row_counter, 5'b00000 };
            mem_readstrobe <= 1;
            fetchdone <= 1;
            preload_done <= 0;
          end
        end
        else begin
          mem_readstrobe <= 0;
          if ( mem_ready ) preload_done <= 1;
        end

        // Write pixel out after an initial delay
        if ( delaycounter == 26 ) begin // Center a 256 pixel wide image
          cache_readen <= 1;

          if ( cache_addrout < 256 ) begin
            if ( cache_readen ) begin
              cache_addrout <= cache_addrout + 1'd1;
              // Visible between d24 and d280
              pixel_signal <= cache_out  ? video_level.gray3 : video_level.black; //cache_out ? gray3 : black;
            end
          end
          else pixel_signal <= video_level.gray1;
        end
        else
          delaycounter <= delaycounter + 1'd1;
      end
      else if ( vblank ) begin
        row_counter <= 0;
      end
      else
      begin
        cache_readen <= 0;
        fetchdone <= 0;
        delaycounter <= 0;
        cache_addrout <= 9'd0;
      end
    end
  end

endmodule
