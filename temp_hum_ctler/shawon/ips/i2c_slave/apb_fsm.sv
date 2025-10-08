module apb_fsm(
  input logic   pclk,
  input logic   presetn,
  input logic   psel,
  input logic   penable,
  input logic   pwrite,
  
  output logic  rd_en,
  output logic  wr_en,
  output logic  pready
);

  parameter IDLE    = 1'b0,
            ACCESS  = 1'b1;
            
  logic pstate, nstate;
  
  //Present state register PSR
  dff #(
//    .RESET_VALUE( 1'b0    ),
    .DFF_WIDTH ( 1       )
  )u_psr(
    .clk        ( pclk    ),
    .reset_b    ( presetn ),
    .d          ( nstate  ),
    .q          ( pstate  )
  );
  
  
  
  always@(*) begin : NSL
    casez(pstate)
    
      IDLE : begin
        nstate = psel ? ACCESS : IDLE;
      end
      
      ACCESS : begin
        nstate = IDLE;
      end
      
      default : begin
        nstate = 1'bx;
      end
      
    endcase
  end
  
  //reading and writing when chip is selected and enabled 
  assign rd_en  = ( pstate == ACCESS ) & ~pwrite  & penable & psel;
  assign wr_en  = ( pstate == ACCESS ) & pwrite   & penable & psel;
  assign pready = 1'b1;

endmodule