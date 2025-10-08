(* keep_hierarchy = "true" *)module i2c_slave_fsm (
  input  logic pclk,                 // System clock
  input  logic presetn,             // Active-low asynchronous reset
  input  logic rx_edge,              // Rising edge of SCL: used for sampling SDA
  input  logic tx_edge,              // Falling edge of SCL: used for shifting data
  input  logic scl_in,               // Serial Clock Line input (actual line state)
  input  logic sda_in,               // Serial Data Line input (actual line state)
  input  logic read,                 // Read operation flag (1 for read, 0 for write)
  input  logic tx_eq8,               // Transmit byte complete (8 bits sent)
  input  logic comp_match,


  output logic sda_en,               // Enable to drive SDA line (output enable)
  output logic counter_en,           // Enable to increment bit counter
  output logic counter_clr,          // Clear bit counter
  output logic ack_cycle,            // Acknowledge cycle indicator
  output logic dack_cycle,           // Data Acknowledge cycle indicator
  output logic shift_en,             // Shift register enable (for TX/RX)
  output logic shift_load_en,         // Load shift register with data
  output logic data_load_en          // Load data into shift register (for TX

);

  localparam [2:0] IDLE     = 3'b000,
                   SLA      = 3'b001,
                   ACK      = 3'b010,
                   TRANSFER = 3'b011,
                   RECEIVE  = 3'b100,
                   DACK     = 3'b101;

  logic [2:0] pstate;
  logic [2:0] nstate;

  logic idle_st;
  logic sla_st;
  logic transfer_st;
  logic receive_st;
  logic dack_st;


  assign idle_st     = pstate == IDLE;
  assign sla_st      = pstate == SLA;
  assign ack_st      = pstate == ACK;
  assign transfer_st = pstate == TRANSFER;
  assign receive_st  = pstate == RECEIVE;
  assign dack_st     = pstate == DACK;

 
  logic sda_prev;
  //NSL
  always@ (*)begin
    casez (pstate)
      IDLE       : nstate = (scl_in & (~ sda_in & sda_prev)) ? SLA : IDLE;
      SLA        : nstate = (tx_eq8 & tx_edge) ? (comp_match ? ACK : IDLE) : SLA;
      ACK        : nstate = tx_edge ? (read ? TRANSFER : RECEIVE) : ACK;
      TRANSFER   : nstate = (tx_eq8 & tx_edge) ? IDLE : TRANSFER;
      RECEIVE    : nstate = (tx_eq8 & tx_edge) ? DACK : RECEIVE;
      DACK       : nstate = tx_edge ? IDLE : DACK;
      default    : nstate = 3'bxxx;
    endcase
  end

  //OL
  assign sda_en         = ack_st | transfer_st | dack_st;
  assign counter_en     = (sla_st | transfer_st | receive_st) & rx_edge;
  assign counter_clr    = idle_st | ack_st | dack_st;
  assign ack_cycle      = ack_st;
  assign dack_cycle     = dack_st;
  assign shift_en       = (transfer_st & tx_edge) | (receive_st & rx_edge) | (sla_st & rx_edge);
  assign shift_load_en  = ack_st & (read) & tx_edge;
  assign data_load_en   = dack_st & tx_edge;

  //PSR
  dff #(
    .FLOP_WIDTH(3),
    .RESET_VALUE(1'b0)
  ) u_dff (
    .clk    (pclk    ),
    .reset_b(presetn),
    .d      (nstate  ),
    .q      (pstate  )
  );

  
  dff #(
  	.RESET_VALUE(1'b0),
  	.FLOP_WIDTH(1)
  )u_sda(
   .clk     ( pclk     ),
   .reset_b ( presetn  ),
   .d       ( sda_in   ),
   .q       ( sda_prev )
  );


endmodule