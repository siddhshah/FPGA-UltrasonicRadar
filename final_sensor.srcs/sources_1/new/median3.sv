`timescale 1ns/1ps

module median3 #(
    parameter int WIDTH = 22
) (
    input  logic             clk,       
    input  logic             reset_n,    
    input  logic             data_valid, 
    input  logic [WIDTH-1:0] in,    
    output logic [WIDTH-1:0] out    
);

    logic [WIDTH-1:0] smp0, smp1, smp2;

    always_ff @(posedge clk) begin
        if (~reset_n) begin
            smp0 <= '0;
            smp1 <= '0;
            smp2 <= '0;
        end else if (data_valid) begin
            smp2 <= smp1;
            smp1 <= smp0;
            smp0 <= in;
        end
    end

    logic [WIDTH-1:0] min01, max01;
    logic [WIDTH-1:0] med_val;

    always_comb begin
        if (smp0 <= smp1) begin
            min01 = smp0;
            max01 = smp1;
        end else begin
            min01 = smp1;
            max01 = smp0;
        end
        if (smp2 <= min01)
            med_val = min01;
        else if (smp2 >= max01)
            med_val = max01;
        else
            med_val = smp2;
    end

    assign out = med_val;

endmodule



