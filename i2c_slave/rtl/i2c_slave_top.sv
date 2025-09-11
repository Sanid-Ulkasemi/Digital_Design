module i2c_slave_top(
	input  logic      pclk,
    input  logic      presetn,
    input  logic      psel,
    input  logic      penable,
    input  logic      pwrite,
    input  logic      scl_in,
    input  logic      sda_in,
    input  logic[7:0] paddr,
    input  logic[31:0] pwdata,
    

    output logic sda_out,
    output logic sda_en,
    output logic pready,
    output logic[31:0] prdata,
    
    //Debug
    output logic[2:0] state,
    output logic[7:0] sr,
    output logic comp
);

  logic data_load_en;
  logic[7:0] tx_data;
  logic[6:0] slave_addr;
  logic[7:0] dr_data;

  i2c_slave_intfc u_intf(
   .pclk         ( pclk         ),
   .presetn      ( presetn      ),
   .psel         ( psel         ),
   .penable      ( penable      ),
   .pwrite       ( pwrite       ),
   .data_load_en ( data_load_en ),
   .paddr        ( paddr        ),
   .pwdata       ( pwdata       ),
   .dr_data      ( dr_data      ),
   
   .pready       ( pready       ),
   .tx_data      ( tx_data      ),
   .slave_addr   ( slave_addr   ),
   .prdata       ( prdata       )
  );

  
  logic ack_cycle;
  logic dack_cycle;
  logic read;
  logic shift_load_en;
  logic shift_en;
  logic comp_match;
  

  shift_register_block u_shift(
   .pclk          ( pclk          ),
   .presetn       ( presetn       ),
   .shift_load_en ( shift_load_en ),
   .ack_cycle     ( ack_cycle     ),
   .dack_cycle    ( dack_cycle    ),
   .tx_data       ( tx_data       ),
   .slave_addr    ( slave_addr    ),
   .sda_in        ( sda_in        ),
   .shift_en      ( shift_en      ),
   .comp_match    ( comp_match    ),
   
   .dr_data       ( dr_data       ),
   .read          ( read          ),
   .sda_out       ( sda_out       )
  );

  
  logic counter_en;
  logic counter_clr;
  logic tx_edge;
  logic rx_edge;
  logic tx_eq8;

  i2c_slave_fsm u_fsm(
   .pclk          ( pclk          ),
   .presetn       ( presetn       ),
   .rx_edge       ( rx_edge       ),
   .tx_edge       ( tx_edge       ),
   .scl_in        ( scl_in        ),
   .sda_in        ( sda_in        ),
   .read          ( read          ),
   .tx_eq8        ( tx_eq8        ),
   .comp_match    ( comp_match    ),
   .state         ( state         ),
   
   
   .sda_en        ( sda_en        ),
   .counter_en    ( counter_en    ),
   .counter_clr   ( counter_clr   ),
   .ack_cycle     ( ack_cycle     ),
   .dack_cycle    ( dack_cycle    ),
   .shift_en      ( shift_en      ),
   .shift_load_en ( shift_load_en ),
   .data_load_en  ( data_load_en  )
  );

  i2c_slave_cnt_cmp u_cnt_cmp(
   .pclk        ( pclk        ),
   .presetn     ( presetn     ),
   .counter_en  ( counter_en  ),
   .counter_clr ( counter_clr ),
   
   .tx_eq8      ( tx_eq8      )
  );

  edge_edtector u_edge_edtector (
  .pclk    ( pclk    ),
  .presetn ( presetn ),
  .scl_in  ( scl_in  ),
  
  .tx_edge ( tx_edge ),
  .rx_edge ( rx_edge )
  );
  
  //Debug
  assign comp = comp_match;
  assign sr   = dr_data;
  
endmodule