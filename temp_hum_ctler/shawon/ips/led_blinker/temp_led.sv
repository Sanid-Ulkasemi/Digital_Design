module temp_led (
  input  logic pclk,
  input  logic presetn,
  input  logic fan_en,
  input  logic heater_en,
         
  output logic led_fan,
  output logic led_heater
);

  localparam FAN_HALF_PERIOD_COUNT    = 10_000_000;
  localparam HEATER_HALF_PERIOD_COUNT = 50_000_000;
  localparam FAN_FULL_PERIOD_COUNT    = 20_000_000;
  localparam HEATER_FULL_PERIOD_COUNT = 100_000_000;

  logic        counter_clear;
  logic        counter_en;
  logic [26:0] temp_count;

  assign counter_en = fan_en | heater_en;
  
  assign counter_clear = ~counter_en | 
                         (fan_en & (temp_count == FAN_FULL_PERIOD_COUNT - 1)) | 
                         (heater_en & (temp_count == HEATER_FULL_PERIOD_COUNT - 1));

  counter_en #( 
    .COUNTER_WIDTH (27)
  ) u_temp_counter (
    .clk           ( pclk          ),
    .reset_b       ( presetn       ),
    .counter_clear ( counter_clear ),
    .en            ( counter_en    ),
    .count         ( temp_count    )
  );

  assign led_fan = fan_en & (temp_count < FAN_HALF_PERIOD_COUNT);
  
  assign led_heater = heater_en & (temp_count < HEATER_HALF_PERIOD_COUNT);

endmodule