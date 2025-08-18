module bit_cnt (
  
  input logic [2:0] char_len,
  input logic [4:0] edge_cnt,
  input logic       cpol,
  input logic       cpha,
  input logic       en_tgl,
  
  output logic      bit_eq_n

);

  logic [4:0] bit_transferred;
  
  
  assign bit_transferred  =  ( char_len == 3'b000 )  ?  {1'b1,char_len,1'b0}  :  {1'b0,char_len,1'b0};
  
  //assign bit_eq_n =  (edge_cnt == bit_transferred) ;
  assign bit_eq_n =  (edge_cnt == bit_transferred-1 ) & en_tgl ;
  //assign bit_eq_n =  (cpol == cpha) ? (edge_cnt == bit_transferred-1 ) & en_tgl  : (edge_cnt == bit_transferred) & en_tgl ;
  
  //assign bit_eq_n =  (cpol ~^ cpha) ? ((edge_cnt == bit_transferred-1) & en_tgl) : (edge_cnt == bit_transferred) & en_tgl ;

endmodule