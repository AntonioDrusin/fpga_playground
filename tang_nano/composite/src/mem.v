module memory (
  input sys_rst_n,
  output mem_clk,
  output [0:3] mem_sio,
  output reg mem_ce_n
);
  gw_osc your_instance_name(
    .oscout(mem_clk) //output oscout
  );

  localparam [2:0] op_wcmd = 2'd1;
   
  reg init_n;
  reg [2:0] state;

  reg ready;    // ready for next operation
  reg [2:0] operation; // 000 nothing, 001 write cmd
  reg [7:0] data;
  reg outbit;
  reg [7:0] op_step;   // step of the operation


  always @(negedge sys_rst_n) 
  begin
     
  end

  always @(posedge mem_clk or negedge sys_rst_n) 
  begin
    if (!sys_rst_n)
    begin
      init_n <= 0;    
    end
    else
    begin
      if ( !init_n ) 
      begin
        state <= 1;
        if ( state == 2'd1 && ready)
        begin
          operation <= op_wcmd;
          data <= 8'h66;
          state <= 2'd2;
        end
        else if ( state == 2'd2 && ready)
        begin
          operation <= op_wcmd;
          data <= 8'h99;
          state <= 2'd3;
        end
        else if ( state == 2'd2 && ready)
        begin
          init_n <= 1;    
          state <= 2'd0;        
        end
      end
   
      if ((ready && operation != 3'b000)) 
      begin
        op_step <= 1;
        {data[6:0], outbit} <= data[7:0];
      end
    end
  end

  always @(negedge mem_clk)
  begin
    if ( op_step > 0 )
      mem_ce_n <= 0;
    else  
      mem_ce_n <= 1;
  end

endmodule



