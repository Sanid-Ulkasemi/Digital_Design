module reg_bank (

  input logic        pclk,
  input logic        presetn,
  input logic        wr_en,
  input logic        rd_en,
  input logic [31:0] pwdata,
  input logic [31:0] paddr,
  input logic        transfer,
  input logic        miso_pad_i,
  input logic        sample_en,
  input logic        transfer_en,
  input logic        bsy_clr,
  
  output logic        ie, 
  output logic        lsb,
  output logic        cpol,
  output logic        cpha, 
  output logic        go_bsy,
  output logic [31:0] prdata,
  output logic [15:0] divider,
  output logic [7:0]  trx,
  output logic [2:0]  char_len
  
);
 
  logic [7:0] ctrl;

      
  logic wr_en_trx;
  logic wr_en_ctrl; 
  logic wr_en_divider;
  
  logic [7:0] d_ctrl;
  logic [15:0]d_divider;
 
  assign wr_en_trx      = wr_en & (paddr == 32'h00) & ( ~transfer );
  assign wr_en_ctrl     = wr_en & (paddr == 32'h10) & ( ~transfer );
  assign wr_en_divider  = wr_en & (paddr == 32'h14) & ( ~transfer );
  
  
  assign d_ctrl [7:0]     = wr_en_ctrl ? { pwdata[12], pwdata[11], pwdata[10], pwdata[9], pwdata[8], pwdata[2:0] } :
                            (bsy_clr ? (8'b11110111 & ctrl[7:0]) : ctrl[7:0]);
                            
  assign d_divider [15:0] = wr_en_divider ? pwdata[15:0] : divider;
  
  
  assign ie            = ctrl[7];
  assign lsb           = ctrl[6];
  assign cpol          = ctrl[5];
  assign cpha          = ctrl[4];
  assign go_bsy        = ctrl[3];
  assign char_len[2:0] = ctrl[2:0]; 
  
                              
 
  //------------------------------------CTRL ----------------------------------------
  
  dff #(
    .FLOP_WIDTH ( 8    ),
    .RESET_VALUE( 8'b0 )
  )u_lctl(  
    .clk     ( pclk      ), 
    .reset_b ( presetn   ),
    .d       ( d_ctrl    ),
    .q       ( ctrl      )
  );   
  //---------------------------------------------------------------------------------
  
  //-----------------------------------DIVIDER---------------------------------------
  
   dff #(
    .FLOP_WIDTH ( 16    ),
    .RESET_VALUE( 16'hffff )
  )u_divider(  
    .clk     ( pclk      ),
    .reset_b ( presetn   ),
    .d       ( d_divider ),
    .q       ( divider   )
  );   
  //---------------------------------------------------------------------------------
  
  //-------------------------------------TRX ----------------------------------------
  
  logic       d_miso;
  logic       q_miso;
  
  assign d_miso = sample_en ? miso_pad_i : q_miso;
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_miso(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d_miso       ),
    .q       ( q_miso       )
  );
  
  //logic [7:0] trx; 
  
  //logic [7:0]d;
  
 
  
  logic d0;
  logic d1;
  logic d2;
  logic d3;
  logic d4;
  logic d5;
  logic d6;
  logic d7;
  
  //assign d = {d7,d6,d5,d4,d3,d2,d1,d0};
  
  /*dff #(
    .FLOP_WIDTH ( 8    ),
    .RESET_VALUE( 8'b0 )
  )u_rx0(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d            ),
    .q       ( trx           )
  );   */
  
  
  
  assign d0 = wr_en_trx ? pwdata[0] : (transfer_en ? ( lsb ? ( (char_len == 3'b001) ? q_miso : trx[1]) : q_miso ) : trx[0] );
  
  assign d1 = wr_en_trx ? pwdata[1] : ( transfer_en ? ( lsb ? ( (char_len == 3'b010) ? q_miso : trx[2] ) : ( ( (char_len == 3'b000) | (char_len > 3'b001) ) ? trx[0] : trx[1] ) ) : trx[1]  );
  
  assign d2 = wr_en_trx ? pwdata[2] : ( transfer_en ? ( lsb ? ( (char_len == 3'b011) ? q_miso : trx[3] ) : ( ( (char_len == 3'b000) | (char_len > 3'b010) ) ? trx[1] : trx[2] ) ) : trx[2]  );
  
  assign d3 = wr_en_trx ? pwdata[3] : ( transfer_en ? ( lsb ? ( (char_len == 3'b100) ? q_miso : trx[4] ) : ( ( (char_len == 3'b000) | (char_len > 3'b011) ) ? trx[2] : trx[3] ) ) : trx[3]  );
  
  assign d4 = wr_en_trx ? pwdata[4] : ( transfer_en ? ( lsb ? ( (char_len == 3'b101) ? q_miso : trx[5] ) : ( ( (char_len == 3'b000) | (char_len > 3'b100) ) ? trx[3] : trx[4] ) ) : trx[4]  );
  
  assign d5 = wr_en_trx ? pwdata[5] : ( transfer_en ? ( lsb ? ( (char_len == 3'b110) ? q_miso : trx[6] ) : ( ( (char_len == 3'b000) | (char_len > 3'b101) ) ? trx[4] : trx[5] ) ) : trx[5]  );
  
  assign d6 = wr_en_trx ? pwdata[6] : ( transfer_en ? ( lsb ? ( (char_len == 3'b111) ? q_miso : trx[7] ) : ( ( (char_len == 3'b000) | (char_len > 3'b110) ) ? trx[5] : trx[6] ) ) : trx[6]  );
  
  assign d7 = wr_en_trx ? pwdata[7] : ( transfer_en ? ( lsb ? ( (char_len == 3'b000) ? q_miso : trx[7] ) : trx[6] ) : trx[7] );
  
  //--------------------------------------trx--------------------------------------------------------------------------------------
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_rx0(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d0       ),
    .q       ( trx[0]   )
  );   
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_rx1(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d1       ),
    .q       ( trx[1]   )
  );   
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_rx2(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d2       ),
    .q       ( trx[2]   )
  );   
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_rx3(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d3       ),
    .q       ( trx[3]   )
  );   
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_rx4(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d4       ),
    .q       ( trx[4]   )
  );   
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_rx5(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d5       ),
    .q       ( trx[5]   )
  );   
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_rx6(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d6       ),
    .q       ( trx[6]   )
  );   
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_rx7(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d7       ),
    .q       ( trx[7]   )
  );   
  //-----------------------------------------------------------------------
  
  //---------------------------------------------------------------------------------
  
  //----------------------------------Read-------------------------------------------
  
  always @(*) begin
    if(rd_en) begin
      casez(paddr) 
        32'h0    : prdata = {24'b0, trx[7:0]};
        32'h10   : prdata = {19'b0, ctrl[7], ctrl[6], ctrl[5], ctrl[4], ctrl[3], 5'b0, ctrl[2:0]};
        32'h14   : prdata = {16'b0, divider[15:0]};
        default  : prdata = 32'bx;
      endcase
    end
    else begin
      prdata = 8'b00000000;
    end
  end
  

endmodule