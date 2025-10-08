(* keep_hierarchy = "true" *)module i2c_slave_intfc(

    input  logic      pclk,
    input  logic      presetn,
    input  logic      psel,
    input  logic      penable,
    input  logic      pwrite,
    input  logic      data_load_en,
    input  logic[31:0] paddr,
    input  logic[31:0] pwdata,
    input  logic[7:0] dr_data,
    input logic [7:0] hum_data, ///////////// Humidity Data

    output logic pready,
    output logic[7:0] tx_data,
    output logic[6:0] slave_addr,
    output logic[31:0] prdata,
    output logic high_hum,
    output logic low_hum,
    output logic still_high_hum,
    output logic still_low_hum
    
);
  
  localparam [7:0] RXREG = 8'h00,
                   TXREG = 8'h04,
                   SLVADR= 8'h08,
                   CTL   = 8'h0C;
                   

  logic rd_en;
  logic wr_en;

  apb_fsm u_apb_sub(
    .pclk    ( pclk    ),
    .presetn ( presetn ),
    .psel    ( psel    ),
    .penable ( penable ),
    .pwrite  ( pwrite  ),
    
    .rd_en   ( rd_en   ),
    .wr_en   ( wr_en   ),
    .pready  ( pready  )
  );

  logic[7:0] rcv_reg_q;
  logic[7:0] rcv_reg_d;
  assign rcv_reg_d = data_load_en ? dr_data : rcv_reg_q;

  dff #(
    .RESET_VALUE ( 1'b0      ),
    .FLOP_WIDTH  ( 8         )
  )u_rcv(
    .clk         ( pclk      ),
    .reset_b     ( presetn   ),
    .d           ( rcv_reg_d ),
    .q           ( rcv_reg_q )
  );
   
   assign tx_data[7:0] = hum_data[7:0];
  
  logic[6:0] slv_adr_q;
  logic[6:0] slv_adr_d;
  assign slv_adr_d = (wr_en & (paddr[7:0] ==  SLVADR))? pwdata[6:0] : slv_adr_q;

  dff #(
    .RESET_VALUE ( 7'b0      ),
    .FLOP_WIDTH  ( 7         )
  )u_slv_addr(
    .clk         ( pclk      ),
    .reset_b     ( presetn   ),
    .d           ( slv_adr_d ),
    .q           ( slv_adr_q )
  );
  
  assign slave_addr = slv_adr_q;
  
  //
  
  logic[3:0] d_ctl;
  logic[3:0] ctl_q;
  assign d_ctl[3:0] = (wr_en & (paddr[7:0] ==  CTL))? pwdata[3:0] : ctl_q;

  dff #(
    .RESET_VALUE ( 4'b0      ),
    .FLOP_WIDTH  ( 4         )
  )u_ctl(
    .clk         ( pclk      ),
    .reset_b     ( presetn   ),
    .d           ( d_ctl ),
    .q           ( ctl_q )
  );
  
  assign high_hum = ctl_q[0];
  assign low_hum  = ctl_q[1];
  assign still_high_hum = ctl_q[2];
  assign still_low_hum  = ctl_q[3];
  
  //

 

  logic[31:0] read_data;

  always@(*)begin
    casez(paddr[7:0])
      RXREG   : read_data = {24'b0,rcv_reg_q};
      TXREG   : read_data = {24'b0,tx_data};
      SLVADR  : read_data = {25'b0,slv_adr_q};
      CTL     : read_data = {28'b0,ctl_q};
      default : read_data = 32'bx;
    endcase
  end
  
  assign prdata = rd_en ? read_data : 32'b0;
endmodule