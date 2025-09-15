module tb_i2c_all;

  logic pclk = 0;
  logic presetn;
  logic psel;
  logic psel2;
  logic penable;
  logic pwrite;
  logic pready;
  logic pready2;
  logic[7:0]  paddr;
  logic[7:0] pwdata, prdata;
  logic[7:0] prdata2;
  
  
  //Master ports
  logic sda_oe_m;
  logic sda_out_m;

  logic scl_oe_m;
  logic scl_out_m;


  //Slave ports
  logic sda_oe_s;
  logic sda_out_s;

  logic i2c_intrr;
  
  logic sda;
  logic scl;

  int i = 0;
  
  parameter BR = 8'b0000_0000,
            CR = 8'b0000_0001,
            SR = 8'b0000_0010,
            DR = 8'b0000_0011;

  //Clock 
  initial forever begin
  	#5
  	pclk = ~pclk;
  end
  initial forever begin
  	repeat(5000)begin
  		@(posedge pclk);
  	end
  	$finish;
  end
  
  task delay(
    input integer delay_amnt
  );
    repeat(delay_amnt)begin
      @(posedge pclk);
    end
  endtask
  
  task reset_test;
    presetn <= 1'b0;
    psel <= 1'b0;
    psel2 <= 1'b0;
    pwrite <= 1'b0;
    penable <= 1'b0;
    paddr <= 8'b0;
    pwdata <= 8'b0;

    delay(1);
    presetn <= 1'b1;

  endtask

  //write data to the memory 
  task feed_data(
    input logic[7:0] addr,
    input logic[7:0] data
  );
    paddr   <= addr;
    pwrite  <= 1'b1;
    pwdata  <= data;
    psel    <= 1'b1;
    
    delay(1);
    penable <= 1'b1;
    delay(1);
    
    psel    <= 1'b0;
    pwrite  <= 1'b0;
    penable <= 1'b0;
  endtask

  //read data from the memory 
  task read_data(
    input logic[7:0] addr
  );
    paddr   <= addr;
    pwrite  <= 1'b0;
    psel    <= 1'b1;
    
    delay(1);
    penable <= 1'b1;
    delay(1);
    
    psel    <= 1'b0;
    penable <= 1'b0;
  endtask


  //I2C tests
  
  //start
  task start_condition;
    feed_data(CR, 8'b1110_0101);
  endtask

  //Sub address transmit
  task sla_tx_rx (
    input logic[6:0] sl_add,
    input logic wr
  );
    feed_data(DR, {sl_add, wr});
    feed_data(CR, 8'b11000101);
  endtask
  
  //data transmit
  task data_tx(
    input logic[7:0] data
  );
    feed_data(DR, data);
    feed_data(CR, 8'b11000101);
    
  endtask

  //stop condition
  task stop_condition;
    feed_data(CR, 8'b11010101);
  endtask

  task stop_start_condition;
    feed_data(CR, 8'b11110101);
  endtask

  i2c_top DUT(

    .pclk      ( pclk     ),
    .presetn   ( presetn  ),
    .psel      ( psel     ),
    .penable   ( penable  ),
    .pwrite    ( pwrite   ),
    
    .sda_in    ( sda   ),
    .scl_in    ( scl   ),
    
    .paddr     ( paddr    ),
    .pwdata    ( pwdata   ),
    
    .sda_oe    ( sda_oe_m   ),
    .sda_out   ( sda_out_m  ),
    .scl_oe    ( scl_oe_m   ),
    .scl_out   ( scl_out_m  ),
    .i2c_intrr ( i2c_intrr),
    .pready    ( pready   ),
    .prdata    ( prdata   )

  );

  i2c_slave_top DUT2(
   .pclk    ( pclk      ),
   .presetn ( presetn   ),
   .psel    ( psel2     ),
   .penable ( penable   ),
   .pwrite  ( pwrite    ),
   .scl_in  ( scl    ),
   .sda_in  ( sda    ),
   .paddr   ( paddr     ),
   .pwdata  ( pwdata    ),
   
   
   .sda_out ( sda_out_s ),
   .sda_en  ( sda_oe_s  ),
   .pready  ( pready2   ),
   .prdata  ( prdata2   )
  );
  
  //keep the buslines high
  assign sda = (~sda_oe_m | sda_out_m ) & (~sda_oe_s | sda_out_s);
  assign scl = scl_oe_m ? scl_out_m : 1'b1;
  

  initial begin 
    reset_test;
    
    //Slave address
    paddr   <= 8'h08;
    pwrite  <= 1'b1;
    pwdata  <= 8'd9;
    psel2    <= 1'b1;
    
    delay(1);
    penable <= 1'b1;
    delay(1);
    
    psel2    <= 1'b0;
    pwrite  <= 1'b0;
    penable <= 1'b0;

    //Slave TX DATA
    paddr   <= 8'h04;
    pwrite  <= 1'b1;
    pwdata  <= 8'hCD;
    psel2    <= 1'b1;
    
    delay(1);
    penable <= 1'b1;
    delay(1);
    
    psel2    <= 1'b0;
    pwrite  <= 1'b0;
    penable <= 1'b0;



    delay(5);
    start_condition;
    
    delay(15);
    sla_tx_rx(7'h9, 1'b0);
    delay(200);
   // feed_data(CR, 8'b11000101);
    data_tx(8'hAB);
    delay(200);
    stop_condition;
    delay(10);
//    start_condition;
//    delay(50);
//    sla_tx_rx(7'b0101_011, 1'b1);
//    delay(200);
//    data_tx(8'b1010_1010);
//    delay(200);
//    data_tx(8'b0011_1100);
//    delay(200);
//    stop_condition;
    delay(50);
    $finish;
  end
 
endmodule