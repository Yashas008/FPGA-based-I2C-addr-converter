module i2c_addr_receiver (
  parameter original_addr=7'h24,
  parameter translated_addr=7'h25
)(
  input wire clk,
  input wire n_rst,
  input wire scl_mas, // I2C device to FPGA(slave)
  inout wire sda_mas, // I2C device to FPGA(slave)
  output wire scl_dev,
  inout wire sda_dev,
  output reg trans_act,
  output reg[2:0] state_debug
);
  
  reg sda_mas_out, sda_mas_oe;
  reg sda_dev_out, sda_dev_oe;
  reg scl_dev_out;
  
  //Buffers 
  
  assign sda_mas= sda_mas_oe ? sda_mas_out: 1'bz;
  assign scl_dev=scl_dev_out;
  assign sda_dev= sda_dev_oe ? sda_dev_out:1'bz;
  
  
  reg scl_mas_d1, scl_mas_d2, scl)mas_d3;
  wire scl_rising_edge = scl_mas_d2 && !scl_mas_d3;
  wire scl_falling_edge = !scl_mas_d2 && scl_mas_d3;
  
  reg sda_mas_d1, sda_mas_d2;
  reg sda_dev_d1, sda_dev_d2;
  
  wire start_condition= ( sda_mas_d2 && !sda_mas_d1 && scl_mas_d2);
  wire stop_condition= (!sda_mas_d2 && sda_mas_d1 && sda_mas_d2);
  
  //Finite state Machine States
  
  localparam idle = 3'd0;
  localparam addr_tx = 3'd1;
  localparam addr_trans = 3'd2;
  localparam addr_tx = 3'd3;
  localparam data_forward = 3'd4;
  localparam wait_stop = 3'd5;
  
  reg [2:0]state;
  reg next_state;
  
  //Counter and Registers
  
  reg [3:0]bit_count;
  reg [7:0]addr_byte;
  
  reg rw_bit; // receiving bit
  reg addr_match;
  
  always @(posedge clk or negedge n_rst) begin 
    if (!n_rst) begin
      scl_mas_d1 <= 1'b1;
      scl_mas_d2 <= 1'b1;
      scl_mas_d3 <= 1'b1;
      
      sda_mas_d1 <= 1'b1;
      sda_mas_d2 <= 1'b1;
      
      sda_dev_d1 <= 1'b1;
      sda_dev_d2 <= 1'b1;
    end
    else begin
      scl_mas_d1 <= scl_mas;
      scl_mas_d2 <= scl_mas_d1;
      scl_mas_d3 <= scl_mas_d2;
      
      sda_mas_d1 <= sda_mas;
      sda_mas_d2 <= sda_mas_d2;
      
      sda_dev_d1 <= sda_dev;
      sda_dev_d2 <= sda_dev_d1;
    end
  end
  
  //Sequential FSM 
  
  always@(posedge clk or negedge n_rst) begin 
    if(!n_rst) //not reset else if statemwnt would be active during n_rst = 1 which would be pointless 
      stae <=idle;
    else
      state <=next_state;
  end
  
  //Combinational part of FSM
  always@(*) begin
    next_state = state;
    
    //I will use case block here due to it being multiple cases 
    
    case(state)
      idle:
        if(start_condition) next_state addr_rx; //Replaced TX with RX as first is transmission and not reception. :)
      
      addr_rx:
        if(bit_count==8 && scl_falling_edge)
          next_state = addr_trans;
      else if(stop_condition)
        next_state = IDLE;
      
      addr_trans:
        next_state = (addr_match ? addr_tx : data_forward);
      
      addr_tx:
        if(bit_count ==8 && scl_falling_edge)
          next_state = data_forward;
      
      data_forward:
        if(stop_condition) next_state = idle;
      
      default:
        next_state = idle;
    endcase
  end
  
  //Save Point 2 for date 1/11/2025
        
      
      
