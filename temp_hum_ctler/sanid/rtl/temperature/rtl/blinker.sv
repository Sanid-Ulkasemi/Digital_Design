(* keep_hierarchy = "true" *)module blinker (

    input logic pclk,
    input logic presetn,
    input logic pb_temp_off,
    input logic fan_on,
    input logic heater_on,

    output logic fan_led,
    output logic heater_led


);
   
   logic blink_cnt_eq_slow;
   logic blink_cnt_eq_fast;
   logic [27:0] blink_cnt;
   logic cnt_clr;
   assign cnt_clr = (heater_on & blink_cnt_eq_slow) | (fan_on & blink_cnt_eq_fast);
  
   counter #(
    .RESET_VALUE   ( 28'b0  ),
    .COUNTER_WIDTH ( 28     )
   ) u_blinkcnt (
    .clk     ( pclk        ),
    .reset_b ( presetn     ),
    .clear   ( cnt_clr      ),
    .en      ( pb_temp_off  ), 
    .count   ( blink_cnt    )
  ); 

  assign blink_cnt_eq_slow = blink_cnt == 28'd49999999; // Actual 1s period
  assign blink_cnt_eq_fast = blink_cnt == 28'd19999999; // actual 0.4s period
//  assign blink_cnt_eq_slow = blink_cnt == 28'd9; // for simulation
//  assign blink_cnt_eq_fast = blink_cnt == 28'd4; // forsimulation
  
  // LED Logic of the FAN
  logic d_fan_led;
  assign d_fan_led = fan_on ? fan_led ^ ( blink_cnt_eq_fast ) : 1'b0;
  
    dff #(
    .RESET_VALUE( 1'b0   ),
    .FLOP_WIDTH ( 1      )
  )u_fan_led(
    .clk        ( pclk      ),
    .reset_b    ( presetn   ),
    .d          ( d_fan_led ),
    .q          ( fan_led   )
  );
  
  
  // LED Logic of the HEATER
  logic d_heater_led;
  assign d_heater_led = heater_on ? (heater_led ^  blink_cnt_eq_slow ) : 1'b0; 
  
  dff #(
    .RESET_VALUE( 1'b0   ),
    .FLOP_WIDTH ( 1      )
  )u_heater_led(
    .clk        ( pclk         ),
    .reset_b    ( presetn      ),
    .d          ( d_heater_led ),
    .q          ( heater_led   )
  );
  
endmodule