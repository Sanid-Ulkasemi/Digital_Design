
(* keep_hierarchy = "true" *)
module spi_top(
  input logic pclk,
  input logic presetn,
  input logic penable,
  input logic psel,
  input logic pwrite,
  input logic miso_pad_i,
  input logic simo_pad_i,
  input logic ss_pad_i,
  input logic sclk_pad_i,
  input logic[31:0] paddr,
  input logic[31:0] pwdata,
  
  output logic pready,
  output logic sclk_pad_o,
  output logic mosi_pad_o,
  output logic somi_pad_o,
  output logic interrupt_pad_o,
  output logic ss_pad_o,
  output logic[31:0] prdata
  
);

 //debug code
 logic[7:0] ss_cnt1;
 logic[7:0] ss_cnt2;
 logic[15:0] sclk_cnt;
 logic[31:0] rd_data;
 
 
 logic ss_del;
 logic sclk_del;
 dff #(
    .FLOP_WIDTH(1),
    .RESET_VALUE(1'b0)
  )u_dff1(
    .clk     ( pclk    ),
    .reset_b ( presetn ),
    .q       ( ss_del  ),
    .d       ( ss_pad_i  )
  );
  
  dff #(
    .FLOP_WIDTH(1),
    .RESET_VALUE(1'b0)
  )u_dff2(
    .clk     ( pclk    ),
    .reset_b ( presetn ),
    .q       ( sclk_del  ),
    .d       ( sclk_pad_i  )
  );
  

 always@(posedge pclk or negedge presetn)begin
    if(~presetn)begin
        ss_cnt1   <= 8'b0;
        ss_cnt2   <= 8'b0;
        sclk_cnt  <= 16'b0;
    end
    else begin
        ss_cnt1   <= ss_cnt1 + (ss_pad_i & ~ss_del);
        ss_cnt2   <= ss_cnt2 + (~ss_pad_i & ss_del);
        sclk_cnt  <= sclk_cnt + (sclk_pad_i ^ sclk_del);
    end   
 end
    
 logic[31:0] temp_rd;
 always@(*)begin
    casez(paddr[7:0])
        8'h30 : temp_rd = {24'b0, ss_cnt1};
        8'h34 : temp_rd = {24'b0, ss_cnt2};
        8'h38 : temp_rd = {16'b0, sclk_cnt};
        default : temp_rd = 32'b0;
    endcase
 end
 assign prdata = rd_data | temp_rd;
 
 //ends here


  logic wr_en, rd_en, bsy_clr, tx_b, rx_b, cnt_eq_word, sclk_tx, cpha, cpol, go_bsy, ie, lsb, wrd;
  logic sclk_sig, odd;
  logic tx_done;
  logic master_mode;

  logic[15:0] divider;
  logic[2:0] char_len;
  logic fifo_load;
  logic load_from_fifo;
  logic fifo_rx_empty;
  logic[7:0] sub_rx;
  logic[7:0] sub_tx;
  logic se;
  
  reg_bank u_reg_bank(
    .pclk           ( pclk           ),
    .presetn        ( presetn        ),
    .wr_en          ( wr_en          ),
    .rd_en          ( rd_en          ),
    .bsy_clr        ( bsy_clr        ),
    .miso           ( miso_pad_i     ),
    .tx_b           ( tx_b           ),
    .rx_b           ( rx_b           ),
    .fifo_load      ( fifo_load      ),
    .load_from_fifo ( load_from_fifo ),
    .cnt_eq_word    ( cnt_eq_word    ),
    .sclk_tx        ( sclk_tx        ),
    .sub_rx         ( sub_rx         ),
    .paddr          ( paddr          ),
    .pwdata         ( pwdata         ),
    .prdata         ( rd_data        ),
    
    .cpha           ( cpha           ),
    .cpol           ( cpol           ),
    .go_bsy         ( go_bsy         ),
    .mosi           ( mosi_pad_o     ),
    .ie             ( ie             ),
    .lsb            ( lsb            ),
    .se             ( se             ),
    .master_mode    ( master_mode    ),
    .wr_rd_done     ( wrd            ),
    .interrupt_pad_o( interrupt_pad_o),
    .sub_tx         ( sub_tx         ),
    .divider        ( divider        ),
    .char_len       ( char_len       )
  );
  
  apb_fsm u_apb_sub(
    .pclk    ( pclk   ),
    .presetn ( presetn),
    .psel    ( psel   ),
    .penable ( penable),
    .pwrite  ( pwrite ),
    
    .rd_en   ( rd_en  ),
    .wr_en   ( wr_en  ),
    .pready  ( pready )
  );
  
  clock_gen u_clk_gen(
    .pclk             ( pclk            ),
    .presetn          ( presetn         ),
    .sclk_tx          ( sclk_tx         ),
    .cpha             ( cpha            ),
    .cpol             ( cpol            ),
    .char_len         ( char_len        ),
    .divider          ( divider         ),
    
    .sclk_pad_o       ( sclk_pad_o      ),
    .cnt_eq_word      ( cnt_eq_word     ),
    .sclk_sig         ( sclk_sig        ),
    .odd              ( odd             )
  );
  
spi_sub_top u_spi_sub_top(
   .pclk           ( pclk           ),
   .presetn        ( presetn        ),
   .ss_pad_i       ( ss_pad_i       ),
   .sub_tx         ( sub_tx         ),
   .simo_pad_i     ( simo_pad_i     ),
   .sclk_in        ( sclk_pad_i     ),
   .cpol           ( cpol           ),
   .cpha           ( cpha           ),
   .se             ( se             ),
   
   .sub_rx         ( sub_rx         ),
   .somi_pad_o     ( somi_pad_o     ),
   .fifo_load      ( fifo_load      ),
   .load_from_fifo ( load_from_fifo )
);

  spi_manager u_spi(
    .pclk             ( pclk            ),
    .presetn          ( presetn         ),
    .go_bsy           ( go_bsy          ),
    .odd              ( odd             ),
    .cnt_eq_word      ( cnt_eq_word     ),
    .sclk_sig         ( sclk_sig        ),
    .wr_rd_done       ( wrd             ),
    .ie               ( ie              ),
    
    .sclk_tx          ( sclk_tx         ),
    .tx_b             ( tx_b            ),
    .rx_b             ( rx_b            ),
    .bsy_clr          ( bsy_clr         )
  );
  
  
  assign ss_pad_o = master_mode ? ~sclk_tx : 1'b1;
  
endmodule