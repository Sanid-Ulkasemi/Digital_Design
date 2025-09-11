`timescale 1ns/1ps

module wdt_top(
  
  input logic         pclk,
  input logic         presetn,
  input logic         psel,
  input logic         pwrite,
  input logic         penable,
  input logic[31:0]   paddr,
  input logic[31:0]   pwdata,
  
  output logic[31:0]  prdata,
  output logic        pready,
  output logic        wdt_reset,
  output logic        wdt_interrupt
);

  logic wr_en;
  logic rd_en;
  logic stall;
  logic lock;
  logic resen;
  logic test;
  logic int_en;
  logic wr_en_icr;
  logic test_reset;
  logic[31:0] cnt_value;
  logic[31:0] cnt_load;

  apb_fsm u_apb(
    .pclk(pclk),
    .presetn(presetn),
    .psel(psel),
    .pwrite(pwrite),
    .penable(penable),

    .wr_en(wr_en),
    .rd_en(rd_en),
    .pready(pready)
  );
  
  interr_gen_fsm u_fsm(
    .pclk(pclk),
    .presetn(presetn),
    .resen(resen),
    .value_eq0(value_eq0),
    .test(test),
    .wr_en_icr(wr_en_icr),
    .int_en(int_en),

    .wdt_reset(wdt_reset),
    .wdt_interrupt(wdt_interrupt), 
    .test_reset(test_reset)
  );


  reg_bank u_reg_bank(

    .pclk(pclk),
    .presetn(presetn),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .value_eq0(value_eq0),
    .test_reset(test_reset),
    .paddr(paddr),
    .pwdata(pwdata),
    .cnt_value(cnt_value),
    .cnt_load(cnt_load),


    .prdata(prdata),
    .stall(stall),
    .lock(lock),
    .int_en(int_en),
    .test(test),
    .resen(resen),
    .wr_en_icr(wr_en_icr)
  );
  
  timer u_timer(
    .pclk(pclk),
    .presetn(presetn),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .stall(stall),
    .int_en(int_en),
    .lock(lock),
    .wr_en_icr(wr_en_icr),
    .paddr(paddr),
    .pwdata(pwdata),

    .cnt_value(cnt_value),
    .cnt_load(cnt_load),
    .value_eq0(value_eq0)
  );

endmodule