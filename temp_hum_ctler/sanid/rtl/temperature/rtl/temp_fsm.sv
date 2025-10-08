(* keep_hierarchy = "true" *)module temp_fsm (

    input logic pclk,
    input logic presetn,
    input logic high_temp,
    input logic low_temp,
    input logic still_high_temp,
    input logic still_low_temp,

    output logic pb_temp_off,
    output logic fan_on,
    output logic heater_on,
    
    output logic [1:0] state

);

  parameter IDLE     = 2'b00,
            HOT      = 2'b01,
            COLD     = 2'b11;
           
  logic [1:0] pstate, nstate;

  //Present state register PSR
  dff #(
    .RESET_VALUE( IDLE    ),
    .FLOP_WIDTH ( 2       )
  )u_psr(
    .clk        ( pclk    ),
    .reset_b    ( presetn ),
    .d          ( nstate  ),
    .q          ( pstate  )
  );
  
 always@(*) begin : NSL
  
    casez(pstate)
    
      IDLE : begin
        nstate = high_temp ? HOT : ( low_temp ? COLD : IDLE );
      end
      
      HOT  : begin
        nstate = still_high_temp ? HOT : IDLE;
      end

      COLD : begin
        nstate = still_low_temp ? COLD : IDLE;
      end
      
      default : begin
        nstate = 2'bx;
      end   
         
    endcase
  end

  assign pb_temp_off = (pstate == HOT)  | (pstate == COLD) ; 
  assign fan_on      = (pstate == HOT)  ;
  assign heater_on   = (pstate == COLD) ;
  
  //debug
  assign state = pstate;

endmodule