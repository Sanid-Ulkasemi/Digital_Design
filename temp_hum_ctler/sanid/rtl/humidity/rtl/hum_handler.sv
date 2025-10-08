(* keep_hierarchy = "true" *)module hum_handler(

    input logic pclk,
    input logic presetn,
    input logic pb_hum_off,
    input logic hum_inc,
    input logic hum_dec,
    input logic hum_on,
    input logic dehum_on,

    output logic [7:0] hum_data

);

   logic [27:0] cnt;
   logic cnt_eq_1s;
   
   counter #(
    .RESET_VALUE   ( 28'b0  ),
    .COUNTER_WIDTH ( 28     )
   ) u_hcnt (
    .clk     ( pclk        ),
    .reset_b ( presetn     ),
    .clear   ( cnt_eq_1s   ),
    .en      ( pb_hum_off  ), 
    .count   ( cnt         )
  ); 

  assign cnt_eq_1s = cnt[27:0] == 28'd99999999; // original 1s
//  assign cnt_eq_1s = cnt[27:0] == 28'd9; // for testing in simulation
  logic incr;
  posedge_detector u_pb_inc(
    .clk(pclk),
    .reset(presetn),
    .in(hum_inc),
    .pos_edge(incr)
  );
  logic decr;
  posedge_detector u_pb_dec(
    .clk(pclk),
    .reset(presetn),
    .in(hum_dec),
    .pos_edge(decr)
  );
  

  logic [7:0] d_hum_data;
  assign d_hum_data[7:0] = pb_hum_off ? ( cnt_eq_1s ?  (hum_data[7:0] + {7'b0,hum_on} - {7'b0,dehum_on} ) : hum_data[7:0] ) : (hum_data[7:0] + {7'b0,incr} - {7'b0,decr} );
  dff #(
    .RESET_VALUE( 8'd50   ),
    .FLOP_WIDTH ( 8       )
  )u_psr(
    .clk        ( pclk       ),
    .reset_b    ( presetn    ),
    .d          ( d_hum_data ),
    .q          ( hum_data   )
  );


  
endmodule



