module edge_detectors(
  
    input logic pclk,
    input logic presetn,
    input logic transfer,
    input logic en_tgl,
    input logic go_bsy,
    input logic even,
    input logic bsy_clr,
    
    output logic leading_edge,
    output logic trailing_edge,
    output logic first_edge 
    
);

  assign leading_edge  = even & en_tgl;
  assign trailing_edge = (~even) & en_tgl;
  assign first_edge    = (~bsy_clr) & go_bsy & (~transfer); ///

endmodule    