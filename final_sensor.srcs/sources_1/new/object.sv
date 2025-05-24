module object ( 
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [21:0] distance,

    output logic [9:0]  BallX, 
    output logic [9:0]  BallY, 
    output logic [9:0]  BallS 
);
	 
    parameter [9:0] Ball_X_Center=320;  // Center position on the X axis
    parameter [9:0] Ball_Y_Center=240;  // Center position on the Y axis
    parameter [9:0] Ball_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Ball_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Ball_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Ball_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] Ball_X_Step=1;      // Step size on the X axis
    parameter [9:0] Ball_Y_Step=1;      // Step size on the Y axis

    assign BallS = 16;  // default ball size
    
    localparam int BALL_RADIUS    = 16;
    localparam int PIXEL_MIN      = BALL_RADIUS;            // 16
    localparam int PIXEL_MAX      = 639 - BALL_RADIUS;      // 623
    localparam int PIXEL_RANGE    = PIXEL_MAX - PIXEL_MIN;  // 607
    localparam int MAX_RAW_TICKS  = 22'd2332240;            // ?400 cm echo
    localparam int C_Q20          = 273;                    // round(607/2332240*2^20)
    localparam int Q_SHIFT        = 20;

    logic [21:0] raw_clamped;
    logic [31:0] dsp_product;
    logic [9:0]  scaled_pix;
    
    logic [9:0] raw_pix, filt_pix;
    
    deadband_filter #(
       .WIDTH     (10),    // 10-bit pixel coordinate
       .THRESHOLD (2)      // ignore changes 2px
     ) jitter_filt (
       .clk   (frame_clk),
       .reset (Reset),
       .in    (raw_pix),
       .out   (filt_pix)
     );
   
    always_ff @(posedge frame_clk)
    begin: Move_Ball
        if (Reset) begin             
			BallY <= Ball_Y_Center;
			BallX <= Ball_X_Center;
        end else begin
            // Update ball position
            BallY <= 8'hF0;

            raw_clamped <= (distance > MAX_RAW_TICKS) ? MAX_RAW_TICKS : distance;
            dsp_product <= raw_clamped * C_Q20;
            scaled_pix <= dsp_product >> Q_SHIFT;
            raw_pix <= PIXEL_MIN + scaled_pix;   
            BallX <= filt_pix;
		end  
    end
endmodule