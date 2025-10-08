module wtd_top (
  
  input logic         pclk,
  input logic         presetn,
  input logic         psel,
  input logic         penable,
  input logic         pwrite,
  input logic  [31:0] paddr,
  input logic  [31:0] pwdata,
  
  output logic        pready,
  output logic        interrupt_o,
  output logic        wdt_reset,
  output logic [31:0] prdata
  
);

  //--------------------------internal signals-----------------
  logic wr_en;
  logic rd_en;
  logic inten;
  logic stall;
  logic resen;
  logic int_clr;
  logic test_en;
  logic count_en;
  logic load_en;
  logic [31:0] wdtvalue;
  logic cnt_eq_0;
  logic cause_reset;
  logic interrupt;
  logic rst;

  //------------------APB-------------------------------
  
  apb_fsm u_apb (
    .pclk    ( pclk    ),
    .presetn ( presetn ),
    .psel    ( psel    ),
    .penable ( penable ),
    .pwrite  ( pwrite  ),
    
    .pready  ( pready  ),
    .wr_en   ( wr_en   ),
    .rd_en   ( rd_en   )  
  );
  
  //--------------------------------------------- 
  
  //------------WDT FSM--------------------
  
  wdt_fsm u_fsm (
    
    .pclk        ( pclk        ),
    .presetn     ( presetn     ),
    .inten       ( inten       ),
    .int_clr     ( int_clr     ),
    .resen       ( resen       ),
    .stall       ( stall       ),
    .test_en     ( test_en     ),
    .cnt_eq_0    ( cnt_eq_0    ),
    
    .interrupt   ( interrupt   ),
    .wdt_reset   ( wdt_reset   ),
    .cause_rst   ( cause_reset ),
    .count_en    ( count_en    ),
    .load_en     ( load_en     )
    
  );
  
  //------------------------------------------
  
  //----------------Comparator------------------
  
  comparator u_comp (
    
    .value    ( wdtvalue    ),
    
    .cnt_eq_0 ( cnt_eq_0 )
  
  );
  //----------------------------------------------- 
  
  //-------------------Register bank----------------
  reg_bank u_reg (
  
    .pclk      ( pclk        ),
    .presetn   ( presetn     ),
    .wr_en     ( wr_en       ),
    .rd_en     ( rd_en       ),
    .pwdata    ( pwdata      ),
    .paddr     ( paddr       ),
    .count_en  ( count_en    ),
    .load_en   ( load_en     ),
    .interrupt ( interrupt   ),
    .cause_rst ( cause_reset ),
    
    .inten     ( inten       ),
    .resen     ( resen       ),
    .stall     ( stall       ),
    .test_en   ( test_en     ),
    .int_clr   ( int_clr     ),
    .prdata    ( prdata      ),
    .wdtvalue  ( wdtvalue    ),
    .interrupt_o   ( interrupt_o )
    
  );  
  //-----------------------------------------------------------
  
endmodule