module hum_storage (
  input  logic         pclk,
  input  logic         presetn,
  input  logic [7:0]  real_time_hum,
  input  logic         pwrite,
  input  logic         penable,
  input  logic         psel,
  input  logic [31:0]  paddr,
  input  logic [31:0]  pwdata,
  input  logic         sda_in,
  input  logic         scl_in,
  input  logic         intpt,
                       
  output logic         pready,
  output logic [31:0]  prdata,
  output logic         sda_out,
  output logic         sda_en
);

  logic delayed_intpt;

  dff #(
    .DFF_WIDTH(1)
  ) u_dff_intpt (
    .clk     ( pclk          ),
    .reset_b ( presetn       ),
    .d       ( intpt         ),
    .q       ( delayed_intpt )
  );

   logic intpt_posedge;

  assign intpt_posedge = intpt & (~ delayed_intpt);

  i2c_slave_top u_i2c_slave_top (
    .pclk          ( pclk          ),
    .presetn       ( presetn       ),
    .psel          ( psel          ),
    .penable       ( penable       ),
    .pwrite        ( pwrite        ),
    .scl_in        ( scl_in        ),
    .sda_in        ( sda_in        ),
    .paddr         ( paddr         ),
    .pwdata        ( pwdata        ),
    
    
    .intpt_posedge ( intpt_posedge ),
    .real_time_hum ( real_time_hum ),
    
    
    .sda_out       ( sda_out       ),
    .sda_en        ( sda_en        ),
    .pready        ( pready        ),
    .prdata        ( prdata        )
);

endmodule