module mosi_gen (
  input logic        pclk,
  input logic        presetn,
  input logic        lsb,
  input logic        transfer_en,
  input logic  [2:0] char_len, 
  input logic  [7:0] trx,
  
  output logic       mosi_pad_o

  
);
  
  logic mout;
  logic xmosi;
  logic d_mosi;
  
  always @(*) begin
    casez(char_len)
  
      3'b000  : mout = trx[7];
      3'b001  : mout = trx[0];
      3'b010  : mout = trx[1];
      3'b011  : mout = trx[2];
      3'b100  : mout = trx[3];
      3'b101  : mout = trx[4];
      3'b110  : mout = trx[5];
      3'b111  : mout = trx[6];
      default : mout = 1'bx;
    
    endcase
  end

  assign xmosi  = lsb ? trx[0] : mout;
  assign d_mosi = transfer_en ? xmosi : mosi_pad_o; 
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b1 )
  )u_mosi(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d_mosi       ),
    .q       ( mosi_pad_o   )
  );
  
endmodule

  

  