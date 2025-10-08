(* keep_hierarchy = "true" *)module hcounter_comp (

    input logic pclk,
    input logic presetn,
    input logic hcnt_en,
    input logic hcnt_clr,

    output logic hcnt_eq_1s,
    output logic hcnt_eq_3s

);

    
   logic [28:0] hcnt;

   counter #(
    .RESET_VALUE   ( 29'b0  ),
    .COUNTER_WIDTH ( 29     )
   ) u_hcnt (
    .clk     ( pclk        ),
    .reset_b ( presetn     ),
    .clear   ( hcnt_clr    ),
    .en      ( hcnt_en     ), 
    .count   ( hcnt        )
  ); 

  assign hcnt_eq_1s = hcnt[28:0] == 29'd99999999 ;  // original 3s
  assign hcnt_eq_3s = hcnt[28:0] == 29'd299999999;  // original 1s

//  assign hcnt_eq_1s = hcnt[28:0] == 29'd5 ;  // testing 1 cycle
//  assign hcnt_eq_3s = hcnt[28:0] == 29'd15;  // testing 3 cycle

endmodule