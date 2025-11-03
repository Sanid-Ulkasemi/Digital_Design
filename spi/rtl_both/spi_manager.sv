
(* keep_hierarchy = "true" *)module spi_manager(
  input logic pclk,
  input logic presetn,
  input logic go_bsy,
  input logic odd,
  input logic cnt_eq_word,
  input logic sclk_sig,
  input logic wr_rd_done,
  input logic ie,

  output logic sclk_tx,
  output logic tx_b,
  output logic rx_b,
  output logic bsy_clr
);
  
  parameter IDLE      = 1'b0;
  parameter TRANSFER  = 1'b1;
  
  logic pstate, nstate;
  logic interrupt;
    
  dff#(
    .RESET_VALUE(1'b0),
    .FLOP_WIDTH(1)
  )u_psr(  
    .clk(pclk),
    .reset_b(presetn),
    .d(nstate),
    .q(pstate)
  );
  
  tff#(
  .RESET_VALUE(1'b0),
  .FLOP_WIDTH(1)
  )u_tff(  
    .clk(pclk),
    .reset_b(presetn),
    .t(interrupt),
    .q(interrupt_pad)
  );

  always@(*)begin
    casez(pstate)
      IDLE : nstate = go_bsy ? TRANSFER : IDLE;
      TRANSFER : nstate = cnt_eq_word ? IDLE : TRANSFER;
      default : nstate = 1'bx;
    endcase
  end
  
  assign sclk_tx = pstate == TRANSFER;
  assign tx_b = (pstate == TRANSFER & ~odd & sclk_sig & ~cnt_eq_word) | (pstate == IDLE & sclk_sig);
  assign rx_b = pstate == TRANSFER & odd & sclk_sig & ~cnt_eq_word;
  assign bsy_clr = pstate == TRANSFER & cnt_eq_word;
  
endmodule