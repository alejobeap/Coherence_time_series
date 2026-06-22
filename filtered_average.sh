#!/bin/bash
# Pedro Espin-Bedon
parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")

# Define file paths
input_file="output_averages_from_cc_tifs.txt"
output_file="filtered_IFS_average_cc_value.txt"
mean_file="mean_value_${parent_dir}_${current_dir}.txt"

# Check if mean file exists
if [ ! -f "$mean_file" ]; then
  echo "Error: Mean value file $mean_file does not exist."
  exit 1
fi

# Read the mean value from the text file
#mean_value=$(cat "$mean_file" | awk '{print $1}') # Assumes the format is "Mean: value"
#mean_value=$(awk '{printf "%.2f", int($1*100)/100}' "$mean_file")  # only take 2 decimals the 0.25 from 0.258 
mean_value=$(awk '{
    v = int($1*100)/100   # Trunca a 2 decimales
    if ($1 > 0.7 && $1 < 0.9)          # Compara con el valor original, no con v
        printf "0.8"
#    else if ($1 > 0.9)
#       printf "%.2f"
    else
        printf "%.2f", v
}' "$mean_file")

echo $mean_value



# Clear output file if it exists
> "$output_file"

# Clear output file if it exists
if [ -e "$output_file" ]; then
  > "$output_file"
fi

while IFS= read -r line
do
  # Extract second column value
  col2=$(echo "$line" | awk '{print $2}')

  # Check if col2 is empty
  if [[ -z "$col2" ]]; then
    continue
  fi

  # Check if col2 is a valid number
  if ! [[ "$col2" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    continue
  fi

  # Check threshold condition using mean_value
  awk -v val="$col2" -v threshold="$mean_value" 'BEGIN{if(val > threshold) exit 0; else exit 1}'
#  awk -v val="$col2" -v threshold=0.4 'BEGIN{if(val > threshold) exit 0; else exit 1}'
  if [[ $? -eq 0 ]]; then
    # Extract first column and append to output file
    echo "$line" | awk '{print $1}' >> "$output_file"
  fi

done < "$input_file"



input_file="output_std_from_cc_tifs.txt"
output_file="filtered_IFS_std_cc_value.txt"

# Clear output file if it exists
> "$output_file"

while IFS= read -r line
do
  # Extract second column value
  col2=$(echo "$line" | awk '{print $2}')

  # Check if col2 is empty
  if [[ -z "$col2" ]]; then
    continue
  fi

  # Check if col2 is a valid number
  if ! [[ "$col2" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    continue
  fi

  # Check threshold condition
  # Only keep if col2 > 0.2 ##or col2 < -100
  awk -v val="$col2" 'BEGIN{if(val > 0.2 ) exit 0; else exit 1}'
  if [[ $? -eq 0 ]]; then
    # Extract first column and append to output file
    echo "$line" | awk '{print $1}' >> "$output_file"
  fi

done < "$input_file"
