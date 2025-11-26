`timescale 1ns / 1ps

module testbench;

    parameter CLOCK_PERIOD = 20; // 50 MHz clock

    // --- Regs for DUT Inputs ---
    reg [9:0] SW;
    reg [2:0] KEY;
    reg       CLOCK_50;

    // PS/2 lines for simulation
    wire PS2_CLK;
    wire PS2_DAT;

    // --- Wires for DUT Outputs ---
    wire [6:0] HEX0;
    wire [6:0] HEX4;
    wire [6:0] HEX5;
    wire [9:0] LEDR;

    // ------------------------------------------------------------
    // Clock generator
    // ------------------------------------------------------------
    initial begin
        CLOCK_50 = 1'b0;
    end

    always #(CLOCK_PERIOD/2) CLOCK_50 = ~CLOCK_50;

    // ------------------------------------------------------------
    // Reset and initialisation
    // ------------------------------------------------------------
    initial begin
        SW     = 10'b0;
        KEY    = 3'b111;   // all keys released (active-low)
        KEY[2] = 1'b0;     // assert reset (RESET_N = 0)

        #100;
        KEY[2] = 1'b1;     // deassert reset
    end

    // ------------------------------------------------------------
    // Task to enter a single digit using one-hot SW
    // SW[d] = 1 selects digit d
    // ------------------------------------------------------------
    task enter_digit(input integer d);
    begin
        SW = (10'b1 << d); // one-hot for digit d
        #10;
        KEY[0] = 1'b0;     // press KEY0 (active-low)
        #20;
        KEY[0] = 1'b1;     // release KEY0
        #10;
        SW = 10'b0;        // clear switches
        #50;
    end
    endtask

    // ------------------------------------------------------------
    // Stimulus: enter 16 digits, then start Luhn
    // Card number: 4992739871688887
    // ------------------------------------------------------------
    initial begin
        // Wait for reset to complete
        #150;

        // Enter digits (index = digit value)
        enter_digit(4);
        enter_digit(9);
        enter_digit(9);
        enter_digit(2);
        enter_digit(7);
        enter_digit(3);
        enter_digit(9);
        enter_digit(8);
        enter_digit(7);
        enter_digit(1);
        enter_digit(6);
        enter_digit(8);
        enter_digit(8);
        enter_digit(8);
        enter_digit(8);
        enter_digit(7);

        // All 16 digits entered; now start Luhn via KEY1
        #100;
        KEY[1] = 1'b0;   // press
        #20;
        KEY[1] = 1'b1;   // release

        // Let simulation run for a while
        #5000;
        $stop;
    end

    // ------------------------------------------------------------
    // Instantiate the Unit Under Test (UUT)
    // ------------------------------------------------------------
    part1 U1 (
        .SW      (SW),
        .KEY     (KEY),
        .CLOCK_50(CLOCK_50),
        .HEX0    (HEX0),
        .HEX4    (HEX4),
        .HEX5    (HEX5),
        .LEDR    (LEDR)
    );

    // ------------------------------------------------------------
    // Monitor some internal signals for debugging
    // ------------------------------------------------------------
    initial begin
        #150; // wait until after reset

        $display(" time   state card_digit digit_count valid led0 led9");
        $monitor("%0t  %0d        %0d          %0d        %b     %b    %b",
                 $time,
                 U1.u_luhn.state,
                 U1.card_digit_reg,
                 U1.u_luhn.digit_count,
                 U1.u_luhn.validity,
                 LEDR[0],
                 LEDR[9]);
    end

endmodule
