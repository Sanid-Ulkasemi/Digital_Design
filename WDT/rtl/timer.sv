`timescale 1ns/1ps

module timer(

  input logic         pclk,
  input logic         presetn,
  input logic         wr_en,
  input logic         rd_en,
  input logic         stall,
  input logic         int_en,
  input logic         lock,
  input logic         wr_en_icr,
  input logic[31:0]   paddr,
  input logic[31:0]   pwdata,

  output logic[31:0]  cnt_value,
  output logic[31:0]  cnt_load,
  output logic        value_eq0
);

  logic       wr_en_load;
  logic[31:0] value;
  logic[31:0] load;
  logic[31:0] counter_out;

  always@(posedge pclk  or negedge presetn)begin
      if(~presetn)begin
        value <= 32'hFFFF_FFFF;
        load  <= 32'hFFFF_FFFF;
      end

      else begin
        value <= wr_en_load & ~lock ? pwdata : (value_eq0 | wr_en_icr ? load : counter_out);
        load  <= wr_en_load & ~lock ? pwdata : load;
      end
  end


  assign cnt_value = value;
  assign cnt_load  = load;
  assign wr_en_load  = wr_en & paddr == 12'h0;
  assign counter_out  = stall ? value : value - int_en;
  assign value_eq0       = ~(|value);

endmodule