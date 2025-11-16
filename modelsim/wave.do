onerror {resume}
quietly WaveActivateNextPane {} 0

# --- Top-level signals from your example style ---
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label KEY -radix binary /testbench/KEY
add wave -noupdate -label SW -radix binary /testbench/SW
add wave -noupdate -label LEDR -radix binary /testbench/LEDR
add wave -noupdate -label HEX0 -radix binary /testbench/HEX0
add wave -noupdate -label HEX4 -radix binary /testbench/HEX4
add wave -noupdate -label HEX5 -radix binary /testbench/HEX5

# --- Add state for context (highly recommended) ---
add wave -noupdate -label luhn_state /testbench/U1/u_luhn/state

# --- Configuration from your example ---
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 120
configure wave -valuecolwidth 60
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {4000 ns}