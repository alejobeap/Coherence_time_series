#!/bin/bash

# Enable nullglob so unmatched globs return an empty array
shopt -s nullglob

# Path to the GEOC directory
geoc_dir="GEOC"

# Loop through each immediate subdirectory of GEOC
find "$geoc_dir" -mindepth 1 -maxdepth 1 -type d | while read -r folder; do
    contents=("$folder"/*)
    item_count=${#contents[@]}

    # Check for matching files
    has_gmt_history=false
    has_temp_dir=false
    has_landmask=false

    [[ -f "$folder/gmt.history" ]] && has_gmt_history=true
    [[ -d "$folder/temp" ]] && has_temp_dir=true

    # Check for any file matching local_*.geo.landmask.tif
    landmask_files=($(compgen -G "$folder/local_*.geo.landmask.tif"))
    [[ ${#landmask_files[@]} -gt 0 ]] && has_landmask=true

    # Conditions for deletion
    delete_reason=""

    if [ $item_count -eq 0 ]; then
        delete_reason="empty folder"

    elif [ $item_count -eq 1 ]; then
        $has_gmt_history && delete_reason="only gmt.history"
        $has_temp_dir && delete_reason="only temp"

    elif [ $item_count -eq 2 ]; then
        if $has_gmt_history && $has_landmask; then
            delete_reason="gmt.history + landmask"
        elif $has_temp_dir && $has_landmask; then
            delete_reason="temp + landmask"
        fi

    elif [ $item_count -eq 3 ]; then
        if $has_gmt_history && $has_temp_dir && $has_landmask; then
            delete_reason="gmt.history + temp + landmask"
        fi
    fi

    # If a delete reason was set, delete the folder
    if [ -n "$delete_reason" ]; then
        echo "Deleting folder: $folder ($delete_reason)"
        rm -r "$folder"
    fi
done

