module refresher250ms (
  input logic clk,
  //input logic en,
  input logic reset,
  output logic measure
);
  logic [24:0] counter;

  assign measure = (counter == 25'd1);

  always_ff @(posedge clk)
    begin
      if(reset)
        counter <= 25'd0;
      else if(/*~en | */(counter == 25'd25_000_000))
        counter <= 25'd0;
      else
        counter <= 25'd1 + counter;
    end
endmodule