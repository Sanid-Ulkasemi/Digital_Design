module hum_measure (
  input  logic        pclk,
  input  logic        presetn,
  input  logic        hum_inc_en,
  input  logic        hum_dec_en,

  output logic [7:0] real_time_hum
);

  always @( posedge pclk or negedge presetn )begin
    if (~ presetn) begin
      real_time_hum <= 8'd50;
    end
    else begin
      real_time_hum <= (hum_inc_en & hum_dec_en) ? real_time_hum : (hum_inc_en ? (real_time_hum + 1'b1) : (hum_dec_en ? (real_time_hum - 1'b1) : real_time_hum));
    end
  end

endmodule