#!/bin/bash
#Pedro Espin-Bedon
# To run the unwrap list as jobs 
parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")


bsub2slurm.sh -o sbatch_logs/"unwrap_${parent_dir}\_${current_dir}".out -e sbatch_logs/"unwrap_${parent_dir}\_${current_dir}".err -J "Unwrap_${parent_dir}\_${current_dir}" -n 10 -W 47:59 -M 32768 -q comet unwrap_sin_png_from_list.sh
