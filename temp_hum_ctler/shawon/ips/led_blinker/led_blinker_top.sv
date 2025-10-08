module led_blinker_top (
  input  logic   pclk,
  input  logic   presetn,
  input  logic   dehumidifier_en,
  input  logic   humidifier_en,
  input  logic   fan_en,
  input  logic   heater_en,
                 
  output logic   led_humidifier,
  output logic   led_dehumidifier,
  output logic   led_fan,
  output logic   led_heater
);

  hum_led u_hum (
    .pclk             ( pclk             ),
    .presetn          ( presetn          ),
    .dehumidifier_en  ( dehumidifier_en  ),
    .humidifier_en    ( humidifier_en    ),
    
    .led_humidifier   ( led_humidifier   ),
    .led_dehumidifier ( led_dehumidifier )
  );

  temp_led u_temp (
    .pclk       ( pclk       ),
    .presetn    ( presetn    ),
    .fan_en     ( fan_en     ),
    .heater_en  ( heater_en  ),
    
    .led_fan    ( led_fan    ),
    .led_heater ( led_heater )
  );

endmodule