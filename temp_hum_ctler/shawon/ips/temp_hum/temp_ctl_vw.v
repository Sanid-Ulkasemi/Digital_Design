module temp_ctl_vw (
  input  wire          pclk,
  input  wire          presetn,
  input  wire          inc_temp_pb,
  input  wire          dec_temp_pb,
  input  wire          pwrite,
  input  wire          penable,
  input  wire          psel,
  input  wire [31:0]   paddr,
  input  wire [31:0]   pwdata,
  input  wire          simo_pad_i,
  input  wire          spi_sclk_in,
  input  wire          ss_pad_i,
  input  wire          intpt,
  input  wire          crossed_min_temp,
  input  wire          crossed_max_temp,
  input  wire          default_temp,
                        
  output wire          fan_en,
  output wire          heater_en,
  output wire          pready,
  output wire [31:0]   prdata,
  output wire          somi_pad_o,
  output wire          pselverr
);

  assign pselverr = 1'b0;
  
  temp_ctl_block u_temp_ctl_block (
      .pclk             ( pclk             ),
      .presetn          ( presetn          ),
      .inc_temp_pb      ( inc_temp_pb      ),
      .dec_temp_pb      ( dec_temp_pb      ),
      .pwrite           ( pwrite           ),
      .penable          ( penable          ),
      .psel             ( psel             ),
      .paddr            ( paddr            ),
      .pwdata           ( pwdata           ),
      .simo_pad_i       ( simo_pad_i       ),
      .spi_sclk_in      ( spi_sclk_in      ),
      .ss_pad_i         ( ss_pad_i         ),
      .intpt            ( intpt            ),
      .crossed_min_temp ( crossed_min_temp ),
      .crossed_max_temp ( crossed_max_temp ),
      .default_temp     ( default_temp     ),
    
      .fan_en           ( fan_en           ),
      .heater_en        ( heater_en        ),
      .pready           ( pready           ),
      .prdata           ( prdata           ),
      .somi_pad_o       ( somi_pad_o       )
  );

endmodule