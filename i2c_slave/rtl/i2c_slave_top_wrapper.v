module i2c_slave_top_wrapper(
	  input  wire      pclk,
    input  wire      presetn,
    input  wire      psel,
    input  wire      penable,
    input  wire      pwrite,
    input  wire      scl_in,
    input  wire      sda_in,
    input  wire[7:0] paddr,
    input  wire[31:0] pwdata,
    
    output wire pslevrr,
    output wire sda_out,
    output wire sda_en,
    output wire pready,
    output wire[31:0] prdata,
    
    //Debug
    output wire[2:0] state,
    output wire[7:0] sr,
    output wire comp

);


  i2c_slave_top u_i2c_slave_top (

    .pclk    ( pclk    ),
    .presetn ( presetn ),
    .psel    ( psel    ),
    .penable ( penable ),
    .pwrite  ( pwrite  ),
    .scl_in  ( scl_in  ),
    .sda_in  ( sda_in  ),
    .paddr   ( paddr   ),
    .pwdata  ( pwdata  ),
    
    
    .sda_out ( sda_out ),
    .sda_en  ( sda_en  ),
    .pready  ( pready  ),
    .prdata  ( prdata  ),
    
    //Debug
    .sr(sr),
    .comp(comp),
    .state(state)

  );
  
  assign pslevrr = 1'b0;

endmodule