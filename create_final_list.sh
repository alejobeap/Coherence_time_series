#!/bin/bash
#Pedro Espin-Bedon
#Merge short and longs and create the final list in GEOC folder

parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")

if [ -n "$1" ]; then
    # Caso 1: argumento entregado → usarlo
    name=$(cat NameVolcano.txt 2>/dev/null)
    subsetnumero=$1
elif [ -s NameVolcano.txt ]; then
    # Caso 2: No hay $1, pero existe NameVolcano.txt
    name=$(cat NameVolcano.txt)
    
    if [ -s SubsetID.txt ]; then
        # Si también hay SubsetID.txt
        subsetnumero=$(cat SubsetID.txt)
    else
        # Si no hay SubsetID.txt → calcular con Python
        subsetnumero=$(python3 VER_Nombre_volcan_V2.py "$name" | tr -d '[]')
    fi
else
    # Caso 3: No hay $1 ni NameVolcano.txt válido
    echo "NameVolcano.txt is missing or empty"
    subsetnumero=$(python3 VER_Nombre_volcan_V2.py "$parent_dir" | tr -d '[]')
    exit 1
fi


scp -r GEOC/geo/* GEOC/
# Define file names
file1="standar_list.txt"
file2="Longs_combination_longs.txt"
output="IFSforLiCSBAS_${current_dir}_${parent_dir}_${subsetnumero}.txt"
Chilescase=0

# Check if both input files exist
if [[ ! -f $file1 || ! -f $file2 ]]; then
    echo "One or both input files do not exist."
    exit 1
fi

# Clear the output file
> "$output"

# Combine the files and sort the result
cat "$file1" "$file2" | sort > "$output"

# Check if the output file was created
if [[ -f $output ]]; then
    echo "Files have been successfully combined and sorted into $output."
else
    echo "Failed to create the output file."
fi


echo "Delete empty folders in GEOC"
deletefolder_GEOC.sh

echo "Check no loopd interferograms and fill with some ones"
### Check if the all list have loops 
Check_loops.py


cat minimal_loops.txt >> $output

# Sort the file in-place (overwrite)
sort -o "$output" "$output"


line_count=$(wc -l < "$output")
echo "Número total de combinaciones generadas: $line_count"


parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")


echo "framebatch_gapfill.sh -l -N -I ${PWD}/IFSforLiCSBAS_${current_dir}_${parent_dir}_${subsetnumero}.txt 5 200 7 2"

framebatch_gapfill.sh -l -N -I ${PWD}/IFSforLiCSBAS_${current_dir}_${parent_dir}_${subsetnumero}.txt 5 200 7 2


#echo "Baseline"
#mk_bperp_file.sh
#mv GEOC/baselines GEOC/baselines_web
#scp -r baselines GEOC/

