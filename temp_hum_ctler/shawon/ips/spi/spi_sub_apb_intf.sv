module spi_sub_apb_intf (
  input  logic        pclk,
  input  logic        presetn,
  input  logic        pwrite,
  input  logic        psel,
  input  logic        penable,
  input  logic [31:0] paddr,
  input  logic [31:0] pwdata,
                      
  output logic        pready,
  output logic [31:0] prdata,
  output logic        cpha,
  output logic        cpol,
  output logic        se
);

  apb_fsm i_fsm_apb (
    .pclk     ( pclk    ),
    .presetn  ( presetn ),
    .psel     ( psel    ),
    .pwrite   ( pwrite  ),
    .penable  ( penable ),
    .pready   ( pready  ),
    .rd_en    ( rd_en   ),
    .wr_en    ( wr_en   )
  );

  logic ctl_wr_en ;
  assign ctl_wr_en = wr_en & (paddr[11:0] == 12'hC04);

  logic ctl_rd_en ;
  assign ctl_rd_en = rd_en & (paddr[11:0] == 12'hC04);

  logic [2:0]ctl_d;
  logic [2:0]ctl_q;

  assign ctl_d = ctl_wr_en ? pwdata[2:0] : ctl_q;

  dff #(
    .DFF_WIDTH(3) 
  ) i_dff_cltr(
    .clk     ( pclk    ),
    .reset_b ( presetn ),
    .q       ( ctl_q   ),
    .d       ( ctl_d   ) 
  );

  assign se   = ctl_q [0];
  assign cpol = ctl_q [1];
  assign cpha = ctl_q [2];

  assign prdata = ctl_rd_en ? {29'b0 , ctl_q} : 32'b0;

endmodule
