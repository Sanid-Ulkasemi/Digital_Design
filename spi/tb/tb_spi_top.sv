module tb_spi_top;
  //signals
  logic        pclk;
  logic        presetn;
  logic        psel;
  logic        pwrite;
  logic        penable;
  logic        miso_pad_i;
  logic [31:0] paddr;
  logic [31:0] pwdata;
  
  logic        pready;
  logic        sclk_pad_o;
  logic        mosi_pad_o;
  logic        interrupt_pad_o;
  logic        ss_pad_o;
  logic [31:0] prdata;
  
  ///////////////////////////////////////////////////
  
//  logic [7:0]  send_data;
//  logic        ie;
//  logic        lsb;
//  logic [15:0] divider;
  logic [1:0] mode;
  assign mode = {tb_spi_top.DUT.u_reg.cpol, tb_spi_top.DUT.u_reg.cpha};
  ///////////////////////////////////////////////////
    
  
  parameter MODE_0  = 2'b00,
            MODE_1  = 2'b01,
            MODE_2  = 2'b10,
            MODE_3  = 2'b11,
            CTRL    = 32'h10,
            DIVIDER = 32'h14,
            TXRX    = 32'h00;
     
  /////////////////////////                DUT connection                   ////////////////////////
  
  spi_top DUT (
  
    .pclk            ( pclk            ),
    .presetn         ( presetn         ),
    .psel            ( psel            ),
    .pwrite          ( pwrite          ),
    .penable         ( penable         ),
    .miso_pad_i      ( miso_pad_i      ),
    .paddr           ( paddr           ),
    .pwdata          ( pwdata          ),
    .pready          ( pready          ),
    .sclk_pad_o      ( sclk_pad_o      ),
    .mosi_pad_o      ( mosi_pad_o      ),
    .interrupt_pad_o ( interrupt_pad_o ),
    .ss_pad_o        ( ss_pad_o        ),
    .prdata          ( prdata          )
    
  );
  
  /////////////////////////////////////////////////////////////////////////////////////////////////
  
  ///////////////////////////               Clock generation             ////////////////////
  
  initial begin
    pclk = 0;
    forever #5 pclk = ~pclk; 
  end
  
  /////////////////////////////////////////////////////////////////////////////////////////
  
  initial begin
  
    //reset-------------------------------
    reset;
    
    delay(5);
    
  
  
   ///////////////////////////////////   Manual Test Run  /////////////////////////////////////////////
   
    start_op(16'd0,  8'b00000000, 1'b1, 1'b0, MODE_0, 3'b000); // lsb = 0 // char_len = 000
    
    start_op(16'd7,  8'b00000000, 1'b0, 1'b1, MODE_1, 3'b011); // lsb = 1 // char_len = 011
    
    start_op(16'd15, 8'b00000000, 1'b1, 1'b0, MODE_2, 3'b110); // lsb = 0 // char_len = 110

    start_op(16'd20, 8'b00000000, 1'b1, 1'b1, MODE_3, 3'b010); // lsb = 1 // char_len = 010  
    
  //////////////////////////////////////////////////////////////////////////////////////////////////////
  
  
    delay(100);
  
  
  ////////////////////////////////   Try writing while a transfer ongoing  ///////////////////////////////////  
  
    write_to_reg(DIVIDER, {16'b0,16'd5});
    write_to_reg(TXRX, 8'b11001100);
    write_to_reg(CTRL, { 19'b0, 1'b1, 1'b1, 2'b00 , 1'b0, 5'b0, 3'd6});   
    write_to_reg(CTRL, { 19'b0, 1'b1, 1'b1, 2'b00 , 1'b1, 5'b0, 3'd6});  
  
    delay(10);
    
    write_to_reg(CTRL, { 19'b0, 1'b1, 1'b1, 2'b00 , 1'b0, 5'b0, 3'd6});   
    write_to_reg(TXRX, 8'b11111111);
    write_to_reg(DIVIDER, {16'b0, 16'd7}); 
  
    @(posedge ss_pad_o);
    delay(5);
    read_from_reg(TXRX);   
    
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////    
   
   
    delay(100);
    
   //////////////////////////////////    lsb = 1 random test     ////////////////////////////////////////////
   
    for(int i=0; i<5 ;i++) begin
      start_op($urandom_range(0, 100),  $urandom_range(0, 8'd255 ), 1'b1, 1'b1, $urandom_range(0,3) , $urandom_range(0,7));  
      delay(5);
    end
    
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////
   
   
   delay(100);
   
   
   /////////////////////////////////    lsb = 0 random test     //////////////////////////////////////////////
   
    for(int i=0; i<5 ;i++) begin
      start_op($urandom_range(0, 100),  $urandom_range(0, 8'd255 ), 1'b1, 1'b0, $urandom_range(0,3) , $urandom_range(0,7));  // lsb = 0 random test
      delay(5);
    end
    
   /////////////////////////////////////////////////////////////////////////////////////////////////////////
   
    delay(50);
    
    $finish;   
     
  end
  
  task reset;
    presetn    = 0;
    psel       = 0;
    penable    = 0;
    pwrite     = 0;
    paddr      = 32'b0;
    pwdata     = 32'b0;
    miso_pad_i = 1;
    delay(2); 
    presetn = 1;
  endtask
  
  //writing register  through apb
  task write_to_reg(logic [31:0] addr, logic [31:0] data);
    begin
      delay(1);
      psel = 1;
      penable = 0;
      pwrite = 1;
      paddr = addr;
      pwdata = data;

      delay(1);
      penable = 1;

      delay(1);
      
      // Return to IDLE
      psel = 0;
      penable = 0;
      pwrite = 0;
    end
  endtask
  
  //reading from register through apb 
  task read_from_reg(logic [31:0] addr);
    begin
      delay(1);
      psel = 1;
      penable = 0;
      pwrite = 0;
      paddr = addr;

      delay(1);
      penable = 1;

      delay(1);
    
      // Return to IDLE
      psel = 0;
      penable = 0;
      pwrite = 0;
    end
  endtask
  
  // clock cycle delay
  task delay(int clk_cycle);
    repeat(clk_cycle) @(posedge pclk);
  endtask

  // Operation
  task start_op(logic[15:0]divider, logic[7:0]send_data, logic ie,logic lsb,logic [1:0] md,logic [2:0]char_len);
  
    write_to_reg(DIVIDER, {{16{1'b0}}, divider});
    write_to_reg(TXRX, send_data);
    write_to_reg(CTRL, { 19'b0, ie, lsb, md , 1'b0, 5'b0, char_len});   
    write_to_reg(CTRL, { 19'b0, ie, lsb, md , 1'b1, 5'b0, char_len});  
    @(posedge ss_pad_o);
    delay(5);
    read_from_reg(TXRX);   
    delay(10);
    
  endtask
  
  

endmodule