(* keep_hierarchy = "true" *)module spi_sub_top (

  input logic pclk,
  input logic presetn,
  input logic psel ,
  input logic penable ,
  input logic pwrite ,
  input logic [31:0]pwdata ,
  input logic [31:0]paddr ,
  input logic ss_pad_i,
  input logic simo_pad_i,
  input logic sclk_in,
  input logic pb_temp_inc,
  input logic pb_temp_dec,

                     
  output logic somi_pad_o,
  output logic fan_led,
  output logic heater_led,
  output logic [31:0]prdata,
  output logic pready
  
);


  // SPI FSM

  logic sample_edge;
  logic transmit_edge;
  logic transfer_finish;
  logic sclk_edge;
  logic se;
  
  logic slave_receive_shift_en;
  logic slave_transfer_shift_en;
  logic counter_clear;
  logic counter_en;


  logic tx_load;
  logic rx_load;

  spi_sub_fsm u_spi_sub_fsm (
    .pclk                    ( pclk                    ),
    .presetn                 ( presetn                 ),
    .ss_pad_i                ( ss_pad_i                ),
    .sample_edge             ( sample_edge             ),
    .transmit_edge           ( transmit_edge           ),
    .transfer_finish         ( transfer_finish         ),
    .sclk_edge               ( sclk_edge               ),
    .se                      ( se                      ),
    
    .slave_receive_shift_en  ( slave_receive_shift_en  ),
    .slave_transfer_shift_en ( slave_transfer_shift_en ),
    .tx_load                 ( tx_load                 ),
    .rx_load                 ( rx_load                 ),
    .counter_clear           ( counter_clear           ),
    .counter_en              ( counter_en              )
  );
  
  // SHIFT REGISTER

  logic [7:0] sub_tx;
  logic [7:0] sub_rx;

  sub_shift_reg_block u_sub_shift_reg_block (
    .pclk                    ( pclk                    ),
    .presetn                 ( presetn                 ),
    .slave_transfer_shift_en ( slave_transfer_shift_en ),
    .sub_tx                  ( sub_tx                  ),
    .slave_receive_shift_en  ( slave_receive_shift_en  ),
    .simo_pad_i              ( simo_pad_i              ),
    .tx_load                 ( tx_load                 ),
    
    .sub_rx                  ( sub_rx                  ),
    .somi_pad_o              ( somi_pad_o              )
  );


  // CLOCK EDGE DETECTOR
  logic cpol;
  logic cpha;

  clk_receiver u_clk_receiver (
    .pclk            ( pclk            ),
    .presetn         ( presetn         ),
    .sclk_in         ( sclk_in         ),
    .cpol            ( cpol            ),
    .cpha            ( cpha            ),
    .counter_en      ( counter_en      ),
    .counter_clear   ( counter_clear   ),
    
    .sample_edge     ( sample_edge     ),
    .sclk_edge       ( sclk_edge       ),
    .transmit_edge   ( transmit_edge   ),
    .transfer_finish ( transfer_finish )
  );


  //APB INTERFACE

  logic [7:0] temp_data;
  logic low_temp;
  logic high_temp;
  logic still_high_temp;
  logic still_low_temp;
  logic [1:0] state;
  logic fan_on;
  logic heater_on;
 
  spi_sub_apb_intf u_intfc(    
  
    .pclk            ( pclk            ),
    .presetn         ( presetn         ),
    .pwrite          ( pwrite          ),
    .psel            ( psel            ),
    .penable         ( penable         ),
    .paddr           ( paddr           ),
    .pwdata          ( pwdata          ),
    .temp_data       ( temp_data       ),
    .sub_rx          ( sub_rx          ),
    .rx_load         ( rx_load         ),
    
    //debug
    .fan_on          ( fan_on          ),
    .heater_on       ( heater_on       ),
    .state           ( state           ),
    //
    
    .pready          ( pready          ),
    .prdata          ( prdata          ),
    .cpha            ( cpha            ),
    .cpol            ( cpol            ),
    .se              ( se              ),
    .high_temp       ( high_temp       ),
    .low_temp        ( low_temp        ),
    .still_high_temp ( still_high_temp ),
    .still_low_temp  ( still_low_temp  ),
    .sub_tx          ( sub_tx          )
    
  );

  

// TEMPERATURE VALUE HANDLER
 
 logic pb_temp_off;
 
 
  temp_handler u_tmphndlr(

    .pclk        ( pclk        ),
    .presetn     ( presetn     ),
    
    .pb_temp_off ( pb_temp_off ),
    
    .temp_inc    ( pb_temp_inc    ),
    .temp_dec    ( pb_temp_dec    ),
    
    .fan_on      ( fan_on      ),
    .heater_on   ( heater_on   ),
    
    .temp_data   ( temp_data   )
    
  );

   // LED BLINKING LOGIC
   blinker u_blinker (
    
    .pclk        ( pclk        ),
    .presetn     ( presetn     ),
    .pb_temp_off ( pb_temp_off ),
    .fan_on      ( fan_on      ),
    .heater_on   ( heater_on   ),
    
    .fan_led     ( fan_led     ),
    .heater_led  ( heater_led  )

   );


 // FSM TO CONTROL FAN AND HEATER0
 temp_fsm u_temp_fsm (

  .pclk            ( pclk            ),
  .presetn         ( presetn         ),
  .high_temp       ( high_temp       ),
  .low_temp        ( low_temp        ),
  .still_high_temp ( still_high_temp ),
  .still_low_temp  ( still_low_temp  ),
  .state(state),
  
  .pb_temp_off     ( pb_temp_off     ),
  .fan_on          ( fan_on          ),
  .heater_on       ( heater_on       )
  
 );
  
endmodule