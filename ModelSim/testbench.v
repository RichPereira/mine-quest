`timescale 1ns / 1ps

module testbench;
    // Inputs
    reg CLOCK_50;
    reg resetn;
    reg is_game_over;
    parameter CLOCK_PERIOD = 20;

    // Outputs
    wire [7:0] minutes;
    wire [7:0] hours;
    wire [7:0] seconds;

    // Clock generation
    initial begin
        CLOCK_50 <= 1'b0;
    end

    always begin
        #(CLOCK_PERIOD / 2) CLOCK_50 = ~CLOCK_50;  // Toggle clock every half period
    end

    // Instantiate the game_timer module
    game_timer U1 (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .is_game_over(is_game_over),
        .minutes(minutes),
        .hours(hours),
        .seconds(seconds)
    );

    initial begin
        // Initial settings
        resetn = 0;
        is_game_over = 0;
        #50;
        resetn = 1;
        #5000;
    end
endmodule
