module i2c_slave_intfc(
  input  logic      pclk,
  input  logic      presetn,
  input  logic      psel,
  input  logic      penable,
  input  logic      pwrite,
  input  logic      data_load_en,
  input  logic[31:0] paddr,
  input  logic[31:0] pwdata,
  input  logic[7:0] dr_data,

  // extra port to update data register
  input  logic       intpt_posedge,
  input  logic [7:0] real_time_hum,

  output logic pready,
  output logic[7:0] tx_data,
  output logic[6:0] slave_addr,
  output logic[31:0] prdata
);
  
  localparam [11:0] RXREG = 12'hC08,
                    TXREG = 12'hC0C,
                    SLVADR= 12'hC10;

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
 //   .RESET_VALUE ( 1'b0      ),
    .DFF_WIDTH  ( 8         )
  )u_rcv(
    .clk         ( pclk      ),
    .reset_b     ( presetn   ),
    .d           ( rcv_reg_d ),
    .q           ( rcv_reg_q )
  );
   
  logic[7:0] tx_reg_q;
  logic[7:0] tx_reg_d;
  //assign tx_reg_d = (wr_en & paddr[7:0] ==  TXREG)? pwdata[7:0] : tx_reg_q;
  assign tx_reg_d = intpt_posedge ? real_time_hum : tx_reg_q;

  dff #(
 //   .RESET_VALUE ( 1'b0      ),
    .DFF_WIDTH  ( 8         )
  )u_tx(
    .clk         ( pclk      ),
    .reset_b     ( presetn   ),
    .d           ( tx_reg_d ),
    .q           ( tx_reg_q )
  );

  assign tx_data = tx_reg_q;
  
  logic[6:0] slv_adr_q;
  logic[6:0] slv_adr_d;
  assign slv_adr_d = (wr_en & paddr[11:0] ==  SLVADR)? pwdata[6:0] : slv_adr_q;

  dff #(
 //   .RESET_VALUE ( 1'b0      ),
    .DFF_WIDTH  ( 7         )
  )u_slv_addr(
    .clk         ( pclk      ),
    .reset_b     ( presetn   ),
    .d           ( slv_adr_d ),
    .q           ( slv_adr_q )
  );
  
  assign slave_addr = slv_adr_q;

  logic[31:0] read_data;

  always@(*)begin
    casez(paddr[7:0])
      RXREG   : read_data = rcv_reg_q;
      TXREG   : read_data = tx_reg_q;
      SLVADR  : read_data = slv_adr_q;
      default : read_data = 32'b0;
    endcase
  end
  
  assign prdata = rd_en ? read_data : 32'b0;
endmodule