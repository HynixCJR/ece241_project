// module that searches for a 6 x 4-bit digit in a BIN database
// this is the "top level module" for the database, main module for rest of code calls getBinInfo() module

module getBinInfo(
    input wire CLOCK_50, // clock signal
    input wire resetn, // low = reset system
    input wire start, // high = start search
    input wire [3:0] d5, d4, d3, d2, d1, d0, // first 6 digits

    output wire found, // high = number exists AND other data found (card level, type, etc.), NOT the same as 'found' in bin_binary_search()
    output wire done, //debugging wire
    output wire [99:0] bank_name, // stores the encoded bank name (bank of montreal, scotiabank, etc.)
    output wire [79:0] card_brand, // stores the encoded card brand (mastercard, visa, etc.)
    output wire [29:0] card_type, // stores the encoded card type (debit/credit)
    output wire [99:0] card_level // stores the encoded card level (standard, premium, commercial, etc.)
);

wire binary_search_found, binary_search_done;
// found != done bc done will always result, but found will only be 1 if the value was actually found, else it will be 0
wire [11:0] binary_search_index_out;

bin_binary_search binary_search0 (
    .clk(CLOCK_50),
    .reset(resetn),
    .start(start),
    .d5(d5),
    .d4(d4),
    .d3(d3),
    .d2(d2),
    .d1(d1),
    .d0(d0),
    .found(binary_search_found),
    .index_out(binary_search_index_out),
    .done(binary_search_done)
);


wire bank_name_search_done, card_brand_search_done, card_type_search_done, card_level_search_done;
assign found = (binary_search_found & bank_name_search_done & card_brand_search_done & card_type_search_done & card_level_search_done);
assign done = binary_search_done;

getBankName bank_name0 (
    .CLOCK_50(CLOCK_50),
    .found_index(binary_search_index_out),
    .resetn(resetn),
    .binary_search_done(binary_search_done),
    .binary_search_found(binary_search_found),//changed from binary_search_found
    .bank_name(bank_name),
    .bank_name_search_done(bank_name_search_done)
);

getCardBrand card_brand0 (
    .CLOCK_50(CLOCK_50),
    .found_index(binary_search_index_out),
    .resetn(resetn),
    .binary_search_done(binary_search_done),
    .binary_search_found(binary_search_found),
    .card_brand(card_brand),
    .card_brand_search_done(card_brand_search_done)
);

getCardType card_type0 (
    .CLOCK_50(CLOCK_50),
    .found_index(binary_search_index_out),
    .resetn(resetn),
    .binary_search_done(binary_search_done),
    .binary_search_found(binary_search_found),
    .card_type(card_type),
    .card_type_search_done(card_type_search_done)
);

getCardLevel card_level0 (
    .CLOCK_50(CLOCK_50),
    .found_index(binary_search_index_out),
    .resetn(resetn),
    .binary_search_done(binary_search_done),
    .binary_search_found(binary_search_found),
    .card_level(card_level),
    .card_level_search_done(card_level_search_done)
);

endmodule