module sensor_top_2 (
  input logic clk, //100 MHz
  input logic reset,
  output logic [7:0] hex_segA,
  output logic [3:0] hex_gridA,
  output logic [7:0] hex_segB,
  output logic [3:0] hex_gridB,
  //HC-SR04 signals
  input logic echo,
  output logic trig,
  output logic audio_left,
  output logic audio_right,
  output logic alert_o,
  output logic [21:0] distance_out
 );
 
 logic [1:0] state;
 logic ready;
 
  localparam IDLE = 2'b00,
          TRIGGER = 2'b01,
           S_WAIT = 2'b11,
        COUNTECHO = 2'b10;

  logic inIDLE, inTRIGGER, inWAIT, inCOUNTECHO;
  logic [9:0] counter;
  logic trigcountDONE, counterDONE;
  logic measure;

  //Ready
  assign ready = inIDLE;
  
  //Decode states
  assign inIDLE = (state == IDLE);
  assign inTRIGGER = (state == TRIGGER);
  assign inWAIT = (state == S_WAIT);
  assign inCOUNTECHO = (state == COUNTECHO);

  //State transactions
  always_ff @(posedge clk or posedge reset)
    begin
      if(reset)
        begin
          state <= IDLE;
        end
      else
        begin
          case(state)
            IDLE:
              begin
                state <= (measure & ready) ? TRIGGER : state;
              end
            TRIGGER:
              begin
                state <= (trigcountDONE) ? S_WAIT : state;
              end
            S_WAIT:
              begin
                state <= (echo) ? COUNTECHO : state;
              end
            COUNTECHO:
              begin
                state <= (echo) ? state : IDLE;
              end
          endcase
          
        end
    end
  
  //Trigger
  assign trig = inTRIGGER;
  
  //Counter
  always_ff @(posedge clk)
    begin
      if(inIDLE)
        begin
          counter <= 10'd0;
        end
      else
        begin
          counter <= counter + {9'd0, (|counter | inTRIGGER)};
        end
    end
  assign trigcountDONE = (counter == 10'd1000);

  logic [21:0] distanceRAW;
  //Get distance
  always_ff @(posedge clk)
    begin
      if(reset)
        distanceRAW <= 22'd0;
      else if(inWAIT)
        distanceRAW <= 22'd0;
      else
        distanceRAW <= distanceRAW + {21'd0, inCOUNTECHO};
    end
    
    logic start;       // start = trigcountDONE strobe
    logic done, valid;
    logic data_valid = done & valid;
     
    echo_timeout #(
      .CLK_FREQ_HZ   (100_000_000),
      .TIMEOUT_MS    (20)
    ) timeout_inst (
      .clk      (clk),
      .reset_n  (~reset),
      .start    (trigcountDONE),  // strobe at end of your 10 µs trigger
      .echo     (echo),
      .done     (done),
      .valid    (valid)
    );
    
    // Signal refresher
    refresher250ms refresher (
        .clk(clk),
        .reset(reset),
        .measure(measure)
    );
        
    // DSP Filters
    logic [21:0] filter_out, filt_distance_med;
    
    median3 #(.WIDTH(22)) median_filter (
        .clk       (clk),
        .reset_n   (~reset),
        .data_valid(data_valid),
        .in        (distanceRAW),
        .out       (filter_out)
    );
    
    clamp_filter #(
        .WIDTH     (22),           
        .MAX_DIST  (22'h2396C9)    
      ) clamp_inst (
        .clk        (clk),
        .reset_n    (~reset),      
        .med5_valid (data_valid),  
        .med5_out   (filter_out),  
        .clamp_out  (filt_distance_med) 
      );
    
    assign distance_out = filt_distance_med;
    
    // HexDrivers
    HexDriver HexA (
        .clk(clk),
        .reset(reset),
        .in({4'b0, 4'b0, {2'b0, filt_distance_med[21:20]}, filt_distance_med[19:16]}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );
    
    HexDriver HexB (
        .clk(clk),
        .reset(reset),
        .in({filt_distance_med[15:12], filt_distance_med[11:8], filt_distance_med[7:4], filt_distance_med[3:0]}),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );
    
    // Proximity Alert
    logic alert;
    proximity_alert prox (
        .clk(clk),
        .reset(~reset),
        .data_valid(data_valid),
        .distance(filt_distance_med),
        .alert(alert)
    );
    
    // Audio
    logic tone;
    
    tone_generator #(
        .CLK_HZ(100_000_000),
        .TONE_HZ(1000)
    ) beep (
        .clk(clk),
        .reset(reset),
        .wave(tone)
    );
    
    // drive both channels
    assign audio_left = alert ? tone : 1'b0;
    assign audio_right = alert ? tone : 1'b0;
    
    assign alert_o = alert;

endmodule