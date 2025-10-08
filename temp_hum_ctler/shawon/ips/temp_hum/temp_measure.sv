module temp_measure (
  input  logic        pclk,
  input  logic        presetn,
  input  logic        temp_inc_en,
  input  logic        temp_dec_en,

  output logic [7:0] real_time_temp
);

  always@(posedge pclk or negedge presetn)begin
    if (~ presetn) begin
      real_time_temp <= 8'd25;
    end
    else begin
      real_time_temp <= (temp_inc_en & temp_dec_en) ? real_time_temp : (temp_inc_en ? (real_time_temp + 1'b1) : (temp_dec_en ? (real_time_temp - 1'b1) : real_time_temp));
    end
  end

endmodule