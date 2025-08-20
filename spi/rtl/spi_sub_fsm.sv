module spi_sub_fsm (
  input  logic pclk,
  input  logic presetn,
  input  logic ss_pad_i,
  input  logic sample_edge,
  input  logic transmit_edge,
  input  logic transfer_finish,
  input  logic sclk_edge,

  output logic slave_receive_shift_en,
  output logic slave_transfer_shift_en,
  output logic fifo_load,
  output logic load_from_fifo,
  output logic counter_clear,
  output logic counter_en
);  

  localparam IDLE  = 1'b0,
             SUBTX = 1'b1;

  logic pstate;
  logic nstate;

  logic subtx_st;
  logic idle_st;

  assign idle_st  = (pstate == IDLE);
  assign subtx_st = (pstate == SUBTX);

  always@(*)begin
    case (pstate)
      IDLE    : nstate = ss_pad_i ? IDLE : SUBTX;
      SUBTX   : nstate = transfer_finish ? IDLE : SUBTX;
      default : nstate = 1'bx;
    endcase
  end

  assign slave_receive_shift_en  = subtx_st & sample_edge;
  assign slave_transfer_shift_en = subtx_st & transmit_edge;
  assign fifo_load               = subtx_st & transfer_finish;
  assign load_from_fifo          = idle_st & (~ ss_pad_i);
  assign counter_clear           = subtx_st & transfer_finish;
  assign counter_en              = subtx_st & sclk_edge;

  
  //PSR
    dff #(
    .FLOP_WIDTH(1)
  )u_dff(
    .clk     ( pclk    ),
    .reset_b ( presetn ),
    .q       ( pstate  ),
    .d       ( nstate  )
  );

endmodule