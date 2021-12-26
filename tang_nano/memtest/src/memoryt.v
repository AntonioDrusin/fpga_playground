module memory (
  input sys_rst_n,
  output reg mem_clk,
  inout wire [3:0] mem_sio,
  output wire mem_ce_n
);
  
  

  wire reset_n;
  wire clk;
  reg [1:0] mem_cmd;

  gw_osc your_instance_name(
    .oscout(clk) //output oscout
  );


  reg [3:0] clk_c;
  always @(posedge clk) 
  begin
    clk_c <= clk_c +1;
    if ( clk_c == 3 ) begin
      clk_c <= 0;
      mem_clk <= !mem_clk;
    end    
  end

  // assign mem_clk = clk;

  reset_repeater reset(
    mem_clk,
    reset_n
  );


  wire ready;
  reg [1:0] command;

  mem_driver mem_driver(
    mem_sio,
    mem_ce_n,
    mem_clk,
    reset_n,
    command,
    ready
  );

  // Simple test, read a byte in SPI mode.
  reg which;
  always_ff @(posedge mem_clk) begin
    if (!reset_n ) begin
      which <= 0;
      command <= 0;
    end 
    else begin
      if ( ready ) begin
        if ( !which ) begin
          command <= mem_driver.CMD_WRITE;
          which <= 1;
        end
        else begin           
          command <= mem_driver.CMD_READ;
        end
      end
      else begin
        command <= 0;
      end
    end
  end
  
  
endmodule

module mem_driver(
  inout wire [3:0] mem_sio,
  output reg mem_ce_n,
  input mem_clk,
  input reset_n,
  input [1:0] command,
  output reg ready
);
  localparam [1:0] CMD_READ = 1;
  localparam [1:0] CMD_WRITE = 2;

  localparam [7:0] PS_CMD_READ = 8'hEB;
  localparam [7:0] PS_CMD_WRITE = 8'h38;

  reg [3:0] sio;
  reg [7:0] rout;
  reg scmd;
  reg [4:0] scounter;
  reg [1:0] executing_command;
      
  assign mem_sio = sio;
  
  initial begin
    mem_ce_n <= 1;
    sio <= 4'd0;
    ready <= 1;
  end

  always @(negedge mem_clk) begin
    if ( !reset_n ) begin
      mem_ce_n <= 1;
      sio <= 0;
      ready <= 1;
      rout <= 0;
      scmd <= 0;
      executing_command <= 0;
    end
    else begin
      if ( ready ) begin
        executing_command <= command;
        if ( command == CMD_READ ) begin
          rout <= PS_CMD_READ;
          scmd <= 1;
          scounter <= 0;
          ready <= 0;    
        end else if ( command == CMD_WRITE ) begin
          rout <= PS_CMD_WRITE;
          scmd <= 1;
          scounter <= 0;
          ready <= 0;           
        end
      end

      if ( scmd != 0) begin
        scounter <= scounter + 5'd1;
        if ( scounter < 8 ) begin
          mem_ce_n <= 0;
          {sio[0], rout[7:1]} <= rout;
          sio[3:1] <= 3'bzzz;
        end
        else if ( scounter < 13 ) begin // Send address
          sio <= 4'd0;
        end
        else if ( scounter < 14 ) begin // Send address
          if ( executing_command == CMD_READ )
            sio <= 4'd15;
          else
            sio <= 4'd0;
        end
      else begin // Rest of the protocol
          if ( executing_command == CMD_READ ) begin
            if (scounter < 20 ) begin // wait cycles
              sio <= 4'bzzzz;
            end
            else if (scounter < 24 ) begin // read 4 nibbles
            end
            else begin  // end of read
              scmd <= 0;
              mem_ce_n <= 1;
              ready <= 1;
              sio[3:0] <= 0;          
              executing_command <= 0;   
            end
          end
          else if ( executing_command == CMD_WRITE ) begin
            if (scounter < 30 ) begin // write 16 nibbles
              sio = scounter[3:0];
            end
            else begin  // end of write
              scmd <= 0;
              mem_ce_n <= 1;
              ready <= 1;
              sio[3:0] <= 0;          
              executing_command <= 0;
            end
          end
        end
      end 
    end
  end
    
endmodule



module reset_repeater( 
  input clk,
  output reg reset_n
);

  reg [7:0] reset_c;     

  always @(posedge clk) begin
      reset_c <= reset_c + 8'd1;
    if ( !reset_n ) begin
      if ( reset_c == 8'hf ) begin
        reset_c <= 0;
        reset_n <= 1;
      end
    end
    else begin
      if ( reset_c == 8'hff ) begin
        reset_c <= 0;
        reset_n <= 0;
      end
    end 
  end

endmodule
