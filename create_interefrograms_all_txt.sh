#!/bin/bash

# File containing the list of dates (one date per line in YYYYMMDD format)
INPUT_FILE="listarslc.txt"
OUTPUT_FILE_2="combination_shorts.txt"

# Step 3: Remove listarslc.txt if it exists
[ -f listarslc.txt ] && rm listarslc.txt

# Step 4: List files in RSLC directory and save to listarslc.txt
ls RSLC -1 >> listarslc.txt

# Ensure the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Input file $INPUT_FILE not found!"
    exit 1
fi


# Clear the output file
if [ -f "$OUTPUT_FILE_2" ]; then
    echo "Output file $OUTPUT_FILE_2 found. Erasing!"
    > "$OUTPUT_FILE_2"
else
    > "$OUTPUT_FILE_2"
fi


# Read dates into an array
dates=($(cat "$INPUT_FILE"))

# Read all lines into an array
mapfile -t lines < "$INPUT_FILE"

# Loop over lines and create combinations (up to next 4 lines)
for ((i=0; i<${#lines[@]}; i++)); do
    for ((j=i+1; j<i+3 && j<${#lines[@]}; j++)); do
        echo "${lines[i]}_${lines[j]}" >> "$OUTPUT_FILE_2"
    done
done

echo "Short combinations written to $OUTPUT_FILE_2"
line_count=$(wc -l < "$OUTPUT_FILE_2")
echo "Total number of combinations generated: $line_count"

