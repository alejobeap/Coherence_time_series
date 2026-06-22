
parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")

bsub2slurm.sh -o LB_clip_${current_dir}_${parent_dir}.out -e LB_clip_${current_dir}_${parent_dir}.err -J LiCSBAS_clip_${current_dir}_${parent_dir} -n 10 -W 23:59 -M 65536 -q short-serial ./jasmin_run_clip.sh
