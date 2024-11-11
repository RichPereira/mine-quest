// module main(CLOCK_50, );

// endmodule


/*
Timer starts when is_game_over = 0. If resetn = 1 or is_game_over = 1, then counter is restarted from zero
*/
module game_timer(CLOCK_50, resetn, is_game_over, minutes, seconds, hours);
    input CLOCK_50, resetn, is_game_over;
    output reg [6:0] minutes;
    output reg [6:0] hours;
    output reg [6:0] seconds;

    parameter MAX_sec_count = 500000; // 50000000 for 50MHz
    reg [26:0] counter;

    always@(posedge CLOCK_50) begin
        if (~reset) begin // sync reset
            counter <= 0; // reset counter
            minutes <= 0;
            hours <= 0;
            seconds <= 0;
        end
        else begin
            if (~is_game_over) begin // continue timer if game is not over
                if (counter == MAX_sec_count) begin
                    counter <= 0;
                    if (seconds == 7'b0111011) begin // if seconds == 59, reset
                        seconds <= 0; 
                        if (minutes == 7'b0111011) begin // if minutes == 59, reset
                            minutes <= 0;
                            if (hours == 7'b1100011)// if hours == 99, reset
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

        end
    end

endmodule