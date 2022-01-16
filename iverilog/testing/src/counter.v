module conway(
  input clk, 
	input [8:0] cells,
	output reg new_state
  );

  reg strobe = 0;
  reg [3:0] ctr = 0;

  initial new_state = 0;

  // Add up the cells
  always @(posedge clk) begin
  	ctr <= cells[0] + cells[1] + cells[2] + 
  			   cells[3] + cells[4] + cells[5] + 
  			   cells[6] + cells[7];
  end    
  
  // set the new state
  always @(posedge clk) begin
    if ( cells[8] ) begin  
      new_state <= ((ctr == 2) || (ctr == 3)) ? 1 : 0;
    end
    else begin
      new_state <= ctr == 3;  
    end
  end

endmodule