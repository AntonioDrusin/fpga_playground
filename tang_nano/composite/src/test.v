module test(
  //input sys_clk,
  output reg [7:0] data
);

wire sys_clk;
    Gowin_OSC your_instance_name(
        .oscout(sys_clk) //output oscout
    );


//
//  wire cache_out;
//  reg vbsram_writeen;
//  reg cache_readen;
//  reg [6:0] vbsram_addrin;
//  reg [8:0] cache_addrout;
//  reg [3:0] vbsram_datain;
//
//  gowin_linecache vcache(
//      .dout(cache_out),     //output [0:0] dout (read)
//      .clka(sys_clk),      //input clka (write)
//      .cea(vbsram_writeen), //input cea (write)
//      .reseta(1'd0),        //input reseta (write)
//      .clkb(sys_clk),       //input clkb (read)
//      .ceb(cache_readen),   //input ceb (read)
//      .resetb(1'd0),        //input resetb (read)
//      .oce(1'd1),           //input oce
//      .ada(vbsram_addrin),  //input [6:0] ada (write)
//      .din(vbsram_datain),  //input [3:0] din (write)
//      .adb(cache_addrout)   //input [8:0] adb (read)
//  );
//  reg [8:0] lcounter = 0;
//
//  always @(posedge sys_clk) begin
//    lcounter <= lcounter + 1'd1;
//    case (lcounter)
//      0: begin
//        vbsram_datain <= 4'h6;
//        vbsram_writeen <= 1;
//        vbsram_addrin <= 0;
//      end
//      1: begin
//        vbsram_datain <= 4'ha;
//        vbsram_addrin <= 1;
//       end
//      2: begin
//        vbsram_writeen <= 0;
//      end
//      3: begin
//        cache_readen <= 1;
//        cache_addrout <= 0;
//      end
//      4,5,6,7,8,9,10,11: begin
//        cache_addrout <= cache_addrout + 1'd1;
//      end
//      12 : begin
//        cache_readen <= 0;
//        lcounter <= 0;
//      end
//    endcase
//  end

  reg cbsram_ce; // clock enable
  reg cbsram_wre; // write enable
  reg [7:0] cbsram_datain;
  wire [7:0] cbsram_dataout;
  reg [7:0] cbsram_addrin;

  reg wbsram_ce;
  reg wbsram_writeen;
  reg [3:0] wbsram_datain;
  wire [3:0] wbsram_dataout;
  reg [8:0] wbsram_addrin;

  Gowin_DPB wram(
      .douta(cbsram_dataout), //output [7:0] douta
      .doutb(wbsram_dataout), //output [3:0] doutb
      .clka(sys_clk), //input clka
      .ocea(cbsram_ce), //input ocea
      .cea(cbsram_ce), //input cea
      .reseta(1'b0), //input reseta
      .wrea(cbsram_wre), //input wrea
      .clkb(sys_clk), //input clkb
      .oceb(wbsram_ce), //input oceb
      .ceb(wbsram_ce), //input ceb
      .resetb(1'b0), //input resetb
      .wreb(wbsram_writeen), //input wreb
      .ada(cbsram_addrin), //input [7:0] ada
      .dina(cbsram_datain), //input [7:0] dina
      .adb(wbsram_addrin), //input [8:0] adb
      .dinb(wbsram_datain) //input [3:0] dinb
  );

  reg [7:0] counter = 0;

  assign cbsram_datain = cbsram_dataout;

  always @(posedge sys_clk) begin
    counter <= counter + 1'd1;
    case (counter)
      0: begin // Write 8 nibbles
        wbsram_ce <= 1;
        wbsram_writeen <= 1;
        wbsram_addrin <= 9'h80;
        wbsram_datain <= 8'h5;
      end
      1 : begin
        wbsram_addrin <= 9'h81;
        wbsram_datain <= 8'h6;
      end
      2 : begin
        wbsram_addrin <= 9'h82;
        wbsram_datain <= 8'ha;
      end
      3 : begin
        wbsram_addrin <= 9'h83;
        wbsram_datain <= 8'h3;
      end
      4: begin
        wbsram_ce <= 0;
        wbsram_writeen <= 0;
      end
      5: begin
        cbsram_ce <= 1;
        cbsram_addrin <= 8'h40;
      end
      6: begin
        cbsram_addrin <= 8'h20;
        cbsram_wre <= 1;
      end
      7: begin
        cbsram_wre <= 0;
        cbsram_ce <= 0;
      end
      8: begin
        cbsram_addrin <= 8'h41;
        cbsram_ce <= 1;
        cbsram_wre <= 0;
        end
      9: begin
        cbsram_addrin <= 8'h21;
        cbsram_wre <= 1;
        end
      10: begin
        cbsram_ce <= 0;
        cbsram_wre <= 0;
      end
      11: begin
        cbsram_ce <= 1;
        cbsram_addrin <= 8'h20;
      end
      12,13,14,15 : begin
        cbsram_addrin <= cbsram_addrin + 1'd1;
        data <= cbsram_dataout;
      end
      16: begin
        cbsram_ce <= 0;
        counter <= 0;
      end
    endcase
  end


endmodule