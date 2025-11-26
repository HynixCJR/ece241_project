// uses a sequential FSM to perform binary search on ./bindb/BIN_numbers.mif
// which is a sorted list (ascending) list of BIN numbers
// the indices of which correspond to the indices of an encoded bank name + card brand + card type + card level .mif

module bin_binary_search (
    input wire clk, // logic transitions on rising edge of clock
    input wire reset, // low = reset system
    input wire start, // high = start search
    // d5 to d0 correspond to 6 digit input
    input wire [3:0] d5, d4, d3, d2, d1, d0,
    
    output reg found, // high = number exists
    output reg [11:0] index_out, // address where memory found, IF FOUND (otherwise it will be 0)
    output reg done // high when search is finished
);

    // MEMORY DECLARATION
    // 2638 words deep, 20 bits wide
    // use 'reg' array to infer memory
    reg [19:0] memory_array [0:2637] /* synthesis ram_init_file = "./bindb/BIN_numbers.mif" */;

    // REGISTERS
    reg [19:0] target; // converted search value (20 bit integer version of 6 digit input)
    reg [12:0] low; // bottom index of current range
    reg [12:0] high; // top index of current range
    reg [12:0] mid; // middle index; the index we are currently checking
    // indices are 12 bits to fit 0 -> 2637 indicies, + 1 bit to prevent overflow in low + high calculation
    
    reg [19:0] read_data; // temp buffer to hold the BIN data read from memory

    // STATE MACHINE
    parameter S_IDLE = 3'd0; // waiting state: if reset high and/or start low
    parameter S_CONVERT = 3'd1; // convert state: converts six 4bit digits into single 20 bit number, for optimization
    parameter S_CALC = 3'd2; // calculate state: calculates the midpoint of the subarray (i.e., "mid" reg)
    parameter S_READ = 3'd3; // wait for memory to return the value stored at the mid index of subarray
    parameter S_COMPARE = 3'd4; // compare memory data with target
    parameter S_DONE = 3'd5; // finished state

    reg [2:0] state;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin // reset everything back to 0 or IDLE
            state <= S_IDLE;
            found <= 0;
            index_out <= 0;
            done <= 0;
        end else begin
            case (state)
                S_IDLE: begin // at IDLE state set done to low
                    done <= 0;
                    if (start) begin // if we start the search then move onto CONVERT state
                        state <= S_CONVERT;
                    end
                end

                // state 1: 6x4-bit digits to 20-bit binary conversion
                S_CONVERT: begin
                    target <= (d5 * 20'd100000) + (d4 * 20'd10000) + (d3 * 20'd1000) + (d2 * 20'd100) + (d1 * 20'd10) + d0;
                    
                    // set initial search bounds
                    low <= 0; // lowest index
                    high <= 2638; // max index
                    found <= 0;
                    state <= S_CALC;
                end

                //state 2: calculate mid
                S_CALC: begin
                    if (low > high) begin
                        // case where item not found
                        found <= 0;
                        state <= S_DONE;
                    end else begin
                        // calculate midpoint if item has yet to be found
                        // mid = (low + high) / 2
                        // apparently divide is >> ????
                        mid <= (low + high) >> 1; 
                        state <= S_READ; // move on to the READ state
                    end
                end

                // state 3: read memory
                // use a cycle for memory address to result in data out
                // bc in M10K blocks, reading is synchronous, so data arrives in next cycle
                // this basically just exists as a delay
                S_READ: begin
                    // use 'mid' from previous state as address
                    read_data <= memory_array[mid];
                    state <= S_COMPARE;
                end

                // state 4: compare
                // the actual comparison step in the binary search algo
                S_COMPARE: begin
                    if (read_data == target) begin
                        // MATCH FOUND!!
                        // set found = high and output index = mid
                        found <= 1;
                        index_out <= mid[11:0];
                        state <= S_DONE;
                    end 
                    else if (read_data < target) begin
                        // case where value is in upper half
                        low <= mid + 1;
                        state <= S_CALC;
                    end 
                    else begin // read_data > target
                    // value is in the lower half
                    if (mid == 0) begin
                        // Item not found - can't search lower than index 0
                        found <= 0;
                        state <= S_DONE;
                    end else begin
                        high <= mid - 1;
                        state <= S_CALC;
                    end
                    end
                end

                S_DONE: begin
                    done <= 1;
                    // wait for start to go low before resetting to IDLE 
                    if (!start) state <= S_IDLE;
                end
            endcase
        end
    end

endmodule