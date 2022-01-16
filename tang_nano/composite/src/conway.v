module conway(
  input work_clk,
  input row_enable,
  input vblank,

  // connection to the buffer ram
  output reg cram_ce,
  output reg cram_wre,
  output reg [7:0] cram_datain,
  input [7:0] cram_dataout,
  output reg [7:0] cram_addrin,

  // connection to psram
  output reg [8:0] mem_wbsram_addr, 
  output reg [15:0] mem_addrin, 
  input mem_ready,
  output reg mem_wread_strobe,
  output reg mem_wwrite_strobe,
  input preload_done,
  input button0,
  input button1
);

  initial cram_ce = 0;
  initial cram_wre = 0;

  localparam [3:0] STEP_HOLD = 0;
  localparam [3:0] STEP_LOADLINE = 1;
  localparam [3:0] STEP_LOADINGLINE = 2;
  localparam [3:0] STEP_PROCESSLINE = 3;
  localparam [3:0] STEP_PROCESSINGLINE = 4;
  localparam [3:0] STEP_MOVELINE1 = 5;
  localparam [3:0] STEP_MOVINGLINE1 = 6;
  localparam [3:0] STEP_MOVELINE2 = 7;
  localparam [3:0] STEP_MOVINGLINE2 = 8;
  localparam [3:0] STEP_STORELINE = 9;
  localparam [3:0] STEP_STORINGLINE = 10;

  localparam [1:0] WBSRAM_LINE0   = 2'h0; // Only use 2 bits, not 9!!
  localparam [1:0] WBSRAM_LINE1   = 2'h1;
  localparam [1:0] WBSRAM_LINE2   = 2'h2;
  localparam [1:0] WBSRAM_LINEOUT = 2'h3;

  // split the BSRAM across two modules
  reg cram_ce1;
  reg cram_ce2;
  reg cram_wre1;
  reg cram_wre2;
  reg [7:0] cram_datain1;
  reg [7:0] cram_datain2;
  reg [7:0] cram_addrin1;
  reg [7:0] cram_addrin2;

  assign cram_ce = cram_ce1 || cram_ce2;
  assign cram_wre = cram_wre1 || cram_wre2;
  assign cram_datain = cram_wre1 ? cram_datain1 : cram_datain2;
  assign cram_addrin = cram_ce1 ? cram_addrin1 : cram_addrin2;

  reg start_algo;
  wire algo_busy;
  reg [7:0] curWriteRow = 8'd0;
  reg pause;
  conway_algo conway_algo(
    work_clk,
    start_algo,
    algo_busy,
    // BSRAM
    cram_ce1,
    cram_wre1,
    cram_datain1,
    cram_dataout,
    cram_addrin1,
    button0,
    pause,
    curWriteRow
  );

  // at start of each line (at line negedge)
  // load the current line on line buffer 2.
  // process line buffer 1 
  // move buffer 1>0
  // move buffer 2>1  
  // store line buffer 1

  reg linestart_strobe;
  reg linestarted;
  assign linestart_strobe = preload_done & !linestarted;
  always @(posedge work_clk) begin
    linestarted <= preload_done;
  end

  reg frame_reset;
  always @(posedge work_clk) begin
    if ( vblank ) frame_reset <= 1;
    if ( frame_reset ) frame_reset <= 0;
  end

  reg preload = 0;
  reg preloaded = 0;
  always @(posedge work_clk) begin
    if ( frame_reset ) begin
      preload <= 1;
      if ( preload ) preloaded <= 1;
    end
  end

  reg [3:0] step = STEP_HOLD;

  // state driver
  always @(posedge work_clk) begin
    case ( step )
      STEP_HOLD:  if ( linestart_strobe ) step <= STEP_LOADLINE;
      STEP_LOADLINE:  if ( mem_ready ) step <= STEP_LOADINGLINE;
      STEP_LOADINGLINE: if ( mem_ready && mem_wread_strobe == 0 ) step <= STEP_PROCESSLINE;
      STEP_PROCESSLINE:  step <= STEP_PROCESSINGLINE;
      STEP_PROCESSINGLINE:  if ( !algo_busy ) step <= STEP_MOVELINE1;
      STEP_MOVELINE1: step <= STEP_MOVINGLINE1;
      STEP_MOVINGLINE1: if ( !movingline ) step <= STEP_MOVELINE2;
      STEP_MOVELINE2:  step <= STEP_MOVINGLINE2;
      STEP_MOVINGLINE2: if ( !movingline ) step <= STEP_STORELINE;
      STEP_STORELINE: if ( mem_ready ) step <= STEP_STORINGLINE;
      STEP_STORINGLINE: if ( mem_ready && mem_wwrite_strobe ) step <= STEP_HOLD;
    endcase
  end

  // line load/store
  reg [7:0] curReadRow = 8'd0;
  always @(posedge work_clk) begin
    if ( frame_reset ) begin
      curReadRow <= 8'h0;
      curWriteRow <= 8'hff;
      pause <= ~button1;
    end
    case ( step )
      STEP_LOADLINE: begin
        if ( mem_ready ) begin // This should always be true here
          mem_addrin <=  { 3'b000, curReadRow, 5'b00000 };
          curReadRow <= curReadRow + 1'd1; // ff, 0, 1 .. ff
          mem_wbsram_addr <= {WBSRAM_LINE2, 7'b0}; // This is a 9 bit address
          mem_wread_strobe <= 1;
        end
      end
      STEP_LOADINGLINE: begin
        mem_wread_strobe <= 0;
      end
      STEP_STORELINE: begin
        if ( mem_ready && preloaded ) begin
          mem_addrin <= { 3'b000, curWriteRow, 5'b00000 };
          mem_wbsram_addr <=  { WBSRAM_LINEOUT, 7'd0 };
          mem_wwrite_strobe <= 1;
          curWriteRow <= curWriteRow + 1'd1;
        end
      end
      STEP_STORINGLINE: begin
        mem_wwrite_strobe <= 0;
      end
    endcase
  end

  // mixed stuff
  reg [1:0] movefromline = 2'd0;
  reg [1:0] movetoline = 2'd0;

  localparam [1:0] MLSTATE_NONE = 0;
  localparam [1:0] MLSTATE_START = 1;
  localparam [1:0] MLSTATE_MOVE = 2;
  reg moveline_start = 0;
  reg movingline;
  assign movingline = moveline_start || moveline;
  always @(posedge work_clk) begin
    case ( step )
      STEP_PROCESSLINE: start_algo <= 1;
      STEP_PROCESSINGLINE: start_algo <= 0; // There must be a better way with 2 flip flops instead of this large comaprator
      STEP_MOVELINE1: begin
        movefromline <= 2'd1;
        movetoline <= 2'd0;
        moveline_start <= 1;
      end
      STEP_MOVINGLINE1: moveline_start <= 0;
      STEP_MOVELINE2: begin
        movefromline <= 2'd2;
        movetoline <= 2'd1;
        moveline_start <= 1;
      end
      STEP_MOVINGLINE2: moveline_start <= 0;
    endcase
  end

  // move lines
  localparam [1:0] STATE_READ= 0;
  localparam [1:0] STATE_WRITE= 1;
  localparam [1:0] STATE_OFF= 2;
  assign cram_datain2 = cram_dataout;
  reg [1:0] movestate = 0;
  reg moveline = 0;
  reg [5:0] movecount = 7'd0;

  always @(posedge work_clk) begin
    // | RADDR | HOLD+WADDR|W |
    if ( moveline_start ) begin
        moveline <= 1;
        movecount <= 7'd0;
        movestate <= 0;
    end
    else if ( moveline ) begin
      if ( movecount < 6'd40 ) begin
        case (movestate)
          STATE_READ: begin
            cram_ce2 <= 1;
            cram_wre2 <= 0;
            cram_addrin2 <= {movefromline, movecount};
            movestate <= STATE_WRITE;
          end
          STATE_WRITE: begin
            cram_addrin2 <= {movetoline, movecount};
            cram_wre2 <= 1;
            movestate <= STATE_OFF;
          end
          STATE_OFF: begin
            cram_wre2 <= 0;
            cram_ce2 <= 0;
            movecount <= movecount + 1'd1;
            movestate <= STATE_READ;
          end
        endcase
      end
      else begin
        moveline <= 0;
      end
    end
  end
endmodule

module conway_algo(
  input work_clk,
  input start, // starts the algorithm
  output reg busy,

  // BSRAM
  output reg cram_ce,
  output reg cram_wre,
  output reg [7:0] cram_datain,
  input [7:0] cram_dataout,
  output reg [7:0] cram_addrin,
  input button0_n,
  input pause,
  input [7:0] curWriteRow
);
  localparam [1:0] WBSRAM_LINE0   = 2'h0; // Only use 2 bits, not 9!!
  localparam [1:0] WBSRAM_LINE1   = 2'h1;
  localparam [1:0] WBSRAM_LINE2   = 2'h2;
  localparam [1:0] WBSRAM_LINEOUT = 2'h3;

  reg working;
  assign busy = working | strobe;

  reg [3:0] counter = 0;

  reg [9:0] original [0:2]; // 8th bit is the previous pixel for neighbouring processing
  reg [7:0] processed;
  reg [5:0] currentReadAddr = 0;
  reg [5:0] currentWriteAddr = 0;

  reg strobe;
  reg started = 0;
  assign strobe = start && !started;

  reg [7:0] test_cache;

  always @(posedge work_clk) begin
    started <= start;
  end

  wire random;
  lfsr lfsr( work_clk, random);

  reg firstLoop = 1;
  // dataloader
  always @(posedge work_clk) begin
  	if ( strobe ) begin
  		working <= 1;
        counter <= 0;
        currentReadAddr <= 0;
        currentWriteAddr <= 0;
        firstLoop <= 1;
  	end

    if ( working ) begin
      counter <= counter + 1'd1;
      case (counter)
        0: begin
          cram_wre <= 0;
          cram_ce <= 1;
          cram_addrin <= {WBSRAM_LINE0, currentReadAddr};
        end
        1: begin
          cram_addrin <= {WBSRAM_LINE1, currentReadAddr};
        end
        2: begin
          cram_addrin <= {WBSRAM_LINE2, currentReadAddr};
        end
        3: begin
          currentReadAddr <= currentReadAddr + 1'd1;
          cram_ce <= 0;
        end
        7: begin
          if ( firstLoop )
            firstLoop <= 0;
          else begin
            currentWriteAddr <= currentWriteAddr + 1'd1;
            cram_ce <= 1;
            cram_wre <= 1;
            cram_addrin <= {WBSRAM_LINEOUT, currentWriteAddr};
//            if ( button0_n )
              cram_datain <=  processed;
//            else begin
              //if ( curWriteRow == 120 && currentWriteAddr == 15 ) cram_datain <=      8'b00011000;
              //else if ( curWriteRow == 121 && currentWriteAddr == 15 ) cram_datain <= 8'b00110000;
              //else if ( curWriteRow == 120 && currentWriteAddr == 15 ) cram_datain <= 8'b00010000;
              //else cram_datain <= 8'd0;
            //end
          end
          if ( currentWriteAddr == 31 ) begin
            working <= 0; // last byte
          end
        end
        8: begin
          cram_wre <= 0;
          cram_ce <= 0;
        end
        11: counter <= 0;
      endcase
    end
    else begin
      cram_ce <= 0;
      cram_wre <= 0;
    end
  end

  // shifter
  always @(posedge work_clk) begin
    if ( working ) begin
      case (counter)
        2: begin
          original[0] <= {cram_dataout, original[0][2], original[0][1]};
        end
        3: begin
          original[1] <= {cram_dataout, original[1][2], original[1][1]};
        end
        4: begin
          original[2] <= {cram_dataout, original[2][2], original[2][1]};
        end
        5,6,7,8,9,10,11: begin
          original[0] <= original[0] >> 1;
          original[1] <= original[1] >> 1;
          original[2] <= original[2] >> 1;
        end
      endcase
    end
  end

  reg [2:0] sum = 0;
  reg c = 0;
  // sum processor
  always @(posedge work_clk) begin
    if ( counter == 0 || (counter >= 5 ) ) begin
      sum <= original[0][2] + original[0][1] + original[0][0] +
             original[1][2] +                  original[1][0] +
             original[2][2] + original[2][1] + original[2][0];
      c <= original[1][1];
    end
  end

  reg newState;
  assign newState = c ? ((sum == 3 || sum == 2) ? 1 : 0) : ((sum == 3) ? 1 : 0);

  // result processor
  always @(posedge work_clk) begin
    if ( strobe ) processed <= 0;
    if ( counter <= 1 || (counter >= 6 ) ) begin
        if ( ~pause ) // hold button
          if ( button0_n ) // randomize button
            processed <= {  newState, processed[7:1]  };
          else
            if ( curWriteRow > 64 && curWriteRow < 196 && currentWriteAddr > 8 && currentWriteAddr < 24 )
              processed <= {  random , processed[7:1]  };
            else
              processed <= {  0 , processed[7:1]  };
        else
          processed <= {  c, processed[7:1]  };
    end
  end

endmodule

module lfsr (
  input clk,
  output reg value
);
  reg [31:1] r = 45;
  assign value = r[31] ^ (~r[28]);
  always @(posedge clk) r <= {r[30:1], value};
endmodule