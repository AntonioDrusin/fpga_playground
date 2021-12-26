module measure(
  output reg [2:0] led,
  input wire sys_clk,
  input wire sys_rst_n
);


reg [23:0] counter;
reg slow_clk;

  Gowin_OSC osc(
      .oscout(fast_clk) 
  );

  always @(posedge fast_clk) begin
    if (counter < 23'd10000)       
        counter <= counter + 23'd1;
    else
    begin
        counter <= 23'd0;
        slow_clk <= ~slow_clk;
    end
    led <= {3{slow_clk}};
  end
  

/* 1ms */

 endmodule