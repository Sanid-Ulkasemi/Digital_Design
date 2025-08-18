module edge_counter (
  input logic pclk,
  input logic presetn,
  input logic bit_eq_n,
  input logic en_tgl,
  
  output logic [4:0] edge_cnt,
  output logic       even

);
  
  counter #(
    .RESET_VALUE   ( 1'b0  ),
    .COUNTER_WIDTH ( 5    )
  ) u_edge_cnt (
    .clk     ( pclk        ),
    .reset_b ( presetn     ),
    .clear   ( bit_eq_n    ),
    .en      ( en_tgl      ), 
    .count   ( edge_cnt    )
  );
  
  assign even =  ~(edge_cnt[0]);

endmodule