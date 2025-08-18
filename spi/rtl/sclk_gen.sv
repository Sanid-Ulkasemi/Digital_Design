 module sclk_gen(
  
  input logic    pclk,
  input logic    presetn,
  input logic    transfer,
  input logic    en_tgl,
  input logic    cpol,
  input logic    cpha,

  output logic   sclk_pad_o
  
);

  logic sclk;
 
  
  tff #(    
    .RESET_VALUE( 0 )
  )u_psr(  
    .clk     ( pclk      ),
    .reset_b ( presetn   ),
    .clear   ( ~transfer ),
    .t       ( en_tgl    ),
    .q       ( sclk      )
  );
  
  
  assign sclk_pad_o = transfer ? ( (cpha == cpol) ? ~sclk : sclk) : cpol ;
  
endmodule