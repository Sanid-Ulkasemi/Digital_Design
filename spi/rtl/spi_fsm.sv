module spi_fsm (
  
  input logic pclk,
  input logic presetn,
  input logic go_bsy,
  input logic en_tgl,
  input logic wr_en,
  input logic rd_en,
  input logic bit_eq_n,
  input logic ie,
  
  output logic transfer,
  output logic interrupt_pad_o,
  output logic bsy_clr,
  output logic clear_cnt

);

  logic  [1:0] pstate,nstate;

  parameter  IDLE       = 2'b00,
             TRANSFER   = 2'b01,
             FINISHED   = 2'b11;

  //-----------------------------------------nsl--------------------------------------------------
  always @(*) begin
    casez(pstate)
      IDLE         : begin 
                       nstate = go_bsy ? TRANSFER : IDLE;
                     end
                     
      TRANSFER     : begin 
                       nstate = bit_eq_n ? FINISHED : TRANSFER;
                     end
                     
      FINISHED     : begin 
                       nstate = (wr_en | rd_en) ? IDLE : FINISHED;
                     end
     
      default : begin 
                  nstate = 2'bx;
                end
    endcase
  end
  
  //------------------------------------------ol------------------------------------------------
  
  assign idle   = pstate == IDLE;
  assign trnsfr = pstate == TRANSFER;
  assign fns    = pstate == FINISHED;
  
  assign transfer = trnsfr;
  assign interrupt_pad_o = fns & ie;
  assign bsy_clr = fns;
  assign clear_cnt = idle | ( trnsfr & en_tgl ) | fns;
  
    
  //-------------------------------------------psr-------------------------------------------------

  dff #(
    .FLOP_WIDTH ( 2    ),
    .RESET_VALUE( IDLE )
  )u_psr(  
    .clk     ( pclk     ),
    .reset_b ( presetn ),
    .d       ( nstate  ),
    .q       ( pstate  )
  );
  //---------------------------------------------------------------------------------------------
endmodule

