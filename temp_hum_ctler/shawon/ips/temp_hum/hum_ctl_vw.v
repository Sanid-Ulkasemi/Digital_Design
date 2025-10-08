module hum_ctl_vw(
  input  wire        pclk,
  input  wire        presetn,
  input  wire        inc_hum_pb,
  input  wire        dec_hum_pb,
                      
  input  wire        psel,
  input  wire        pwrite,
  input  wire        penable,
  input  wire [31:0] paddr,
  input  wire [31:0] pwdata,
                      
  input  wire        sda_in,
  input  wire        scl_in,
  input  wire        intpt,
  input  wire        crossed_min_hum,
  input  wire        crossed_max_hum,
  input  wire        default_hum,                      
  output wire [31:0] prdata,
  output wire        pready,
                      
  output wire        sda_out,
  output wire        sda_en,
                      
  output wire        dehumidifier_en,
  output wire        humidifier_en,
  output wire        pslverr
);

  assign pslverr = 1'b0;



  hum_ctl_block u_hum_ctl_block (
    .pclk            ( pclk            ),
    .presetn         ( presetn         ),
    .inc_hum_pb      ( inc_hum_pb      ),
    .dec_hum_pb      ( dec_hum_pb      ),
    
    .psel            ( psel            ),
    .pwrite          ( pwrite          ),
    .penable         ( penable         ),
    .paddr           ( paddr           ),
    .pwdata          ( pwdata          ),
    
    .sda_in          ( sda_in          ),
    .scl_in          ( scl_in          ),
    .intpt           ( intpt           ),
    .crossed_min_hum ( crossed_min_hum ),
    .crossed_max_hum ( crossed_max_hum ),
    .default_hum     ( default_hum     ),
    
    .prdata          ( prdata          ),
    .pready          ( pready         ),
    
    .sda_out         ( sda_out         ),
    .sda_en          ( sda_en          ),
    
    .dehumidifier_en ( dehumidifier_en ),
    .humidifier_en   ( humidifier_en   )
  );
  
  


endmodule