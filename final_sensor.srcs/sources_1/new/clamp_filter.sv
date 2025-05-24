module clamp_filter #(
  parameter int WIDTH = 16,
  parameter int MAX_DIST = 16'd400
)(
  input  logic               clk,
  input  logic               reset_n,
  input  logic               med5_valid, 
  input  logic [WIDTH-1:0]   med5_out,  
  output logic [WIDTH-1:0]   clamp_out 
);

  logic [WIDTH-1:0] last_valid;

  always_ff @(posedge clk) begin
    if (~reset_n) begin
      last_valid <= '0;     
    end
    else if (med5_valid) begin
      if (med5_out <= MAX_DIST)
        last_valid <= med5_out;
    end
  end

  assign clamp_out = (med5_out > MAX_DIST) ? last_valid : med5_out;

endmodule
