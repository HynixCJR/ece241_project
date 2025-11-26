// returns the 100bit card level associated with the BIN number
// merged into a single module to ensure correct Block RAM timing and inference

module getCardLevel(
    input wire CLOCK_50,
    input wire [11:0] found_index, // index where BIN was found
    input wire resetn, // universal reset signal (Active Low)
    input wire binary_search_done,
    input wire binary_search_found,

    output reg [99:0] card_level, // outputted bank name, will be all 0 if binary_search_done == 0
                                 // if binary_search_done == 1 & binary_search_found == 0, outputted
                                 // name will correspond to "BANK NAME NOT FOUND"
    output reg card_level_search_done // 0 if not done, 1 if done
);

    // INDICES
    // 2638 words deep, 6 bits wide
    // use 'reg' array to infer memory
    reg [5:0] card_levels_indices [0:2637] /* synthesis ram_init_file = "./bindb/card_level_indices.mif" */;

    // NAMES
    // 51 words deep, 100 bits wide
    reg [99:0] card_levels [0:50] /* synthesis ram_init_file = "./bindb/card_level.mif" */;

    // SIGNALS
    // Intermediate registers for the memory pipeline
    reg [5:0] internal_bank_index; // always assigned to a value in card_level_indices
    reg [99:0] internal_card_level_raw; // always assigned to a value in card_level
    // Pipeline control signals to match memory latency (2 cycles)
    reg [1:0] pipe_done;
    reg [1:0] pipe_found;

    // LOGIC
    // synchronous memory reads
    always @(posedge CLOCK_50) begin
        // cycle 1: read index from first memory using search result
        internal_bank_index <= card_levels_indices[found_index];

        // cycle 2: read name from second memory using result of cycle 1
        // note: this naturally happens 1 clock cycle after internal_bank_index is updated
        internal_card_level_raw <= card_levels[internal_bank_index];
    end

    // control pipeline and output logic
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            // reset all value
            card_level_search_done <= 1'b0;
            card_level <= 100'b0;
            pipe_done <= 2'b0;
            pipe_found <= 2'b0;
        end else begin
            // shift control signals down pipeline to match memory latency
            // we delay signals by 2 clock cycles so they arrive at the end
            // at the exact same time the data arrives from the memories
            pipe_done <= {pipe_done[0], binary_search_done};
            pipe_found <= {pipe_found[0], binary_search_found};

            // check the delayed "done" signal (output of the pipeline)
            if (pipe_done[1]) begin
                card_level_search_done <= 1'b1;

                // check the delayed "found" signal
                if (pipe_found[1]) begin
                    // if binary search produced a result, output the memory data
                    card_level <= internal_card_level_raw;
                end else begin
                    // if binary search produces no results then set bank name to "CARD LEVEL NOT FOUND"
                    card_level <= 100'b0001100001100100010000000011000010110110001010110000000011100111110100000000011001111101010111000100;
                end
            end else begin
                // if not done, keep waiting
                card_level_search_done <= 1'b0;
                card_level <= 100'b0;
            end
        end
    end

endmodule