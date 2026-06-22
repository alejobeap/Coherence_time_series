#!/bin/bash

# Script to create a 'log' directory and run the LiCSAR_03_mk_ifgs.py script with specified arguments and then run framebatch_gapfill.sh with the generated combinations.
# Pedro Espin-Bedon

tracks=$(basename "$(pwd)")
name=$(basename "$(dirname "$(pwd)")")

# Create the 'log' directory
mkdir -p log
mkdir -p GEOC

#echo "Create Baselines file"
#mk_bperp_file.sh
#mv GEOC/baselines GEOC/baselines_web
#scp -r baselines GEOC/

echo "Create Baselines file"

if [ -d "GEOC/baselines" ] || [ -d "GEOC/baselines_web" ]; then
    echo "Baselines already generated. Skipping..."
else
    mk_bperp_file.sh
    mv GEOC/baselines GEOC/baselines_web
    scp -r baselines GEOC/
fi


awk '{ if ($3 > 250 || $3 < -250) print $2 }' baselines > baselinesmayor2delete.txt

## Crear jobs
#sbatch --qos=high --output=MKIFS_${name}_${tracks}.out --error=MKIFS_${name}_${tracks}.err --job-name=MKIFS_${name}_${tracks} -n 8 --time=23:59:00 --mem=65536 -p comet --account=comet_lics --partition=standard --wrap="LiCSAR_03_mk_ifgs.py -d . -r 7 -a 2 -c 0 -i combination_shorts.txt"

# Run the LiCSAR_03_mk_ifgs.py script with the given arguments
#LiCSAR_03_mk_ifgs.py -d . -r 7 -a 2 -c 0 -i filtered_date_pairs.txt

# Notify the user of completion
echo "Log directory created and LiCSAR_03_mk_ifgs.py executed successfully."

parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")


echo "framebatch_gapfill.sh -l -N -I ${PWD}/combination_shorts.txt 5 200 7 2"

framebatch_gapfill.sh -N -l -I ${PWD}/combination_shorts.txt -o 5 200 7 2


