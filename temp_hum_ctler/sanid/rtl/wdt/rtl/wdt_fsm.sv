(* keep_hierarchy = "true" *)module wdt_fsm (
  
  input logic pclk,
  input logic presetn,
  input logic inten,
  input logic int_clr,
  input logic resen,
  input logic stall,
  input logic test_en,
  input logic cnt_eq_0,
  
  output logic interrupt,
  output logic wdt_reset,
  output logic cause_rst,
  output logic count_en,
  output logic load_en

);

  logic rst_flag;
  logic d_rst_flag;
  logic  [1:0] pstate,nstate;

  parameter    IDLE      = 2'b00,
               COUNTING = 2'b01,
               INTERRUPT = 2'b10,
               RESET     = 2'b11;
                                       
//nsl
  always @(*) begin
    casez(pstate)
    
      IDLE          : begin 
                        nstate = inten ? COUNTING : IDLE ;
                      end
                         
      COUNTING      : begin 
                         nstate = cnt_eq_0 ? INTERRUPT : COUNTING ;
                      end 
      
      INTERRUPT     : begin 
                          nstate = int_clr ? COUNTING : ( cnt_eq_0 ? (test_en ? INTERRUPT : ( resen ? RESET : INTERRUPT )) : INTERRUPT ) ;
                      end     
     
      RESET         : begin 
                         nstate = INTERRUPT ;
                      end                         
      
      default       : begin 
                        nstate = 2'bx;
                      end
    endcase
  end
  
//ol
  
  assign idle = (pstate == IDLE); 
  assign cnt  = (pstate == COUNTING);
  assign intr = (pstate == INTERRUPT);
  assign rs   = (pstate == RESET); 
  
  assign interrupt   = intr | rs ;
  assign wdt_reset   = rs | (intr & rst_flag);  // If reset needs to be a signal that holds its value until system asserts restart then i need to uncomment the segment.
  //assign wdt_reset   = (rs & (~test_en)); // | (intr & rst_flag);  // If reset needs to be a signal that holds its value until system asserts restart then i need to uncomment the segment.
  assign cause_rst   = intr & cnt_eq_0 & test_en;
  assign count_en    = (idle & inten) | (cnt & (~stall)) | (intr & (~stall) & (~cnt_eq_0) );
  assign load_en     =  (cnt & cnt_eq_0) | (intr & (cnt_eq_0 | int_clr)) ;

//psr

  dff #(
    .FLOP_WIDTH ( 2     ),
    .RESET_VALUE( IDLE )
  )u_psr(  
    .clk     ( pclk     ),
    .reset_b ( presetn   ),
    .d       ( nstate  ),
    .q       ( pstate  )
  );
  
// wdt reset

 
  assign d_rst_flag = ( rst_flag | rs ) & (~int_clr);
  
  dff #(
    .FLOP_WIDTH ( 1     ),
    .RESET_VALUE( 1'b0 )
  )u_reset(  
    .clk     ( pclk     ),
    .reset_b ( presetn   ),
    .d       ( d_rst_flag ),
    .q       ( rst_flag  )
  );



endmodule