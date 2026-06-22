#!/bin/bash

echo "Estimated the average coherence"
Estimate_Coherence_Average_from_DEM.py
plot_histogram_average_coherence.py
filtered_average.sh
matriz_coherencia.py
echo "Longs list"
Longs_combinaciones_filtradas.sh
echo "Standar list"
create_standar_list.sh
echo "Final List"
create_final_list.sh
