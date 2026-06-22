#!/usr/bin/env python
# Pedro Espin-Bedon
import numpy as np
import matplotlib.pyplot as plt
import os

# File name
file_name = 'output_averages_from_cc_tifs.txt'

# Initialize lists to store data
data_values = []

# Read the file
with open(file_name, 'r') as file:
    for line in file:
        parts = line.strip().split()
        if len(parts) == 2:
            try:
                value = float(parts[1])
                data_values.append(value)
            except ValueError:
                # Skip lines with 'nan' or non-numeric values
                continue

# Convert to NumPy array
data_values = np.array(data_values)

# Calculate mean and standard deviation
mean_value = np.nanmean(data_values)
std_value = np.nanstd(data_values)

# Print mean and standard deviation
print(f"Mean: {mean_value:.2f}")
print(f"Standard Deviation: {std_value:.2f}")

# Plot histogram
plt.figure(figsize=(8, 6))
plt.hist(data_values, bins=15, color='blue', alpha=0.7, edgecolor='black')
plt.axvline(mean_value, color='red', linestyle='dashed', linewidth=1.5, label=f'Mean: {mean_value:.4f}')
#plt.axvline(0.4, color='red', linestyle='dashed', linewidth=1.5, label='Mean: 0.4')

plt.title('Histogram of longs IFS')
plt.xlabel('Value')
plt.ylabel('Frequency')
plt.grid(axis='y', linestyle='--', alpha=0.7)

# Add mean and standard deviation to the plot
plt.text(0.05, 0.9, f"Mean: {mean_value:.4f}\nStd: {std_value:.4f}", transform=plt.gca().transAxes, 
         fontsize=12, bbox=dict(facecolor='white', alpha=0.5, edgecolor='black'))

# Save the figure
current_directory = os.getcwd()
# Extract parts of the directory for naming
path_parts = current_directory.split(os.sep)
if len(path_parts) >= 2:
    location_name = path_parts[-2]
    batch_name = path_parts[-1]
else:
    location_name = "Unknown"
    batch_name = "Unknown"
output_filename = f"Histogram_{location_name}_{batch_name}.png"
output_path = os.path.join(current_directory, output_filename)


# Save the mean value to a text file
mean_output_filename = f"mean_value_{location_name}_{batch_name}.txt"
mean_output_path = os.path.join(current_directory, mean_output_filename)
if os.path.exists(mean_output_path):
    os.remove(mean_output_path)
with open(mean_output_path, 'w') as mean_file:
    mean_file.write(f"{mean_value:.3f}")

plt.savefig(output_path, dpi=300)

# Show the plot
#plt.show()
