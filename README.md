# =========================
# STANDARD PROCESSING FLOW
# =========================

# 1. Create volcano folder links
Copy_Link_Folder_Volcano.sh <volcano_name>
# Take some time to copy everithing
# Example
Copy_Link_Folder_Volcano.sh Fernandina
# Sometime need the code of ID because there are more that one name in the data base
Copy_Link_Folder_Volcano.sh Fernandina 2228

# Enter the directory name of frame for example Fernandina/0126D/

# 2. Run coherence analysis
Run_coherence_analysis.sh 
# waiting some minutes to finish the jobs

# 3. Run standard long interferogram filter and Generate final interferogram list
Run_filter_longer_standar.sh

# waiting some minutes to finish the jobs

# 5. Check folders without unw.png
Buscar_folders_sin_unw_png.sh

# =========================
# UNWRAPPING OPTIONS
# =========================

# Option 1: Standard SNAPHU unwrap (faster)
Unwrap_run.sh
#waiting some hour depends of jasmin

# Option 2: Re-unwrapping (slower but more robust)
reunwrap_sin_png_from_list.sh

# =========================
# VERIFY UNWRAPPING RESULTS
# =========================

# Check again for missing unw.png files
Buscar_folders_sin_unw_png.sh

# If result = 0:
#   All interferograms were unwrapped successfully.
#
# If result != 0:
#   Some interferograms failed.
#   You can:
#     - rerun the job automatically, or
#     - unwrap manually.

# =========================
# MANUAL UNWRAP (NO JOBS)
# =========================

while IFS= read -r linea; do
    unwrap_geo.sh `cat sourceframe.txt` $linea
done < listaunwpng.txt

# =========================
# AUTOMATIC JOB UNWRAP
# =========================

Unwrap_run.sh

# =========================
# FINAL PROCESSING
# =========================

# Run full-area processing only when missing unwrap count = 0
./jasmin_run_cmd.sh

# =========================
# OPTIONAL: CLIP AREA
# =========================

# Example: generate 25 km² clipped area
clip_info2.py --area 25

# Run clipped-area processing
jasmin_run_cmd_clip.sh

# =========================
# Volcano test Portal DEEPVolc
# =========================
# Copy for DEEPvolcano test portal
Copyfiles.sh
