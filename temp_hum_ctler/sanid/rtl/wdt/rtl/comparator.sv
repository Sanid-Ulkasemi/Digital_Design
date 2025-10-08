module comparator (
  
  input logic [31:0] value,
  
  output logic cnt_eq_0

);

  assign cnt_eq_0 = (value == 32'b0); 

endmodule