(* keep_hierarchy = "true" *)module spi_sub_top (
  input logic        pclk,
  input logic        presetn,
  input  logic        pwrite,
  input  logic        psel,
  input  logic        penable,
  input  logic [31:0] paddr,
  input  logic [31:0] pwdata,

  input logic        ss_pad_i,
  input logic [7:0]  sub_tx,
  input logic        simo_pad_i,
  input logic        sclk_in,
                     
  output logic        pready,
  output logic [31:0] prdata,
                     
  output logic [7:0] sub_rx,
  output logic       somi_pad_o

//  output logic       fifo_load,
//  output logic       load_from_fifo
);


  logic sample_edge;
  logic transmit_edge;
  logic transfer_finish;
  logic sclk_edge;
  
  logic slave_receive_shift_en;
  logic slave_transfer_shift_en;
  logic counter_clear;
  logic se;
  logic load_from_fifo;
  logic fifo_load;

  spi_sub_fsm u_spi_sub_fsm (
    .pclk                    ( pclk                    ),
    .presetn                 ( presetn                 ),
    .ss_pad_i                ( ss_pad_i                ),
    .sample_edge             ( sample_edge             ),
    .transmit_edge           ( transmit_edge           ),
    .transfer_finish         ( transfer_finish         ),
    .sclk_edge               ( sclk_edge               ),
    .se                      ( se                      ),
    
    .slave_receive_shift_en  ( slave_receive_shift_en  ),
    .slave_transfer_shift_en ( slave_transfer_shift_en ),
    .fifo_load               ( fifo_load               ),
    .load_from_fifo          ( load_from_fifo          ),
    .counter_clear           ( counter_clear           ),
    .counter_en              ( counter_en              )
  );
  

  sub_shift_reg_block u_sub_shift_reg_block (
    .pclk                    ( pclk                    ),
    .presetn                 ( presetn                 ),
    .slave_transfer_shift_en ( slave_transfer_shift_en ),
    .sub_tx                  ( sub_tx                  ),
    .slave_receive_shift_en  ( slave_receive_shift_en  ),
    .simo_pad_i              ( simo_pad_i              ),
    .load_from_fifo          ( load_from_fifo          ),
    
    .sub_rx                  ( sub_rx                  ),
    .somi_pad_o              ( somi_pad_o              )
  );

  logic cpha;
  logic cpol;

  clk_receiver u_clk_receiver (
    .pclk            ( pclk            ),
    .presetn         ( presetn         ),
    .sclk_in         ( sclk_in         ),
    .cpol            ( cpol            ),
    .cpha            ( cpha            ),
    .counter_en      ( counter_en      ),
    .counter_clear   ( counter_clear   ),
    
    .sample_edge     ( sample_edge     ),
    .sclk_edge       ( sclk_edge       ),
    .transmit_edge   ( transmit_edge   ),
    .transfer_finish ( transfer_finish )
  );


  spi_sub_apb_intf u_spi_sub_apb_intf (
    .pclk    ( pclk    ),
    .presetn ( presetn ),
    .pwrite  ( pwrite  ),
    .psel    ( psel    ),
    .penable ( penable ),
    .paddr   ( paddr   ),
    .pwdata  ( pwdata  ),
    
    .pready  ( pready  ),
    .prdata  ( prdata  ),
    .cpha    ( cpha    ),
    .cpol    ( cpol    ),
    .se      ( se      )
  );
  
endmodule