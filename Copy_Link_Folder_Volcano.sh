#!/bin/bash

if [ -z "$1" ]; then
  echo "Uso: $0 <Namefolder> Numeroid(optional)"
  exit 1
fi

NOMBRE=$1
NUMERO=$2


# Si NUMERO no se pasa como argumento, lo buscamos con Python
if [ -z "$NUMERO" ]; then
    NUMERO=$(python3 /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/VER_Nombre_volcan_V2.py "$NOMBRE" | tr -d '[]')
    if [ $? -ne 0 ] || [ -z "$NUMERO" ]; then
        echo "Error executing VER_Nombre_volcan_V2.py or empty value"
        exit 1
    fi
fi

echo "NNumber obtained: $NUMERO"

# Replace spaces, dots, and dashes with underscores
NOMBRE_CLEAN=$(echo "$NOMBRE" | sed -E 's/[ .-]+/_/g')



# Create the directory
mkdir -p "$NOMBRE_CLEAN"


echo "Directory created: $NOMBRE_CLEAN"

cd "$NOMBRE_CLEAN" || { echo "Could not enter folder $NOMBRE"; exit 1; }

RUTA_BASE="/gws/pw/j07/comet_lics/volc_subsets/$NUMERO"

CARPETAS=( $(ls -d "$RUTA_BASE"/*/ 2>/dev/null | xargs -n 1 basename) )

if [ ${#CARPETAS[@]} -eq 0 ]; then
  echo "No folders found within $RUTA_BASE"
  exit 1
fi

TOTAL_PASOS=$((${#CARPETAS[@]} * 3))
PASO_ACTUAL=0

for CARPETA in "${CARPETAS[@]}"; do
  mkdir -p "$CARPETA/geo"
  mkdir -p "$CARPETA/RSLC"
  mkdir -p "$CARPETA/SLC"
  mkdir -p "$CARPETA/GEOC/geo"


  GEO30="$RUTA_BASE/$CARPETA/geo.30m"
  GEO="$RUTA_BASE/$CARPETA/geo"
  
  if [ -d "$GEO30" ] && [ -d "$GEO" ]; then
    shopt -s nullglob
    files=("$GEO30"/*)
    shopt -u nullglob
  
    if [ ${#files[@]} -gt 0 ]; then
      GEO_FOLDER="geo.30m"
    else
      GEO_FOLDER="geo"
    fi
  
  elif [ -d "$GEO30" ]; then
    shopt -s nullglob
    files=("$GEO30"/*)
    shopt -u nullglob
  
    if [ ${#files[@]} -gt 0 ]; then
      GEO_FOLDER="geo.30m"
    else
      echo "geo.30m is empty in $RUTA_BASE/$CARPETA"
      continue
    fi
  
  elif [ -d "$GEO" ]; then
    shopt -s nullglob
    files=("$GEO"/*)
    shopt -u nullglob
  
    if [ ${#files[@]} -gt 0 ]; then
      GEO_FOLDER="geo"
    else
      echo "geo is empty in $RUTA_BASE/$CARPETA"
      continue
    fi
  
  else
    echo "No folder found for geo.30m or geo in $RUTA_BASE/$CARPETA"
    continue
  fi

  ((PASO_ACTUAL++))
  PORCENTAJE=$(( PASO_ACTUAL * 100 / TOTAL_PASOS ))
  echo "the folder is $GEO_FOLDER"
  echo "[$PORCENTAJE%] Copying $GEO_FOLDER en $CARPETA/geo..."
  rsync -a --ignore-existing "$RUTA_BASE/$CARPETA/$GEO_FOLDER/" "$CARPETA/geo/" 2>&1 | tee -a ../debug.log

  ((PASO_ACTUAL++))
  PORCENTAJE=$(( PASO_ACTUAL * 100 / TOTAL_PASOS ))
  echo "[$PORCENTAJE%] Copying RSLC en $CARPETA..."
  rsync -a --ignore-existing "$RUTA_BASE/$CARPETA/RSLC/" "$CARPETA/RSLC/" 2>&1 | tee -a ../debug.log

  echo "Unzipping RSLC zip..."

  for dir in "$CARPETA"/RSLC/*/; do
    [ -d "$dir" ] || continue

    shopt -s nullglob
    zips=("$dir"/*.zip)
    shopt -u nullglob

    if [ ${#zips[@]} -gt 0 ]; then

        echo "Unzipping in $dir"

        if unzip -o "${zips[@]}" -d "$dir" >> ../debug.log 2>&1; then

            echo "Deleting zip(s) in $dir"

            rm -f "${zips[@]}"

        else

            echo "ERROR unzipping in $dir"

        fi
    fi
  done
  ((PASO_ACTUAL++))
  PORCENTAJE=$(( PASO_ACTUAL * 100 / TOTAL_PASOS ))
  echo "[$PORCENTAJE%] Copying SLC en $CARPETA..."
  rsync -a --ignore-existing "$RUTA_BASE/$CARPETA/SLC/" "$CARPETA/SLC/" 2>&1 | tee -a ../debug.log
# rsync -a --ignore-existing "$RUTA_BASE/$CARPETA/local_config.py" "$CARPETA/SLC/"
  rsync -a --ignore-existing "$RUTA_BASE/$CARPETA/local_config.py" "$CARPETA/"



# Detectar automáticamente la carpeta FECHA
  FECHA=$(find "$CARPETA/SLC" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | head -n 1)

#  echo "Fecha detectada: $FECHA"

  # Mover carpeta original a _old
  mv "$CARPETA/SLC/$FECHA" "$CARPETA/SLC/${FECHA}_old"

  # Crear nueva carpeta
  mkdir -p "$CARPETA/SLC/$FECHA"

  # Copiar archivos desde RSLC
  cp "$CARPETA/RSLC/$FECHA/${FECHA}.rslc" \
   "$CARPETA/SLC/$FECHA/${FECHA}.slc"

  cp "$CARPETA/RSLC/$FECHA/${FECHA}.rslc.par" \
   "$CARPETA/SLC/$FECHA/${FECHA}.slc.par"


#  # GEOC.meta.30m
#  if [ -d "$RUTA_BASE/$CARPETA/GEOC.meta.30m" ]; then
#    echo "Copiando GEOC.meta.30m..."
#    rsync -a --ignore-existing "$RUTA_BASE/$CARPETA/GEOC.meta.30m/" "$CARPETA/GEOC/geo/" 2>&1 | tee -a ../debug.log
#    rsync -a --ignore-existing "$RUTA_BASE/$CARPETA/GEOC.meta.30m/" "$CARPETA/GEOC/" 2>&1 | tee -a ../debug.log
#  fi


  # GEOC.meta.30m o GEOC.30m si no hay la GEOC.meta.30m usar GEOC.30m
  if [ -d "$RUTA_BASE/$CARPETA/GEOC.meta.30m" ]; then
    echo "Copying GEOC.meta.30m..."
    ORIGEN="$RUTA_BASE/$CARPETA/GEOC.meta.30m"
  elif [ -d "$RUTA_BASE/$CARPETA/GEOC.30m" ]; then
    echo "GEOC.meta.30m does not exist, copying GEOC.30m..."
    ORIGEN="$RUTA_BASE/$CARPETA/GEOC.30m"
  else
    echo "Does not exist GEOC.meta.30m ni GEOC.30m" | tee -a ../debug.log
    ORIGEN=""
  fi
  
  if [ -n "$ORIGEN" ]; then
    rsync -a --ignore-existing "$ORIGEN/" "$CARPETA/GEOC/geo/" 2>&1 | tee -a ../debug.log
    rsync -a --ignore-existing "$ORIGEN/" "$CARPETA/GEOC/" 2>&1 | tee -a ../debug.log
  fi


  # GEOC.MLI.30m
  if [ -d "$RUTA_BASE/$CARPETA/GEOC.MLI.30m" ]; then
    echo "Copying GEOC.MLI.30m..."
    find "$RUTA_BASE/$CARPETA/GEOC.MLI.30m" -type f | while read -r archivo; do
      rsync -a --ignore-existing "$archivo" "$CARPETA/GEOC/geo/" 2>&1 | tee -a ../debug.log
      rsync -a --ignore-existing "$archivo" "$CARPETA/GEOC/" 2>&1 | tee -a ../debug.log
    done
  fi

  # Buscar archivo corners_clip.*
  file=$(ls "$RUTA_BASE/$CARPETA"/corners_clip.* 2>/dev/null | head -n 1)
  echo "$file"
  if [[ -n "$file" ]]; then
    basename="${file##*.}"
    [ -f "$CARPETA/sourceframe.txt" ] && rm "$CARPETA/sourceframe.txt"
    echo "$basename" > "$CARPETA/sourceframe.txt"

    geo_file=$(ls "$CARPETA/GEOC/"*.geo.mli.tif 2>/dev/null | head -n 1)
    if [ -n "$geo_file" ]; then
      mv "$geo_file" "$CARPETA/GEOC/$basename.geo.mli.tif"
    fi
  else
    echo "No corners_clip.* file found."
  fi

  frameID="$basename"

# Take everything before the first letter
  digits="${frameID%%[A-Za-z]*}"

# Remove leading zeros by forcing numeric interpretation
  trackID=$((10#$digits))

  echo "trackID=$trackID"


  LiCSARweb="$LiCSAR_public" #"/gws/nopw/j04/nceo_geohazards_vol1/public/LiCSAR_products.public"
  echo "$LiCSARweb/$trackID/$frameID/metadata/baselines"
  if [ -e "$LiCSARweb/$trackID/$frameID/metadata/baselines" ]; then
    rsync -a --ignore-existing \
        "$LiCSARweb/$trackID/$frameID/metadata/baselines" \
        "$CARPETA/GEOC/" 2>&1 | tee -a ../debug.log
  fi
  
  # Renombrar .png si existe
  png_file=$(ls "$CARPETA/GEOC/"*.geo.mli.png 2>/dev/null | head -n 1)
  if [ -n "$png_file" ]; then
    mv "$png_file" "$CARPETA/GEOC/$basename.geo.mli.png"
  fi



  #set -euo pipefail

  # Remove leading zeros by forcing numeric interpretation
  trackID=$((10#$digits))
  echo "trackID=$trackID"


  echo "############# GACOS link ##############"

  LiCSARweb="$LiCSAR_public" #"/gws/nopw/j04/nceo_geohazards_vol1/public/LiCSAR_products"
  epochdir="$LiCSARweb/$trackID/$frameID/epochs"
  gacosdir="$CARPETA/GACOS"

  # Ensure GACOS directory exists
  mkdir -p "$gacosdir"

  # Iterate over epochs
  for epoch in "$epochdir"/*; do
    epoch=$(basename "$epoch")
    gacosfile="$epochdir/$epoch/$epoch.sltd.geo.tif"

    if [[ -f "$gacosfile" ]]; then
       ln -sf "$gacosfile" "$gacosdir/$epoch.sltd.geo.tif"
    fi

  done

  echo "############# ERA5 link ##############"

  LiCSARweb="$LiCSAR_public" #"/gws/nopw/j04/nceo_geohazards_vol1/public/LiCSAR_products"
  epochdir="$LiCSARweb/$trackID/$frameID/epochs"
  era5dir="$CARPETA/ERA5"

  # Ensure GACOS directory exists
  mkdir -p "$era5dir"

  # Iterate over epochs
  for epoch in "$epochdir"/*; do
    epoch=$(basename "$epoch")
    era5file="$epochdir/$epoch/$epoch.icams.sltd.geo.tif"
    #echo "$era5file"

    if [[ -f "$era5file" ]]; then
       ln -sf "$era5file" "$era5dir/$epoch.icams.sltd.geo.tif"
       #echo "$era5file"
    fi

  done

  echo "############ Ionos ###################" 

#  "geo.iono.code.tif"

  LiCSARweb="$LiCSAR_public" #"/gws/nopw/j04/nceo_geohazards_vol1/public/LiCSAR_products"
  epochdir="$LiCSARweb/$trackID/$frameID/epochs"
  ionosdir="$CARPETA/IONOS"

  # Ensure GACOS directory exists
  mkdir -p "$ionosdir"

#icams.sltd.geo.tif
  # Iterate over epochs
  for epoch in "$epochdir"/*; do
    epoch=$(basename "$epoch")
    ionosfile="$epochdir/$epoch/$epoch.geo.iono.code.tif"

    if [[ -f "$ionosfile" ]]; then
       ln -sf "$ionosfile" "$ionosdir/$epoch.geo.iono.code.tif"
    fi

  done


  echo "$NOMBRE" > NameVolcano.txt
  echo "$NUMERO" > SubsetID.txt


  # Clonar y mover Create_list_ifs
  echo "Copying other files to $CARPETA..."
  (
    cd "$CARPETA" || { echo "No se pudo entrar a $CARPETA"; exit 1; }
    echo "$NOMBRE" > NameVolcano.txt
    echo "$NUMERO" > SubsetID.txt
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/batch_LiCSBAS.sh .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/jasmin_run_cmd.sh .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/jasmin_run.sh .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/batch_LiCSBAS_clip.sh .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/jasmin_run_cmd_clip.sh .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/jasmin_run_clip.sh .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/LiCSAlert*_examples.py .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/LiCSAlert_*sh .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/LiCSAtmo_*sh .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/lics*jasmin*.sh .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/LiCSAtmo_example.py .
    cp -r /gws/ssde/j25a/nceo_geohazards/vol1/projects/COMET/DEEPVolc_Pedro/SCRIPTS/h52licsalertjson.sh .



    #./Run_all.sh
  )

done

echo "Process completed for all folders."
