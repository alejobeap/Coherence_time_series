#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Script to get volcano IDS from Milan's data base and check if the corresponding folders exist in the LiCS database
# Pedro Espin-Bedon
import volcdb
import sys
import os

# Validate input arguments
if len(sys.argv) < 2:
    print("Usage: python Name_Volcano_from_data_base_Milan.py <volcano_name>")
    sys.exit(1)

# Get volcano name from command-line arguments
volcano_name = sys.argv[1]

try:
    # Find the volcano by name
    result = volcdb.find_volcano_by_name(volcano_name)
    
    # Ensure at least one result
    if len(result) == 0:
        print(f"No volcano found with the name '{volcano_name}'.")
        sys.exit(1)
    
    # If only one result, process directly
    if len(result) == 1:
        volcid = int(result.iloc[0].volc_id)
        video_ids = volcdb.get_volclip_vids(volcid)
        print(video_ids)
        sys.exit(0)

    # If multiple entries found, check which folder exists
    existing_folders = []
    base_path = "/gws/nopw/j04/nceo_geohazards_vol1/projects/LiCS/proc/current/subsets/volc"

    for idx, row in result.iterrows():
        volcid = int(row["volc_id"])
        video_ids = volcdb.get_volclip_vids(volcid)
        
        for vid in video_ids:
            folder_path = os.path.join(base_path, str(vid))
            if os.path.isdir(folder_path):
                existing_folders.append((volcid, vid, folder_path))
    
    if len(existing_folders) == 0:
        print(f"No matching folders found for '{volcano_name}' in {base_path}.")
        sys.exit(1)
    elif len(existing_folders) == 1:
        volcid, vid, path = existing_folders[0]
        print(f"Found one matching folder: {path}")
        print(f"Video ID: {vid}")
    else:
        print(f"Multiple valid folders found for '{volcano_name}':")
        for volcid, vid, path in existing_folders:
            print(f"  - volc_id: {volcid}, video_id: {vid}, path: {path}")
        print("Please refine your search.")

except Exception as e:
    print(f"An error occurred: {e}")
    sys.exit(1)
