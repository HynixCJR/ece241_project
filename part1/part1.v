// =====================================================================
// Top + Luhn (exactly two modules)
//   - SW[9:0] one-hot digit select: SW[0]=0 ... SW[9]=9
//   - KEY0, KEY1 are active-LOW pushbuttons
//   - CLOCK_50 50 MHz, RESET_N active-LOW
//   - HEX0 shows current selected digit; HEX5 HEX4 show index (1..16)
//   - LEDR[0] lights if valid, LEDR[9] if invalid (after Luhn done)
// =====================================================================

module part1(
    input  wire [9:0] SW,
    input  wire [2:0] KEY,
    input  wire       CLOCK_50,
    output wire [6:0] HEX0,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [9:0] LEDR
);

	wire KEY0 = KEY[0];
	wire KEY1 = KEY[1];
	wire RESET_N = KEY[2];

    // ---------------------------------------------------------------
    // 0) Synchronize keys and detect falling edges (one-cycle pulses)
    // ---------------------------------------------------------------
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
    wire key0_fall = key0_sync[1] & ~key0_sync[0]; // active-low press
    wire key1_fall = key1_sync[1] & ~key1_sync[0];

    // ---------------------------------------------------------------
    // 1) One-hot switch decode -> digit (0..9), with validity guard
    // ---------------------------------------------------------------
    reg  [3:0] sel_digit;
    reg        sel_valid;
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

    // ---------------------------------------------------------------
    // 2) Storage for 16 entered digits (first press = most significant)
    // digits[0] = first entered (MSD, leftmost)
    // digits[15] = last entered (LSD/check digit, rightmost)
    // ---------------------------------------------------------------
    reg [3:0] digits [0:15];
    reg [4:0] count;   // 0..16 keeping track of what amount of numbers we have entered into the sjhift register

    parameter ST_ENTRY = 2'd0, ST_READY = 2'd1, ST_RUN = 2'd2;

    reg [1:0] ui_state;

    integer i;
    always @(posedge CLOCK_50 or negedge RESET_N) begin
        if (!RESET_N) begin
            ui_state <= ST_ENTRY;
            count    <= 5'd0;
            for (i=0; i<16; i=i+1) digits[i] <= 4'd0;
        end else begin
            case (ui_state)
                ST_ENTRY: begin
                    if (key0_fall && sel_valid && (count < 16)) begin
                        digits[count] <= sel_digit;  // MSD first, check digit ends at [15]
                        count         <= count + 1'b1;
                        if (count == 5'd15) ui_state <= ST_READY;
                    end
                end
                ST_READY: begin
                    if (key1_fall) ui_state <= ST_RUN;
                end
                ST_RUN: begin
                    // hold until reset
                end
                default: ui_state <= ST_ENTRY;
            endcase
        end
    end


    reg luhn_on;
    reg [4:0] sr_idx;
    reg [3:0] card_digit_reg;
    reg started;

    wire luhn_valid, luhn_done, luhn_pulse;

    always @(posedge CLOCK_50 or negedge RESET_N) begin
        if (!RESET_N) 
        begin
            luhn_on <= 1'b0;
            sr_idx <= 5'd0;
            card_digit_reg <= 4'd0;
            started <= 1'b0;
        end 
        else 
        begin
            if (ui_state == ST_RUN && !started) begin
                started <= 1'b1;
                luhn_on <= 1'b1;           // hold high until reset
                sr_idx <= 5'd15;          // D0 = digits[15] (check)
                card_digit_reg <= digits[15];     // present check digit now
            end
            if (luhn_pulse) begin                 // asserted during SHIFT_* states
                if (sr_idx != 0) begin
                    sr_idx         <= sr_idx - 1'b1;
                    card_digit_reg <= digits[sr_idx - 1'b1];
                end
            end
        end
    end

    // Instantiate our luhn module that will check if our number is valid or not
    luhn u_luhn (card_digit_reg, luhn_on, CLOCK_50, RESET_N, luhn_valid, luhn_done, luhn_pulse);

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
    parameter [6:0] SEG7_DASH  = 7'b0111111; // '-'

    assign HEX0 = sel_valid ? seg7_digit(sel_digit) : SEG7_DASH;

    wire [4:0] idx  = (ui_state == ST_ENTRY) ? (count + 5'd1) : 5'd16;
    wire tens = (idx >= 5'd10);
    wire [3:0] ones = tens ? (idx - 5'd10) : idx[3:0];

    assign HEX5 = tens ? seg7_digit(4'd1) : SEG7_BLANK;
    assign HEX4 = seg7_digit(ones);

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

