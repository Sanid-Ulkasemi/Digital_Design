(* keep_hierarchy = "true" *)module apb_fsm (
  input logic       pclk,
  input logic       presetn,
  input logic       psel,
  input logic       penable,
  input logic       pwrite,
  
  output logic      pready,
  output logic      wr_en,
  output logic      rd_en
);


  
  logic  pstate,nstate;

  parameter  IDLE       = 1'b0,
             READ_WRITE = 1'b1;

//nsl
  always @(*) begin
    casez(pstate)
      IDLE         : begin 
                       nstate = (psel & ~penable) ? READ_WRITE : IDLE;
                     end
      READ_WRITE   : begin 
                       nstate = IDLE;
                     end
     
      default : begin 
                  nstate = 1'bx;
                end
    endcase
  end
  
//ol
  
  assign rw = pstate == READ_WRITE;
  
  assign pready = 1'b1 ;
  assign wr_en  = rw & psel & pwrite & penable;
  assign rd_en  = rw & psel & (~pwrite) & penable;
  
//psr

  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( IDLE )
  )u_psr(  
    .clk     ( pclk     ),
    .reset_b ( presetn ),
    .d       ( nstate  ),
    .q       ( pstate  )
  );

endmodule

