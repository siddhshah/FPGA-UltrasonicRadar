`timescale 1ns/1ps

module color_mapper (
    input  logic        clk,
    input  logic        reset,
    input  logic [9:0]  BallX,
    input  logic [9:0]  BallY,
    input  logic [9:0]  Ball_size,
    input  logic [9:0]  DrawX,
    input  logic [9:0]  DrawY,
    input  logic [9:0]  Dist_cm,
    input  logic        alert,

    output logic [3:0]  Red,
    output logic [3:0]  Green,
    output logic [3:0]  Blue
);

    logic ball_on;
    logic signed [10:0] dx, dy;
    logic [10:0] abs_dx, abs_dy, diag_err;
    localparam int X_THICK = 1;

    always_comb begin
        dx       = $signed({1'b0,DrawX}) - $signed({1'b0,BallX});
        dy       = $signed({1'b0,DrawY}) - $signed({1'b0,BallY});
        abs_dx   = dx < 0 ? -dx : dx;
        abs_dy   = dy < 0 ? -dy : dy;
        diag_err = (abs_dx>abs_dy) ? abs_dx-abs_dy : abs_dy-abs_dx;
        ball_on  = (abs_dx<=Ball_size) && (abs_dy<=Ball_size) && (diag_err<=X_THICK);
    end

    localparam int VPIX    = 480;
    localparam int BASE_Y  = VPIX - 20;
    localparam int TICK_SP = 80;
    logic radar_base = (DrawY == BASE_Y);
    logic radar_tick = ((DrawX % TICK_SP) == 0);

    localparam int BIG_N       = 4;
    localparam int CHAR_W      = 8;
    localparam int CHAR_H      = 16;
    localparam int LABEL_Y0    = BASE_Y + 4;
    localparam int CHARS       = 3;

    localparam int BALL_RADIUS = 16;
    localparam int PIXEL_MIN   = BALL_RADIUS;       
    localparam int PIXEL_MAX   = 639 - BALL_RADIUS;
    localparam int PIXEL_RANGE = PIXEL_MAX - PIXEL_MIN;
    localparam int MAX_CM      = 400;

    localparam int TICK_CM[0:3] = '{
        (80  - PIXEL_MIN)*MAX_CM/PIXEL_RANGE,
        (240 - PIXEL_MIN)*MAX_CM/PIXEL_RANGE,
        (400 - PIXEL_MIN)*MAX_CM/PIXEL_RANGE,
        (560 - PIXEL_MIN)*MAX_CM/PIXEL_RANGE
    };

    logic [10:0] font_addr;
    logic  [7:0] pixel_data;
    font_rom font_inst (.addr(font_addr), .data(pixel_data));

    logic        text_on, text_bit;
    logic [3:0]  digit, char_idx;

    logic        corner_text_on;
    logic [2:0]  corner_char_idx;
    logic [6:0]  corner_code;
    localparam int CORNER_X     = 8;
    localparam int CORNER_Y     = 8;
    localparam int CORNER_CHARS = 6;

    integer i, tick_x, label_x, cm_val, pix_rel, cx;

    always_comb begin
        text_on        = 1'b0;
        font_addr      = 11'd0;
        text_bit       = 1'b0;
        corner_text_on = 1'b0;

        for (i = 0; i < BIG_N; i = i + 1) begin
            tick_x  = (2*i + 1) * TICK_SP;
            label_x = tick_x - (CHARS*CHAR_W)/2 + (CHAR_W/2);
            cm_val  = TICK_CM[i];
            if (DrawX >= label_x && DrawX < label_x + CHARS*CHAR_W &&
                DrawY >= LABEL_Y0  && DrawY < LABEL_Y0 + CHAR_H) begin

                char_idx  = (DrawX - label_x) / CHAR_W;
                case (char_idx)
                  0: digit = cm_val / 100;
                  1: digit = (cm_val % 100) / 10;
                  default: digit = cm_val % 10;
                endcase

                font_addr = (7'h30 + digit) * CHAR_H + (DrawY - LABEL_Y0);
                text_bit  = pixel_data[(CHAR_W-1) - ((DrawX - label_x) % CHAR_W)];
                if (text_bit) text_on = 1'b1;
            end
        end

        for (corner_char_idx = 0; corner_char_idx < CORNER_CHARS; corner_char_idx = corner_char_idx + 1) begin
            cx = CORNER_X + corner_char_idx * CHAR_W;
            if (DrawX >= cx && DrawX < cx + CHAR_W &&
                DrawY >= CORNER_Y && DrawY < CORNER_Y + CHAR_H) begin

                unique case (corner_char_idx)
                  3'd0: corner_code = 7'h30 + (Dist_cm / 100);
                  3'd1: corner_code = 7'h30 + ((Dist_cm % 100) / 10);
                  3'd2: corner_code = 7'h30 + (Dist_cm % 10);
                  3'd3: corner_code = 7'h20; // space
                  3'd4: corner_code = 7'h43; // 'C'
                  default: corner_code = 7'h4D; // 'M'
                endcase

                font_addr = corner_code * CHAR_H + (DrawY - CORNER_Y);
                text_bit  = pixel_data[(CHAR_W-1) - ((DrawX - cx) % CHAR_W)];
                if (text_bit) corner_text_on = 1'b1;
            end
        end

        if (corner_text_on)
            text_on = 1'b1;
    end

    localparam int COUNTER_MAX = 27'd10000000;
    logic [26:0] counter;
    logic        color_alert;

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            color_alert <= 1'b0;
        end else if (alert) begin
            counter <= counter + 1;
            if (counter >= COUNTER_MAX) begin
                color_alert <= ~color_alert;
                counter     <= 0;
            end
        end else begin
            color_alert <= 1'b0;
            counter     <= 0;
        end
    end

    always_comb begin : RGB_Display
        if (ball_on) begin
            if (!color_alert) begin
                Red   = 4'hF; Green = 4'h0; Blue  = 4'h0;
            end else begin
                Red   = 4'h0; Green = 4'h0; Blue  = 4'h0;
            end
        end else if (radar_base || radar_tick || text_on) begin
            Red   = 4'h0; Green = 4'hF; Blue  = 4'h0;
        end else begin
            if (!color_alert) begin
                Red   = 4'h0; Green = 4'h0; Blue  = 4'h0;
            end else begin
                Red   = 4'hF; Green = 4'h0; Blue  = 4'h0;
            end
        end
    end

endmodule
