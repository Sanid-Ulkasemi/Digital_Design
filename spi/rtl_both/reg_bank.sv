
(* keep_hierarchy = "true" *)module reg_bank(
  input logic pclk,
  input logic presetn,
  input logic wr_en,
  input logic rd_en,
  input logic bsy_clr,
  input logic miso,
  input logic tx_b,
  input logic rx_b,
  input logic sclk_tx,
  input logic fifo_load,
  input logic load_from_fifo,
  input logic cnt_eq_word,
  input logic[7:0] sub_rx,
  input logic[31:0] paddr,
  input logic[31:0] pwdata,
  
  output logic cpha,
  output logic cpol,
  output logic go_bsy,
  output logic mosi,
  output logic ie,
  output logic lsb,
  output logic se,
  output logic wr_rd_done,
  output logic master_mode,
  output logic interrupt_pad_o,
  output logic[7:0] sub_tx,
  output logic[2:0] char_len,
  output logic[15:0] divider,
  output logic[31:0] prdata
);

  logic [31:0] read_out;
  logic[7:0] tx, tx_raw;
  logic[7:0] rx, rx_org, rx_out, rx_flip;
  logic[9:0] ctrl;
  
  logic addr_tx;
  logic addr_ctrl;
  logic addr_divider;
  logic addr_tfsr;
  logic addr_rfsr;

  
  
  logic mosi_dff, mosi_out;
  
  //RX fifo signals
  logic fifo_rx_rd_en;
  logic fifo_rx_wr_en;
  logic fifo_rx_clr;
  logic fifo_rx_empty;
  logic[3:0] fifo_rx_dc;
  logic[7:0] fifo_rx_data_out;
  logic[7:0] fifo_rx_data_in;
  logic fifo_rx_full;

  //TX fifo signals
  logic fifo_tx_wr_en;
  logic fifo_tx_rd_en;
  logic[3:0] fifo_tx_dc;
  logic[7:0] fifo_tx_data_out;
  logic fifo_tx_empty;
  logic fifo_tx_full;
  logic fifo_rx_empty_q;

  //intpt
  logic intpt_d;

  assign intpt_d = interrupt_pad_o ? ~((wr_en & addr_ctrl & pwdata[12] & ~go_bsy) | fifo_rx_empty) : (ie & ~fifo_rx_empty & fifo_rx_empty_q);

  dff #(
  	.RESET_VALUE(1'b0),
  	.FLOP_WIDTH(1)
  )u_dff2(
   .clk     ( pclk            ),
   .reset_b ( presetn         ),
   .d       ( fifo_rx_empty   ),
   .q       ( fifo_rx_empty_q )
  );
  
  dff #(
  	.RESET_VALUE(1'b0),
  	.FLOP_WIDTH(1)
  )u_dff_intpt(
   .clk     ( pclk            ),
   .reset_b ( presetn         ),
   .d       ( intpt_d         ),
   .q       ( interrupt_pad_o )
  );
  

  dff#(
  .RESET_VALUE(1'b0),
  .FLOP_WIDTH(1)
)u_mosi_dff(  
  .clk(pclk),
  .reset_b(presetn),
  .d(mosi_dff),
  .q(mosi)
);


assign fifo_rx_wr_en = ctrl[3] ? cnt_eq_word : fifo_load;
assign fifo_rx_data_in = ctrl[3] ? rx_org : sub_rx;
assign master_mode = ctrl[3];

fifo_sync#(
  .FIFO_DEPTH(16),
  .DATA_WIDTH(8),
  .FIFO_DEPTH_LOG(4)
)u_fifo_rx(

  .clk        ( pclk          ),
  .rst_n      ( presetn       ),
  .wr_en      ( fifo_rx_wr_en ),
  .rd_en      ( fifo_rx_rd_en    ),
  .clear      ( fifo_rx_clr      ),
  .data_in    ( fifo_rx_data_in  ),
  .data_out   ( fifo_rx_data_out ),
  .data_count ( fifo_rx_dc       ),
  .empty      ( fifo_rx_empty    ),
  .full       ( fifo_rx_full     )
);


assign fifo_tx_wr_en = wr_en & addr_tx;
assign fifo_tx_rd_en = ctrl[3] ? go_bsy & ~sclk_tx : load_from_fifo;
assign sub_tx = fifo_tx_data_out;


fifo_sync#(
  .FIFO_DEPTH(16),
  .DATA_WIDTH(8),
  .FIFO_DEPTH_LOG(4)
)u_fifo_tx(

  .clk        ( pclk             ),
  .rst_n      ( presetn          ),
  .wr_en      ( fifo_tx_wr_en    ),
  .rd_en      ( fifo_tx_rd_en    ),
  .clear      ( fifo_rx_clr      ),
  .data_in    ( pwdata[7:0]      ),
  .data_out   ( fifo_tx_data_out ),
  .data_count ( fifo_tx_dc       ),
  .empty      ( fifo_tx_empty    ),
  .full       ( fifo_tx_full     )
);




  always@(posedge pclk or negedge presetn)begin
    
    //reset value of the registers
    if(~presetn)begin
      tx[7:0] <= 8'b0;
      rx[7:0] <= 8'b0;
      ctrl[9:0] <= 10'b0;
      divider[15:0] <= 16'hffff;
    end  
    
    else begin
      tx[7:0] <= fifo_tx_rd_en & ctrl[3] ? (fifo_tx_data_out) : (tx_b & ctrl[3] ? (lsb ? {1'b0, tx[7:1]} : {tx[6:0], 1'b0}) : tx) ;

      rx[7:0] <=  rx_b & ctrl[3] ? {rx[6:0], miso} : rx ;
      
      ctrl[9:0] <= (wr_en & ~go_bsy & addr_ctrl) ? {pwdata[12:8], pwdata[4:0]} : (bsy_clr & fifo_tx_empty ? (ctrl & 10'b11_1101_1111) : ctrl);
      
      divider[15:0] <= (wr_en & ~go_bsy & addr_divider) ? pwdata[15:0] : divider;
      
    end
  end
  
  always@(*)begin
  
    //Selecting the MSB from the transmit register according charlen
    casez(char_len)
      3'b000 : mosi_out = tx[7];
      3'b001 : mosi_out = tx[0];
      3'b010 : mosi_out = tx[1];
      3'b011 : mosi_out = tx[2];
      3'b100 : mosi_out = tx[3];
      3'b101 : mosi_out = tx[4];
      3'b110 : mosi_out = tx[5];
      3'b111 : mosi_out = tx[6];
      default : mosi_out = 1'bx;
    endcase
    
    //organaizing the receive register values
    casez(char_len)
      3'b000  : rx_out = rx_flip[7:0];
      3'b001  : rx_out = {{7{1'b0}}, rx_flip[7]};
      3'b010  : rx_out = {{6{1'b0}}, rx_flip[7:6]};
      3'b011  : rx_out = {{5{1'b0}}, rx_flip[7:5]};
      3'b100  : rx_out = {{4{1'b0}}, rx_flip[7:4]};
      3'b101  : rx_out = {{3{1'b0}}, rx_flip[7:3]};
      3'b110  : rx_out = {{2{1'b0}}, rx_flip[7:2]};
      3'b111  : rx_out = {{1{1'b0}}, rx_flip[7:1]};
      default : rx_out = 8'bx;
    
    endcase

  end

  //address comparator
  assign addr_tx      = paddr[7:0] == 8'h00;
  assign addr_ctrl    = paddr[7:0] == 8'h10;
  assign addr_divider = paddr[7:0] == 8'h14;
  assign addr_tfsr    = paddr[7:0] == 8'h18;
  assign addr_rfsr    = paddr[7:0] == 8'h2C;

  //indicates if there has been a read or write in the register bank
  assign wr_rd_done = (addr_ctrl | addr_divider | addr_tx) & (wr_en | rd_en) & ~go_bsy;

  assign mosi_dff = tx_b ? (lsb ? tx[0] : mosi_out) : mosi;
  assign cpha = ctrl[6];
  assign cpol = ctrl[7];
  assign lsb = ctrl[8];
  assign ie = ctrl[9];
  assign go_bsy = ctrl[5];
  assign se = ctrl[4];
  assign char_len[2:0] = ctrl[2:0];
  assign fifo_rx_rd_en = rd_en & addr_tx;
  assign fifo_rx_clr = 1'b0;

  
  //flip the bits of register
  assign rx_flip  [7:0]         = {rx[0],rx[1],rx[2],rx[3],rx[4],rx[5],rx[6],rx[7]};
  assign rx_org   [7:0]         = lsb ? rx_out : rx;
  
  always@(*) begin
    casez(paddr[7:0])
        8'h00 : read_out = fifo_rx_data_out;
        8'h10 : read_out = {18'b0, ctrl[9:5],3'b0,ctrl[4:0]};
        8'h14 : read_out = {16'b0, divider};
        8'h18 : read_out = {26'b0, fifo_rx_empty, fifo_rx_full, fifo_rx_dc};
        8'h2C : read_out = {26'b0, fifo_tx_empty, fifo_tx_full, fifo_tx_dc};
        8'h30 : read_out = 32'b0;
        8'h34 : read_out = 32'b0;
        8'h38 : read_out = 32'b0;
        default: read_out = 32'b0;
    endcase
  end
  
  //selecting the organized value of rx for stroing after the transfer is complete
  
  
  assign prdata   [31:0]        = rd_en ? read_out : 32'b0;

  //read logic
  

endmodule