module comparator(

  input logic [15:0] count,
  input logic [15:0] divider,
  input logic        transfer,
  
  output logic en_tgl

);

  assign en_tgl = (count == divider) & transfer;

endmodule