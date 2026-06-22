#!/bin/bash
# Pedro Espin-Bedon
# Run unwrap as a job from the list
echo "Run Reunwrap"
parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")


bsub2slurm.sh -o sbatch_logs/"reunwrap_${parent_dir}\_${current_dir}".out -e sbatch_logs/"reunwrap_${parent_dir}\_${current_dir}".err -J "Reunwrap_${parent_dir}\_${current_dir}" -n 10 -W 47:59 -M 32768 -q comet reunwrap_sin_png_from_list.sh
