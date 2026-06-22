#!/usr/bin/env python
# Pedro Espin-Bedon
#Coherence Matrix plot
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
import sys

# Define file paths
# Get the parent and current directory names
current_dir = os.path.basename(os.getcwd())
parent_dir = os.path.basename(os.path.dirname(os.getcwd()))
mean_file = f"mean_value_{parent_dir}_{current_dir}.txt"

# Check if mean file exists
if not os.path.isfile(mean_file):
    print(f"Error: Mean value file {mean_file} does not exist.")
    sys.exit(1)

# Read the mean value from the text file
try:
    with open(mean_file, 'r') as file:
        mean_value = float(file.readline().split()[0])  # Assumes the format is "Mean: value"
        mean_value = int(mean_value * 100) / 100 ## take only two decimals is correct?
    print(f"Mean value read from file: {mean_value}")
except Exception as e:
    print(f"Error reading mean value from file: {e}")
    sys.exit(1)


# Cargar los datos del archivo
file_path = "output_averages_from_cc_tifs.txt"
data = []

with open(file_path, "r") as file:
    for line in file:
        parts = line.strip().split()
        if len(parts) == 2:
            dates, value = parts
            date1, date2 = dates.split("_")
            data.append([date1, date2, float(value)])

# Crear un DataFrame
df = pd.DataFrame(data, columns=["date1", "date2", "coherence"])

# Crear una matriz de coherencia
unique_dates1 = sorted(df["date1"].unique())
unique_dates2 = sorted(df["date2"].unique())
matrix = np.full((len(unique_dates1), len(unique_dates2)), np.nan)

matrix_filt = np.full((len(unique_dates1), len(unique_dates2)), np.nan)

nifgs=0
# Rellenar la matriz con los valores de coherencia
for _, row in df.iterrows():
    i = unique_dates1.index(row["date1"])
    j = unique_dates2.index(row["date2"])
    matrix[i, j] = row["coherence"]
    nifgs=nifgs+1

# Graficar la matriz
plt.figure(figsize=(30, 20))
cmap = plt.cm.viridis
plt.imshow(matrix, cmap=cmap, aspect="auto", origin="upper")

# AÃ±adir etiquetas a los ejes
plt.xticks(ticks=range(len(unique_dates2)), labels=unique_dates2, rotation=90, fontsize=7)
plt.yticks(ticks=range(len(unique_dates1)), labels=unique_dates1, fontsize=7)
plt.colorbar(label="Coherence")
plt.title(f"Coherence Matrix (All longs IFS:{nifgs})")
plt.xlabel("Date2")
plt.ylabel("Date1")

# Add `nigs` value in the top-left corner
#plt.text(
#    x=-0.1,  # Adjust based on plot dimensions
#    y=1.05,  # Adjust based on plot dimensions
#    s=f"IFS: {nifgs}", 
#    fontsize=10, 
#    transform=plt.gca().transAxes  # Use axes-relative coordinates
#)


# Guardar la imagen
plt.tight_layout()

output_file = f"matrix_{parent_dir}_{current_dir}.png"

#output_file = "mnatris.png"
plt.savefig(output_file, dpi=100)
plt.close()

print(f"Imagen guardada como {output_file}")




nifgs=0
# Rellenar la matriz con los valores de coherencia
for _, row in df.iterrows():
    if row["coherence"]>mean_value:
      i = unique_dates1.index(row["date1"])
      j = unique_dates2.index(row["date2"])
      matrix_filt[i, j] = row["coherence"]
      nifgs=nifgs+1
    else:
      continue


# Graficar la matriz
plt.figure(figsize=(30, 20))
cmap = plt.cm.viridis
plt.imshow(matrix_filt, cmap=cmap, aspect="auto", origin="upper")

# AÃ±adir etiquetas a los ejes
plt.xticks(ticks=range(len(unique_dates2)), labels=unique_dates2, rotation=90, fontsize=7)
plt.yticks(ticks=range(len(unique_dates1)), labels=unique_dates1, fontsize=7)
plt.colorbar(label="Coherence")
plt.title(f"Filter Coherence Matrix (IFS:{nifgs})")
plt.xlabel("Date2")
plt.ylabel("Date1")

# Add `nigs` value in the top-left corner
#plt.text(
#    x=-0.1,  # Adjust based on plot dimensions
#    y=1.05,  # Adjust based on plot dimensions
#    s=f"IFS: {nifgs}",
#    fontsize=10,
#    transform=plt.gca().transAxes  # Use axes-relative coordinates
#)


# Guardar la imagen
plt.tight_layout()

output_file = f"filtered_matrix_{parent_dir}_{current_dir}.png"

#output_file = "filtered_matriz.png"
plt.savefig(output_file, dpi=100)
plt.close()

print(f"Imagen guardada como {output_file}")


def extract_year(date_str):
    # Extrae los 4 primeros dígitos como año
    return int(date_str[:4])

# Rango de años bianuales
year_ranges = [(2014, 2016), (2016, 2018), (2018, 2020), (2020, 2022), (2022, 2024), (2024, 2026)]

def plot_submatrices(matrix_data, title_prefix, output_prefix):
    for matrix_type, matrix_name in zip([matrix, matrix_filt], ["full", "filtered"]):
        fig, axes = plt.subplots(2, 3, figsize=(36, 24))  # 6 subplots en una sola figura
        axes = axes.flatten()

        for idx, (start_year, end_year) in enumerate(year_ranges):
            ax = axes[idx]
            
            # Filtrar fechas dentro del rango
            date1_indices = [i for i, d in enumerate(unique_dates1) if start_year <= extract_year(d) < end_year]
            date2_indices = [j for j, d in enumerate(unique_dates2) if start_year <= extract_year(d) < end_year]

            # Submatriz y etiquetas
            if not date1_indices or not date2_indices:
                ax.set_title(f"{start_year}-{end_year}\n(No data)")
                ax.axis('off')
                continue

            submatrix = matrix_type[np.ix_(date1_indices, date2_indices)]
            xticks = [unique_dates2[j] for j in date2_indices]
            yticks = [unique_dates1[i] for i in date1_indices]

            im = ax.imshow(submatrix, cmap=cmap, aspect="auto", origin="upper")
            ax.set_title(f"{title_prefix} {start_year}-{end_year}")
            ax.set_xticks(range(len(xticks)))
            ax.set_xticklabels(xticks, rotation=90, fontsize=6)
            ax.set_yticks(range(len(yticks)))
            ax.set_yticklabels(yticks, fontsize=6)

        # Agregar barra de color y guardar
        fig.subplots_adjust(right=0.9)
        cbar_ax = fig.add_axes([0.92, 0.15, 0.015, 0.7])
        fig.colorbar(im, cax=cbar_ax, label="Coherence")

        plt.tight_layout(rect=[0, 0, 0.9, 1])
        output_file = f"{output_prefix}_{matrix_name}_{parent_dir}_{current_dir}.png"
        plt.savefig(output_file, dpi=100)
        plt.close()
        print(f"Submatriz guardada como {output_file}")

# Llamada a la función para graficar submatrices
#plot_submatrices(matrix, "Coherence Matrix", "submatrix")
plot_submatrices(matrix_filt, "Filtered Coherence Matrix", "filtered_submatrix")

