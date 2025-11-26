module ps2_converter (
    input wire CLOCK_50, // clock
    input wire reset, // reset input (active high?)
    input wire [7:0] scancode, // the inputted key value
    input wire ps2_pressed, // value that determines if a key on the ps2 has been pressed
    output reg [9:0] number, // the one-hot coded number that gets outputted
    output reg shift, // signal to shift through register
    output reg check_luhn // signal to check the luhn state
);


// states for E0h prefix and F0h break codes
reg [7:0] last_scancode;
reg E0_prefix; // 1 if the last scancode was 8'hE0
reg F0_prefix; // 1 if the last scancode was 8'hF0

// scan codes for keys

localparam SC_right = 8'h74;
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

// sequential logic for state tracking
always @(posedge CLOCK_50) begin
    if (reset) begin
        last_scancode <= 8'h00;
        E0_prefix <= 1'b0;
        F0_prefix <= 1'b0;
    end else begin
        // reset single cycle execute_move pulse

        if (ps2_pressed) begin
            // first check for break code (F0h)
            if (scancode == 8'hF0) begin
                // key release prefix detected
                F0_prefix <= 1'b1;
                E0_prefix <= 1'b0; // end any E0 sequence
					 shift <= SHIFT_OFF;
                check_luhn <= CHCK_LUHN_OFF;
            end 
            // second check for extended code (E0h)
            else if (scancode == 8'hE0) begin
                // extended key prefix detected
                E0_prefix <= 1'b1;
                F0_prefix <= 1'b0; // end any F0 sequence
            end 
            // finally process the move
            else begin
                // ignore if prev code was key-release code (F0) 
                if (F0_prefix) begin
                    F0_prefix <= 1'b0; // clear F0 flag
                end 
                // ignore if prev code was E0 (second byte of an extended key)
                else if (E0_prefix) begin
                    E0_prefix <= 1'b0; // clear flags
                    F0_prefix <= 1'b0;

                    case(scancode)
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
                    F0_prefix <= 1'b0; // clear flags
                    E0_prefix <= 1'b0;
                    
                    case (scancode)
                        SC_0: begin
                            number <= NUMOUT_0;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                        SC_1: begin
                            number <= NUMOUT_1;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                        SC_2: begin
                            number <= NUMOUT_2;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                        SC_3: begin
                            number <= NUMOUT_3;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                        SC_4: begin
                            number <= NUMOUT_4;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                        SC_5: begin
                            number <= NUMOUT_5;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                        SC_6: begin
                            number <= NUMOUT_6;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                        SC_7: begin
                            number <= NUMOUT_7;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                        SC_8: begin
                            number <= NUMOUT_8;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                        SC_9: begin
                            number <= NUMOUT_9;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end

                        SC_enter: begin
                            number <= number;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_ON;
                        end

                        default: begin
                            number <= number;
                            shift <= SHIFT_OFF;
                            check_luhn <= CHCK_LUHN_OFF;
                        end
                    endcase
                end
            end
            
            last_scancode <= scancode; // store current scancode
        end
    end
end


endmodule