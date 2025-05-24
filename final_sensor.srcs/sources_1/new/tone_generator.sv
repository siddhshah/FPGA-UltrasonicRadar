// tone_generator.sv (fixed)
`timescale 1ns/1ps
module tone_generator #(
    parameter integer CLK_HZ  = 100_000_000,
    parameter integer TONE_HZ = 1000
) (
    input  logic clk,
    input  logic reset,
    output logic wave
);
    localparam integer HALF_PERIOD = CLK_HZ / (TONE_HZ * 2);
    logic [$clog2(HALF_PERIOD)-1:0] cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            cnt  <= 0;
            wave <= 0;
        end
        else if (cnt == HALF_PERIOD-1) begin
            cnt  <= 0;
            wave <= ~wave;
        end
        else begin
            cnt <= cnt + 1;
        end
    end
endmodule
