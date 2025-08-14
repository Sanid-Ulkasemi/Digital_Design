(* keep_hierarchy = "true" *)module apb_intfc(
  input pclk,
  input presetn,
  input psel,
  input pwrite,
  input penable,
  input [31:0] paddr,
  input [31:0] pwdata,

  input [10:0] rbr,
  input parity_error,
  input frame_error,
  input error_check,
  input shift_cnt_eq,
  input rx_fifo_empty,
  input tsr_load,
  input receive_done,
  input tx_fifo_empty,
  input uart_intpt,
  input uart_break,
  input rx_fifo_full,
  input rbrf,

  input loop_txd,
  input uart_rxd,
  input uart_txd,

  output loop,
  output thr_wr_en,
  output rbr_rd_en,
  output [1:0] rxfiftl,
  output txclr,
  output rxclr,
  output fifoen,
  output sp,
  output eps,
  output pen,
  output stb,
  output [1:0] wls,
  output [7:0] dll,
  output [7:0] dlh,
  output urrst,
  output utrst,

  output thre,
  output etbei,
  output pe,
  output elsi,
  output fe,
  output bi,
  output dr,
  output erbi,

  output pready,
  output [31:0] prdata
);

  wire ier_wr_en;
  wire fcr_wr_en;
  wire lcr_wr_en;
  wire dll_wr_en;
  wire dlh_wr_en;
  wire pwremu_mgmt_wr_en;

  // APB FSM
  wire wr_en;
  wire rd_en;

  fsm_apb_protocol i_fsm_apb_protocol (
    .pclk(pclk),
    .preset_n(presetn),
    .psel(psel),
    .pwrite(pwrite),
    .penable(penable),
    .pready(pready),
    .rd_en(rd_en),
    .wr_en(wr_en)
  );

  // Comparator
  assign thr_wr_en = (paddr[7:0] == 8'b0) & wr_en;
  assign ier_wr_en = (paddr[7:0] == 8'h4) & wr_en;
  assign fcr_wr_en = (paddr[7:0] == 8'h8) & wr_en;
  assign lcr_wr_en = (paddr[7:0] == 8'hC) & wr_en;
  assign dll_wr_en = (paddr[7:0] == 8'h20) & wr_en;
  assign dlh_wr_en = (paddr[7:0] == 8'h24) & wr_en;
  assign pwremu_mgmt_wr_en = (paddr[7:0] == 8'h30) & wr_en;

  // Interrupt enable register
  wire [2:0] ier_d;
  reg [2:0] ier_q;

  assign ier_d = ier_wr_en ? pwdata[2:0] : ier_q;
  
  always @(posedge pclk or negedge presetn) begin
    if (~presetn)
      ier_q <= 3'b0;
    else
      ier_q <= ier_d[2:0];
  end

  assign erbi = ier_q[0];
  assign etbei = ier_q[1];
  assign elsi = ier_q[2];

  // FIFO control register
  wire [4:0] fcr_d;
  reg [4:0] fcr_q;
    
  assign fcr_d = fcr_wr_en ? {pwdata[7:6], pwdata[2:0]} : fcr_q;
  always @(posedge pclk or negedge presetn) begin
    if (~presetn)
      fcr_q <= 5'b0;
    else
      fcr_q <= fcr_d;
  end

  assign fifoen = fcr_q[0];
  assign rxclr = fcr_q[1];
  assign txclr = fcr_q[2];
  assign rxfiftl = fcr_q[4:3];

  // Line control register
  reg [7:0] lcr_q;
  wire [7:0] lcr_d;
    
  assign lcr_d = lcr_wr_en ? pwdata[7:0] : lcr_q;
  
  always @(posedge pclk or negedge presetn) begin
    if (~presetn)
      lcr_q <= 8'b0;
    else
      lcr_q <= lcr_d;
  end

  assign wls = lcr_q[1:0];
  assign stb = lcr_q[2];
  assign pen = lcr_q[3];
  assign eps = lcr_q[4];
  assign sp = lcr_q[5];
  assign bc = lcr_q[6];
  assign loop = lcr_q[7];

  // Status control
  wire parity_st_d;
  wire frame_st_d;
  wire de_st_d;
  wire thre_st_d;
  wire temt_st_d;
  wire bi_st_d;
  wire oe_st_d;
  wire rxfifoe_st_d;

  wire paddr_eq_rbr_thr;

  wire [7:0] lsr_d;
  reg [7:0] lsr_q;

  wire temt;
  wire oe;

  assign rbr_rd_en = (paddr_eq_rbr_thr & rd_en);
  assign paddr_eq_rbr_thr = (paddr[7:0] == 8'b0);


  assign parity_st_d      = fifoen ? (((rbr[8]) | pe)  & ( ~ (rd_en & paddr_eq_rbr_thr))) : ((parity_error & error_check) | pe) & ( ~ (rd_en & paddr_eq_rbr_thr));
  assign frame_st_d       = fifoen ? ((rbr[9] | fe) & ( ~ (rd_en & paddr_eq_rbr_thr))) : ((frame_error & error_check) | fe) & ( ~ (rd_en & paddr_eq_rbr_thr));
  assign de_st_d          = fifoen ? ~rx_fifo_empty : ((receive_done | dr) & ( ~ (rd_en & paddr_eq_rbr_thr)));
  assign thre_st_d        = ~thr_wr_en & ((~fifoen & tsr_load) | ((fifoen & tx_fifo_empty) | thre));
  assign temt_st_d        = shift_cnt_eq ? thre : temt;
  assign bi_st_d          = fifoen ? (rbr[10] & ( ~ (rd_en & paddr_eq_rbr_thr))) : ((uart_break | bi) & ( ~ (rd_en & paddr_eq_rbr_thr)));
  assign oe_st_d          = fifoen ? (((rx_fifo_full & receive_done) | oe) & (~ (rd_en & paddr_eq_rbr_thr))) : (rbrf & receive_done);
  assign rxfifoe_st_d     = |(lsr_d[4:0]);




  assign lsr_d = {rxfifoe_st_d, temt_st_d, thre_st_d, bi_st_d, frame_st_d, parity_st_d, oe_st_d ,de_st_d};
  assign bi = lsr_q[4];
  assign oe = lsr_q[1];
  assign pe = lsr_q[2];
  assign fe = lsr_q[3];
  assign temt = lsr_q[6];
  assign thre = lsr_q[5];
  assign dr = lsr_q[0];

  always @(posedge pclk or negedge presetn) begin
    if (~presetn)
      lsr_q <= 8'b0110_0000;
    else
      lsr_q <= lsr_d;
  end

  // DLL
  wire [7:0] dll_d;

  assign dll_d = dll_wr_en ? pwdata[7:0] : dll;
  dff #(
   .RESET_VALUE ( 1'b0    ),
   .FLOP_WIDTH  ( 8       )
  )u_dll(
   .clk         ( pclk    ),
   .reset_b     ( presetn ),
   .d           ( dll_d   ),
   .q           ( dll     )
  );
  // DLH
  wire [7:0] dlh_d;

  assign dlh_d = dlh_wr_en ? pwdata[7:0] : dlh;
  dff #(
   .RESET_VALUE ( 1'b0    ),
   .FLOP_WIDTH  ( 8       )
  )u_dlh(
   .clk         ( pclk    ),
   .reset_b     ( presetn ),
   .d           ( dlh_d   ),
   .q           ( dlh     )
  );
  // Power and emulation
  wire [1:0] pwr_d;
  reg [1:0] pwr_q;
    
  assign pwr_d = pwremu_mgmt_wr_en ? pwdata[15:14] : pwr_q;
  
  always @(posedge pclk or negedge presetn) begin
    if (~presetn)
      pwr_q <= 2'b0;
    else
      pwr_q <= pwr_d;
  end

  assign utrst = pwr_q[1];
  assign urrst = pwr_q[0];

  //Internal baud rate calculation.
  wire[31:0] br_ps;
  wire[31:0] br_pl;
  wire wr_br_ps;
  wire wr_br_pl;
  
  assign wr_br_ps = (paddr[7:0] == 8'h34) & wr_en;
  assign wr_br_pl = (paddr[7:0] == 8'h38) & wr_en;
  
  counter #(
	.RESET_VALUE (1'b0),
	.COUNTER_WIDTH (32)
    )u_br_ps_counter(
	.clk(pclk),
	.reset_b(presetn),
	.clear(wr_br_ps),
	.en(~uart_rxd),
	
	.count(br_ps)
    );
    
    counter #(
	.RESET_VALUE (1'b0),
	.COUNTER_WIDTH (32)
    )u_br_pl_counter(
	.clk(pclk),
	.reset_b(presetn),
	.clear(wr_br_pl),
	.en(~uart_txd),
	
	.count(br_pl)
    );

  reg [31:0] rd_data;
  //Read logic
  always@(*)begin
    case(paddr[7:0])
      32'h0   : rd_data = {24'b0, rbr[7:0]};
      32'h4   : rd_data = {29'b0, ier_q[2:0]};
      32'h8   : rd_data = {24'b0, fifoen, fifoen, 5'b0, ~uart_intpt};
      32'hC   : rd_data = {24'b0, lcr_q [7:0]};
      32'h14  : rd_data = {21'b0, loop_txd, uart_txd, uart_rxd, lsr_q};
      32'h20  : rd_data = {24'b0, dll};
      32'h24  : rd_data = {24'b0, dlh};
      32'h30  : rd_data = {16'b0, pwr_q[1:0], 14'b0};
      32'h34  : rd_data = br_ps;
      32'h38  : rd_data = br_pl;
      default : rd_data = 32'bx;
    endcase
  end

  assign prdata = rd_en ? rd_data : 32'b0;


endmodule