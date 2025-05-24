`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2025 10:31:42 PM
// Design Name: 
// Module Name: sensor_testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sensor_testbench();

    logic clk;
    logic reset;
    logic echo;        // From sensor
    logic trig;        // To sensor
    logic alert_o;    // Proximity alert
    logic audio_left;
    logic audio_right;
    logic [21:0] distance_out;
    logic [7:0] hex_segA;
    logic [3:0] hex_gridA;
    logic [7:0] hex_segB;
    logic [3:0] hex_gridB;
    
    sensor_top_2 sensor (.*);
    
    initial begin
        clk = 1'b1;
    end
    
    always begin
        #1 clk = ~clk;
    end
    
    initial begin
    
        reset = 0;
        #20
        reset = 1;
        #20
        reset = 0;
    
        #588_236 echo = 1;
        
        #1000
    
        $finish();
    end

endmodule
