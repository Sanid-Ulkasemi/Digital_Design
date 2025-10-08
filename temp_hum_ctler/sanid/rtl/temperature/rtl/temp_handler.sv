(* keep_hierarchy = "true" *)module temp_handler(

    input logic pclk,
    input logic presetn,
    
    input logic pb_temp_off,
    
    input logic temp_inc, //push button for temparature increment
    input logic temp_dec, //push button for temparature decrement
    
    input logic fan_on,
    input logic heater_on,

    output logic [7:0] temp_data

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
    .en      ( pb_temp_off  ), 
    .count   ( cnt         )
  ); 

  assign cnt_eq_1s = cnt[27:0] == 28'd99999999; // original 1s
//  assign cnt_eq_1s = cnt[27:0] == 28'd9; // for testing in simulation
  logic incr;
  posedge_detector u_pb_inc(
    .clk(pclk),
    .reset(presetn),
    .in(temp_inc),
    .pos_edge(incr)
  );
  logic decr;
  posedge_detector u_pb_dec(
    .clk(pclk),
    .reset(presetn),
    .in(temp_dec),
    .pos_edge(decr)
  );
  

  logic [7:0] d_temp_data;
  assign d_temp_data[7:0] = pb_temp_off ? ( cnt_eq_1s ?  (temp_data[7:0] + {7'b0,heater_on} - {7'b0,fan_on} ) : temp_data[7:0] ) : (temp_data[7:0] + {7'b0,incr} - {7'b0,decr} );
  dff #(
    .RESET_VALUE( 8'd25   ),
    .FLOP_WIDTH ( 8       )
  )u_psr(
    .clk        ( pclk       ),
    .reset_b    ( presetn    ),
    .d          ( d_temp_data ),
    .q          ( temp_data   )
  );


  
endmodule



