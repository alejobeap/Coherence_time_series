#!/bin/bash
# Pedro Espin-Bedon
# Search within GEOC for folders containing interferograms that do not have an ‘unw’ file in either image or TIF format, and create a list so that you can then proceed with the unwrap.
#“Sometimes these files are not created due to problems with the RSLCs or other issues, and these empty folders are deleted in this step.”
# Ruta base
base_dir="GEOC"

# Archivo de salida
output_file="listaunwpng.txt"

if [ -f "$output_file" ]; then
    echo "El archivo existe, ejecutando script..."
    Buscar_empty_tifs_2_delete.py
else
    echo "El archivo NO existe, no se ejecuta."
fi

#echo "DELETE EMPTY FOLDERS"
#Buscar_empty_tifs_2_delete.py

# Limpiar el archivo de salida si existe
: > "$output_file"


# Solo carpetas de primer nivel dentro de GEOC que empiezan con '2'
for dir in "$base_dir"/2*/; do
    # Verifica si es un directorio
    [ -d "$dir" ] || continue

    # Verifica si NO existen archivos .png o .tif requeridos
    png_missing=false
    tif_missing=false

    if ! ls "$dir"/*geo.unw.png 1>/dev/null 2>&1; then
        png_missing=true
    fi

    if ! ls "$dir"/*geo.unw.tif 1>/dev/null 2>&1; then
        tif_missing=true
    fi

    # Si falta al menos uno de los dos, escribe el nombre del directorio
    if $png_missing || $tif_missing; then
        basename "$dir" >> "$output_file"
    fi
done


#!/bin/bash

# Archivo de entrada
archivo="listaunwpng.txt"

# Archivos temporales
archivo_otros="tmp_otros.txt"
archivo_mayo_sep="tmp_mayo_sep.txt"

# Limpiar archivos temporales previos
> "$archivo_otros"
> "$archivo_mayo_sep"

# Leer línea por línea
while IFS= read -r linea; do
    # Extraer el mes de la primera fecha (YYYYMMDD)
    mes=${linea:4:2}

    # Si el mes está entre 05 y 09, guardar en archivo_mayo_sep
    if [[ "$mes" =~ ^0[5-9]$ ]]; then
        echo "$linea" >> "$archivo_mayo_sep"
    else
        echo "$linea" >> "$archivo_otros"
    fi
done < "$archivo"

# Concatenar las líneas: primero las que NO son de mayo a septiembre, luego las otras
cat "$archivo_otros" "$archivo_mayo_sep" > "$archivo"

# Limpiar archivos temporales
rm "$archivo_otros" "$archivo_mayo_sep"

while IFS= read -r linea; do rm -rf GEOC/$linea/*unw*tif ; done < listaunwpng.txt

sort -u "$archivo"

line_count=$(wc -l < "$archivo")
echo "📄 Número total de combinaciones generadas: $line_count"


#echo "conexiones aisladas"
#python conexiones_aisladas.py
#framebatch_gapfill.sh -l -N -I ${PWD}/interferogramasnoaislados.txt 5 200 7 2
