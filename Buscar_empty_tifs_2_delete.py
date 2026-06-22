#!/usr/bin/env python
# Pedro Espin-Bedon
# Used to search for empty coherence maps that have been created but contain no data, and to delete them from GEOC folder
import rasterio
import numpy as np

def is_visually_empty(arr, nodata_val):
    if np.ma.isMaskedArray(arr):
        return arr.mask.all()
    if nodata_val is not None:
        return np.all((arr == nodata_val) | np.isnan(arr))
    # Additional: treat all-zero or single-value arrays as empty
    return np.all(np.isnan(arr)) or np.all(arr == arr.flat[0])

# Read input list
with open("listaunwpng.txt", "r") as f:
    date_pairs = [line.strip() for line in f if line.strip()]

empty_files = []

for pair in date_pairs:
   # tif_path = f"GEOC/{pair}/{pair}.geo.unw.tif"
    tif_path = f"GEOC/{pair}/{pair}.geo.diff_pha.tif"

    try:
        with rasterio.open(tif_path) as src:
            data = src.read(1)
            nodata = src.nodata
            if is_visually_empty(data, nodata):
                empty_files.append(pair)
    except Exception as e:
        print(f"Error reading {tif_path}: {e}")
        empty_files.append(pair)  # Optional: include unreadable as empty

# Save empty file list
with open("empty.txt", "w") as f:
    for pair in empty_files:
        f.write(pair + "\n")

print(f"Found {len(empty_files)} empty files out of {len(date_pairs)} checked.")


import os
import shutil

# Ruta al archivo que contiene las lÃ­neas (nombres de carpetas o archivos)
input_file = "empty.txt"

with open(input_file, "r") as f:
    for line in f:
        linea = line.strip()  # elimina espacios y saltos de lÃ­nea
        path_to_remove = os.path.join("GEOC", linea)

        # Eliminar archivo o carpeta si existe
        if os.path.isdir(path_to_remove):
            shutil.rmtree(path_to_remove)
            print(f"Removed directory: {path_to_remove}")
        elif os.path.isfile(path_to_remove):
            os.remove(path_to_remove)
            print(f"Removed file: {path_to_remove}")
        else:
            print(f"Not found: {path_to_remove}")
