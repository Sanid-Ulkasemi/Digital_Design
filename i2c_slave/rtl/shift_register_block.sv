module shift_register_block (
  input  logic       pclk,             
  input  logic       presetn,          // Active-low reset
  input  logic       shift_load_en,    // Enable shift register
  input  logic       ack_cycle,      
  input  logic       dack_cycle,     
  input  logic [7:0] tx_data,
  input  logic [6:0] slave_addr,
  input  logic       sda_in,
  
  output logic [7:0] dr_data,
  output logic       read,
  output logic       sda_out
  
);
  logic bit_out;
  logic [1:0] shift_mode;

  assign shift_mode = shift_load_en ? 2'b11 : (shift_en ? 2'b10 : 2'b00); 

  universal_shift_reg #(
    .DATA_WIDTH(8)
  ) shift_inst (
    .clk          ( pckl         ),
    .rst          ( presetn      ),      
    .select       ( shift_mode   ),
    .p_din        ( tx_data      ),
    .s_left_din   ( 1'b0         ),
    .s_right_din  ( sda_in       ),
    .p_dout       ( dr_data      ),
    .s_left_dout  (  bit_out     ), 
    .s_right_dout (              )
  );

  always @ (*) begin
    casez ({ack_cycle,dack_cycle})
      2'b00   : sda_out = bit_out;
      2'b01   : sda_out = 1'b0;
      2'b10   : sda_out = ~(slave_addr == dr_data[7:1]);
      2'b11   : sda_out = bit_out;
      default : sda_out = 8'bx;
    endcase
  end

  assign read = dr_data[0];

endmodule