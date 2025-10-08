module edge_detector (
  input  logic pclk,
  input  logic presetn,
  input  logic scl_in,
  
  output logic tx_edge,
  output logic rx_edge
);

 logic scl_delay;

  dff #(
    .DFF_WIDTH(1)
  ) u_dff (
    .clk     ( pclk      ),
    .reset_b ( presetn   ),
    .d       ( scl_in    ),
    .q       ( scl_delay )
  );

  assign tx_edge = ~ scl_in & scl_delay;
  assign rx_edge = scl_in & (~ scl_delay);

endmodule
