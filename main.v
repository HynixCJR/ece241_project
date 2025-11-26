// ------------- PAYMENT CARD VALIDATOR AND IDENTIFIER -------------
//
// By Matthew Kong and Darman Ahmad
// Written for ECE241 at the University of Toronto
// November 2025
//
// This is the top-level module of the entire payment card verifier.
// All modules, unless otherwise stated, are written by Matthew Kong and Darman Ahmad.
// All visuals are designed by Matthew Kong
// BIN database values are scraped from https://bincheck.io/ca

//     /\_____/\
//    /  o   o  \
//   ( ==  ^  == )
//    )         (
//   (           )
//  ( (  )   (  ) )
// (__(__)___(__)__)


module main(
    input wire [2:0] KEY, // latch a digit (active-low), reset and "run Luhn" button
    input wire CLOCK_50,
    inout PS2_CLK,
    inout PS2_DAT,
    output wire [6:0] HEX0,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output reg [9:0] LEDR,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);

//Defining our digit and letter dimensions for easier access later
localparam DIGIT_W = 13;
localparam DIGIT_H = 15;
localparam LETTER_W = 8;
localparam LETTER_H = 11;


wire [8:0] color; //this is the wire for the colour signal that we are feeding into the vga adapter (changes in our FSMs that draw different things)
wire [9:0] X; //the x location of what we draw (needs 10 bits because the lowest bit count that can cover 640 pixles is 10)
wire [8:0] Y;//y location of what we draw (needs 9 bits cuz same reason as above)
wire write; //The write enable for our vga, it turns on whenever we want to write some pixels

wire RESET_N = KEY[2];  // active-low reset

// VGA adapter with background image initialized (taken from example given by Professor brown)
vga_adapter VGA (
    .resetn(RESET_N),
    .clock(CLOCK_50),
    .color(color),
    .x(X),
    .y(Y),
    .write(write),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_BLANK_N(VGA_BLANK_N),
    .VGA_SYNC_N(VGA_SYNC_N),
    .VGA_CLK(VGA_CLK)
);
defparam VGA.BACKGROUND_IMAGE = "./images/bgidle.mif"; //image we have selected for our background as well as the colour depth that we want for it
defparam VGA.COLOR_DEPTH = 9;


// below we define and store all of the mifs for all of the digits and letters that we will need to print while our program will run
localparam DIGIT_PIXELS = DIGIT_W * DIGIT_H; //dimensions of digits
localparam DIGIT_ADDR_BITS = 10; //number of address bits needed to index every pixel in our digit rom
localparam LETTER_PIXELS = LETTER_W * LETTER_H;
localparam LETTER_ADDR_BITS = 7;

wire [8:0] d0,d1,d2,d3,d4,d5,d6,d7,d8,d9; //defining the outputs for each digit
reg  [8:0] digit_pixel; //the selected pixel that we have picked from on of the roms
reg  [DIGIT_ADDR_BITS-1:0] digit_addr; //the address into whicher ROM we are using
reg  [LETTER_ADDR_BITS-1:0] letter_addr;



// Digit 0 ROM (Ill define what everything does here cuz then it just repeats)

altsyncram digit0_rom (
    .clock0 (CLOCK_50),
    .address_a (digit_addr), //the address comes out from here
    .q_a (d0), //where the output of each pixel goes
    .aclr0 (1'b0),
    .aclr1 (1'b0),
    .address_b (),
    .byteena_a (1'b1),
    .byteena_b (1'b1),
    .clock1 (),
    .clocken0 (1'b1),
    .clocken1 (1'b1),
    .data_a (),
    .data_b (),
    .q_b (),
    .wren_a (1'b0), //write enables are off, we only want to be able to read the files not write to them
    .wren_b (1'b0)
);
defparam
    digit0_rom.operation_mode = "ROM", //setting all of the parameters for storing a digit, what kind of memory
    digit0_rom.width_a = 9, //The depth of the colour
    digit0_rom.widthad_a = DIGIT_ADDR_BITS, //the number of address bits needed
    digit0_rom.numwords_a = DIGIT_PIXELS, //"area" of the digit image
    digit0_rom.outdata_reg_a = "CLOCK0", //rom data appears 1 clock cycle after the address changes
    digit0_rom.init_file = "./text/zero.mif", // the name of the file 
    digit0_rom.intended_device_family = "Cyclone V"; //the board type this data is meant to be saved on 

altsyncram digit1_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (d1),
    .wren_a (1'b0),
    .data_a (9'b0),
    .clock1 (),
    .wren_b (1'b0),
    .address_b (),
    .data_b (),
    .q_b (),
    .clocken0 (1'b1),
    .clocken1 (1'b1),
    .aclr0 (1'b0),
    .aclr1 (1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    digit1_rom.operation_mode = "ROM",
    digit1_rom.width_a = 9,
    digit1_rom.widthad_a = DIGIT_ADDR_BITS,
    digit1_rom.numwords_a = DIGIT_PIXELS,
    digit1_rom.outdata_reg_b = "CLOCK0",
    digit1_rom.init_file = "./text/digit1.mif";

altsyncram digit2_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (d2),
    .wren_a (1'b0),
    .data_a (9'b0),
    .clock1 (),
    .wren_b (1'b0),
    .address_b (),
    .data_b (),
    .q_b (),
    .clocken0 (1'b1),
    .clocken1 (1'b1),
    .aclr0 (1'b0),
    .aclr1 (1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    digit2_rom.operation_mode = "ROM",
    digit2_rom.width_a = 9,
    digit2_rom.widthad_a = DIGIT_ADDR_BITS,
    digit2_rom.numwords_a = DIGIT_PIXELS,
    digit2_rom.outdata_reg_b = "CLOCK0",
    digit2_rom.init_file = "./text/digit2.mif";

altsyncram digit3_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (d3),
    .wren_a (1'b0),
    .data_a (9'b0),
    .clock1 (),
    .wren_b (1'b0),
    .address_b (),
    .data_b (),
    .q_b (),
    .clocken0 (1'b1),
    .clocken1 (1'b1),
    .aclr0 (1'b0),
    .aclr1 (1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    digit3_rom.operation_mode = "ROM",
    digit3_rom.width_a = 9,
    digit3_rom.widthad_a = DIGIT_ADDR_BITS,
    digit3_rom.numwords_a = DIGIT_PIXELS,
    digit3_rom.outdata_reg_b = "CLOCK0",
    digit3_rom.init_file = "./text/digit3.mif";

altsyncram digit4_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (d4),
    .wren_a (1'b0),
    .data_a (9'b0),
    .clock1 (),
    .wren_b (1'b0),
    .address_b (),
    .data_b (),
    .q_b (),
    .clocken0 (1'b1),
    .clocken1 (1'b1),
    .aclr0 (1'b0),
    .aclr1 (1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    digit4_rom.operation_mode = "ROM",
    digit4_rom.width_a = 9,
    digit4_rom.widthad_a = DIGIT_ADDR_BITS,
    digit4_rom.numwords_a = DIGIT_PIXELS,
    digit4_rom.outdata_reg_b = "CLOCK0",
    digit4_rom.init_file = "./text/digit4.mif";

altsyncram digit5_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (d5),
    .wren_a (1'b0),
    .data_a (9'b0),
    .clock1 (),
    .wren_b (1'b0),
    .address_b (),
    .data_b (),
    .q_b (),
    .clocken0 (1'b1),
    .clocken1 (1'b1),
    .aclr0 (1'b0),
    .aclr1 (1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    digit5_rom.operation_mode = "ROM",
    digit5_rom.width_a = 9,
    digit5_rom.widthad_a = DIGIT_ADDR_BITS,
    digit5_rom.numwords_a = DIGIT_PIXELS,
    digit5_rom.outdata_reg_b = "CLOCK0",
    digit5_rom.init_file = "./text/digit5.mif";

altsyncram digit6_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (d6),
    .wren_a (1'b0),
    .data_a(9'b0),
    .clock1(),
    .wren_b(1'b0),
    .address_b(),
    .data_b(),
    .q_b(),
    .clocken0(1'b1),
    .clocken1(1'b1),
    .aclr0(1'b0),
    .aclr1(1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    digit6_rom.operation_mode = "ROM",
    digit6_rom.width_a = 9,
    digit6_rom.widthad_a = DIGIT_ADDR_BITS,
    digit6_rom.numwords_a = DIGIT_PIXELS,
    digit6_rom.outdata_reg_b = "CLOCK0",
    digit6_rom.init_file = "./text/digit6.mif";

altsyncram digit7_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (d7),
    .wren_a (1'b0),
    .data_a(9'b0),
    .clock1(),
    .wren_b(1'b0),
    .address_b(),
    .data_b(),
    .q_b(),
    .clocken0(1'b1),
    .clocken1(1'b1),
    .aclr0(1'b0),
    .aclr1(1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    digit7_rom.operation_mode = "ROM",
    digit7_rom.width_a = 9,
    digit7_rom.widthad_a = DIGIT_ADDR_BITS,
    digit7_rom.numwords_a = DIGIT_PIXELS,
    digit7_rom.outdata_reg_b = "CLOCK0",
    digit7_rom.init_file = "./text/digit7.mif";

altsyncram digit8_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (d8),
    .wren_a (1'b0),
    .data_a(9'b0),
    .clock1(),
    .wren_b(1'b0),
    .address_b(),
    .data_b(),
    .q_b(),
    .clocken0(1'b1),
    .clocken1(1'b1),
    .aclr0(1'b0),
    .aclr1(1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    digit8_rom.operation_mode = "ROM",
    digit8_rom.width_a = 9,
    digit8_rom.widthad_a = DIGIT_ADDR_BITS,
    digit8_rom.numwords_a = DIGIT_PIXELS,
    digit8_rom.outdata_reg_b = "CLOCK0",
    digit8_rom.init_file = "./text/digit8.mif";

altsyncram digit9_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (d9),
    .wren_a (1'b0),
    .data_a(9'b0),
    .clock1(),
    .wren_b(1'b0),
    .address_b(),
    .data_b(),
    .q_b(),
    .clocken0(1'b1),
    .clocken1(1'b1),
    .aclr0(1'b0),
    .aclr1(1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    digit9_rom.operation_mode = "ROM",
    digit9_rom.width_a = 9,
    digit9_rom.widthad_a = DIGIT_ADDR_BITS,
    digit9_rom.numwords_a = DIGIT_PIXELS,
    digit9_rom.outdata_reg_b = "CLOCK0",
    digit9_rom.init_file = "./text/digit9.mif";

//same thing as above but now for each letter of the alphabet beause we want to print them all.
wire [8:0] LA, LB, LC, LD, LE, LF, LG, LH, LI, LJ, LK, LL, LM, LN, LO, LP, LQ, LR, LS, LT, LU, LV, LW, LX, LY, LZ;

altsyncram letterA_rom(
    .clock0 (CLOCK_50),
    .address_a (digit_addr),
    .q_a (LA),
    .wren_a (1'b0),
    .data_a (9'b0),
    .clock1(),
    .wren_b(1'b0),
    .address_b (),
    .data_b(),
    .q_b(),
    .clocken0 (1'b1),
    .clocken1 (1'b1),
    .aclr0 (1'b0),
    .aclr1 (1'b0),
    .byteena_a (1'b1),
    .byteena_b (1'b1)
);
defparam
    letterA_rom.operation_mode = "ROM",
    letterA_rom.width_a = 9,
    letterA_rom.widthad_a = LETTER_ADDR_BITS,
    letterA_rom.numwords_a = LETTER_PIXELS,
    letterA_rom.outdata_reg_b = "CLOCK0",
    letterA_rom.init_file = "./text/letterA.mif";

altsyncram letterB_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LB),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterB_rom.operation_mode="ROM", letterB_rom.width_a=9,
    letterB_rom.widthad_a=LETTER_ADDR_BITS, letterB_rom.numwords_a=LETTER_PIXELS,
    letterB_rom.outdata_reg_b="CLOCK0", letterB_rom.init_file="./text/letterB.mif";

altsyncram letterC_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LC),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterC_rom.operation_mode="ROM", letterC_rom.width_a=9,
    letterC_rom.widthad_a=LETTER_ADDR_BITS, letterC_rom.numwords_a=LETTER_PIXELS,
    letterC_rom.outdata_reg_b="CLOCK0", letterC_rom.init_file="./text/letterC.mif";

altsyncram letterD_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LD),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterD_rom.operation_mode="ROM", letterD_rom.width_a=9,
    letterD_rom.widthad_a=LETTER_ADDR_BITS, letterD_rom.numwords_a=LETTER_PIXELS,
    letterD_rom.outdata_reg_b="CLOCK0", letterD_rom.init_file="./text/letterD.mif";

altsyncram letterE_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LE),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterE_rom.operation_mode="ROM", letterE_rom.width_a=9,
    letterE_rom.widthad_a=LETTER_ADDR_BITS, letterE_rom.numwords_a=LETTER_PIXELS,
    letterE_rom.outdata_reg_b="CLOCK0", letterE_rom.init_file="./text/letterE.mif";

altsyncram letterF_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LF),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterF_rom.operation_mode="ROM", letterF_rom.width_a=9,
    letterF_rom.widthad_a=LETTER_ADDR_BITS, letterF_rom.numwords_a=LETTER_PIXELS,
    letterF_rom.outdata_reg_b="CLOCK0", letterF_rom.init_file="./text/letterF.mif";

altsyncram letterG_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LG),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterG_rom.operation_mode="ROM", letterG_rom.width_a=9,
    letterG_rom.widthad_a=LETTER_ADDR_BITS, letterG_rom.numwords_a=LETTER_PIXELS,
    letterG_rom.outdata_reg_b="CLOCK0", letterG_rom.init_file="./text/letterG.mif";

altsyncram letterH_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LH),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterH_rom.operation_mode="ROM", letterH_rom.width_a=9,
    letterH_rom.widthad_a=LETTER_ADDR_BITS, letterH_rom.numwords_a=LETTER_PIXELS,
    letterH_rom.outdata_reg_b="CLOCK0", letterH_rom.init_file="./text/letterH.mif";

altsyncram letterI_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LI),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterI_rom.operation_mode="ROM", letterI_rom.width_a=9,
    letterI_rom.widthad_a=LETTER_ADDR_BITS, letterI_rom.numwords_a=LETTER_PIXELS,
    letterI_rom.outdata_reg_b="CLOCK0", letterI_rom.init_file="./text/letterI.mif";

altsyncram letterJ_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LJ),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterJ_rom.operation_mode="ROM", letterJ_rom.width_a=9,
    letterJ_rom.widthad_a=LETTER_ADDR_BITS, letterJ_rom.numwords_a=LETTER_PIXELS,
    letterJ_rom.outdata_reg_b="CLOCK0", letterJ_rom.init_file="./text/letterJ.mif";

altsyncram letterK_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LK),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterK_rom.operation_mode="ROM", letterK_rom.width_a=9,
    letterK_rom.widthad_a=LETTER_ADDR_BITS, letterK_rom.numwords_a=LETTER_PIXELS,
    letterK_rom.outdata_reg_b="CLOCK0", letterK_rom.init_file="./text/letterK.mif";

altsyncram letterL_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LL),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterL_rom.operation_mode="ROM", letterL_rom.width_a=9,
    letterL_rom.widthad_a=LETTER_ADDR_BITS, letterL_rom.numwords_a=LETTER_PIXELS,
    letterL_rom.outdata_reg_b="CLOCK0", letterL_rom.init_file="./text/letterL.mif";

altsyncram letterM_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LM),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterM_rom.operation_mode="ROM", letterM_rom.width_a=9,
    letterM_rom.widthad_a=LETTER_ADDR_BITS, letterM_rom.numwords_a=LETTER_PIXELS,
    letterM_rom.outdata_reg_b="CLOCK0", letterM_rom.init_file="./text/letterM.mif";

altsyncram letterN_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LN),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterN_rom.operation_mode="ROM", letterN_rom.width_a=9,
    letterN_rom.widthad_a=LETTER_ADDR_BITS, letterN_rom.numwords_a=LETTER_PIXELS,
    letterN_rom.outdata_reg_b="CLOCK0", letterN_rom.init_file="./text/letterN.mif";

altsyncram letterO_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LO),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterO_rom.operation_mode="ROM", letterO_rom.width_a=9,
    letterO_rom.widthad_a=LETTER_ADDR_BITS, letterO_rom.numwords_a=LETTER_PIXELS,
    letterO_rom.outdata_reg_b="CLOCK0", letterO_rom.init_file="./text/letterO.mif";

altsyncram letterP_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LP),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterP_rom.operation_mode="ROM", letterP_rom.width_a=9,
    letterP_rom.widthad_a=LETTER_ADDR_BITS, letterP_rom.numwords_a=LETTER_PIXELS,
    letterP_rom.outdata_reg_b="CLOCK0", letterP_rom.init_file="./text/letterP.mif";

altsyncram letterQ_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LQ),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterQ_rom.operation_mode="ROM", letterQ_rom.width_a=9,
    letterQ_rom.widthad_a=LETTER_ADDR_BITS, letterQ_rom.numwords_a=LETTER_PIXELS,
    letterQ_rom.outdata_reg_b="CLOCK0", letterQ_rom.init_file="./text/letterQ.mif";

altsyncram letterR_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LR),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterR_rom.operation_mode="ROM", letterR_rom.width_a=9,
    letterR_rom.widthad_a=LETTER_ADDR_BITS, letterR_rom.numwords_a=LETTER_PIXELS,
    letterR_rom.outdata_reg_b="CLOCK0", letterR_rom.init_file="./text/letterR.mif";

altsyncram letterS_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LS),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterS_rom.operation_mode="ROM", letterS_rom.width_a=9,
    letterS_rom.widthad_a=LETTER_ADDR_BITS, letterS_rom.numwords_a=LETTER_PIXELS,
    letterS_rom.outdata_reg_b="CLOCK0", letterS_rom.init_file="./text/letterS.mif";

altsyncram letterT_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LT),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterT_rom.operation_mode="ROM", letterT_rom.width_a=9,
    letterT_rom.widthad_a=LETTER_ADDR_BITS, letterT_rom.numwords_a=LETTER_PIXELS,
    letterT_rom.outdata_reg_b="CLOCK0", letterT_rom.init_file="./text/letterT.mif";

altsyncram letterU_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LU),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterU_rom.operation_mode="ROM", letterU_rom.width_a=9,
    letterU_rom.widthad_a=LETTER_ADDR_BITS, letterU_rom.numwords_a=LETTER_PIXELS,
    letterU_rom.outdata_reg_b="CLOCK0", letterU_rom.init_file="./text/letterU.mif";

altsyncram letterV_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LV),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterV_rom.operation_mode="ROM", letterV_rom.width_a=9,
    letterV_rom.widthad_a=LETTER_ADDR_BITS, letterV_rom.numwords_a=LETTER_PIXELS,
    letterV_rom.outdata_reg_b="CLOCK0", letterV_rom.init_file="./text/letterV.mif";

altsyncram letterW_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LW),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterW_rom.operation_mode="ROM", letterW_rom.width_a=9,
    letterW_rom.widthad_a=LETTER_ADDR_BITS, letterW_rom.numwords_a=LETTER_PIXELS,
    letterW_rom.outdata_reg_b="CLOCK0", letterW_rom.init_file="./text/letterW.mif";

altsyncram letterX_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LX),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterX_rom.operation_mode="ROM", letterX_rom.width_a=9,
    letterX_rom.widthad_a=LETTER_ADDR_BITS, letterX_rom.numwords_a=LETTER_PIXELS,
    letterX_rom.outdata_reg_b="CLOCK0", letterX_rom.init_file="./text/letterX.mif";

altsyncram letterY_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LY),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterY_rom.operation_mode="ROM", letterY_rom.width_a=9,
    letterY_rom.widthad_a=LETTER_ADDR_BITS, letterY_rom.numwords_a=LETTER_PIXELS,
    letterY_rom.outdata_reg_b="CLOCK0", letterY_rom.init_file="./text/letterY.mif";

altsyncram letterZ_rom(.clock0(CLOCK_50), .address_a(digit_addr), .q_a(LZ),
    .wren_a(1'b0), .data_a(9'b0), .clock1(), .wren_b(1'b0), .address_b(),
    .data_b(), .q_b(), .clocken0(1'b1), .clocken1(1'b1), .aclr0(1'b0),
    .aclr1(1'b0), .byteena_a(1'b1), .byteena_b(1'b1));
defparam letterZ_rom.operation_mode="ROM", letterZ_rom.width_a=9,
    letterZ_rom.widthad_a=LETTER_ADDR_BITS, letterZ_rom.numwords_a=LETTER_PIXELS,
    letterZ_rom.outdata_reg_b="CLOCK0", letterZ_rom.init_file="./text/letterZ.mif";


//The below section is the muxes that pick which digit or letter will be printing next (which will be used by our draw fsms)
reg [8:0] letter_pixel;
reg [4:0] draw_code; // 0-9 for digits, 0-25 for letters
reg draw_is_letter; // 0 = digit, 1 = letter

always @(*) begin
    case (draw_code[3:0])  // digits 0..9, we dont care about the 5th bit, because that only corresponds to the letters
        4'd0: digit_pixel = d0;
        4'd1: digit_pixel = d1;
        4'd2: digit_pixel = d2;
        4'd3: digit_pixel = d3;
        4'd4: digit_pixel = d4;
        4'd5: digit_pixel = d5;
        4'd6: digit_pixel = d6;
        4'd7: digit_pixel = d7;
        4'd8: digit_pixel = d8;
        4'd9: digit_pixel = d9;
        default: digit_pixel = 9'd0;
    endcase
end

always @(*) begin
    case (draw_code)
        5'd0:  letter_pixel = 9'd0;
        5'd1:  letter_pixel = LA;
        5'd2:  letter_pixel = LB;
        5'd3:  letter_pixel = LC;
        5'd4:  letter_pixel = LD;
        5'd5:  letter_pixel = LE;
        5'd6:  letter_pixel = LF;
        5'd7:  letter_pixel = LG;
        5'd8:  letter_pixel = LH;
        5'd9:  letter_pixel = LI;
        5'd10: letter_pixel = LJ;
        5'd11: letter_pixel = LK;
        5'd12: letter_pixel = LL;
        5'd13: letter_pixel = LM;
        5'd14: letter_pixel = LN;
        5'd15: letter_pixel = LO;
        5'd16: letter_pixel = LP;
        5'd17: letter_pixel = LQ;
        5'd18: letter_pixel = LR;
        5'd19: letter_pixel = LS;
        5'd20: letter_pixel = LT;
        5'd21: letter_pixel = LU;
        5'd22: letter_pixel = LV;
        5'd23: letter_pixel = LW;
        5'd24: letter_pixel = LX;
        5'd25: letter_pixel = LY;
        5'd26: letter_pixel = LZ;
        default: letter_pixel = 9'd0; // blank for spaces
    endcase
end



//Below we will be defining our drawing engine, which includes multiple FSMs for different "sections" of drawing

//The base locations of where our digits will be printing, this also defines where all of our text printing will be referenced to
localparam BASE_X = 8'd120;
localparam BASE_Y = 9'd255;

// Digits (Row 0)
localparam CARD_X = 10'd108;
localparam CARD_Y = 9'd342;

// Bank Name (Row 1)
localparam BANK_X = 10'd111;
localparam BANK_Y = 9'd298;

// Card Brand (Row 2)
localparam BRAND_X = 10'd111;
localparam BRAND_Y = 9'd96;

// Card Type (Row 3, Col 0-6)
localparam TYPE_X = 10'd447;
localparam TYPE_Y = 9'd217;

// Card Level (Row 4, Col 7+)
localparam LEVEL_X = 10'd279;
localparam LEVEL_Y = 9'd96;

//the start and stop x and ys of the clear rectangle, which makes it look like we cleared the previous entries, but we just cover it with a black box
localparam [9:0] CLEAR_X0 = BASE_X;
localparam [9:0] CLEAR_X1 = BASE_X + 16*DIGIT_W;
localparam [8:0] CLEAR_Y0 = BASE_Y;
localparam [8:0] CLEAR_Y1 = BASE_Y + 4*DIGIT_H-5;



// Green "card valid" circle in bottom-right corner, just defining its paramters
//values are random because we guess/checked where everything should load lol
localparam integer CIRCLE_R = 4;
localparam [9:0] CIRCLE_X0 = 10'd603;
localparam [9:0] CIRCLE_X1 = CIRCLE_X0 + (CIRCLE_R*2);
localparam [8:0] CIRCLE_Y0 = 9'd445;
localparam [8:0] CIRCLE_Y1 = CIRCLE_Y0 + (CIRCLE_R*2);
localparam integer CIRCLE_CX = CIRCLE_X0 + CIRCLE_R;
localparam integer CIRCLE_CY = CIRCLE_Y0 + CIRCLE_R;
localparam integer CIRCLE_R_SQ = CIRCLE_R * CIRCLE_R;
localparam [8:0] GREEN_COLOR = 9'b000111000;

//states definitions for our main draw engine
localparam DRAW_IDLE = 2'd0;
localparam DRAW_BUSY = 2'd1;
localparam DRAW_WAIT = 2'd2;

reg [1:0] draw_state;
reg [4:0] gx, gy; //x and y defintion of the singular pixel that we are currently drawing WITHIN our mif file
reg [6:0] draw_idx; // basically defining a "grid" with this to draw on on our vga output, and this just chooses which section of the grid we are printing on.
reg [1:0] row;
reg [4:0] col;


//state definitions for our shape drawing FSM
localparam SHAPE_IDLE = 2'd0;
localparam SHAPE_CLEAR = 2'd1;
localparam SHAPE_CIRCLE = 2'd2;
localparam SHAPE_WAIT = 2'd3;

reg [1:0] shape_state; //state selector
reg [9:0] sx; //scanning the x and y dimensions
reg [8:0] sy;
reg reset_clear_pending; // black box reset pulse
reg clear_circle_pending; //Circle reset "pulse"


//selecting where we are "clearing"
reg [2:0] clear_step;
reg [9:0] curr_x0, curr_x1;
reg [8:0] curr_y0, curr_y1;

integer dx, dy, sx_i, sy_i; //defining two integers for looping in our fsm when we are trying to locate where to draw a shape
integer dist2;

// draw requests from UI and BIN info
reg ui_start_draw_digit;
reg info_start_draw_digit;
wire start_draw_digit_raw;
reg start_draw_digit_d;
wire start_draw_digit_pulse;
reg [6:0] new_digit_idx;
reg [4:0] new_draw_code;
reg new_draw_is_letter;
reg [9:0] X_r;
reg [8:0] Y_r;
reg [8:0] color_r;

//defining some delayed wires for debugging
reg[9:0] X_r_del;
reg[8:0] Y_r_del;
reg char_write_del;


//delayed pipeline for character printing issues
always @(posedge CLOCK_50)
begin
X_r_del <=X_r;
Y_r_del <=Y_r;
char_write_del <= (draw_state == DRAW_BUSY);
end

// shape (clear / circle) drawing registers
reg [8:0] shape_color;
reg [9:0] shape_X;
reg [8:0] shape_Y;
reg shape_write;
reg shape_active;

// glyph engine write strobe
wire glyph_write = (draw_state == DRAW_BUSY); //while we are in the busy mode, the character drawing enable is on (so we can print our characters)

//some wires for the abitrator to use
wire glyph_busy = (draw_state != DRAW_IDLE); // glyph engine is drawing a character
wire shape_can_draw = !glyph_busy && !ui_start_draw_digit && !info_start_draw_digit;
wire shape_takeover = shape_can_draw && (shape_state != SHAPE_IDLE);


// arbitrate between character drawing and shapes so that we dont accidentally "clear" while the user is typing
assign color = shape_takeover ? shape_color : color_r;
assign write = shape_takeover ? shape_write : char_write_del;
assign X = shape_takeover ? shape_X : X_r_del;
assign Y = shape_takeover ? shape_Y : Y_r_del;

// X/Y position assignment with CUSTOM PLACEMENT
always @(posedge CLOCK_50) begin
    color_r <= (draw_is_letter ? letter_pixel : digit_pixel);
    
    // We determine position based on the "Row" (draw_idx[5:4])
    case (draw_idx[6:4])
        // ROW 0: The 16-digit Card Number
        2'd0: begin 
            X_r <= CARD_X + (draw_idx[3:0] * (draw_is_letter ? LETTER_W : DIGIT_W)) + gx;
            Y_r <= CARD_Y + gy;
        end

        // ROW 1:Bank Name
        2'd1: begin 
            X_r <= BANK_X + (draw_idx[3:0] * (draw_is_letter ? LETTER_W : DIGIT_W)) + gx;
            Y_r <= BANK_Y + gy;
        end

        // ROW 2:Card Brand
        2'd2: begin 
            X_r <= BRAND_X + (draw_idx[3:0] * (draw_is_letter ? LETTER_W : DIGIT_W)) + gx;
            Y_r <= BRAND_Y + gy;
        end

        3'd3: begin
            X_r <= TYPE_X + (draw_idx[3:0] * (draw_is_letter ? LETTER_W : DIGIT_W)) + gx;
            Y_r <= TYPE_Y + gy;
        end
        3'd4: begin
            X_r <= LEVEL_X + (draw_idx[3:0] * (draw_is_letter ? LETTER_W : DIGIT_W)) + gx;
            Y_r <= LEVEL_Y + gy;
        end
    endcase
end


assign start_draw_digit_raw = ui_start_draw_digit | info_start_draw_digit;

always @(posedge CLOCK_50 or negedge RESET_N) begin
    if (!RESET_N)
        start_draw_digit_d <= 1'b0;
    else
        start_draw_digit_d <= start_draw_digit_raw;
end

assign start_draw_digit_pulse = start_draw_digit_raw & ~start_draw_digit_d;

// ROM address inside glyph
always @(*) begin
if(draw_is_letter)
    digit_addr = gy[3:0] * LETTER_W + gx[3:0];
    else
    digit_addr = gy * DIGIT_W +gx;
end

//if we are printing a letter or a digit (since they have different dimensions)
integer curW, curH;

//choosing which height width we want to use based on our drawIsletter signal 
always@(*)begin
curW = draw_is_letter ? LETTER_W : DIGIT_W;
curH = draw_is_letter ? LETTER_H : DIGIT_H;
end

// draw FSM
always @(posedge CLOCK_50 or negedge RESET_N) begin
    if (!RESET_N) begin
    //settign state to idle thats how we start
        draw_state <= DRAW_IDLE;
        //the mif we are drawing is set to 0,0 so we print from the start of the mif every time
        gx<= 0;
        gy<= 0;
        //the draw index is set to 0 so that we start printing in the very first column and row in our "grid"
        draw_idx <= 0;
        //we havent started printing anything, so we just set the selected character to "space"
        draw_code<= 0;
        draw_is_letter<= 1'b0;
    end else begin
        case (draw_state)

            DRAW_IDLE: begin
                if (start_draw_digit_pulse) begin
                //making sure to move to the next index each time we cycle through this fsm so that we dont just keep printing in the same spot
                    draw_idx <= new_digit_idx;
                    //changing the draw code based on the current draw ode
                    draw_code <= new_draw_code;
                    draw_is_letter <= new_draw_is_letter;
                    //starting from 0,0 for each .mif so that we dont start drawing from a random value of the mif
                    gx <= 0;
                    gy <= 0;
                    draw_state <= DRAW_BUSY;
                end
            end

            DRAW_BUSY: begin
            //cycling through the pixels first in the y direction then x (after each column is complete) then resetting the current position index to 0 for the next character
                if (gx == curW-1) begin
                    gx <= 0;
                    if (gy == curH-1) begin
                        gy <= 0;
                        draw_state <= DRAW_IDLE;
                    end else begin
                        gy <= gy + 1;
                    end
                end else begin
                    gx <= gx + 1;
                end
            end

            default: draw_state <= DRAW_IDLE;
        endcase
    end
end

//This is the ps2 converter section, where we send and recieve data from the ps2 keyboard
wire [7:0] received_data;
wire received_data_en;
wire command_was_sent;
wire error_communication_timed_out;

PS2_Controller ps2 (
    .CLOCK_50 (CLOCK_50),
    .reset(~RESET_N),
    .the_command(8'h00),
    .send_command (1'b0),
    .PS2_CLK (PS2_CLK),
    .PS2_DAT (PS2_DAT),
    .command_was_sent (command_was_sent),
    .error_communication_timed_out(error_communication_timed_out),
    .received_data (received_data),
    .received_data_en (received_data_en)
);

//defining names that are similar to what we used in the prototype to avoid refactoring code
wire KEY0, KEY1;
wire [9:0] SW;

ps2_converter ps2_convert(
    .CLOCK_50 (CLOCK_50),
    .sc (received_data),
    .ps2_pressed(received_data_en),
    .number (SW),
    .shift (KEY0),
    .check_luhn (KEY1)
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

wire key0_fall = key0_sync[1] & ~key0_sync[0];
wire key1_fall = key1_sync[1] & ~key1_sync[0];

wire key0_pressed = key0_fall;
wire key1_pressed = key1_fall;



//selecting the current digit and preparing it for the luhn module starts here
reg [3:0] sel_digit;//which digit we selected
reg sel_valid;// if thats a valid digit

//the case statement for selecting the digit based on what our SW value is (which we now get from the ps2 keyboard)
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


//defining reg for the count of the card number as well as the value of each digit (the first definitoin)
reg [3:0] digits [0:15];
reg [4:0] count;

//setting parameters for our luhn interface fsm
parameter ST_ENTRY = 2'd0,
          ST_READY = 2'd1,
          ST_RUN   = 2'd2;
reg [1:0] ui_state;

// UI's view of which glyph to draw
reg [6:0] ui_digit_idx;
reg [4:0] ui_digit_value;// 0..9 for digits (kept in 5 bits)
reg ui_draw_is_letter;// always 0 for card digits



//defining wires to use in our binary search module that checks the card information
reg bin_start;
wire bin_found;
wire bin_done;
wire [99:0] bank_name;
wire [79:0] card_brand;
wire [29:0] card_type;
wire [99:0] card_level;

reg bin_found_d;
wire bin_found_pulse;


//creating a pulse so that we can latch the found signa (remnants of debugging)
always@(posedge CLOCK_50 or negedge RESET_N)
begin
if(!RESET_N)
bin_found_d <= 1'b0;
else
bin_found_d <= bin_found;
end

assign bin_found_pulse = bin_found & ~bin_found_d;

// first 6 digits for Binary search storage definition
reg [3:0] bin_d0,bin_d1,bin_d2,bin_d3,bin_d4,bin_d5;
always@(*)
begin
bin_d0 <= digits[5];
bin_d1 <= digits[4];
bin_d2 <= digits[3];
bin_d3 <= digits[2];
bin_d4 <= digits[1];
bin_d5 <= digits[0];
end

//our binary search module instantiation
getBinInfo bin_info0 (
    .CLOCK_50 (CLOCK_50),
    .resetn (RESET_N),
    .start (bin_start),
    .d5 (bin_d5),
    .d4 (bin_d4),
    .d3 (bin_d3),
    .d2 (bin_d2),
    .d1 (bin_d1),
    .d0 (bin_d0),
    .found (bin_found),
    .done (bin_done),
    .bank_name (bank_name),
    .card_brand (card_brand),
    .card_type (card_type),
    .card_level (card_level)
);



always @(posedge CLOCK_50 or negedge RESET_N) begin
    if (!RESET_N) begin
    //set all the values to 0 so that we can begin the card number entry
        ui_state <= ST_ENTRY;
        count <= 5'd0;
        ui_start_draw_digit <= 1'b0;
        ui_digit_idx <= 6'd0;
        ui_digit_value <= 5'd0;
        //we are not drawing letters in this fsm so we can keep this 0
        ui_draw_is_letter <= 1'b0;
        //binary search does not start until luhn is valid and we are in st_un
        bin_start <= 1'b0;
    end else begin

        if (ui_state != ST_ENTRY)
            ui_start_draw_digit <= 1'b0;
        else
            ui_start_draw_digit <= 1'b0;

        case (ui_state)
            ST_ENTRY: begin
                //adding the digits to the wire that we send to luhn based on what index it is
                if (key0_pressed && sel_valid && (count < 16)) begin
                    digits[count] <= sel_digit;
                    ui_digit_idx <= {3'b000, count[3:0]};
                    ui_digit_value <= {1'b0, sel_digit};
                    ui_draw_is_letter <= 1'b0;
                    ui_start_draw_digit <= 1'b1;
                    count <= count + 1'b1;
                    //once we have entered 16 digits, we move to the next state
                    if (count == 5'd15)
                        ui_state <= ST_READY;
                end
            end

            //when the user is ready, thhey click enter and it moves to the enxt state
            ST_READY: begin
                if (key1_pressed)
                    ui_state <= ST_RUN;
            end

            //we only do a bin check if the card number is valid
            ST_RUN: begin
                // nothing here
                if (luhn_valid && !bin_start)
                    begin
                    bin_start<=1'b1;
                    end
            end

        endcase
    end
end

//attatching our selected digits to our luhn module
reg luhn_on;
reg [4:0] sr_idx;
reg [3:0] card_digit_reg;
reg started;
integer i;

wire luhn_valid, luhn_done, luhn_pulse;

always @(posedge CLOCK_50 or negedge RESET_N) begin
    if (!RESET_N) begin
        luhn_on <= 1'b0;
        sr_idx <= 5'd0;
        card_digit_reg <= 4'd0;
        started <= 1'b0;
    end else begin
        if (ui_state == ST_RUN && !started) begin
            started <= 1'b1;
            luhn_on <= 1'b1;
            sr_idx <= 5'd15;
            card_digit_reg <= digits[15];  //check digit first
        end

        if (luhn_pulse) begin
            for (i = 15; i >= 0; i = i - 1) begin
                if (sr_idx == i && i != 0) begin
                    sr_idx         <= i - 1;
                    card_digit_reg <= digits[i - 1];
                end
            end
        end
    end
end

//starting our luhn module
luhn u_luhn (
    .card_digit (card_digit_reg),
    .luhn_on    (luhn_on),
    .clock      (CLOCK_50),
    .resetn     (RESET_N),
    .validity   (luhn_valid),
    .done       (luhn_done),
    .pulse      (luhn_pulse)
);

// Pulse when Luhn finishes AND card is valid
reg  luhn_done_valid_prev;
wire luhn_done_valid_rise = (luhn_done & luhn_valid & ~luhn_done_valid_prev);

always @(posedge CLOCK_50 or negedge RESET_N) begin
    if (!RESET_N)
        luhn_done_valid_prev <= 1'b0;
    else
        luhn_done_valid_prev <= luhn_done & luhn_valid;
end


//creating functions that read the data from the bin search and set the values to the indexs of the wires we had previously defined
function [4:0] get_bank_char;
    input [99:0] word;
    input [4:0] idx;// 0 = first letter
    begin
        // Read 5 bits starting at MSB (99)
        get_bank_char = word[99 - 5*idx -: 5];
    end
endfunction

function [4:0] get_brand_char;
    input [79:0] word;
    input [4:0] idx;
    begin
        get_brand_char = word[79 - 5*idx -: 5];
    end
endfunction


function [4:0] get_type_char;
    input [29:0] word;
    input [4:0] idx;
    begin
        get_type_char = word[29 - 5*idx -: 5];
    end
endfunction

function [4:0] get_level_char;
    input [99:0] word;
    input [4:0] idx;
    begin
        get_level_char = word[99 - 5*idx -: 5];
    end
endfunction

//Drawing the info on the screen
//setting some parameters
localparam BANK_MAX_CHARS  = 16; // we clip to 16 even though we have 20
localparam BRAND_MAX_CHARS = 16;
localparam TYPE_MAX_CHARS  = 6;
localparam LEVEL_MAX_CHARS = 16;
localparam TOTAL_INFO_CHARS = BANK_MAX_CHARS + BRAND_MAX_CHARS + TYPE_MAX_CHARS + LEVEL_MAX_CHARS;

reg info_active;
reg [5:0] info_step;
reg [6:0] info_digit_idx;
reg [4:0] info_letter_index;
reg info_draw_is_letter;

reg [4:0] info_char_code_comb;
reg [2:0] info_row_comb;
reg [3:0] info_col_comb;
reg[5:0] temp_idx;
reg [5:0] temp_idx_plus7;

// Combinational selection of which char to draw at current info_step
always @(*) begin
    info_char_code_comb = 5'd31;
    info_row_comb = 2'd0;
    info_col_comb = 4'd0;
    temp_idx = 6'd0;

    // BANK NAME (0–15)
    if (info_step < BANK_MAX_CHARS) begin
        temp_idx = info_step;
        info_row_comb = 2'd1;
        info_col_comb = temp_idx[3:0];
        info_char_code_comb = get_bank_char(bank_name, temp_idx[4:0]);

    // BRAND NAME (16–31)
    end else if (info_step < BANK_MAX_CHARS + BRAND_MAX_CHARS) begin
        temp_idx = info_step - BANK_MAX_CHARS;
        info_row_comb = 2'd2;
        info_col_comb = temp_idx[3:0];
        info_char_code_comb = get_brand_char(card_brand, temp_idx[4:0]);

    // TYPE (32–37)
    end else if (info_step < BANK_MAX_CHARS + BRAND_MAX_CHARS + TYPE_MAX_CHARS) begin
        temp_idx = info_step - (BANK_MAX_CHARS + BRAND_MAX_CHARS);
        info_row_comb = 2'd3;
        info_col_comb = temp_idx[3:0]; // type starts at column 0
        info_char_code_comb = get_type_char(card_type, temp_idx[4:0]);

    // LEVEL (38–53)
   end else if (info_step < TOTAL_INFO_CHARS) begin
        temp_idx = info_step - (BANK_MAX_CHARS + BRAND_MAX_CHARS + TYPE_MAX_CHARS);
        info_row_comb = 3'd4; 
        info_col_comb = temp_idx[3:0]; 
        info_char_code_comb = get_level_char(card_level, temp_idx[4:0]);
    end

end


//smaller always (sub fsm) for our information drawing on the screen
always @(posedge CLOCK_50 or negedge RESET_N) begin
    if (!RESET_N) begin
        info_active <= 1'b0;
        info_step <= 6'd0;
        info_start_draw_digit <= 1'b0;
        info_digit_idx <= 6'd0;
        info_letter_index <= 5'd0;
        info_draw_is_letter <= 1'b0;
    end else begin
        info_start_draw_digit <= 1'b0;
            //start the information print if the bin is found
        if (bin_found_pulse) begin
            info_active <= 1'b1;
            info_step   <= 6'd0;
        end else if (info_active && (draw_state == DRAW_IDLE) && (shape_state == SHAPE_IDLE) && !ui_start_draw_digit && !info_start_draw_digit) begin
        //pringting the information step by step
            if (info_step < TOTAL_INFO_CHARS) begin
                if (info_char_code_comb < 5'd26) begin
                    info_digit_idx <= {info_row_comb, info_col_comb};
                    info_letter_index <= info_char_code_comb;
                    info_draw_is_letter <= 1'b1;
                    info_start_draw_digit <= 1'b1;
                end
                info_step <= info_step + 1'b1;
            end else begin
                info_active <= 1'b0;
            end
        end
    end
end


// dynamic clear box coordinates based on the step
always @(*) begin
    case (clear_step)
        // Clear Card Digits
        3'd0: begin
            curr_x0 = CARD_X;
            curr_x1 = CARD_X + (16 * DIGIT_W);
            curr_y0 = CARD_Y;
            curr_y1 = CARD_Y + DIGIT_H;
        end
        // Clear Bank Name
        3'd1: begin
            curr_x0 = BANK_X;
            curr_x1 = BANK_X + (BANK_MAX_CHARS * LETTER_W);
            curr_y0 = BANK_Y;
            curr_y1 = BANK_Y + LETTER_H;
        end
        // Clear Brand
        3'd2: begin
            curr_x0 = BRAND_X;
            curr_x1 = BRAND_X + (BRAND_MAX_CHARS * LETTER_W);
            curr_y0 = BRAND_Y;
            curr_y1 = BRAND_Y + LETTER_H;
        end
        // Clear Type
        3'd3: begin
            curr_x0 = TYPE_X;
            curr_x1 = TYPE_X + (TYPE_MAX_CHARS * LETTER_W);
            curr_y0 = TYPE_Y;
            curr_y1 = TYPE_Y + LETTER_H;
        end
        // Clear Level
        3'd4: begin
            curr_x0 = LEVEL_X;
            curr_x1 = LEVEL_X + (LEVEL_MAX_CHARS * LETTER_W);
            curr_y0 = LEVEL_Y;
            curr_y1 = LEVEL_Y + LETTER_H;
        end
        // Default safe values
        default: begin
            curr_x0 = 0; curr_x1 = 0; curr_y0 = 0; curr_y1 = 0;
        end
    endcase
end


//below is the shape drawing fsm, (idk what my partner wanted to say here, https://www.reddit.com/r/redditsniper/)
always @(posedge CLOCK_50 or negedge RESET_N) begin
    if (!RESET_N) begin
        shape_state <= SHAPE_CIRCLE;
        shape_active <= 1'b0;
        shape_write <= 1'b0;
        sx <= CIRCLE_X0;
        sy <= CIRCLE_Y0;
        clear_circle_pending <= 1'b1;
        reset_clear_pending <= 1'b1;
        clear_step <= 3'd0; // reset step counter
    end else begin
        // default: no write unless a state asserts it
        shape_write  <= 1'b0;
        shape_active <= (shape_state != SHAPE_IDLE);

        case (shape_state)
            SHAPE_IDLE: begin
                if (reset_clear_pending) begin
                    shape_state <= SHAPE_CLEAR;
                    clear_step <= 3'd0; // start at the first section (card digits)
                    // load coordinates for step 0 immediately
                    sx <= CARD_X; 
                    sy <= CARD_Y;
                end
                else if (luhn_done_valid_rise) begin
                    shape_state <= SHAPE_CIRCLE;
                    sx <= CIRCLE_X0;
                    sy <= CIRCLE_Y0;
                end
            end

            SHAPE_CLEAR: begin
                // draw black pixels
                shape_color <= 9'd0;
                shape_X <= sx;
                shape_Y <= sy;
                shape_write <= 1'b1;

                // check bounds using the DYNAMIC variables (curr_x1, curr_y1)
                if (sx >= curr_x1 - 1) begin
                    sx <= curr_x0; // reset X to start of current box
                    if (sy >= curr_y1 - 1) begin
                        // box finished
                        // check if we have more sections to clear
                        if (clear_step < 3'd4) begin
                            clear_step <= clear_step + 1'b1;        
                            sx <= 0; // temp value, will be corrected by logic below
                            sy <= 0; // temp value
                        end else begin
                            // ALL 5 sections cleared
                            shape_state <= SHAPE_IDLE;
                            reset_clear_pending <= 1'b0;
                        end
                    end else begin
                        sy <= sy + 1'b1;
                    end
                end else begin
                    sx <= sx + 1'b1;
                end
                

                if (sy == (curr_y1 - 1) && sx == (curr_x1 - 1) && clear_step < 3'd4) begin
                     shape_state <= SHAPE_WAIT; 
                end
            end
            
            // wait state to allow combinational logic to update coordinates
            SHAPE_WAIT: begin
                shape_state <= SHAPE_CLEAR;
                sx <= curr_x0;
                sy <= curr_y0;
            end

            SHAPE_CIRCLE: begin
                // check if arbitrator allows drawing
                // if text is printing, shape_can_draw will be 0, and we pause
                if (shape_can_draw) begin

                    sx_i = sx;
                    sy_i = sy;
                    
                    dx = sx_i - CIRCLE_CX;
                    dy = sy_i - CIRCLE_CY;
                    dist2 = dx*dx + dy*dy;

                    // draw pixel if inside the radius
                    if (dist2 <= CIRCLE_R_SQ) begin
                        shape_color <= clear_circle_pending ? 9'd0 : GREEN_COLOR;
                        shape_X <= sx;
                        shape_Y <= sy;
                        shape_write <= 1'b1;
                    end else begin
                        // ensure we don't write stray pixels outside the circle
                        shape_write <= 1'b0; 
                    end

                    // increment Logic
                    if (sx == CIRCLE_X1 - 1) begin
                        sx <= CIRCLE_X0;
                        if (sy == CIRCLE_Y1 - 1) begin
                            // circle Finished
                            clear_circle_pending <= 1'b0;
                            sy <= CIRCLE_Y0;
                            shape_state <= SHAPE_IDLE;
                        end else begin
                            sy <= sy + 1'b1;
                        end
                    end else begin
                        sx <= sx + 1'b1;
                    end

                end else begin
                    // PAUSE STATE bc text engine is busy
                    // hold current SX/SY coordinates and wait
                    shape_write <= 1'b0;
                end
            end
            default: shape_state <= SHAPE_IDLE;
        endcase
    end
end

//basically merging the info drawing and the shape drawing into the main fsm
always @(*) begin
    if (ui_start_draw_digit) begin
        new_digit_idx = ui_digit_idx;
        new_draw_code = ui_digit_value;
        new_draw_is_letter = ui_draw_is_letter;
    end else if (info_start_draw_digit) begin
        new_digit_idx = info_digit_idx;
        new_draw_code = info_letter_index;
        new_draw_is_letter = 1'b1;
    end else begin
        new_digit_idx = 6'd0;
        new_draw_code = 5'd0;
        new_draw_is_letter = 1'b0;
    end
end

//below is just our debug for the seg7 displays, we use this to see the prvious digit, as well as the current index of card we are entering
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
parameter [6:0] SEG7_DASH  = 7'b0111111;

reg [6:0] hex0_reg, hex4_reg, hex5_reg;
reg [4:0] idx;
reg [3:0] ones;
reg tens;

always @(*) begin
    // HEX0: selected digit
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
    end else begin
        tens = 1'b0;
        ones = idx[3:0];
    end

    if (tens)
        hex5_reg = seg7_digit(4'd1);
    else
        hex5_reg = SEG7_BLANK;

    hex4_reg = seg7_digit(ones);
end

assign HEX0 = hex0_reg;
assign HEX4 = hex4_reg;
assign HEX5 = hex5_reg;

//some debugging of signals with the LEDR
always @(*)
begin
    // Luhn result
    LEDR[0] <= luhn_done &  (luhn_valid);
    LEDR[9] <= luhn_done & ~(luhn_valid);

    // BIN found indicator
    LEDR[6] <= bin_found;
    LEDR[5] <= bin_start;
end
endmodule

// code to implement the luhn algorithm
// this assumes we have:
// - a working SR to store the digits, which listens to a pulse signal and updates 4-bit value of R->L digit of card
// - code outside of luhn should conver the 16 bit signal from switches to 4 bits
// - all 4 bit inputs are valid
module luhn(
    input  wire [3:0] card_digit,// card_digit is a single 4 bit digit of card; output of SR
    input  wire luhn_on,// signal to turn on the luhn module
    input  wire clock,
    input  wire resetn,
    output reg validity,// LEDR value (we turn on led9 if invalid, led0 if valid)
    output reg done,// 1 while in FINAL_CHECK
    output wire pulse// pulse to shift new value out of SR
);
    parameter IDLE = 3'd0, GET_CHECK_DIGIT = 3'd1, SHIFT_ODD = 3'd2, PROCESS_ODD = 3'd3, SHIFT_EVEN = 3'd4, PROCESS_EVEN  = 3'd5, FINAL_CHECK = 3'd6, INVALID = 3'd7;

    reg [2:0] state, next_state;
    reg [4:0] digit_count;// Internal counter for 16 digits (0-15)
    reg [7:0] sum; // single running sum of processed digits D1..D15
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

