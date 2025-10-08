module spi_sub_apb_intf (

  input  logic        pclk,
  input  logic        presetn,
  input  logic        pwrite,
  input  logic        psel,
  input  logic        penable,
  input  logic [31:0] paddr,
  input  logic [31:0] pwdata,
  input logic  [7:0]  temp_data,
  input logic   [7:0] sub_rx,
  input logic         rx_load,
  
  input logic         fan_on, //debug
  input logic         heater_on, //debug
  input logic  [1:0]  state, //debug
                      
  output logic        pready,
  output logic [31:0] prdata,
  output logic        cpha,
  output logic        cpol,
  output logic        se,
  output logic        high_temp,
  output logic        low_temp,
  output logic        still_high_temp,
  output logic        still_low_temp,
  output logic [7:0]  sub_tx
  
);
  
  localparam [7:0] TX     = 8'h00,
                   RX     = 8'h04,
                   CTL    = 8'h08,
                   STATUS = 8'h0C; 

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
  
  // RX
  logic [7:0] d_rxd;
  logic [7:0] rxd;
  assign d_rxd = rx_load ? sub_rx : rxd;
  dff #( 
    .RESET_VALUE( 'b0   ),
    .FLOP_WIDTH ( 8      )
  )u_rxd(
    .clk        ( pclk       ),
    .reset_b    ( presetn    ),
    .d          ( d_rxd ),
    .q          ( rxd   )
  );
  //--------------------------------------
  
  
  
  //TX
  assign sub_tx[7:0] = temp_data[7:0];
  //------------------------------------
  
  
  //CTL
  logic ctl_wr_en ;
  assign ctl_wr_en = wr_en & (paddr[7:0] == CTL);

  logic ctl_rd_en ;
  assign ctl_rd_en = rd_en & (paddr[7:0] == CTL);

  logic [6:0]ctl_d;
  logic [6:0]ctl_q;

  assign ctl_d = ctl_wr_en ? pwdata[6:0] : ctl_q;

  dff #(
    .RESET_VALUE( 'b0   ),
    .FLOP_WIDTH ( 7      )
  )u_ctl(
    .clk        ( pclk       ),
    .reset_b    ( presetn    ),
    .d          ( ctl_d ),
    .q          ( ctl_q   )
  );
  
  logic [3:0] st_d;
  assign st_d = {fan_on,heater_on,state[1:0]};
  logic [3:0] st_q;
  
  dff #(
    .RESET_VALUE( 'b0   ),
    .FLOP_WIDTH ( 4      )
  )u_status(
    .clk        ( pclk       ),
    .reset_b    ( presetn    ),
    .d          ( st_d       ),
    .q          ( st_q       )
  );


  assign se   = ctl_q [0];
  assign cpol = ctl_q [1];
  assign cpha = ctl_q [2];
  
  assign high_temp = ctl_q[3];
  assign low_temp = ctl_q[4];
  assign still_high_temp = ctl_q[5];
  assign still_low_temp = ctl_q[6];
  //-------------------------------------------------------
  
  
  
  //READ
  logic[31:0] read_data;

  always@(*)begin
    casez(paddr[7:0])
      TX   : read_data = {24'b0,sub_tx};
      RX   : read_data = {24'b0,rxd};
      CTL  : read_data = {25'b0,ctl_q};
      STATUS : read_data = {28'b0,st_q};
      default : read_data = 32'bx;
    endcase
  end
  
  assign prdata = rd_en ? read_data : 32'b0;
  

endmodule