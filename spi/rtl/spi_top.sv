module spi_top(
  
  input logic        pclk,
  input logic        presetn,
  input logic        psel,
  input logic        pwrite,
  input logic        penable,
  input logic        miso_pad_i,
  input logic [31:0] paddr,
  input logic [31:0] pwdata,
  
  output logic        pready,
  output logic        sclk_pad_o,
  output logic        mosi_pad_o,
  output logic        interrupt_pad_o,
  output logic        ss_pad_o,
  output logic [31:0] prdata
  
);

  //-------------------------------------------internal signal-----------------------------------------------
  logic [15:0] count;
  logic [4:0]  edge_cnt;
  logic [15:0] divider;
  logic [2:0]  char_len;
  logic [7:0]  trx;
  logic        en_tgl;
  logic        go_bsy;
  logic        clear_cnt;
  logic        bit_eq_n;
  logic        wr_en;
  logic        rd_en;
  logic        ie;
  logic        transfer;
  logic        bsy_clr;
  logic        leading_edge;
  logic        trailing_edge;
  logic        first_edge;
  logic        cpol;
  logic        cpha;  
  logic        lsb;
  logic        transfer_en;
  logic        sample_en;
  logic        wr_en_trx;
  
  
  //---------------------------------------------------------------------------------------------------------
  //------------------------------------------APB-----------------------------------------------------
  
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
  
  //--------------------------------------------------------------------------------------------------------- 
  
  //------------------------------------------COMPARATOR-----------------------------------------------------
  
  comparator u_comp (
  
    .count    ( count    ),
    .divider  ( divider  ),
    .transfer ( transfer ),
    .en_tgl   ( en_tgl   )
  
  );
  
  //---------------------------------------------------------------------------------------------------------
  
  
  //------------------------------------------SS GENERATOR-----------------------------------------------------
  
  ss_gen u_ss (
  
    .go_bsy   ( go_bsy   ),
    .ss_pad_o ( ss_pad_o )
  
  );
  
  //---------------------------------------------------------------------------------------------------------
  
  
  //------------------------------------------Counter-----------------------------------------------------
  
  counter #(
    .RESET_VALUE   ( 1'b0  ),
    .COUNTER_WIDTH ( 16    )
  ) u_counter1 (
    .clk     ( pclk        ),
    .reset_b ( presetn     ),
    .clear   ( clear_cnt   ),
    .en      ( 1'b1        ), 
    .count   ( count       )
  );
  
  //------------------------------------------------------------------------------------------------------
  
  //------------------------------------------SCLK Generator-----------------------------------------------------
  
  sclk_gen u_sclk (
  
    .pclk       ( pclk       ),
    .presetn    ( presetn    ),
    .transfer   ( transfer   ),
    .en_tgl     ( en_tgl     ),
    .cpol       ( cpol       ),
    .cpha       ( cpha       ),
    .sclk_pad_o ( sclk_pad_o )
    
  );
  
  //------------------------------------------------------------------------------------------------------
  
  //------------------------------------------Edge Counter-----------------------------------------------------
  
  edge_counter u_edcount (
  
    .pclk     ( pclk     ),
    .presetn  ( presetn  ),
    
    .bit_eq_n ( bit_eq_n ),
    .en_tgl   ( en_tgl   ),
    .edge_cnt ( edge_cnt ),
    .even     ( even     )
    
  );
  
  //------------------------------------------------------------------------------------------------------
  
  //------------------------------------------Edge Detector-----------------------------------------------------
  
  edge_detectors u_edge (
  
    .pclk          ( pclk          ),
    .presetn       ( presetn       ),
    .transfer      ( transfer      ),
    .en_tgl        ( en_tgl        ),
    .go_bsy        ( go_bsy        ),
    .bsy_clr       ( bsy_clr       ),
    .even          ( even          ),
    .leading_edge  ( leading_edge  ),
    .trailing_edge ( trailing_edge ),
    .first_edge    ( first_edge    )
    
  );
  
  //------------------------------------------------------------------------------------------------------
  
  //------------------------------------------Bit Count Checker-----------------------------------------------------
  
  bit_cnt u_bit_cnt (
  
    .char_len ( char_len   ),
    .edge_cnt ( edge_cnt   ),
    .cpol     ( cpol       ),
    .en_tgl   ( en_tgl     ),
    .cpha     ( cpha       ),
    .bit_eq_n ( bit_eq_n   )
  
  );
  
  //------------------------------------------------------------------------------------------------------
  
  //------------------------------------------SPI FSM-----------------------------------------------------
  
  spi_fsm u_fsm (
  
    .pclk            ( pclk            ),
    .presetn         ( presetn         ),
    .go_bsy          ( go_bsy          ),
    .en_tgl          ( en_tgl          ),
    .wr_en           ( wr_en           ),
    .rd_en           ( rd_en           ),
    .bit_eq_n        ( bit_eq_n        ),
    .ie              ( ie              ),
    .transfer        ( transfer        ),
    .interrupt_pad_o ( interrupt_pad_o ),
    .bsy_clr         ( bsy_clr         ),
    .clear_cnt       ( clear_cnt       )
    
  );
  
  //------------------------------------------------------------------------------------------------------
  
  //------------------------------------------Shift Logic-------------------------------------------------
  
  shift_logic u_shift_logic (
  
    .leading_edge  ( leading_edge  ),
    .trailing_edge ( trailing_edge ),
    .first_edge    ( first_edge    ),
    //.cpha          ( cpha          ),
    .transfer_en   ( transfer_en   ),
    .sample_en     ( sample_en     )
        
  );
  
  //------------------------------------------------------------------------------------------------------
  
  //------------------------------------------Register Bank-----------------------------------------------
  
  reg_bank u_reg (
  
    .pclk        ( pclk        ),
    .presetn     ( presetn     ),
    .pwdata      ( pwdata      ),
    .paddr       ( paddr       ),
    .wr_en       ( wr_en       ),
    .rd_en       ( rd_en       ),
    .transfer    ( transfer    ),
    .bsy_clr     ( bsy_clr     ),
    .miso_pad_i  ( miso_pad_i  ),
    .sample_en   ( sample_en   ),
    .transfer_en ( transfer_en ),
   
    .ie          ( ie          ),
    .lsb         ( lsb         ),
    .cpol        ( cpol        ),
    .cpha        ( cpha        ),
    .go_bsy      ( go_bsy      ),
    .prdata      ( prdata      ),
    .divider     ( divider     ),
    .char_len    ( char_len    ),
    .trx          ( trx          )
  
  );

  //------------------------------------------------------------------------------------------------------
  
  
  
  //------------------------------------------------------------------------------------------------------
  
  mosi_gen u_mosi (
  
    .pclk        ( pclk        ),
    .presetn     ( presetn     ),
    .lsb         ( lsb         ),
    .transfer_en ( transfer_en ),
    .char_len    ( char_len    ),
    .trx          ( trx          ),
    .mosi_pad_o  ( mosi_pad_o  )
  
  );
endmodule