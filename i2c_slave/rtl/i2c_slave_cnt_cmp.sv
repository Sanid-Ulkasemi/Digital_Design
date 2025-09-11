module i2c_slave_cnt_cmp(
  input logic pclk,
  input logic presetn,
  input logic counter_en,
  input logic counter_clr,

  output logic tx_eq8
);

  logic[3:0] cnt_val;
 
  counter #(
    .RESET_VALUE(1'b0),
    .COUNTER_WIDTH(4)
  )u_counter(
    .clk(pclk),
    .reset_b(presetn),
    .en(counter_en),
    .clear(counter_clr),
  
    .counter(cnt_val)
  );

  assign tx_eq8 = cnt_val == 4'b1000;
  

endmodule