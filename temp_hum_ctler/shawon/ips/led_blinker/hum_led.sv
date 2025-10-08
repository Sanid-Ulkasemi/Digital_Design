module hum_led (
  input  logic  pclk,
  input  logic  presetn,
  input  logic  dehumidifier_en,
  input  logic  humidifier_en,
                
  output logic  led_humidifier,
  output logic  led_dehumidifier
);

  // Define constants for time counts based on a 100MHz clock
  localparam SEC_1_COUNT = 100_000_000;
  localparam SEC_3_COUNT = 300_000_000;
  localparam SEC_4_COUNT = 400_000_000;

  logic [28:0] temp_count;
  logic        count_en;
  logic        counter_clear;

  logic        count_eq_4;

   assign count_en      = (dehumidifier_en | humidifier_en);
   assign counter_clear = (~ (dehumidifier_en | humidifier_en)) | count_eq_4;

  counter_en #( 
   .COUNTER_WIDTH (29)
) u_hum_counter (
  .clk           ( pclk          ),
  .reset_b       ( presetn       ),
  .counter_clear ( counter_clear ),
  .en            ( count_en      ),
  .count         ( temp_count    )
  );

  assign count_eq_4 = (temp_count == SEC_4_COUNT - 1);

  assign led_dehumidifier = dehumidifier_en & (temp_count < SEC_3_COUNT);
  assign led_humidifier   = humidifier_en & (temp_count >= SEC_3_COUNT);

endmodule 