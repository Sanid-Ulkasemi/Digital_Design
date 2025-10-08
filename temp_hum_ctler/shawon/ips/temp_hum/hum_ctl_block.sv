module hum_ctl_block(
  input  logic        pclk,
  input  logic        presetn,
  input  logic        inc_hum_pb,
  input  logic        dec_hum_pb,
                      
  input  logic        psel,
  input  logic        pwrite,
  input  logic        penable,
  input  logic [31:0] paddr,
  input  logic [31:0] pwdata,
                      
  input  logic        sda_in,
  input  logic        scl_in,
  input  logic        intpt,
  input  logic        crossed_min_hum,
  input  logic        crossed_max_hum,
  input  logic        default_hum,
                      
  output logic [31:0] prdata,
  output logic        pready,
                      
  output logic        sda_out,
  output logic        sda_en,
                      
  output logic        dehumidifier_en,
  output logic        humidifier_en
);

  logic count_eq_1s;
  logic hum_counter_en;
  logic hum_counter_clr;
  logic hum_dec_en;
  logic hum_inc_en;

  hum_ctl_fsm u_hum_ctl_fsm (
    .pclk            ( pclk            ),
    .presetn         ( presetn         ),
    .inc_hum_pb      ( inc_hum_pb      ),
    .dec_hum_pb      ( dec_hum_pb      ),
    .crossed_min_hum ( crossed_min_hum ),
    .crossed_max_hum ( crossed_max_hum ),
    .default_hum     ( default_hum     ),
    .count_eq_1s     ( count_eq_1s     ),
    
    .hum_inc_en      ( hum_inc_en      ),
    .hum_dec_en      ( hum_dec_en      ),
    .dehumidifier_en ( dehumidifier_en ),
    .humidifier_en   ( humidifier_en   ),
    .hum_counter_clr ( hum_counter_clr ),
    .hum_counter_en  ( hum_counter_en  )
  );

  logic [7:0] real_time_hum;

  hum_storage u_hum_storage(
    .pclk          ( pclk          ),
    .presetn       ( presetn       ),
    .real_time_hum ( real_time_hum ),
    .pwrite        ( pwrite        ),
    .penable       ( penable       ),
    .psel          ( psel          ),
    .paddr         ( paddr         ),
    .pwdata        ( pwdata        ),
    .sda_in        ( sda_in        ),
    .scl_in        ( scl_in        ),
    .intpt         ( intpt         ),
    
    .pready        ( pready        ),
    .prdata        ( prdata        ),
    .sda_out       ( sda_out       ),
    .sda_en        ( sda_en        )
  );

  hum_measure u_hum_measure (
    .pclk          ( pclk          ),
    .presetn       ( presetn       ),
    .hum_inc_en    ( hum_inc_en    ),
    .hum_dec_en    ( hum_dec_en    ),
    
    .real_time_hum ( real_time_hum )
  );

  hum_timer_counter u_timer_counter_hum (
    .pclk            ( pclk            ),
    .presetn         ( presetn         ),
    .hum_counter_en  ( hum_counter_en  ),
    .hum_counter_clr ( hum_counter_clr ),
    
    .count_eq_1s     ( count_eq_1s     )
  );

endmodule