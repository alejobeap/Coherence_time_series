#!/bin/bash
#Pedro Espin-Bedon
#Run the unwrap_geo.sh script for each interferogram as a job 
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
       #sbatch --qos=high --output=sbatch_logs/${parent_dir}_$file.out --error=sbatch_logs/${parent_dir}_$file.err --job-name=${parent_dir}_$file -n 8 --time=02:59:00 --mem=65536 -p comet --account=comet_lics --partition=standard --wrap="unwrap_geo.sh `cat sourceframe.txt` $file"
       # Extraer el mes de la primera fecha (YYYYMMDD)
  mes=${file:4:2}

  # Si el mes está entre 05 y 09, cambiar a 10 horas para trata de procesar con mala coherencia
  if [[ "$mes" =~ ^0[5-9]$ || "$mes" == "10" ]]; then
        sbatch --qos=high --output=sbatch_logs/${parent_dir}_${file}_${current_dir}.out --error=sbatch_logs/${parent_dir}_${file}_${current_dir}.err --job-name=${parent_dir}_unw_${file}_${current_dir} -n 8 --time=01:30:00 --mem=16384 -p comet --account=comet_lics --partition=standard --wrap="unwrap_geo.sh `cat sourceframe.txt` $file"

        #sbatch --qos=high --output=sbatch_logs/${parent_dir}_${file}_${current_dir}.out --error=sbatch_logs/${parent_dir}_${file}_${current_dir}.err --job-name=${parent_dir}_unw_${file}_${current_dir} -n 8 --time=01:30:00 --mem=32768 -p comet --account=comet_lics --partition=standard --wrap="unwrap_geo.sh `cat sourceframe.txt` $file"
  else
        sbatch --qos=high --output=sbatch_logs/${parent_dir}_${file}_${current_dir}.out --error=sbatch_logs/${parent_dir}_${file}_${current_dir}.err --job-name=${parent_dir}_unw_${file}_${current_dir} -n 8 --time=00:30:00 --mem=8192 -p comet --account=comet_lics --partition=standard --wrap="unwrap_geo.sh `cat sourceframe.txt` $file"  #65536
        #sbatch --qos=high --output=sbatch_logs/${parent_dir}_${file}_${current_dir}.out --error=sbatch_logs/${parent_dir}_${file}_${current_dir}.err --job-name=${parent_dir}_unw_${file}_${current_dir} -n 8 --time=00:30:00 --mem=32768 -p comet --account=comet_lics --partition=standard --wrap="unwrap_geo.sh `cat sourceframe.txt` $file"  #65536


        
  fi
  
done < listaunwpng.txt

echo "Processing completed."


