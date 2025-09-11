`timescale 1ns/1ps

module interr_gen_fsm(
  input logic         pclk,
  input logic         presetn,
  input logic         resen,
  input logic         value_eq0,
  input logic         test,
  input logic         wr_en_icr,
  input logic         int_en,

  output logic        wdt_reset,
  output logic        wdt_interrupt,
  output logic        test_reset
);

  parameter IDLE       = 2'b00; 
  parameter INTERRUPT  = 2'b01;
  parameter RESET      = 2'b10;
  

  logic[1:0] nstate, pstate;

  dff #(
    .RESET_VALUE(1'b0),
    .FLOP_WIDTH (2)
  )u_psr(
    .clk(pclk),
    .reset_b(presetn),
    .d(nstate),
    .q(pstate)
  );

    
  always@(*)begin
    
    casez(pstate)
      IDLE      : nstate = value_eq0 & int_en ? INTERRUPT : IDLE;
      INTERRUPT : nstate = value_eq0 & resen ? RESET : (wr_en_icr ? IDLE : INTERRUPT);
      RESET     : nstate = wr_en_icr & test ? IDLE : RESET; 
    
      default : nstate = 2'bx;
    endcase

  end

  assign wdt_interrupt  = pstate == INTERRUPT | pstate == RESET;
  assign wdt_reset      = pstate == RESET & resen & ~test;
  assign test_reset     = test & ((pstate == RESET) | (pstate == INTERRUPT & value_eq0));

endmodule