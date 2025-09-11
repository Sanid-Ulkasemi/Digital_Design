`timescale 1ns/1ps

module reg_bank(
  input logic         pclk,
  input logic         presetn,
  input logic         wr_en,
  input logic         rd_en,
  input logic         value_eq0,
  input logic         test_reset,
  input logic[31:0]   paddr,
  input logic[31:0]   pwdata,
  input logic[31:0]   cnt_value,
  input logic[31:0]   cnt_load,

  output logic        stall,
  output logic        lock,
  output logic        int_en,
  output logic        test,
  output logic        resen,
  output logic        wr_en_icr,
  output logic[31:0]  prdata

);

  logic lockreg;
  logic[31:0] read_data_raw;
  logic[1:0] ctl, test_reg, int_caus;
  logic ris, mis;
  
  logic wr_en_ctl;
  logic wr_en_test_reg;
  logic wr_en_lock;
  
  always@(posedge pclk  or negedge presetn)begin
      if(~presetn)begin
      //resetting values
        lockreg   <=  1'b0;
        ctl       <=  2'b0;
        test_reg  <=  2'b0;
        ris       <=  1'b0;
        mis       <=  1'b0;
        int_caus  <=  2'b0;
      end

      else begin
        ctl       <= wr_en_ctl ? (ctl[0] ? {pwdata[1], ctl[0]} : pwdata[1:0]) : ctl;
        test_reg  <= wr_en_test_reg ? (lock ? {test_reg[1], pwdata[0]} : {pwdata[8], pwdata[0]}) : test_reg; 
        lockreg   <= wr_en_lock? ~(pwdata == 32'h1ACC_E551) : lockreg;
        ris       <= wr_en_icr ? 1'b0   : ris | value_eq0;
        mis       <= wr_en_icr ? 1'b0   : mis | (value_eq0 & ctl[0]);
        int_caus  <= wr_en_icr ? 2'b0  : {test_reset, int_caus[0] | value_eq0};
      end
  end


  always@(*)begin
    casez(paddr[11:0])
      12'h0   : read_data_raw  = cnt_load;
      12'h4   : read_data_raw  = cnt_value;
      12'h8   : read_data_raw  = {30'b0, ctl};
      12'hC   : read_data_raw  = 32'b0;
      12'h10  : read_data_raw  = {31'b0, ris};
      12'h14  : read_data_raw  = {31'b0, mis};
      12'h418 : read_data_raw  = {23'b0, test_reg[1], 7'b0, test_reg[0]};
      12'h41C : read_data_raw  = {30'b0, int_caus};
      12'hC00 : read_data_raw  = {31'b0, lock};

      default: read_data_raw = 32'bx;
    endcase
  end  

  assign lock   = lockreg;
  assign int_en = ctl[0];
  assign stall  = test_reg[1];
  assign test   = test_reg[0];
  assign resen  = ctl[1];

  assign prdata = rd_en ? read_data_raw : 32'b0;
  assign wr_en_ctl  = wr_en & paddr == 12'h8 & ~lock;
  assign wr_en_icr  = wr_en & paddr == 12'hC & ~lock;
  assign wr_en_test_reg = wr_en & paddr == 12'h418 ;
  assign wr_en_lock = wr_en & paddr == 12'hC00 ;

endmodule