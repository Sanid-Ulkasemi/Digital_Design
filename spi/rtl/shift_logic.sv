module shift_logic (
  
  input logic leading_edge,
  input logic trailing_edge,
  input logic first_edge,
  //input logic cpha,
  
  output logic transfer_en,
  output logic sample_en

);

  assign sample_en = leading_edge;
  assign transfer_en = trailing_edge | first_edge;
  
  //assign sample_en   = cpha ? trailing_edge : leading_edge ;
  //assign transfer_en = (cpha ? leading_edge : trailing_edge) | first_edge ; 
 
  //assign sample_en   = cpha ? leading_edge : trailing_edge ;
  //assign transfer_en = (cpha ? trailing_edge : leading_edge) | first_edge ; 

endmodule