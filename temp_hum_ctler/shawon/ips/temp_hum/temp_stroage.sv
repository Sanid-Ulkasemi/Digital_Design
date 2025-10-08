module temp_stroage (
  input  logic          pclk,
  input  logic          presetn,
  input  logic [7:0]    real_time_temp,
  input  logic          pwrite,
  input  logic          penable,
  input  logic          psel,
  input  logic [31:0]   paddr,
  input  logic [31:0]   pwdata,
  input  logic          simo_pad_i,
  input  logic          spi_sclk_in,
  input  logic          ss_pad_i,
  input  logic          intpt,
                        
  output logic          pready,
  output logic [31:0]   prdata,
  output logic          somi_pad_o
);

//  logic delayed_intpt;

//  dff #(
//    .DFF_WIDTH(1)
//  ) u_dff_intpt (
//    .clk     ( pclk          ),
//    .reset_b ( presetn       ),
//    .d       ( intpt         ),
//    .q       ( delayed_intpt )
//  );

//   logic intpt_posedge;

//  assign intpt_posedge = intpt & (~ delayed_intpt);

  spi_sub_top u_spi_sub_top(
    .pclk           ( pclk           ),
    .presetn        ( presetn        ),
    .pwrite         ( pwrite         ),
    .psel           ( psel           ),
    .penable        ( penable        ),
    .paddr          ( paddr          ),
    .pwdata         ( pwdata         ),
    
    .ss_pad_i       ( ss_pad_i       ),
    .sub_tx         ( real_time_temp ),
    .simo_pad_i     ( simo_pad_i     ),
    .sclk_in        ( spi_sclk_in    ),
    
    .pready         ( pready         ),
    .prdata         ( prdata         ),
    
    .sub_rx         (                ),
    .somi_pad_o     ( somi_pad_o     )
  );

endmodule