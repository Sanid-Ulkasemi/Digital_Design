`timescale 1ns/1ps

module dff #(
	parameter RESET_VALUE = 1'b0,
	parameter	FLOP_WIDTH = 1
)(
	input logic 										clk,
	input logic 										reset_b,
	input logic[FLOP_WIDTH-1 : 0] 	d,
	
	output logic[FLOP_WIDTH-1 : 0]	q 
);


	always@(posedge clk or negedge reset_b)begin

		if(~reset_b )begin
			q[FLOP_WIDTH-1 : 0] <= {FLOP_WIDTH{RESET_VALUE}};
		end
		
		else begin
			q[FLOP_WIDTH-1 : 0] <= d[FLOP_WIDTH-1 : 0];
		end
	end

endmodule

module tff #(
	parameter RESET_VALUE = 1'b0,
	parameter FLOP_WIDTH = 1
)(
	input logic clk,
	input logic reset_b,
	input logic t,
	output logic[FLOP_WIDTH-1 : 0] q
);
	
	always@(posedge clk or negedge reset_b)begin
		if(~reset_b) begin
			q[FLOP_WIDTH-1:0] <= {FLOP_WIDTH{RESET_VALUE}};
		end
		else begin
			q[FLOP_WIDTH-1:0] <= q ^ {FLOP_WIDTH{t}};
		end
	end

endmodule

module tff_clr #(
	parameter RESET_VALUE = 1'b0,
	parameter FLOP_WIDTH = 1,
	parameter CLEAR_VALUE = 1'b0
)(
	input logic clk,
	input logic reset_b,
	input logic t,
	input logic clr,
	
	output logic[FLOP_WIDTH-1 : 0] q
);
	
	always@(posedge clk or negedge reset_b)begin
		if(~reset_b) begin
			q[FLOP_WIDTH-1:0] <= {FLOP_WIDTH{RESET_VALUE}};
		end
		else begin
			q[FLOP_WIDTH-1:0] <= clr ?  {FLOP_WIDTH{RESET_VALUE}} : q ^ {FLOP_WIDTH{t}};
		end
	end

endmodule


module counter #(
	parameter 													RESET_VALUE = 1'b0,
	parameter														COUNTER_WIDTH = 1
)(
	input logic 												clk,
	input logic 												reset_b,
	input logic													en,
	input logic 												clear,
	
	output logic[COUNTER_WIDTH - 1 : 0] counter
);


	always@(posedge clk or negedge reset_b) begin
		if(~reset_b)begin
			counter[COUNTER_WIDTH-1 : 0] <= {COUNTER_WIDTH{RESET_VALUE}};
		end
		else begin
			counter[COUNTER_WIDTH-1 : 0] <= clear ? {COUNTER_WIDTH{RESET_VALUE}} : counter + en;
		end
	end

endmodule

module mod_n_counter #(
	parameter RESET_VALUE = 1'b0,
	parameter	COUNTER_WIDTH = 1
)(
	input logic 												clk,
	input logic 												reset_b,
	input logic[COUNTER_WIDTH - 1 : 0] 	n,
	input logic 												clear,
	output logic[COUNTER_WIDTH - 1 : 0] counter
);


	always@(posedge clk or negedge reset_b) begin
		if(~reset_b)begin
			counter[COUNTER_WIDTH-1 : 0] <= {COUNTER_WIDTH{RESET_VALUE}};
		end
		else begin
			counter[COUNTER_WIDTH-1 : 0] <= clear | (counter + 1'b1 == n) ? {COUNTER_WIDTH{RESET_VALUE}} : counter + 1'b1;
		end
	end

endmodule

module decoder_2to4(
  input logic[1:0] d,
  
  output logic q0,
  output logic q1,
  output logic q2,
  output logic q3
);

  assign q0 = ~d[0] & ~d[1];
  assign q1 =  d[0] & ~d[1];
  assign q2 = ~d[0] &  d[1];
  assign q3 =  d[0] &  d[1];

endmodule

module shft_register#(
  parameter RESET_VALUE = 1'b0,
  parameter REGISTER_WIDTH = 1
)(
		input logic clk,
		input logic reset_b,
    
    input logic s0,
    input logic s1,
    input logic shift_in,
    input logic[REGISTER_WIDTH - 1 : 0] data_in,
    
    output logic[REGISTER_WIDTH-1 : 0] data_out,
    output logic shift_out

);

  logic[REGISTER_WIDTH-1:0] data;
  logic[REGISTER_WIDTH-1:0] selected_data;
  always@(posedge clk or negedge reset_b)begin
      
    if(~reset_b)begin
      data[REGISTER_WIDTH-1:0] <= {REGISTER_WIDTH{RESET_VALUE}};
    end

    else begin
      data[REGISTER_WIDTH-1:0] <= selected_data[REGISTER_WIDTH-1:0];  
    end

  end

  always@(*)begin
    case({s0, s1})
      2'b00 : selected_data = data;
      2'b01 : selected_data = {shift_in, data[6:0]};
      2'b10 : selected_data = {data[7:1], shift_in};
      2'b11 : selected_data = data_in;
      default:
        selected_data = {REGISTER_WIDTH{1'bx}};
    endcase
  end

  assign data_out = data;
  assign shift_out= data[0];

endmodule

//...........................................................FIFO.......................................
module fifo_sync #( 
     parameter FIFO_DEPTH = 8,
	   parameter DATA_WIDTH = 32,
     parameter FIFO_DEPTH_LOG = 3
)(
	     input logic clk, 
       input logic rst_n,
       input logic wr_en, 
       input logic rd_en, 
       input logic clear,
       input logic [DATA_WIDTH-1:0] data_in, 
       output logic [DATA_WIDTH-1:0] data_out, 
       output logic [FIFO_DEPTH_LOG:0] data_count, 
	     output logic empty,
	     output logic full
	    
); 

  
  // Declare a by-dimensional array to store the data
  logic [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];// depth 8 => [0:7] 32 bit elements
	
	// Wr/Rd pointer have 1 extra bits at MSB
  logic [FIFO_DEPTH_LOG-1:0] write_pointer;//3:0
  logic [FIFO_DEPTH_LOG-1:0] read_pointer;//3:0
  logic fifo_wr_en;
  logic fifo_rd_en;
  
  //write enbale and read enable logic with full and empty 
  assign fifo_wr_en = ~full & wr_en;
  assign fifo_rd_en = ~empty & rd_en;

  //write
    always @(posedge clk or negedge rst_n) begin
      
      if(~rst_n)
		    write_pointer <= 0;
		    
      else  begin
         fifo[write_pointer[FIFO_DEPTH_LOG-1:0]] <= (fifo_wr_en && ~full) ?  data_in : fifo[write_pointer[FIFO_DEPTH_LOG-1:0]];
	       write_pointer <= clear ? ( write_pointer <= 'b0 ) : ( (fifo_wr_en && ~full) ? ( write_pointer + 1'b1 ) :  write_pointer ) ;
      end
      
    end
  
	//read
	always @(posedge clk or negedge rst_n) begin
      
	    if(~rst_n) begin
		    read_pointer <= 0;
		  end
		  
      else begin
        
	      read_pointer <= clear ? ( write_pointer <= 'b0 ) : ((fifo_rd_en && ~empty) ?  (read_pointer + 1'b1) : read_pointer) ;
      end
      
	end
  
  assign data_out[DATA_WIDTH-1:0] =  fifo[read_pointer[FIFO_DEPTH_LOG-1:0]] ;
	
	
 // Counter to count the number of data is written to the FIFO 
  always @(posedge clk or negedge rst_n) begin
  
        if(~rst_n) begin
		      data_count[FIFO_DEPTH_LOG:0] <= 'b0;
		    end 
		    
        else  begin
        
          if(clear) begin
            data_count[FIFO_DEPTH_LOG:0] <= 'b0;
          end
          
          else begin
            casez({fifo_wr_en,fifo_rd_en})
              2'b00   : data_count[FIFO_DEPTH_LOG:0] <= data_count[FIFO_DEPTH_LOG:0];
              2'b01   : data_count[FIFO_DEPTH_LOG:0] <= empty ? data_count[FIFO_DEPTH_LOG:0] : data_count[FIFO_DEPTH_LOG:0] - 1;
              2'b10   : data_count[FIFO_DEPTH_LOG:0] <= full ? data_count[FIFO_DEPTH_LOG:0] : data_count[FIFO_DEPTH_LOG:0] + 1;
              2'b11   : data_count[FIFO_DEPTH_LOG:0] <= data_count[FIFO_DEPTH_LOG:0]; 
              default : data_count[FIFO_DEPTH_LOG:0] <= 'bx;            
            endcase
          end
        end
  end
  
  
  assign empty             = data_count == 0;
  assign full              = data_count == FIFO_DEPTH;
  
  
endmodule
//--------------------------------------------------------------------------------------------------------------------


// Universal shift register

//mode control          opeartion 
//--------------------------------------
//  00                   No Change
//  01                   Shift Right
//  10                   Shift Left
//  11                   Parallel Load

module universal_shift_reg #(
  parameter DATA_WIDTH = 8
)(
  input  logic                      clk, 
  input  logic                      rst, 
  input  logic                [1:0] select,                        // select operation
  input  logic [DATA_WIDTH - 1 : 0] p_din,                         // parallel data in 
  input  logic                      s_left_din,                    // serial left data in
  input  logic                      s_right_din,                   // serial right data in
  output logic [DATA_WIDTH - 1 : 0] p_dout,                        // parallel data out
  output logic                      s_left_dout,                   // serial left data out
  output logic                      s_right_dout                   // serial right data out
);
  always@(posedge clk or negedge rst) begin
    if(~ rst) begin
      p_dout <= 'b0;
    end
    else begin
      casez (select)
        2'b00    : p_dout <= p_dout;                                    // No Chnage
        2'b01    : p_dout <= {s_left_din,p_dout[DATA_WIDTH - 1 : 1]};  // Right Shift
        2'b10    : p_dout <= {p_dout[DATA_WIDTH - 2 : 0], s_right_din};  // Left Shift
        2'b11    : p_dout <= p_din;                                     // Parallel in - Parallel out
        default  : p_dout <= 'bx; 
      endcase
    end
  end
  assign s_left_dout  = p_dout[DATA_WIDTH - 1];
  assign s_right_dout = p_dout[0]; 
endmodule


//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


// >>>>>>>>>>>>>>>>>>>>> COUNTER WITH ENABLE>>>>>>>>>>>>>>>>>>>>

module counter_en #(
  parameter COUNTER_WIDTH = 16
)(
  input logic                        clk,
  input logic                        reset_b,
  input logic                        counter_clear,
  input logic                        en,
  output logic [COUNTER_WIDTH-1 : 0] count
);

  always @(posedge clk or negedge reset_b) begin
    if (~reset_b) begin
      count[COUNTER_WIDTH -1 : 0] <= 'b0;
    end
    else begin
      count[COUNTER_WIDTH -1 : 0] <= counter_clear ? 'b0 : (en ? (count [COUNTER_WIDTH -1 : 'b0] + 1'b1) : count);
    end
  end

endmodule
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
