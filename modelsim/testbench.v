`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20; // 50 MHz clock

    // --- Regs for DUT Inputs ---
    reg [9:0] SW;
    reg [2:0] KEY;
    reg       CLOCK_50;

    // --- Wires for DUT Outputs ---
    wire [6:0] HEX0;
    wire [6:0] HEX4;
    wire [6:0] HEX5;
    wire [9:0] LEDR;

	initial begin
        CLOCK_50 <= 1'b0;
	end // initial
	always @ (*)
	begin : Clock_Generator
		#((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
	end
	
	initial begin
        // Initialize all inputs
        SW <= 10'b0;
        KEY[0] <= 1'b1; // Active-low, 1 = not pressed
        KEY[1] <= 1'b1; // Active-low, 1 = not pressed
        
        // Assert active-low reset
        KEY[2] <= 1'b1;
        #30; // Hold reset for 100ns
        KEY[2] <= 1'b0;
        #40; // Wait for system to stabilize
        KEY[2] <= 1'b1;
        #50;
	end // initial

    // Test sequence for entering a valid card
    // 4992739871688887
	initial begin
        // Wait for reset to finish
        #150;

        // Manually entering digits:
        // Enter 4
        SW = (1'b1 << 5); #5;
        KEY[0] = 0; #20; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 9
        SW = (1'b1 << 1); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 9
        SW = (1'b1 << 0); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 2
        SW = (1'b1 << 5); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 7
        SW = (1'b1 << 1); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 3
        SW = (1'b1 << 0); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 9
        SW = (1'b1 << 5); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 8
        SW = (1'b1 << 1); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 7
        SW = (1'b1 << 0); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 1
        SW = (1'b1 << 5); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 6
        SW = (1'b1 << 1); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 8
        SW = (1'b1 << 0); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 8
        SW = (1'b1 << 5); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 8
        SW = (1'b1 << 1); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 8
        SW = (1'b1 << 0); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;
        // Enter 7
        SW = (1'b1 << 0); #10;
        KEY[0] = 0; #10; KEY[0] = 1; #10; SW = 0; #50;

        // All 16 digits are in. Now press KEY[1] to start Luhn.
        #100; // wait
        KEY[1] = 0; // press
        #20; // hold
        KEY[1] = 1; // release
        
        // Let simulation run
        #5000;
        $stop;
	end // initial
	
    // Instantiate the Unit Under Test (UUT)
	part1 U1 (
        .SW(SW),
        .KEY(KEY),
        .CLOCK_50(CLOCK_50),
        .HEX0(HEX0),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .LEDR(LEDR)
    );

    // --- Add $monitor to display signals ---
    initial begin
        // Wait for reset to de-assert
        #150;
        $monitor("Time: %t | luhn_state: %s | card_digit: %d | digit_count: %d | validity: %b | LEDR[0]: %b",
                 $time, 
                 U1.u_luhn.state, 
                 U1.card_digit_reg, 
                 U1.u_luhn.digit_count,
                 U1.u_luhn.validity,
                 LEDR[0]);
    end

endmodule