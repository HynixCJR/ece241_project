module ps2_converter (
    input wire CLOCK_50, // clock
    input wire [7:0] sc, // the inputted key value
    input wire ps2_pressed, // value that determines if a key on the ps2 has been pressed
    output reg [9:0] number, // the one-hot coded number that gets outputted
    output reg shift, // signal to shift through register
    output reg check_luhn // signal to check the luhn state
);

reg [7:0] prev_sc; // previous scancode 

// extended (E0) and break (F0) key codes
reg E0_prefix; // 1 if the last scancode was 8'hE0
reg F0_prefix; // 1 if the last scancode was 8'hF0


// regular key scan codes
localparam SC_right = 8'h74; // ideally we won't use this (EDIT: we're not really, but the functionality still exists)
localparam SC_enter = 8'h5A;
localparam SC_0 = 8'h45;
localparam SC_1 = 8'h16;
localparam SC_2 = 8'h1E;
localparam SC_3 = 8'h26;
localparam SC_4 = 8'h25;
localparam SC_5 = 8'h2E;
localparam SC_6 = 8'h36;
localparam SC_7 = 8'h3D;
localparam SC_8 = 8'h3E;
localparam SC_9 = 8'h46;

// output values
// one hot encoded because i'm too lazy to fix up the rest of the ancient logic
localparam NUMOUT_0 = 10'b0000000001;
localparam NUMOUT_1 = 10'b0000000010;
localparam NUMOUT_2 = 10'b0000000100;
localparam NUMOUT_3 = 10'b0000001000;
localparam NUMOUT_4 = 10'b0000010000;
localparam NUMOUT_5 = 10'b0000100000;
localparam NUMOUT_6 = 10'b0001000000;
localparam NUMOUT_7 = 10'b0010000000;
localparam NUMOUT_8 = 10'b0100000000;
localparam NUMOUT_9 = 10'b1000000000;
localparam NUMOUT_NONE = 10'b0000000000; // same as if no switches are active

localparam CHCK_LUHN_OFF = 1'b1;
localparam CHCK_LUHN_ON = 1'b0;
localparam SHIFT_OFF = 1'b1;
localparam SHIFT_ON = 1'b0; // on = 0 to emulate KEYs

reg prev_sc_was_num;

// state tracking
always @(posedge CLOCK_50) begin
    if (ps2_pressed) begin
        // first check for break code (F0h)
        if (sc == 8'hF0) begin
            // key release prefix detected
            F0_prefix <= 1'b1;
            E0_prefix <= 1'b0; // end any E0 sequence
            shift <= SHIFT_OFF;
            check_luhn <= CHCK_LUHN_OFF;
        end 
        // second check for extended code (E0h)
        else if (sc == 8'hE0) begin
            // extended key prefix detected
            E0_prefix <= 1'b1;
            F0_prefix <= 1'b0; // end any F0 sequence
        end 
        // finally process the move
        else begin
            // ignore if prev code was key-release code (F0) 
            if (F0_prefix) begin
                F0_prefix <= 1'b0; // clear F0 flag
                if (prev_sc_was_num) begin
                            shift <= SHIFT_ON;
                        end else begin
                            shift <= SHIFT_OFF;
                            prev_sc_was_num <= 1'b0;
                            // ensures we're not just setting the pre_sc_was_num to 0 immediately after setting it to 1 in previous state
                        end						  
                
            end 
            // logic for extended signal
            // this code isn't even necessary anymore but i'm just keeping it there so that nothing breaks any further lol
            else if (E0_prefix) begin
                E0_prefix <= 1'b0;
                F0_prefix <= 1'b0;

                case(sc)
                    SC_right: begin
                        number <= number;
                        shift <= SHIFT_ON;
                        check_luhn <= CHCK_LUHN_OFF;
                    end
                    default: begin
                        number <= number;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                    end
                endcase                    
            end 

            // regular make code (key press)
            else begin
                // set prefix flags back to 0
                F0_prefix <= 1'b0;
                E0_prefix <= 1'b0;
                
                case (sc)
                    SC_0: begin
                        number <= NUMOUT_0;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end
                    SC_1: begin
                        number <= NUMOUT_1;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end
                    SC_2: begin
                        number <= NUMOUT_2;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end
                    SC_3: begin
                        number <= NUMOUT_3;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end
                    SC_4: begin
                        number <= NUMOUT_4;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end
                    SC_5: begin
                        number <= NUMOUT_5;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end
                    SC_6: begin
                        number <= NUMOUT_6;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end
                    SC_7: begin
                        number <= NUMOUT_7;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end
                    SC_8: begin
                        number <= NUMOUT_8;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end
                    SC_9: begin
                        number <= NUMOUT_9;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b1;
                    end

                    SC_enter: begin
                        number <= number;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_ON;
                        prev_sc_was_num <= 1'b0;
                    end
						  
                    default: begin
                        number <= number;
                        shift <= SHIFT_OFF;
                        check_luhn <= CHCK_LUHN_OFF;
                        prev_sc_was_num <= 1'b0;
                    end
                endcase
            end
        end
        
        prev_sc <= sc; // store current scancode
    end
end


endmodule