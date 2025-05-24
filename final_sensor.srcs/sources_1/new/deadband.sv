module deadband_filter #(
  parameter int WIDTH     = 10,   // bits of your pixel coordinate
  parameter int THRESHOLD = 2     // pixels: anything <=2px is "jitter"
)(
  input  logic               clk,
  input  logic               reset, 
  input  logic [WIDTH-1:0]   in,   // new scaled X
  output logic [WIDTH-1:0]   out   // jitter-filtered X
);

  // holds the "last stable" value
  logic [WIDTH-1:0] last_val;
  // fabs(in - last_val)
  logic [WIDTH-1:0] diff;
  
  logic [WIDTH-1:0] out_reg;

  // register block with async reset
  always_ff @(posedge clk) begin
    if (reset) begin
      last_val <= in;
      out_reg  <= in;
    end
    else begin
      // compute absolute difference
      diff <= (in > last_val) ? (in - last_val) : (last_val - in);

      if (diff > THRESHOLD) begin
        // real movement: update both
        last_val <= in;
        out_reg  <= in;
      end
      else begin
        // tiny jitter: hold previous
        out_reg <= last_val;
      end
    end
  end
  
  assign out = out_reg;

endmodule