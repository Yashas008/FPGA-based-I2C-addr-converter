module i2c_addr_receiver # (
  parameter original_addr= 7'h24,
  parameter translated_addr= 7'h25
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
  
  assign sda_mas = sda_mas_oe ? sda_mas_out : 1'bz;
  assign scl_dev = scl_dev_out;
  assign sda_dev = sda_dev_oe ? sda_dev_out : 1'bz;
  
  
  reg scl_mas_d1, scl_mas_d2, scl_mas_d3;
  wire scl_rising_edge =  scl_mas_d2 && !scl_mas_d3;
  wire scl_falling_edge = !scl_mas_d2 &&  scl_mas_d3;
  
  reg sda_mas_d1, sda_mas_d2;
  reg sda_dev_d1, sda_dev_d2;
  
  wire start_condition = ( sda_mas_d2 && !sda_mas_d1 && scl_mas_d2);
  wire stop_condition  = (!sda_mas_d2 &&  sda_mas_d1 && scl_mas_d2);
  
  //Finite state Machine States
  
  localparam idle = 3'd0;
  localparam addr_rx = 3'd1; // declared addr_tx twice due to bad handwriting
  localparam addr_trans = 3'd2;
  localparam addr_tx = 3'd3;
  localparam data_forward = 3'd4;
  localparam wait_stop = 3'd5;
  
  reg [2:0]state;
  reg [2:0]next_state;
  
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
      sda_mas_d2 <= sda_mas_d1;
      
      sda_dev_d1 <= sda_dev;
      sda_dev_d2 <= sda_dev_d1;
    end
  end
  
  //Sequential FSM 
  
  always@(posedge clk or negedge n_rst) begin 
    if(!n_rst) //not reset else if statemwnt would be active during n_rst = 1 which would be pointless 
      state <= idle;
    else
      state <= next_state;
  end
  
  //Combinational part of FSM
  always@(*) begin
    next_state = state;
    
    //I will use case block here due to it being multiple cases 
    
    case(state)
      idle:
        if(start_condition) next_state = addr_rx; //Replaced TX with RX as first is transmission and not reception. :)
      
      addr_rx:
        if(bit_count == 8 && scl_falling_edge)
          next_state = addr_trans;
        else if(stop_condition)
          next_state = idle;
      
      addr_trans:
        next_state = (addr_match ? addr_tx : data_forward);
      
      addr_tx:
        if(bit_count == 8 && scl_falling_edge)
          next_state = data_forward;
      
      data_forward:
        if(stop_condition) next_state = idle;
      
      default:
        next_state = idle;
    endcase
  end
  
  //Save Point 2 for date 1/11/2025
  
  always@(posedge clk or negedge n_rst) begin
    if(!n_rst) begin
      bit_count <= 0;
    end else begin 
      case(state)
        
        idle: bit_count <= 0;
        
        addr_tx:
          if(scl_rising_edge && bit_count < 8)
            bit_count <= bit_count + 1;
          else if (scl_falling_edge && bit_count == 8)
            bit_count <= 0;
        
        addr_rx:
          if(scl_falling_edge) begin
            if(bit_count < 8)
              bit_count <= bit_count + 1;
            else
              bit_count <= 0;
          end
        
        default:
          bit_count <= 0;
      endcase
    end
  end
  
  // the above block contains the bit counter 
  
  always@(posedge clk or negedge n_rst) begin
    if(!n_rst) begin
      addr_byte <= 0;
      rw_bit <= 0;
      addr_match <= 0;
    end else begin
      case(state)
        
        addr_rx: begin
          if(scl_rising_edge && bit_count < 8) begin
            if(bit_count < 7)
              addr_byte <= {addr_byte[6:0], sda_mas_d2};
            else
              rw_bit <= sda_mas_d2;
          end 
        end
        
        addr_trans: begin
          addr_match <= (addr_byte[7:1] == original_addr);
          
          $display( "Captured address = %02h 7bit = %02h recw = %b match = %b time = %0t", addr_byte , addr_byte[7:1] , rw_bit, (addr_byte[7:1] == original_addr), $time); //forgot time while coding
                   end
                   
        idle: begin
          addr_match <= 0;
          addr_byte <= 0;
        end
      endcase
    end
  end
  
  always@(posedge clk or negedge n_rst) begin
    if(!n_rst)
      trans_act <= 1'b0;
    else begin
      if(stop_condition)
        trans_act <= 1'b0;
      else if (state == addr_trans && addr_match) // I dropped my book here causing me to stall in typing the code
        trans_act <= 1'b1;
      else
        trans_act <= trans_act;
    end
  end // I cut and repasted the code here as I found a missing parentheses in the $display line which caused a cascading end line issues.
  
  // Output Control
  
  always@(posedge clk or negedge n_rst) begin
    if(!n_rst) begin
      sda_mas_out <= 1'b1;
      sda_mas_oe <= 1'b0;
      
      sda_dev_out <= 1'b1;
      sda_dev_oe <= 1'b0;
      
      scl_dev_out <= 1'b1;
    end else begin
      case(state)
        idle: begin
          sda_mas_oe <= 0;
          sda_dev_oe <= 0;
          scl_dev_out <= 1'b1;
        end
        
        addr_rx: begin
          sda_mas_oe <= (bit_count == 8);
          sda_mas_out <= 0;
          sda_dev_out <= 0;
          sda_dev_oe <= 0;
        end
        
        addr_trans: begin
          scl_dev_out <= 0; // had doible semicolon here, no idea how that got there
        end
        
        addr_tx: begin
          scl_dev_out <= scl_mas_d2;
          sda_dev_oe <= 1;
          sda_mas_oe <= 0;
          
          if(bit_count < 7)
            sda_dev_out <= translated_addr[6-bit_count];
          else if (bit_count == 7)
            sda_dev_out <= rw_bit;
          else
            sda_dev_oe <= 0;
        end
        
        data_forward: begin
          scl_dev_out <= scl_mas_d2;
          
          if(rw_bit) begin
            sda_mas_oe <= 1;
            sda_mas_out <= sda_dev_d2;
            sda_dev_oe <= 0;
          end else begin
            sda_mas_oe <= 1;
            sda_mas_out <= sda_mas_d2;
            sda_dev_oe <= 0;
          end
        end
        
      endcase
    end
  end
  
  
  //Debug output for reference
  
  always@(posedge clk or negedge n_rst) begin
    if(!n_rst)
      state_debug <= 3'd0;
    else
      state_debug <= state;
  end 
endmodule


// Based on my personal checking with an AI code dectector, it did say 0-5% due to having clean FSM states and I get that..but since I have been designing in analog for a good time it is common for analog designers to make it so it looks like it is working even if it doesnt scream core RTL engineer.
