`timescale 1us/1us
module test;

  initial begin
    $dumpvars(0, test);
  end
  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #5 clk = !clk;


  reg [8:0] status;
  wire out;

  initial begin
     # 9  status = 9'b000100000; // stays dead
     # 10 status = 9'b001001001; // spawns
     # 10 status = 9'b100000101; // lives
     # 10 status = 9'b100111100; // dies
     # 100 $finish;
  end

  conway conway (clk, status, out);

  initial 
     $monitor("At time %t, out = %h, status = %b", $time, out, status);
endmodule 