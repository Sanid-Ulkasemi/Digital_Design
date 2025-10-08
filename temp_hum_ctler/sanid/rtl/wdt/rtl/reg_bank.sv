module reg_bank (

  input logic         pclk,
  input logic         presetn,
  input logic         wr_en,
  input logic         rd_en,
  input logic [31:0]  pwdata,
  input logic [31:0]  paddr,
  input logic         count_en,
  input logic         load_en,
  input logic         interrupt,
  input logic         cause_rst,
  
  output logic        inten,
  output logic        resen,
  output logic        stall,
  output logic        test_en,
  output logic        int_clr,     
  output logic [31:0] prdata,
  output logic [31:0] wdtvalue,
  output logic        interrupt_o
  
);
  
  logic access;
  logic unlock;
 
  
  //-------------------------register values----------------------------------
  logic [31:0] wdtload; 
  logic [2:0]  ctl;
  logic [1:0]  test;
  logic        wdtris;
  logic        wdtmis; // my final interrupt output;

  
  
 
  //----------------------------wr_en signals-------------------------------
  
  logic wr_en_ctl;
  logic wr_en_test; 
  logic wr_en_lock;
  
  assign wr_en_load = wr_en & ( paddr[11:0] == 12'h0   ) & unlock;
  assign wr_en_ctl  = wr_en & ( paddr[11:0] == 12'h8   ) & unlock;
  assign wr_en_test = wr_en & ( paddr[11:0] == 12'h418 ) ; 
  assign wr_en_lock = wr_en & ( paddr[11:0] == 12'hC00 ) ; 
  

  //---------------------------------bits from registers------------------------------
  
  logic inttype;
  logic caus_intr;
  logic caus_reset;
  
  assign inten   = ctl[0];
  assign resen   = ctl[1];
  assign inttype = ctl[2];
  assign test_en = test[0];
  assign stall   = test[1];

  //-------------------------------------d pin logics----------------------------------  
  
  logic [31:0] d_wdtload;//
  logic [2:0]  d_ctl;
  logic [1:0]  d_test;
  logic        d_unlock;    
  
  assign d_wdtload [31:0]  =  ( wr_en_load ? pwdata[31:0] : wdtload[31:0] ) ;  
  assign d_ctl     [2:0]   =  (wr_en_ctl  ? (ctl[0] ? {pwdata[2],pwdata[1],ctl[0]} : pwdata[2:0]) : ctl[2:0]);    
  assign d_test    [1:0]   =  (wr_en_test ? ( unlock ? {pwdata[8], pwdata[0]} : {test[1], pwdata[0]} ) : test[1:0]);
  assign d_unlock = wr_en_lock ? access : unlock;
  //------------------------------------ LOAD ---------------------------------------
  
  dff #(
    .FLOP_WIDTH ( 32    ),
    .RESET_VALUE( 32'h1DCD6500 )
  )u_load(  
    .clk     ( pclk       ), 
    .reset_b ( presetn    ),
    .d       ( d_wdtload  ),
    .q       ( wdtload    )
  );
  
   //--------------------------------------------------------------------------------   
  
   //------------------------------------ VALUE  --------------------------------------
   
   logic  ld_en ;
   assign  ld_en = load_en | wr_en_load ;
   
   logic [31:0] ld_data;
   assign ld_data[31:0] = ( wr_en_load ? pwdata[31:0] : ( load_en ? wdtload : wdtvalue ));
    
   counter_ld #(
    .RESET_VALUE   ( 32'h1DCD6500 ),
    .COUNTER_WIDTH ( 32    )
  ) u_value (
    .clk       ( pclk        ),
    .reset_b   ( presetn     ),
    .clear     ( 1'b0        ),
    .load      ( ld_en       ),
    .en        ( count_en    ), 
    .load_data ( ld_data     ),
    .count     ( wdtvalue    )
  ); 
   
   //------------------------------------------------------------------------------
  
   //------------------------------------ CTL ---------------------------------------
  
                   
    dff #(
    .FLOP_WIDTH ( 3    ),
    .RESET_VALUE( 3'h0 )
  )u_ctl(  
    .clk     ( pclk     ),
    .reset_b ( presetn  ),
    .d       ( d_ctl    ),
    .q       ( ctl      )
  );   
  
   //------------------------------------------------------------------------------
  
  
  //----------------------------------- ICR ---------------------------------------
  
  assign int_clr  = wr_en & ( paddr[11:0] == 12'hC   ) & unlock;
  
  //------------------------------------------------------------------------------
  
  //----------------------------------- RIS ---------------------------------------
  
   assign wdtris          = interrupt;
   
  //------------------------------------------------------------------------------
  
  //----------------------------------- MIS ---------------------------------------
  
   assign wdtmis          = interrupt & inten;  
   assign interrupt_o     = wdtmis;   
   
  //------------------------------------------------------------------------------
  
  //----------------------------------- TEST ---------------------------------------
  
  dff #(
    .FLOP_WIDTH ( 2     ),
    .RESET_VALUE( 2'b00 )
  )u_test(  
    .clk     ( pclk     ),
    .reset_b ( presetn  ),
    .d       ( d_test   ),
    .q       ( test     )
  );   
  //------------------------------------------------------------------------------
  
  //----------------------------------- INT_CAUS ---------------------------------------
  logic d_caus_reset;
  assign d_caus_reset =  (caus_reset | cause_rst) & test_en;
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b0 )
  )u_intcaus(  
    .clk     ( pclk         ),
    .reset_b ( presetn      ),
    .d       ( d_caus_reset ),
    .q       ( caus_reset   )
  );   
  assign caus_intr  = interrupt; 

  //------------------------------------------------------------------------------
  
  //----------------------------------- lock ---------------------------------------
  
 
  assign access = (pwdata == 32'h1ACCE551);
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 1'b1 )
  )u_lock(  
    .clk     ( pclk      ),
    .reset_b ( presetn   ),
    .d       ( d_unlock    ),
    .q       ( unlock      )
  );   
  
  //------------------------------------------------------------------------------
  
  //----------------------------------- READ -------------------------------------
  
  
  always @(*) begin
    if(rd_en) begin
      casez(paddr[11:0]) 
        12'h0    : prdata = wdtload;
        12'h4    : prdata = wdtvalue;
        12'h8    : prdata = {29'b0,ctl};
        12'h10   : prdata = {31'b0,wdtris};
        12'h14   : prdata = {31'b0,wdtmis};
        12'h418  : prdata = {23'b0,stall,7'b0,test_en};
        12'h41C  : prdata = {30'b0,caus_reset,caus_intr};
        12'hC00  : prdata = {31'b0,~unlock};
        default  : prdata = 32'bx;
      endcase
    end
    else begin
      prdata = 32'h0;
    end
  end
  

endmodule