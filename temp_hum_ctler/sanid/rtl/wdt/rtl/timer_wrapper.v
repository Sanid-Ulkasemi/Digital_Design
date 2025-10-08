module timer_wrapper (
  
  input wire         pclk,
  input wire         presetn,
  input wire         psel,
  input wire         penable,
  input wire         pwrite,
  input wire  [31:0] paddr,
  input wire  [31:0] pwdata,
  
  output wire        pready,
  output wire        interrupt_o,
  output wire [31:0] prdata,
   output wire pslverr

);

 assign plsverr = 1'b0;
wtd_top wdt (

  .pclk        ( pclk        ),
  .presetn     ( presetn     ),
  .psel        ( psel        ),
  .penable     ( penable     ),
  .pwrite      ( pwrite      ),
  .paddr       ( paddr       ),
  .pwdata      ( pwdata      ),
  
  .pready      ( pready      ),
  .interrupt_o ( interrupt_o ),
  .wdt_reset   (    ),
  .prdata      ( prdata      )
  
);


endmodule