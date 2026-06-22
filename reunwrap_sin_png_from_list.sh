#!/bin/bash
# Pedro Espin-Bedon
# Run reunwrap_mila.py as jobs
parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")

# Check if the GEOC directory exists
if [ ! -d "GEOC" ]; then
  echo "Error: Directory 'GEOC' does not exist."
  exit 1
fi



# Step 3: Iterate over the files listed in listaifs.txt
while IFS= read -r file; do
  echo "Processing file: $file"
  sbatch --qos=high --output=sbatch_logs/${parent_dir}_reunw_${file}_${current_dir}.out --error=sbatch_logs/${parent_dir}_reunw_${file}_${current_dir}.err --job-name=${parent_dir}_reunw_${file}_${current_dir} -n 8 --time=02:59:00 --mem=32768 -p comet --account=comet_lics --partition=standard --wrap="reunwrap_geo.sh $file"
done < listaunwpng.txt
