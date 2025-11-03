
(* keep_hierarchy = "true" *)module clock_gen(
  input logic pclk,
  input logic presetn,
  input logic sclk_tx,
  input logic cpha,
  input logic cpol,
  input  logic[2:0] char_len,
  input logic[15:0] divider,
  
  output logic sclk_pad_o,
  output logic cnt_eq_word,
  output logic sclk_sig,
  output logic odd
  
);


  logic[16:0] clk_cnt;
  logic[8:0] tx_cnt;

  logic comp_out;
  logic cnt_geq_word1;
  logic tff_d;
  logic tff_clr;

  logic sclk_delayed_d;
  logic sclk_delayed;

  logic sclk_raw;
  logic sclk_no_pol;


  tff_clr#(
    .RESET_VALUE(1'b0),
    .FLOP_WIDTH(1),
    .CLEAR_VALUE(1'b0)
  )u_tff(  
    .clk     ( pclk       ),
    .reset_b ( presetn    ),
    .t       ( tff_d      ),
    .clr     ( tff_clr    ),
    
    .q       ( sclk_raw   )
  );

  dff#(
    .RESET_VALUE(1'b0),
    .FLOP_WIDTH(1)
  )u_dff(  
    .clk     ( pclk       ),
    .reset_b ( presetn    ),
    .d       ( sclk_delayed_d   ),
    
    .q       ( sclk_delayed   )
  );




  always@(posedge pclk or negedge presetn)begin
  
    if(~presetn)begin
      clk_cnt[16:0] <= 17'b0;
      tx_cnt [8:0]  <= 9'b0;
    end
  
    else begin
      clk_cnt[16:0] <= comp_out ? 17'b0 : clk_cnt + sclk_tx;
      tx_cnt [8:0]  <= ~sclk_tx ? 9'b0 : tx_cnt + comp_out;
    end
  end
  
  assign comp_out = clk_cnt == divider;
  assign tff_d    = comp_out & ~cnt_geq_word1;
  assign tff_clr  = 1'b0;
  
  assign sclk_delayed_d = comp_out ? sclk_raw : sclk_delayed;
  
  assign cnt_eq_word   = (tx_cnt == {~(|char_len), char_len, 1'b1} ) & comp_out;
  assign cnt_geq_word1 = tx_cnt >= {~(|char_len), char_len, 1'b0};
  assign odd = tx_cnt[0];
  assign sclk_no_pol = cpha ? sclk_delayed : sclk_raw;
  assign sclk_pad_o  = cpol ? ~sclk_no_pol : sclk_no_pol; 
  
  assign sclk_sig = tff_d;

  
  
endmodule