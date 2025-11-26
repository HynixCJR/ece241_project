// returns the 100bit bank name associated with the BIN number
// merged into a single module to ensure correct Block RAM timing and inference

module getBankName(
    input wire CLOCK_50,
    input wire [11:0] found_index, // index where BIN was found
    input wire resetn, // universal reset signal (Active Low)
    input wire binary_search_done,
    input wire binary_search_found,

    output reg [99:0] bank_name, // outputted bank name, will be all 0 if binary_search_done == 0
                                 // if binary_search_done == 1 & binary_search_found == 0, outputted
                                 // name will correspond to "BANK NAME NOT FOUND"
    output reg bank_name_search_done // 0 if not done, 1 if done
);

    // INDICES
    // 2638 words deep, 6 bits wide
    // use 'reg' array to infer memory
    reg [5:0] bank_names_indices [0:2637] /* synthesis ram_init_file = "./bindb/bank_names_indices.mif" */;

    // NAMES
    // 59 words deep, 100 bits wide
    reg [99:0] bank_names [0:58] /* synthesis ram_init_file = "./bindb/bank_names.mif" */;

    // SIGNALS
    // Intermediate registers for the memory pipeline
    reg [5:0] internal_bank_index; // always assigned to a value in bank_names_indices
    reg [99:0] internal_bank_name_raw; // always assigned to a value in bank_names
    
    // Pipeline control signals to match memory latency (2 cycles)
    reg [1:0] pipe_done;
    reg [1:0] pipe_found;

    // synchronous memory reads
    always @(posedge CLOCK_50) begin
        // cycle 1: read index from first memory using search result
        internal_bank_index <= bank_names_indices[found_index];

        // cycle 2: read name from second memory using result of cycle 1
        // note: this naturally happens 1 clock cycle after internal_bank_index is updated
        internal_bank_name_raw <= bank_names[internal_bank_index];
    end

    // control pipeline and output logic
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            // reset all value
            bank_name_search_done <= 1'b0;
            bank_name <= 100'b0;
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
                bank_name_search_done <= 1'b1;

                // check the delayed "found" signal
                if (pipe_found[1]) begin
                    // if binary search produced a result, output the memory data
                    bank_name <= internal_bank_name_raw;
                end else begin
                    // if binary search produces no results then set bank name to "BANK NAME NOT FOUND"
                    bank_name <= 100'b0001000001011100101100000011100000101101001010000001110011111010000000001100111110101011100010000000;
                end
            end else begin
                // if not done, keep waiting
                bank_name_search_done <= 1'b0;
                bank_name <= 100'b0;
            end
        end
    end

endmodule