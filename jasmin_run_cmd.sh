
parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")

bsub2slurm.sh -o LB_${current_dir}_${parent_dir}.out -e LB_${current_dir}_${parent_dir}.err -J LiCSBAS_${current_dir}_${parent_dir} -n 10 -W 23:59 -M 65536 -q short-serial ./jasmin_run.sh
