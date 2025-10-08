
module sub_shift_reg_block (
  input  logic        pclk,
  input  logic        presetn,
  input  logic        slave_transfer_shift_en,
  input  logic [7:0]  sub_tx,
  input  logic        slave_receive_shift_en,
  input  logic        simo_pad_i,
  input  logic        tx_load,
                      
  output logic [7:0]  sub_rx,
  output logic        somi_pad_o
);

  logic[1:0] shift_mode_receive;
  logic[1:0] shift_mode_transmit;

  assign shift_mode_receive  = slave_receive_shift_en ? 2'b10 : 2'b0;
  assign shift_mode_transmit = tx_load ? 2'b11 : (slave_transfer_shift_en ? 2'b10 : 2'b00);
  logic [7:0] tx_shift_q;
  universal_shift_reg #(
    .DATA_WIDTH(8)
  ) transfer_shift (
    .clk         ( pclk                ),
    .rst         ( presetn             ),      
    .select      ( shift_mode_transmit ),
    .p_din       ( sub_tx      ),
    .s_left_din  ( '0                  ),
    .s_right_din ( '0                  ),
    .p_dout       (  tx_shift_q        ),  
    .s_left_dout (   somi_pad_o  ),
    .s_right_dout (              )
  );


  universal_shift_reg #(
    .DATA_WIDTH(8)
  ) receiver_shift (
    .clk          ( pclk               ),
    .rst          ( presetn            ),      
    .select       ( shift_mode_receive ),
    .p_din        ( '0                 ),
    .s_left_din   (     ),
    .s_right_din  (  simo_pad_i    ),
    .p_dout       ( sub_rx             ),
    .s_left_dout  (                    ),
    .s_right_dout (                    )
  );

endmodule

