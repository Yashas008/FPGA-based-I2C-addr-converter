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
  
