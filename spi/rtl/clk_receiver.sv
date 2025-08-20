module clk_receiver (
  input  logic pclk,
  input  logic presetn,
  input  logic sclk_in,
  input  logic counter_en,
  input  logic counter_clear,

  output logic sample_edge,
  output logic transmit_edge,
  output logic transfer_finish
);

  logic sclk_q;
  
  dff #(
    .FLOP_WIDTH(1)
  )u_sclk(
    .clk     ( pclk    ),
    .reset_b ( presetn ),
    .q       ( sclk_q  ),
    .d       ( sclk_in )
  );

  logic sclk_edge;

  assign sclk_edge = sclk_in ^ sclk_q;

  logic even_edge;
  logic even_edge_d;

  assign even_edge_d = sclk_edge ? (~ even_edge) : even_edge;

  dff #(
    .FLOP_WIDTH(1)
  )u_dff(
    .clk     ( pclk        ),
    .reset_b ( presetn     ),
    .q       ( even_edge   ),
    .d       ( even_edge_d )
  );

  assign sample_edge   = sclk_edge & (((~ cpha) & even_edge) | (cpha & (~ even_edge)));
  assign transmit_edge = sclk_edge & (((~ cpha) & (~even_edge)) | (cpha & even_edge));

  logic [2:0] receiver_cycle_count;

  counter_en #( 
   .COUNTER_WIDTH (3)
) u_frame_counter (

  .clk           ( pclk                       ),
  .reset_b       ( presetn                    ),
  .counter_clear ( counter_clear),
  .en            ( counter_en   ),
  .count         ( receive_cycle_count        )
  );

  assign transfer_finish = (receive_cycle_count == 3'b111);

endmodule

