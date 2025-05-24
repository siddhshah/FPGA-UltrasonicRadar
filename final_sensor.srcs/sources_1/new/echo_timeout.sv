`timescale 1ns/1ps

// echo_timeout.sv
// Module to issue a 'done' strobe when an echo returns or a timeout occurs
// If no echo falling edge occurs within TIMEOUT_MS ms, a timeout is flagged
// and 'valid' goes low, ignoring the measurement.

module echo_timeout #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int TIMEOUT_MS = 20,
    parameter int TIMEOUT_CYCLES = (CLK_FREQ_HZ/1000) * TIMEOUT_MS,
    parameter int CNT_WIDTH = $clog2(TIMEOUT_CYCLES+1)
) (
    input  logic clk,
    input  logic reset_n,
    input  logic start,
    input  logic echo,
    output logic done,
    output logic valid
);
    
    typedef enum logic [1:0] {IDLE, WAIT} state_t;
    state_t state, next_state;

    logic [CNT_WIDTH-1:0] cnt;
    logic echo_d1;
    logic echo_fall = echo_d1 & ~echo;

    always_ff @(posedge clk) begin
        if (~reset_n) begin
            state <= IDLE;
            cnt <= '0;
            echo_d1 <= 1'b0;
        end else begin
            state <= next_state;
            echo_d1 <= echo;
            case (state)
                IDLE: begin
                    cnt <= '0;
                end
                WAIT: begin
                    if (cnt < TIMEOUT_CYCLES)
                        cnt <= cnt + 1;
                end
            endcase
        end
    end

    // Combinational: next state and strobes
    logic done_reg, valid_reg;
    always_comb begin
        // default outputs
        next_state = state;
        done_reg   = 1'b0;
        valid_reg  = 1'b0;

        case (state)
            IDLE: begin
                if (start) begin
                    next_state = WAIT;
                end
            end
            WAIT: begin
                if (echo_fall) begin
                    // echo returned in time
                    done_reg = 1'b1;
                    valid_reg = 1'b1;
                    next_state = IDLE;
                end else if (cnt >= TIMEOUT_CYCLES) begin
                    // timeout expired
                    done_reg = 1'b1;
                    valid_reg = 1'b0;
                    next_state = IDLE;
                end
            end
        endcase
    end

    assign done = done_reg;
    assign valid = valid_reg;

endmodule
