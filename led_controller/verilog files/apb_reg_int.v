`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2025 11:44:49 AM
// Design Name: 
// Module Name: apb_reg_int
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module apb_reg_led(
  input  wire        pclk,
  input  wire        presetn,
  input  wire        psel,
  input  wire        pwrite,
  input  wire        penable,
  input  wire [31:0] pwdata,
  input  wire [31:0] paddr,
  output wire [31:0] prdata,
  output wire        led0,
  output wire        led1,
  output wire        led2,
  output wire        led3,
  output wire        pslverr, 
  output wire        pready
  );
    
    wire rd_en;
    wire wr_en;
    
    wire wr_00;
    wire wr_04;
    wire wr_08;
    wire wr_0C;
    
    wire [3:0] reg00_d;
    wire [3:0] reg00_q;
    wire [3:0] reg04_d;
    wire [3:0] reg04_q;
    wire [3:0] reg08_d;
    wire [3:0] reg08_q;
    wire [3:0] reg0C_d;
    wire [3:0] reg0C_q;
    reg  [3:0] rdata;
    
    
  parameter STATE_WIDTH = 1;
                              
  parameter IDLE  = 1'b0,
            SETUP = 1'b1;
  
  wire [STATE_WIDTH-1:0] pstate;
  reg  [STATE_WIDTH-1:0]  nstate;
                    

  always @(*) begin : NSL
    casez(pstate)
      IDLE    : nstate[STATE_WIDTH-1:0] = (psel)? SETUP : IDLE ;
      SETUP   : nstate[STATE_WIDTH-1:0] = (psel)? SETUP : IDLE ;
      default : nstate =  1'bx;
    endcase
  end
  
  assign nstate_in = nstate;
  
  assign wr_en  = (pstate == SETUP) & (pwrite & penable & psel) ;
  assign rd_en  = (pstate == SETUP) & (~pwrite & penable & psel) ;
  assign pready = (pstate == SETUP) | (pstate == IDLE);
  assign pslverr= 1'b0;
  
  dff # (.FLOP_WIDTH(STATE_WIDTH),
         .RESET_VALUE(IDLE)
  
  ) u_psr (
    
    .clk    ( pclk    ),
    .reset  ( presetn ),
    .d      ( nstate  ),
    .q      ( pstate  )
  );
    
  assign wr_00 = (paddr == 8'h00) & wr_en;
  assign wr_04 = (paddr == 8'h04) & wr_en;
  assign wr_08 = (paddr == 8'h08) & wr_en;
  assign wr_0C = (paddr == 8'h0C) & wr_en;    
    
//.....................Register..................................................//    
  assign reg00_d = wr_00? pwdata[3:0] : reg00_q ;
  dff # (.FLOP_WIDTH(4),
         .RESET_VALUE(0)
  
  ) u_reg00 (
    
    .clk(pclk),
    .reset(presetn),
    .d(reg00_d),
    .q(reg00_q)
  );
  
  assign reg04_d = wr_04? pwdata[3:0] : reg04_q ;
  dff # (.FLOP_WIDTH(4),
         .RESET_VALUE(0)
  
  ) u_reg04 (
    
    .clk(pclk),
    .reset(presetn),
    .d(reg04_d),
    .q(reg04_q)
  );
  
  assign reg08_d = wr_08? pwdata[3:0] : reg08_q ;
  dff # (.FLOP_WIDTH(4),
         .RESET_VALUE(0)
  
  ) u_reg08 (
    
    .clk(pclk),
    .reset(presetn),
    .d(reg08_d),
    .q(reg08_q)
  );
  
  assign reg0C_d = wr_0C? pwdata[3:0] : reg0C_q ;
  dff # (.FLOP_WIDTH(4),
         .RESET_VALUE(0)
  
  ) u_reg0C (
    
    .clk(pclk),
    .reset(presetn),
    .d(reg0C_d),
    .q(reg0C_q)
  );
//....................................................................................//
  
  always @(*) begin
    case(paddr[7:0])
        8'h00 : rdata = reg00_q;
        8'h04 : rdata = reg04_q;
        8'h08 : rdata = reg08_q;
        8'h0C : rdata = reg0C_q;
        default  : rdata = 4'bx ;    
    endcase
  end
  
  assign prdata = rd_en? {28'b0,rdata} : 32'b0 ;
  
  assign led0 = reg00_q[0];
  assign led1 = reg04_q[0];
  assign led2 = reg08_q[0];
  assign led3 = reg0C_q[0];
          
endmodule
  
