module full_top (
    input logic Clk,
    input logic reset_rtl_0,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,
        
    //HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB,
    
    //HC-SR04 signals
    input logic echo,
    output logic trig,
    output logic audio_left,
    output logic audio_right,
    output logic alert_o
);
    
    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY, ballxsig, ballysig, ballsizesig;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah;
    
    logic [21:0] distance;
    
    assign reset_ah = reset_rtl_0;
    
    sensor_top_2 sensor (
      .clk(Clk), //100 MHz
      .reset(reset_ah),
      .hex_segA(hex_segA),
      .hex_gridA(hex_gridA),
      .hex_segB(hex_segB),
      .hex_gridB(hex_gridB),
      
      //HC-SR04 signals
      .echo(echo),
      .trig(trig),
      .audio_left(audio_left),
      .audio_right(audio_right),
      .alert_o(alert_o),
      .distance_out(distance)
    );
    
    logic alert;
    assign alert = alert_o;
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );

    
    // Object Module
    object object_instance(
        .Reset(reset_ah),
        .frame_clk(vsync),
        .distance(distance),
        .BallX(ballxsig),
        .BallY(ballysig),
        .BallS(ballsizesig)
    );
    
    localparam int MAX_RAW_TICKS = 22'd2332240;
    localparam int TICKS_PER_CM  = MAX_RAW_TICKS / 400;

    logic [9:0] dist_cm;

    always_comb begin
      if (distance >= MAX_RAW_TICKS)
        dist_cm = 10'd400;
      else
        dist_cm = distance / TICKS_PER_CM;
    end
    
    //Color Mapper Module   
    color_mapper color_instance(
        .clk(Clk),
        .reset(reset_ah),
        .BallX(ballxsig),
        .BallY(ballysig),
        .DrawX(drawX),
        .DrawY(drawY),
        .Dist_cm(dist_cm),
        .alert(alert),
        .Ball_size(ballsizesig),
        .Red(red),
        .Green(green),
        .Blue(blue)
    );
    
endmodule