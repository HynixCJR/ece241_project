module part2(
    // input wire [9:0] SW,
    input wire [2:0] KEY, // latch a digit (active-low), reset and our "test" luhn alg. button
    input wire CLOCK_50,
    inout PS2_CLK,
    inout PS2_DAT,
    output wire [6:0] HEX0,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [9:0] LEDR
);

wire [7:0] received_data;
wire received_data_en;
wire command_was_sent;
wire error_communication_timed_out;

PS2_Controller ps2 (
    // Inputs
    .CLOCK_50(CLOCK_50),
    .reset(reset),
    .the_command(8'h00),
    .send_command(1'b0),
    
    .PS2_CLK(PS2_CLK),
    .PS2_DAT(PS2_DAT),
    
    .command_was_sent(command_was_sent),
    .error_communication_timed_out(error_communication_timed_out),
    .received_data(received_data),
    .received_data_en(received_data_en)
);

//key synchronizer, basically just makes sure that our key presses are aligned with the clock cycle of the board, otherwise we send our flipflps into undefined states during edge cases
// wire KEY0 = KEY[0];
// wire KEY1 = KEY[1];
wire RESET_N = KEY[2];

wire KEY0, KEY1;
wire [9:0] SW;

ps2_converter ps2_convert(
    // inputs to ps2 -> regular input converter
    .CLOCK_50(CLOCK_50),
    .reset(~RESET_N),
    .scancode(received_data),
    .ps2_pressed(received_data_en),
    .number(SW),
    .shift(KEY0),
    .check_luhn(KEY1)
);

    reg [1:0] key0_sync, key1_sync;
    always @(posedge CLOCK_50 or negedge RESET_N) begin
        if (!RESET_N) begin
            key0_sync <= 2'b11;
            key1_sync <= 2'b11;
        end else begin
            key0_sync <= {key0_sync[0], KEY0};
            key1_sync <= {key1_sync[0], KEY1};
        end
    end
    wire key0_fall = ~key0_sync[1] & key0_sync[0]; //active-low press
    wire key1_fall = ~key1_sync[1] & key1_sync[0];


wire key0_pressed = key0_fall;
wire key1_pressed = key1_fall;
//Setting the one hot codes based on which switch the user has flipped up for ease
    reg [3:0] sel_digit;
    reg sel_valid;
    always @* begin
        sel_valid = 1'b1;
        case (SW)
            10'b0000000001: sel_digit = 4'd0;
            10'b0000000010: sel_digit = 4'd1;
            10'b0000000100: sel_digit = 4'd2;
            10'b0000001000: sel_digit = 4'd3;
            10'b0000010000: sel_digit = 4'd4;
            10'b0000100000: sel_digit = 4'd5;
            10'b0001000000: sel_digit = 4'd6;
            10'b0010000000: sel_digit = 4'd7;
            10'b0100000000: sel_digit = 4'd8;
            10'b1000000000: sel_digit = 4'd9;
            default: begin
                sel_digit = 4'd0;
                sel_valid = 1'b0;
            end
        endcase
    end


    reg [3:0] digits [0:15];//The digits that we have entered into the shift reg
    reg [4:0] count;   // 0..16 keeping track of what amount of numbers we have entered into the sjhift register

    parameter ST_ENTRY = 2'd0, ST_READY = 2'd1, ST_RUN = 2'd2;
    reg [1:0] ui_state; //What part of the program we are in, are we entering numbers, are we ready to send the numbers to the FSM luhn, or are we running the luhn FSM

    always @(posedge CLOCK_50 or negedge RESET_N) 
    begin
        if (!RESET_N) 
        begin
        ui_state <= ST_ENTRY;//we start at the entry state, we are ready to start entering numbers
        count <= 5'd0;//make sure the count is 0, we are currently on the 0th index (out of 16)
end 
else 
begin
    case (ui_state)
        ST_ENTRY: begin
            if (key0_pressed && sel_valid && (count < 16)) //If we have a selected number, we click 0, and the count is less than 16 (havent typed a full card#)
            begin
                digits[count] <= sel_digit;//set the current count digit to the selected digit
                count <= count + 1'b1;//increase the count by 1
                if (count == 5'd15)//once we reach 16 digits, we are now in the ready state and can send our number to the FSM
                    ui_state <= ST_READY;
            end
        end
        ST_READY: 
        if (key1_pressed) ui_state <= ST_RUN;//Once we clikc the key1, we are now in a run state and sent the card number to the module
        default: ui_state <= ST_ENTRY;//default state
    endcase
end
end


    reg luhn_on;//enable for our luhn fsm
    reg [4:0] sr_idx;//the digit we are currentlt sending 
    reg [3:0] card_digit_reg;//this is the digit that is being processed by the fsm
    reg started;//have we started the fsm or not
    integer i;//for our for loop traversal

    wire luhn_valid, luhn_done, luhn_pulse;//for matthews module

    always @(posedge CLOCK_50 or negedge RESET_N) begin
        if (!RESET_N) 
        begin
            //setting all to 0 when reset
            luhn_on <= 1'b0;
            sr_idx <= 5'd0;
            card_digit_reg <= 4'd0;
            started <= 1'b0;
        end 
        else 
        begin
            if (ui_state == ST_RUN && !started) 
            begin
                //start the run once we hacve reached a UI state of run
                started <= 1'b1;
                luhn_on <= 1'b1; // enable the luhn
                sr_idx <= 5'd15;// this is the index we are currently on (starts with the check digit(last digit))
                card_digit_reg <= digits[15]; // present check digit now; load up the check digit right off the bat
            end
            if (luhn_pulse) begin
                for (i = 15; i >= 0; i = i - 1) 
                begin
                    if (sr_idx == i && i != 0) 
                    begin
                    sr_idx <= i - 1;
                    card_digit_reg <= digits[i - 1]; //loading the current digit into the nth last spot in the digit register for the luhn alg to be able to read the number in the right order
        end
    end
end

        end
    end

    // Instantiate our luhn module that will check if our number is valid or not
    luhn u_luhn (card_digit_reg, luhn_on, CLOCK_50, RESET_N, luhn_valid, luhn_done, luhn_pulse);


    //Setting out seg7 displays to help with debugging and what number we are adding
    function [6:0] seg7_digit;
        input [3:0] n;
        begin
            case (n)
                4'd0: seg7_digit = 7'b1000000;
                4'd1: seg7_digit = 7'b1111001;
                4'd2: seg7_digit = 7'b0100100;
                4'd3: seg7_digit = 7'b0110000;
                4'd4: seg7_digit = 7'b0011001;
                4'd5: seg7_digit = 7'b0010010;
                4'd6: seg7_digit = 7'b0000010;
                4'd7: seg7_digit = 7'b1111000;
                4'd8: seg7_digit = 7'b0000000;
                4'd9: seg7_digit = 7'b0010000;
                default: seg7_digit = 7'b1111111;
            endcase
        end
    endfunction

    parameter [6:0] SEG7_BLANK = 7'b1111111;
    parameter [6:0] SEG7_DASH = 7'b0111111; //this is just a dash

   reg [6:0] hex0_reg, hex4_reg, hex5_reg;
reg [4:0] idx;
reg [3:0] ones;
reg tens;

always @(*) begin

    //showing the selected digit on the hex0
    if (sel_valid)
        hex0_reg = seg7_digit(sel_digit);
    else
        hex0_reg = SEG7_DASH;

    if (ui_state == ST_ENTRY)
        idx = count + 5'd1;
    else
        idx = 5'd16;


    if (idx >= 5'd10) begin
        tens = 1'b1;
        ones = idx - 5'd10;
    end 
    //showing the ones index on hex4
    else 
    begin
        tens = 1'b0;
        ones = idx[3:0];
    end
    //turning on the hex5 if we have reached past >9 index
    if (tens)
        hex5_reg = seg7_digit(4'd1);
    else
        hex5_reg = SEG7_BLANK;

    hex4_reg = seg7_digit(ones);
end

assign HEX0 = hex0_reg;
assign HEX4 = hex4_reg;
assign HEX5 = hex5_reg;


    //assign the led the values of luhn validity once we are done with the luhn module
    assign LEDR[0] = luhn_done &  (luhn_valid);
    assign LEDR[9] = luhn_done & ~(luhn_valid);

endmodule

// code to implement the luhn algorithm
// this assumes we have:
// - a working SR to store the digits, which listens to a pulse signal and updates 4-bit value of R->L digit of card
// - code outside of luhn should conver the 16 bit signal from switches to 4 bits
// - all 4 bit inputs are valid
module luhn(
    input  wire [3:0] card_digit,// card_digit is a single 4 bit digit of card; output of SR
    input  wire       luhn_on,// signal to turn on the luhn module
    input  wire       clock,
    input  wire       resetn,
    output reg        validity,// LEDR value (we turn on led9 if invalid, led0 if valid)
    output reg        done,// 1 while in FINAL_CHECK
    output wire       pulse// pulse to shift new value out of SR
);
    parameter IDLE = 3'd0, GET_CHECK_DIGIT = 3'd1, SHIFT_ODD = 3'd2, PROCESS_ODD = 3'd3, SHIFT_EVEN = 3'd4, PROCESS_EVEN  = 3'd5, FINAL_CHECK = 3'd6, INVALID = 3'd7;

    reg [2:0] state, next_state;
    reg [4:0] digit_count;// Internal counter for 16 digits (0-15)
    reg [7:0] sum;        // single running sum of processed digits D1..D15
    reg [3:0] check_digit;// The final digit of the card number (D0)

    reg [4:0] doubled_digit;// Temporary register for doubling calculation

    // Pulse is high for exactly one cycle when moving to a new processing state
    assign pulse = (state == SHIFT_ODD) || (state == SHIFT_EVEN);

// FSM
always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
        state <= IDLE;
        sum <= 8'd0;
        digit_count <= 5'd0;
        check_digit <= 4'd0;
        validity <= 1'b0;
        done <= 1'b0;
    end 
    else 
    begin
        done <= 1'b0;

        case (state)
            IDLE: begin
                sum <= 8'd0;
                digit_count <= 5'd0;
                check_digit <= 4'd0;
                validity <= 1'b0;
                if (luhn_on)
                    state <= GET_CHECK_DIGIT;
                else
                    state <= IDLE;
            end

            GET_CHECK_DIGIT: 
            begin
                // Sample D0 (no shift this cycle)
                check_digit <= card_digit;
                sum <= 8'd0;
                digit_count <= 5'd1;  // next will be D1

                if (card_digit > 9)
                    state <= INVALID;
                else
                    state <= SHIFT_ODD;
            end

            SHIFT_ODD: 
            begin
                state <= PROCESS_ODD; // read it next cycle
            end

            PROCESS_ODD: 
            begin
                //double and remove 9 if over 9
                doubled_digit = {1'b0, card_digit} << 1;
                if (doubled_digit > 9) doubled_digit = doubled_digit - 5'd9;
                sum <= sum + doubled_digit;
                digit_count <= digit_count + 1'b1;

                if (card_digit > 9)
                    state <= INVALID;
                else if (digit_count == 5'd15)
                    state <= FINAL_CHECK; // just read D15
                else
                    state <= SHIFT_EVEN;  // go fetch even
            end
            SHIFT_EVEN: 
            begin
                state <= PROCESS_EVEN; // read it next cycle
            end


            PROCESS_EVEN: 
            begin
                sum <= sum + card_digit;   // add as-is
                digit_count <= digit_count + 1'b1;

                if (card_digit > 9)
                    state <= INVALID;
                else
                    state <= SHIFT_ODD;
            end
            FINAL_CHECK: 
            begin
                validity <= (((sum + check_digit) % 10) == 0);
                done <= 1'b1;

                if (luhn_on)
                    state <= FINAL_CHECK; 
                else
                    state <= IDLE;
            end

            INVALID: begin
                validity <= 1'b0;

                if (luhn_on)
                    state <= INVALID;
                else
                    state <= IDLE;
            end

            default: begin
                state <= IDLE; //to make sure we hvae no latches
            end
        endcase
    end
end
endmodule

