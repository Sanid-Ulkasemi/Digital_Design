module humidity_wrapper (

    input  wire      pclk,
    input  wire      presetn,
    input  wire      psel,
    input  wire      penable,
    input  wire      pwrite,
    input  wire      scl_in,
    input  wire      sda_in,
    input  wire[31:0] paddr,
    input  wire[31:0] pwdata,
    
    //push button inputs
    input  wire      pb_hum_inc,
    input  wire      pb_hum_dec,  



    output wire       sda_out,
    output wire       sda_en,
    output wire       pready,
    output wire[31:0] prdata,
    output wire       pslverr,

    output wire hum_led,
    output wire dehum_led

);

i2c_slave_top i2c (

  .pclk       ( pclk       ),
  .presetn    ( presetn    ),
  .psel       ( psel       ),
  .penable    ( penable    ),
  .pwrite     ( pwrite     ),
  .scl_in     ( scl_in     ),
  .sda_in     ( sda_in     ),
  .paddr      ( paddr      ),
  .pwdata     ( pwdata     ),
  
  
  .pb_hum_inc ( pb_hum_inc ),
  .pb_hum_dec ( pb_hum_dec ),
  
  
  
  .sda_out    ( sda_out    ),
  .sda_en     ( sda_en     ),
  .pready     ( pready     ),
  .prdata     ( prdata     ),
  .pslverr    ( pslverr    ),
  
  .hum_led    ( hum_led    ),
  .dehum_led  ( dehum_led  )

);

endmodule