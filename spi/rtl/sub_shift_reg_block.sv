module sub_shift_reg_block (
  input  logic       presetn,
  input  logic       slave_transfer_shift_en,
  input  logic [7:0] sub_tx,
  input  logic       slave_receive_shift_en,
  input  logic       simo_pad_i,
  
  output logic [7:0] sub_rx,
  output logic       somi_pad_o
);

  logic shift_mode_receive;
  logic shift_mode_transmit;

  assign shift_mode_receive  = slave_receive_shift_en ? 2'b01 : 2'b0;
  assign shift_mode_transmit = load_from_fifo ? 2'b11 : (slave_transfer_shift_en ? 01 : 00);

  universal_shift_reg #(
    .DATA_WIDTH(8)
  ) transfer_shift (
    .clk          ( pckl               ),
    .rst          ( presetn            ),      
    .select       ( shift_mode_receive ),
    .p_din        ( sub_tx             ),
    .s_left_din   ( '0                 ),
    .s_right_din  ( '0                 ),
    .p_dout       (                    ), 
    .s_left_dout  (                    ),
    .s_right_dout ( somi_pas_o         )
  );


  universal_shift_reg #(
    .DATA_WIDTH(8)
  ) receiver_shift (
    .clk          ( pckl               ),
    .rst          ( presetn            ),      
    .select       ( shift_mode_receive ),
    .p_din        ( '0                 ),
    .s_left_din   ( simo_pad_i         ),
    .s_right_din  (                    ),
    .p_dout       ( sub_rx             ),
    .s_left_dout  (                    ),
    .s_right_dout (                    )
  );

endmodule

