module hum_ctl_fsm (
  input  logic pclk,
  input  logic presetn,
  input  logic inc_hum_pb,
  input  logic dec_hum_pb,
  input  logic crossed_min_hum,
  input  logic crossed_max_hum,
  input  logic default_hum,
  input  logic count_eq_1s,

  output logic hum_inc_en,
  output logic hum_dec_en,
  output logic dehumidifier_en,
  output logic humidifier_en,
  output logic hum_counter_clr,
  output logic hum_counter_en
);

  localparam IDLE    = 2'b00,
             DRY     = 2'b01,
             MOSTURE = 2'b10;
 
  logic [1:0] pstate;
  logic [1:0] nstate;

  // Finding the posedge of inc and dec push button press

  logic inc_hum_pb_delayed;
  logic dec_hum_pb_delayed;

  dff #(
    .DFF_WIDTH(1)
  ) u_dff_delayed_inc (
    .clk     ( pclk               ),
    .reset_b ( presetn            ),
    .d       ( inc_hum_pb         ),
    .q       ( inc_hum_pb_delayed )
  );

  dff #(
    .DFF_WIDTH(1)
  ) u_dff_delayed_dec (
    .clk     ( pclk               ),
    .reset_b ( presetn            ),
    .d       ( dec_hum_pb         ),
    .q       ( dec_hum_pb_delayed )
  );

  logic posedge_inc_hum_pb;
  logic posedge_dec_hum_pb;

  assign posedge_inc_hum_pb = inc_hum_pb & (~ inc_hum_pb_delayed);
  assign posedge_dec_hum_pb = dec_hum_pb & (~ dec_hum_pb_delayed);

  //NSL
  always@(*)begin
    case (pstate)
      IDLE    : nstate = crossed_min_hum ? DRY : (crossed_max_hum ? MOSTURE : IDLE);
      DRY     : nstate = default_hum ? IDLE : DRY;
      MOSTURE : nstate = default_hum ? IDLE : MOSTURE;
      default : nstate = 2'bx;
    endcase
  end

  logic idle_st;
  logic dry_st;
  logic mosture_st;

  assign idle_st    = (pstate == IDLE);
  assign dry_st     = (pstate == DRY);
  assign mosture_st = (pstate == MOSTURE);

  //OL 
  assign hum_inc_en      = (idle_st & posedge_inc_hum_pb) | (dry_st & count_eq_1s);
  assign hum_dec_en      = (idle_st & posedge_dec_hum_pb) | (mosture_st & count_eq_1s);
  assign dehumidifier_en = mosture_st;
  assign humidifier_en   = dry_st;
  assign hum_counter_en  = dry_st | mosture_st;
  assign hum_counter_clr = ((dry_st | mosture_st) & count_eq_1s) | idle_st;

  //PSR
  dff #(
    .DFF_WIDTH(2)
  ) u_dff (
    .clk    (pclk    ),
    .reset_b(presetn ),
    .d      (nstate  ),
    .q      (pstate  )
  );

endmodule