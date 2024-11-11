module main(KEY, CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
    input [3:0] KEY;
    input CLOCK_50;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire is_game_over;
    wire [7:0] minutes;
    wire [7:0] seconds;
    wire [7:0] hours;
    game_timer U1(CLOCK_50, KEY[0], KEY[1], minutes, seconds, hours);
    display_time U2(hours, minutes, seconds, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
endmodule

/*
Timer starts when is_game_over = 0. If resetn = 1 or is_game_over = 1, then counter is restarted from zero
*/
module game_timer(CLOCK_50, resetn, is_game_over, minutes, seconds, hours);
    input CLOCK_50, resetn, is_game_over;
    output reg [7:0] minutes;
    output reg [7:0] hours;
    output reg [7:0] seconds;

    parameter MAX_sec_count = 50000000; // 50000000 - 50Mhz
    reg [26:0] counter;

    always@(posedge CLOCK_50) begin
        if (~resetn) begin
            counter <= 0; // reset counter and other vars
            minutes <= 0;
            hours <= 0;
            seconds <= 0;
        end
        else begin
            if (is_game_over == 1'b0) begin // continue timer if game is not over
                if (counter == MAX_sec_count) begin
                    counter <= 0;
                    if (seconds == 8'b00111011) begin // if seconds == 59, reset
                        seconds <= 0;
                        if (minutes == 8'b00111011) begin // if minutes == 59, reset
                            minutes <= 0;
                            if (hours == 8'b01100011)// if hours == 99, reset
                                hours <= 0;
                            else
                                hours <= hours + 1; // increment hours
                        end
                        else
                            minutes <= minutes + 1; // increment minutes
                    end
                    else 
                        seconds <= seconds + 1; // increment seconds
                end
                else
                    counter <= counter + 1; // increment counter
            end
            else begin
                // hold the value if the game is over
                counter <= counter;
                seconds <= seconds;
                minutes <= minutes;
                hours <= hours;
            end
        end
    end

endmodule

// Helper function to display time on the de1soc board - Hex display
module display_time (hh, mm, ss, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
    input [7:0] hh;
    input [7:0] mm;
    input [7:0] ss;  
    output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

    // Separate tens and ones digits for each time unit
    wire [3:0] hh_tens = hh / 10;
    wire [3:0] hh_ones = hh % 10;
    wire [3:0] mm_tens = mm / 10;
    wire [3:0] mm_ones = mm % 10;
    wire [3:0] ss_tens = ss / 10;
    wire [3:0] ss_ones = ss % 10;

    // Instantiate hex_decoder for each 7-segment display
    hex_decoder hex5_inst(hh_tens, HEX5);  // Hours tens
    hex_decoder hex4_inst(hh_ones, HEX4);  // Hours ones
    hex_decoder hex3_inst(mm_tens, HEX3);  // Minutes tens
    hex_decoder hex2_inst(mm_ones, HEX2);  // Minutes ones
    hex_decoder hex1_inst(ss_tens, HEX1);  // Seconds tens
    hex_decoder hex0_inst(ss_ones, HEX0);  // Seconds ones

endmodule
// Helper function to display the time on the hex display
module hex_decoder(value, HEX);
    output reg [6:0] HEX;
    input [3:0] value;
    always @(*)
        begin
            case(value)
                4'b0000: HEX = 7'b1000000; //0
                4'b0001: HEX = 7'b1111001; //1
                4'b0010: HEX = 7'b0100100; //2
                4'b0011: HEX = 7'b0110000; //3
                4'b0100: HEX = 7'b0011001; //4
                4'b0101: HEX = 7'b0010010; //5
                4'b0110: HEX = 7'b0000010; //6
                4'b0111: HEX = 7'b1111000; //7
                4'b1000: HEX = 7'b0000000; //8
                4'b1001: HEX = 7'b0011000; //9
                default: HEX = 7'b1000000; // blank
            endcase 
        end

endmodule

