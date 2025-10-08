module temperature_wrapper (

  input wire pclk,
  input wire presetn,
  input wire psel ,
  input wire penable ,
  input wire pwrite ,
  input wire [31:0]pwdata ,
  input wire [31:0]paddr ,
  input wire ss_pad_i,
  input wire simo_pad_i,
  input wire sclk_in,
  input wire pb_temp_inc,
  input wire pb_temp_dec,

                     
  output wire somi_pad_o,
  output wire fan_led,
  output wire heater_led,
  output wire [31:0]prdata,
  output wire pready,
  output wire pslverr 

);
assign plsverr = 1'b0;
spi_sub_top spi (

  .pclk        ( pclk        ),
  .presetn     ( presetn     ),
  .psel        ( psel        ),
  .penable     ( penable     ),
  .pwrite      ( pwrite      ),
  .pwdata      ( pwdata      ),
  .paddr       ( paddr       ),
  .ss_pad_i    ( ss_pad_i    ),
  .simo_pad_i  ( simo_pad_i  ),
  .sclk_in     ( sclk_in     ),
  .pb_temp_inc ( pb_temp_inc ),
  .pb_temp_dec ( pb_temp_dec ),
  
  
  .somi_pad_o  ( somi_pad_o  ),
  .fan_led     ( fan_led     ),
  .heater_led  ( heater_led  ),
  .prdata      ( prdata      ),
  .pready      ( pready      )
  
);

endmodule