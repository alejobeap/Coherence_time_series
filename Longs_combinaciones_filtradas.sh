#!/bin/bash
# Pedro Espin-Bedon
# Create list for longs interferograms
# --- Archivos ---
input_file="filtered_IFS_average_cc_value.txt"
months_file="mesecrear.txt"
dates_longs_file="dates_longs.txt"
dates_longs_filter_file="dates_longs_filter.txt"
output_file="Longs_combination_longs.txt"

# --- Limpieza previa ---
[ -f "$months_file" ] && rm "$months_file"
[ -f "$dates_longs_filter_file" ] && rm "$dates_longs_filter_file"
> "$output_file"

# --- Crear lista de fechas base ---
awk -F'_' '{print $1}' "$input_file" | sort -u > "$dates_longs_file"

# --- Calcular meses por año ---
declare -A month_years month_count
while read -r line; do
    year="${line:0:4}"
    month="${line:4:2}"
    key="$month:$year"
    month_years["$key"]=1
done < "$dates_longs_file"

for key in "${!month_years[@]}"; do
    month="${key%%:*}"
    month_count["$month"]=$(( ${month_count["$month"]:-0} + 1 ))
done

first_year=$(head -n 1 "$dates_longs_file" | cut -c1-4)
last_year=$(tail -n 1 "$dates_longs_file" | cut -c1-4)
total_years=$((last_year - first_year + 0))

# --- Threshold inicial ---
#threshold=$(( total_years - 2 ))
#(( threshold < 1 )) && threshold=1


# --- Threshold inicial ---
if (( total_years >= 11 )); then
    threshold=$(( total_years - 2 ))
elif (( total_years < 9 )); then
    threshold=$(( total_years - 3 ))

else
    # Optional: handle total_years between 9 and 10
    threshold=$(( total_years - 3 ))
fi

# Ensure threshold is at least 1
(( threshold < 1 )) && threshold=1

echo "Threshold by default is $threshold"


echo "Range of years: $first_year-$last_year ($total_years years)"
echo "Initial threshold: $threshold"

# --- Funciones ---
month_diff() {
    local start="$1" end="$2"
    local sy=${start:0:4} sm=$((10#${start:4:2}))
    local ey=${end:0:4} em=$((10#${end:4:2}))
    echo $(((ey - sy) * 12 + (em - sm)))
}

is_valid_diff() {
    case "$1" in
        3|6|9|12) return 0 ;;
        *) return 1 ;;
    esac
}

generate_combinations() {
    local threshold="$1"
    > "$months_file"
    > "$dates_longs_filter_file"
    > "$output_file"

    # --- Filtrar meses ---
    for month in "${!month_count[@]}"; do
        if [ "${month_count[$month]}" -ge "$threshold" ]; then
            echo "$month"
        fi
    done | sort > "$months_file"

    mapfile -t valid_months < "$months_file"
    months_regex=$(IFS='|'; echo "${valid_months[*]}")

    grep -E "^[0-9]{4}(${months_regex})[0-9]{2}$" "$dates_longs_file" > "$dates_longs_filter_file"

    # Añadir últimos RSLC si existen
    if [ -d RSLC ]; then
        ls RSLC -1 | grep -E "^[0-9]{8}$" | tail -n 6 >> "$dates_longs_filter_file"
    fi

    sort -u "$dates_longs_filter_file" -o "$dates_longs_filter_file"
    dates=($(sort "$dates_longs_filter_file"))

    # --- Generar combinaciones válidas ---
    for ((i=0; i<${#dates[@]}; i++)); do
        d1=${dates[i]}
        for ((j=i+1; j<${#dates[@]}; j++)); do
            d2=${dates[j]}
            diff=$(month_diff "$d1" "$d2")
            if is_valid_diff "$diff"; then
                echo "${d1}_${d2}" >> "$output_file"
            fi
        done
    done

    sort -u "$output_file" -o "$output_file"
    wc -l < "$output_file"
}

# --- Threshold interactivo ---
min_threshold=1
max_threshold=$total_years

line_count=$(generate_combinations "$threshold")
prev_threshold=-1
prev2_threshold=-1

while true; do
    # Detectar oscilación tipo A ↔ B
    if (( threshold == prev2_threshold )); then
        echo "Oscillation detected between $threshold and $prev_threshold → stopping"
        break
    fi

    prev2_threshold=$prev_threshold
    prev_threshold=$threshold

    if (( line_count > 500 )); then
        ((threshold++))
        (( threshold > max_threshold )) && break
    elif (( line_count < 50 )); then
        ((threshold--))
        (( threshold < min_threshold )) && break
    else
        break
    fi

    line_count=$(generate_combinations "$threshold")
    echo "Threshold: $threshold -> combinations: $line_count"

    if (( line_count == 0 )); then
#        echo "No combinations → stopping"
#        break
        echo "0 combinations → decreasing threshold"
        ((threshold--))
        (( threshold < min_threshold )) && break
        line_count=$(generate_combinations "$threshold")
        echo "Threshold: $threshold -> combinations: $line_count"
        continue

    fi
done
``

# --- Función para verificar conexiones entre años existentes ---
mapfile -t existing_combinations < <(sort -u "$output_file")
exists_connection_between_years() {
    local year1=$1
    local year2=$2
    for combo in "${existing_combinations[@]}"; do
        local start_year=${combo:0:4}
        local end_year=${combo:9:4}
        if { [[ "$start_year" == "$year1" && "$end_year" == "$year2" ]] || [[ "$start_year" == "$year2" && "$end_year" == "$year1" ]]; }; then
            return 0
        fi
    done
    return 1
}

force_real_gaps() {
    mapfile -t years < <(cut -c1-4 "$dates_longs_filter_file" | sort -u)
    local n=${#years[@]}
    local N=5  # Número de fechas antes y después del gap

    for ((i=0; i<n-1; i++)); do
        local y1=${years[i]}
        # Buscar el siguiente año con datos
        for ((j=i+1; j<n; j++)); do
            local y2=${years[j]}
            local gap=$((y2 - y1))
            if (( gap > 1 )); then
                # Revisar si hay alguna conexión intermedia
                local has_intermediate=false
                for ((k=i; k<j; k++)); do
                    if exists_connection_between_years "${years[k]}" "${years[k+1]}"; then
                        has_intermediate=true
                        break
                    fi
                done
                if ! $has_intermediate; then
                    echo "There is no real connection between $y1 and $y2 → forcing combinations between the last $N dates of $y1 and the first $N of $y2..."

                    # Fechas del año anterior al gap
                    local dates_y1=()
                    for d in "${dates[@]}"; do
                        [[ "${d:0:4}" == "$y1" ]] && dates_y1+=("$d")
                    done
                    # Tomar las últimas N fechas
                    local last_y1=("${dates_y1[@]: -$N}")

                    # Fechas del año posterior al gap
                    local dates_y2=()
                    for d in "${dates[@]}"; do
                        [[ "${d:0:4}" == "$y2" ]] && dates_y2+=("$d")
                    done
                    # Tomar las primeras N fechas
                    local first_y2=("${dates_y2[@]:0:$N}")

                    # Generar todas las combinaciones cruzadas y escribir en el archivo
                    for d1 in "${last_y1[@]}"; do
                        for d2 in "${first_y2[@]}"; do
                            echo "${d1}_${d2}" >> "$output_file"
                        done
                    done
                fi
                break  # Solo forzar la primera conexión del gap
            fi
        done
    done
}



# --- Leer fechas filtradas globalmente ---
mapfile -t dates < <(sort -u "$dates_longs_filter_file")

# --- Llamar función de gaps reales ---
force_real_gaps


# Ordenar y limpiar
sort -u "$output_file" -o "$output_file"

# --- Control final del tamaño ---
line_count=$(wc -l < "$output_file")
echo "After generating all: $line_count combinations"

if (( line_count > 500 )); then
    echo "More than 500 combinations → applying uniform sampling"

    sort -u "$output_file" | awk '
    {
        data[NR]=$0
    }
    END {
        if (NR <= 500) {
            for (i=1; i<=NR; i++) print data[i]
        } else {
            for (k=0; k<500; k++) {
                idx = int(k * (NR-1) / 499) + 1
                print data[idx]
            }
        }
    }' > tmp && mv tmp "$output_file"

    line_count=$(wc -l < "$output_file")
    echo "Reduce to $line_count connections"
fi

# --- Guardar total final ---
echo "Number of long connections: $line_count"
