module led_blinker_top_vw (
  input wire pclk,
  input wire presetn,
  input wire dehumidifier_en,
  input wire humidifier_en,
  input wire fan_en,
  input wire heater_en,

  output wire led_humidifier,
  output wire led_dehumidifier,
  output wire led_fan,
  output wire led_heater
);

  led_blinker_top u_led_blinker_top (
    .pclk             ( pclk             ),
    .presetn          ( presetn          ),
    .dehumidifier_en  ( dehumidifier_en  ),
    .humidifier_en    ( humidifier_en    ),
    .fan_en           ( fan_en           ),
    .heater_en        ( heater_en        ),
    
    .led_humidifier   ( led_humidifier   ),
    .led_dehumidifier ( led_dehumidifier ),
    .led_fan          ( led_fan          ),
    .led_heater       ( led_heater       )
  );

endmodule