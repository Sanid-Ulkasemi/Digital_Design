module temp_ctl_fsm (
  input  logic pclk,
  input  logic presetn,
  input  logic inc_temp_pb,
  input  logic dec_temp_pb,
  input  logic crossed_min_temp,
  input  logic crossed_max_temp,
  input  logic default_temp,
  input  logic count_eq_1s,

  output logic temp_inc_en,
  output logic temp_dec_en,
  output logic fan_en,
  output logic heater_en,
  output logic temp_counter_clr,
  output logic temp_counter_en
);

  localparam IDLE = 2'b00,
             COLD = 2'b01,
             HOT  = 2'b10;
 
  logic [1:0] pstate;
  logic [1:0] nstate;

  // Finding the posedge of inc and dec push button press

  logic inc_temp_pb_delayed;
  logic dec_temp_pb_delayed;

  dff #(
    .DFF_WIDTH(1)
  ) u_dff_delayed_inc_temp (
    .clk     ( pclk               ),
    .reset_b ( presetn            ),
    .d       ( inc_temp_pb         ),
    .q       ( inc_temp_pb_delayed )
  );

  dff #(
    .DFF_WIDTH(1)
  ) u_dff_delayed_dec_temp (
    .clk     ( pclk               ),
    .reset_b ( presetn            ),
    .d       ( dec_temp_pb         ),
    .q       ( dec_temp_pb_delayed )
  );

  logic posedge_inc_temp_pb;
  logic posedge_dec_temp_pb;

  assign posedge_inc_temp_pb = inc_temp_pb & (~ inc_temp_pb_delayed);
  assign posedge_dec_temp_pb = dec_temp_pb & (~ dec_temp_pb_delayed);

  //NSL
  always@(*)begin
    case (pstate)
      IDLE    : nstate = crossed_min_temp ? COLD : (crossed_max_temp ? HOT : IDLE);
      COLD    : nstate = default_temp ? IDLE : COLD;
      HOT     : nstate = default_temp ? IDLE : HOT;
      default : nstate = 2'bx;
    endcase
  end

  logic idle_st;
  logic cold_st;
  logic hot_st;

  assign idle_st = (pstate == IDLE);
  assign cold_st = (pstate == COLD);
  assign hot_st  = (pstate == HOT);

  //OL 
  assign temp_inc_en      = (idle_st & posedge_inc_temp_pb) | (cold_st & count_eq_1s);
  assign temp_dec_en      = (idle_st & posedge_dec_temp_pb) | (hot_st & count_eq_1s);
  assign fan_en           = hot_st;
  assign heater_en        = cold_st;
  assign temp_counter_en  = cold_st | hot_st;
  assign temp_counter_clr = ((cold_st | hot_st) & count_eq_1s) | idle_st;

  //PSR
  dff #(
    .DFF_WIDTH(2)
  ) u_dff (
    .clk     ( pclk    ),
    .reset_b ( presetn ),
    .d       ( nstate  ),
    .q       ( pstate  )
  );

endmodule