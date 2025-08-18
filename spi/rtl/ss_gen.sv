module ss_gen (
  
  input logic go_bsy,
  
  output logic ss_pad_o

);

  assign ss_pad_o = ~go_bsy;

endmodule