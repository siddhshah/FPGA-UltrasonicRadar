`timescale 1ns / 1ps
module proximity_alert (
    input logic clk,
    input logic reset,
    input logic data_valid,
    input logic [21:0] distance,
    output logic alert
);

    always_ff @(posedge clk) begin
        if(~reset) alert <= 1'b0;
        else if(data_valid) alert <= (distance > 0 && distance < 22'h155A8);
    end
    
endmodule