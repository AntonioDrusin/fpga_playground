// reads 40 bytes into bsram at specified address

module memory (
  input clk,  
  output reg out_ready,  // does not listen to commands when low.

  input [15:0] vps_addr,  // Source or destination address in pseudoram
  input [15:0] cps_addr,  // Source or destination address in pseudoram

  input vread_strobe,      // read 40 bytes into video bsram
  input wread_strobe,     // read 40 bytes into process bsram
  input wwrite_strobe,    // write 40 bytes from process bsram

  // video line connection to bsram
  output vbsram_writeen,
  output [3:0] vbsram_datain,
  output [6:0] vbsram_addrin,

  // work bsram
  input [8:0] wbsram_mem_addr, // which address of bsram to start from
  output wbsram_ce,
  output wbsram_writeen,
  output [3:0] wbsram_datain,
  output [8:0] wbsram_addrin,
  input [3:0] wbsram_dataout,

  // configuration
  input [7:0] mem_150us_clock_count, // The min number of mem_clk to reach a 150us delay.

  // These are connected to the mem chip. Pinout is for Sipeed TANG Nano
  inout wire [3:0] mem_sio,   // sio[0] pin 22, sio[1] pin 23, sio[2] pin 24, sio[3] pin 21
  output wire mem_ce_n,       // pin 19
  output wire mem_clk         // pin 20
);
 
  localparam [2:0] STEP_DELAY = 0;
  localparam [2:0] STEP_RSTEN = 1;
  localparam [2:0] STEP_RST = 2;
  localparam [2:0] STEP_SPI2QPI = 3;
  localparam [2:0] STEP_IDLE = 4;

  localparam [7:0] PS_CMD_RSTEN = 8'h66;
  localparam [7:0] PS_CMD_RST   = 8'h99;
  localparam [7:0] PS_CMD_QPI   = 8'h35;

  reg [15:0] counter = 0;
  reg [2:0] step = 0;
  reg initialized = 0;

  // I thought phasing this 180 would have made things better (more stable signals on clock transition). It does not.
  assign mem_clk = clk;
  wire driver_ce_n;
  wire [3:0] driver_sio_out;  
  wire driver_ready;
  wire driver_sio_outputen;

  mem_driver mem_driver(
    clk,
    vread_strobe,
    wread_strobe,
    wwrite_strobe,
    
    vps_addr,
    cps_addr,
    driver_ready,

    vbsram_writeen,
    vbsram_datain,
    vbsram_addrin,

    wbsram_mem_addr,
    wbsram_ce,
    wbsram_writeen,
    wbsram_datain,
    wbsram_addrin,
    wbsram_dataout,

    mem_sio,
    driver_sio_out,
    driver_sio_outputen,

    driver_ce_n
  );

  wire command_ce_n;
  reg command_strobe = 0;
  reg [7:0] command;
  wire command_ready;
  wire command_line;

  spi_command spi_command(
    clk,
    command,
    command_strobe,
    command_ready,
    command_line,
    command_ce_n
  );

  reg initializing = 0;
  always @(posedge clk) begin
    if ( !initialized ) 
      if ( command_ready && !command_strobe) 
        case (step)
          STEP_DELAY: begin 
            // datasheet requires a 150us delay before sending the reset upon power up
            counter <= counter + 1'd1;
            if ( counter[15:8] == mem_150us_clock_count ) begin
              initializing <= 1;
              step <= STEP_RSTEN;
            end
          end
          STEP_RSTEN: begin
            // RSTEN followed by RST. This sequence is required in the datasheet      
            // But the chip seems functional without it. Removing the RSTEN+RST steps can
            // be a way to recover some LUTs
            command <= PS_CMD_RSTEN;
            command_strobe <= 1;
            step <= STEP_RST;
          end
          STEP_RST: begin
            command <= PS_CMD_RST;
            command_strobe <= 1;
            step <= STEP_SPI2QPI;
          end      
          STEP_SPI2QPI: begin
            // Switch to QPI commands, this saves 6 clocks per read/write     
            // But if you do not need the speed, should not use QPI at all for the Tang Nano
            // The FPGA is just too small.
            command <= PS_CMD_QPI;
            command_strobe <= 1;
            step <= STEP_IDLE;
          end
          STEP_IDLE: begin
            initialized <= 1;
          end
        endcase
    if ( command_strobe ) command_strobe <= 0;
  end
  
  assign out_ready = initialized && driver_ready;
  assign mem_ce_n = command_ce_n && driver_ce_n;
  assign mem_sio = command_ce_n 
    ? (driver_sio_outputen ? driver_sio_out : 4'hZ ) 
    : ({ 3'bzzz, command_line });  
endmodule

module mem_driver(
  input clk,
  input vread_strobe,
  input wread_strobe,
  input wwrite_strobe,

  input [15:0] vaddr,
  input [15:0] caddr,
  output reg ready,

  // video line connection to bsram
  output reg vbsram_writeen,
  output reg [3:0] vbsram_datain,
  output reg [6:0] vbsram_addrin,

  // process bsram
  input [8:0] wbsram_mem_addr, // which address of bsram to start from
  output reg wbsram_ce,
  output reg wbsram_writeen,
  output reg [3:0] wbsram_datain,
  output reg [8:0] wbsram_addrin,
  input [3:0] wbsram_dataout,

  input wire [3:0] mem_sio_in,
  output reg [3:0] mem_sio_out,
  output reg mem_sio_outputen,
  output reg mem_ce_n
);
  localparam [7:0] PS_CMD_READ  = 8'hEB;
  localparam [7:0] PS_CMD_WRITE = 8'h38;
  
  reg [3:0] sio_out = 0;
  reg reading = 0;
  reg writing = 0;
  reg [6:0] counter = 0; 
  reg video = 0;

  initial mem_ce_n = 1;  
  assign ready = !reading && !writing && mem_ce_n;  

  always @(posedge clk) begin
    if ( ready ) begin
      if ( vread_strobe ) begin
        vbsram_addrin <=0;
        reading <= 1; 
        counter <= 0; 
        video <= 1;
      end
      else if ( wread_strobe ) begin
        wbsram_addrin <= wbsram_mem_addr;
        counter <= 0; 
        video <= 0;
        reading <= 1; 
      end
      else if ( wwrite_strobe ) begin
        wbsram_addrin <= wbsram_mem_addr;
        counter <= 0;
        video <= 0;
        writing <= 1;
      end
    end
    else begin
      counter <= counter + 1'd1;
      case (counter) 
        0: begin 
              mem_ce_n <= 0;
              mem_sio_outputen <= 1;
              mem_sio_out <= reading ? PS_CMD_READ[7:4] : PS_CMD_WRITE[7:4];
           end
        1: mem_sio_out <= reading ? PS_CMD_READ[3:0] : PS_CMD_WRITE[3:0];
        2: mem_sio_out <= 4'd0;
        3: mem_sio_out <= 4'd0;
        4: mem_sio_out <= video ? vaddr[15:12] : caddr[15:12];
        5: mem_sio_out <= video ? vaddr[11:8] : caddr[11:8];
        6: begin
             mem_sio_out <= video ? vaddr[7:4] : caddr[7:4];
             if ( writing ) wbsram_ce <= 1;
           end
        7: begin
             mem_sio_out <= video ? vaddr[3:0] : caddr[3:0];
             if ( writing ) begin
               mem_sio_out <= wbsram_dataout;
               wbsram_addrin <= wbsram_addrin + 1'd1;
             end
           end
        default: begin
          if ( reading ) begin
            if ( counter > 13 ) begin // Allow 6 clocks of wait for the RAM to get ready
              mem_sio_outputen <= 0;
              if ( video ) 
                vbsram_writeen <= 1;
              else begin
                wbsram_writeen <= 1;
                wbsram_ce <= 1;
              end

              if ( vbsram_writeen )
                vbsram_addrin <= vbsram_addrin + 1'd1;
              if ( wbsram_writeen )
                wbsram_addrin <= wbsram_addrin + 1'd1;

              if ( counter == 78 ) begin // Max is 64 nibbles at a time
                reading <= 0;   // 13 + 80 nibbles of reading + 1
                wbsram_writeen <= 0;
                vbsram_writeen <= 0;
                wbsram_ce <= 0;
                mem_ce_n <= 1;
              end
            end
          end 
          else if ( writing ) begin
            mem_sio_out <= wbsram_dataout;
            wbsram_addrin <= wbsram_addrin + 1'd1;
            if ( counter == 72 ) begin  // 7 + 64 nibbles + 1
              writing <= 0;
              wbsram_ce <= 0;
              mem_ce_n <= 1;
            end
          end
        end
      endcase
    end
  end
  
  always @(mem_sio_in)  vbsram_datain <= mem_sio_in;
  always @(mem_sio_in)  wbsram_datain <= mem_sio_in;

endmodule


module spi_command( // 12 reg 7 lut 300MHz max
  input clk,
  input [7:0] command,
  input strobe,
  output reg ready,
  output reg line,
  output reg ce_n
);

  reg [7:0] shifter;
  reg sendcommand = 0;
  reg [2:0] command_ctr = 0;

  always @(posedge clk) begin
    if ( ready && strobe ) begin
       sendcommand <= 1;    
       shifter <= command;
       command_ctr <= 0;      
    end
    else if ( sendcommand ) begin
      shifter <= shifter << 1;
      command_ctr <= command_ctr + 1'd1;
      if ( command_ctr == 3'd7 ) begin
        sendcommand <= 0;
      end
    end
  end

  assign line = shifter[7];
  assign ce_n = ~sendcommand;
  assign ready = ce_n;
endmodule
