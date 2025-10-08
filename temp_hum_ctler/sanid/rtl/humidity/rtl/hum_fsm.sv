(* keep_hierarchy = "true" *)module hum_fsm (
    input logic pclk,
    input logic presetn,
    input logic high_hum,
    input logic low_hum,
    input logic still_high_hum,
    input logic still_low_hum,
    input logic hcnt_eq_1s,
    input logic hcnt_eq_3s,

    output logic hum_led,
    output logic dehum_led,
    output logic hcnt_en,
    output logic hcnt_clr,
    output logic pb_hum_off,
    output logic hum_on,
    output logic dehum_on

);

  parameter IDLE     = 3'b000,
            HLED_ON  = 3'b001,
            HLED_OFF = 3'b011,
            DLED_OFF = 3'b010,
            DLED_ON  = 3'b110;
          
  logic [2:0] pstate, nstate;

  
  //Present state register PSR
  dff #(
    .RESET_VALUE( IDLE    ),
    .FLOP_WIDTH ( 3       )
  )u_psr(
    .clk        ( pclk    ),
    .reset_b    ( presetn ),
    .d          ( nstate  ),
    .q          ( pstate  )
  );
  

  always@(*) begin : NSL
    casez(pstate)
    
      IDLE : begin
        nstate = low_hum ? HLED_OFF : ( high_hum ? DLED_ON : IDLE );
      end
      
      HLED_ON : begin
        nstate = still_low_hum ?  ( hcnt_eq_1s ? HLED_OFF : HLED_ON ) : IDLE ;
      end

      HLED_OFF : begin
        nstate = still_low_hum ?  ( hcnt_eq_3s ? HLED_ON : HLED_OFF ) : IDLE ;
      end

      DLED_OFF : begin
        nstate = still_high_hum ? ( hcnt_eq_1s ? DLED_ON : DLED_OFF ) : IDLE ;
      end

      DLED_ON : begin
        nstate = still_high_hum ?  ( hcnt_eq_3s ? DLED_OFF : DLED_ON ) : IDLE ;
      end
      
      default : begin
        nstate = 3'bx;
      end
      
    endcase
  end
  
  assign hum_led    = (pstate == HLED_ON);
  assign dehum_led  = (pstate == DLED_ON);
  assign hcnt_en    = (pstate == HLED_ON)  | (pstate == DLED_ON) | (pstate == HLED_OFF) | (pstate == DLED_OFF) ;
  assign hcnt_clr   = ( (pstate == HLED_ON) & (hcnt_eq_1s | ~still_low_hum) ) | ( (pstate == HLED_OFF) & (hcnt_eq_3s | ~still_low_hum) ) | ( (pstate == DLED_ON) & (hcnt_eq_3s | ~still_high_hum) ) | ( (pstate == DLED_OFF) & (hcnt_eq_1s | ~still_high_hum) ) ; 
  assign pb_hum_off = (pstate == HLED_ON)  | (pstate == DLED_ON) | (pstate == HLED_OFF) | (pstate == DLED_OFF) ; 
  assign hum_on     = (pstate == HLED_ON)  | (pstate == HLED_OFF) ;
  assign dehum_on   = (pstate == DLED_ON)  | (pstate == DLED_OFF) ;
  

    
endmodule