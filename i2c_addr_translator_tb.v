`timescale 1ns/1ps 

module i2c_addr_receiver_tb;
  
  reg clk;
  reg n_rst;
  reg scl_mas;
  tri sda_mas; //this was on inout silly me 
  
  wire scl_dev;
  tri sda_dev;
  
  reg sda_drive;
  reg sda_val;
  
  assign sda_mas = (sda_drive) ? sda_val : 1'bz;
  
  i2c_addr_receiver #(
    .original_addr(7'h24),
    .translated_addr(7'h25)
  ) DUT (
    .clk(clk),
    .n_rst(n_rst),
    .scl_mas(scl_mas),
    .sda_mas(sda_mas),
    .scl_dev(scl_dev),
    .sda_dev(sda_dev),
    .trans_act(),
    .state_debug()
  );
  integer i;
  reg [7:0]addr_packet; //I kinda overlooked the fact that in Verilog I cant declare new variables mid block.. typical mistake
  always #5 clk =~ clk; //Clock at 100 Mhz . overkill? yes but it is asked in the task sheet
  
  task send_bit (input bit s); // i deleted bit because I thought that was interfering with the code on Cadence NC.
    begin
      sda_drive = 1;
      sda_val = s;
      #20 scl_mas = 1;
      #20 scl_mas = 0;
    end 
  endtask
  initial begin
    clk = 0;
    n_rst = 0;
    scl_mas = 1;
    sda_drive = 1;
    sda_val = 1;
    
    #50 n_rst =1; //Shut off reset?
    
    #50 sda_val = 0;
    #20 scl_mas = 0; //Start the transfer (hope it works cause it should)
    
    
    addr_packet = { 7'h24 , 1'b0};
    
    for(i = 7; i >= 0; i= i - 1)
      send_bit(addr_packet[i]);
    
    scl_mas = 1;
    #20 sda_val = 1;
    
    #300; 
    
    
    $dumpfile("dump.vcd"); $dumpvars(0 , i2c_addr_receiver_tb); //Shift key..
    $finish; //Almost forgot a semicolon again...
  end
endmodule

