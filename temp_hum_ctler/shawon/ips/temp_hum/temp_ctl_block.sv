module temp_ctl_block (
  input  logic          pclk,
  input  logic          presetn,
  input  logic          inc_temp_pb,
  input  logic          dec_temp_pb,
  //input  logic [7:0]    real_time_temp,
  input  logic          pwrite,
  input  logic          penable,
  input  logic          psel,
  input  logic [31:0]   paddr,
  input  logic [31:0]   pwdata,
  input  logic          simo_pad_i,
  input  logic          spi_sclk_in,
  input  logic          ss_pad_i,
  input  logic          intpt,
  input  logic          crossed_min_temp,
  input  logic          crossed_max_temp,
  input  logic          default_temp,
                        
  output logic          fan_en,
  output logic          heater_en,
  output logic          pready,
  output logic [31:0]   prdata,
  output logic          somi_pad_o
);

  logic temp_inc_en;
  logic temp_dec_en;
  logic temp_counter_clr;
  logic temp_counter_en;
  logic count_eq_1s;

  temp_ctl_fsm u_temp_ctl_fsm ( 
    .pclk             ( pclk             ),
    .presetn          ( presetn          ),
    .inc_temp_pb      ( inc_temp_pb      ),
    .dec_temp_pb      ( dec_temp_pb      ),
    .crossed_min_temp ( crossed_min_temp ),
    .crossed_max_temp ( crossed_max_temp ),
    .default_temp     ( default_temp     ),
    .count_eq_1s      ( count_eq_1s      ),
    
    .temp_inc_en      ( temp_inc_en      ),
    .temp_dec_en      ( temp_dec_en      ),
    .fan_en           ( fan_en           ),
    .heater_en        ( heater_en        ),
    .temp_counter_clr ( temp_counter_clr ),
    .temp_counter_en  ( temp_counter_en  )
  );

  logic [7:0] real_time_temp;

  temp_stroage u_temp_stroage ( 
    .pclk           ( pclk           ),
    .presetn        ( presetn        ),
    .real_time_temp ( real_time_temp ),
    .pwrite         ( pwrite         ),
    .penable        ( penable        ),
    .psel           ( psel           ),
    .paddr          ( paddr          ),
    .pwdata         ( pwdata         ),
    .simo_pad_i     ( simo_pad_i     ),
    .spi_sclk_in    ( spi_sclk_in    ),
    .ss_pad_i       ( ss_pad_i       ),
    .intpt          ( intpt          ),
    
    .pready         ( pready         ),
    .prdata         ( prdata         ),
    .somi_pad_o     ( somi_pad_o     )
  );

  temp_measure u_temp_measure (
    .pclk           ( pclk           ),
    .presetn        ( presetn        ),
    .temp_inc_en    ( temp_inc_en    ),
    .temp_dec_en    ( temp_dec_en    ),
    
    .real_time_temp ( real_time_temp )
  );

  temp_timer_counter u_temp_timer_counter(
    .pclk             ( pclk             ),
    .presetn          ( presetn          ),
    .temp_counter_en  ( temp_counter_en  ),
    .temp_counter_clr ( temp_counter_clr ),
    
    .count_eq_1s      ( count_eq_1s      )
  );

endmodule