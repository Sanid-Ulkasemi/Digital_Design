`timescale 1ns/1ps

(* keep_hierarchy = "true" *) module wdt_top_pl(
  input wire         pclk,
  input wire         presetn,
  input wire         psel,
  input wire         pwrite,
  input wire         penable,
  input wire[31:0]   paddr,
  input wire[31:0]   pwdata,
  
  output wire[31:0]  prdata,
  output wire        pready,
  output wire        wdt_res,
  output wire        wdt_interrupt,
  output wire        pslverr
);
  
  assign pslverr = 1'b0;
  
  wdt_top u_wdt_top (
    .pclk          ( pclk          ),
    .presetn       ( presetn       ),
    .psel          ( psel          ),
    .pwrite        ( pwrite        ),
    .penable       ( penable       ),
    .paddr         ( paddr         ),
    .pwdata        ( pwdata        ),
    
    .prdata        ( prdata        ),
    .pready        ( pready        ),
    .wdt_reset     ( wdt_res       ),
    .wdt_interrupt ( wdt_interrupt )
  );
    
endmodule