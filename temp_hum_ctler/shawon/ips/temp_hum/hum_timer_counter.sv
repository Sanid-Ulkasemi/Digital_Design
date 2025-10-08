module hum_timer_counter (
  input  logic pclk,
  input  logic presetn,
  input  logic hum_counter_en,
  input  logic hum_counter_clr,

  output logic count_eq_1s
);

  logic [26:0] sec_count;

  counter_en #(
    .COUNTER_WIDTH(27)
  ) timer_counter(
    .clk           ( pclk            ),
    .reset_b       ( presetn         ),
    .counter_clear ( hum_counter_clr ),
    .en            ( hum_counter_en  ),
    .count         ( sec_count       )
  );

  assign count_eq_1s = (sec_count == 27'd99999999);

endmodule