module load licsbas_comet_dev
parent_dir=$(basename "$(dirname "$(pwd)")")
current_dir=$(basename "$(pwd)")
./batch_LiCSBAS.sh
LiCSBAS_flt2geotiff.py -i TS_GEOCml2mask/results/vel.filt.mskd -p GEOCml2mask/EQA.dem_par -o ${parent_dir}_${current_dir}.vel_filt.mskd.geo.tif
#LiCSBAS_flt2geotiff.py -i TS_GEOCml2mask/results/vel.filt -p GEOCml2mask/EQA.dem_par -o ${parent_dir}_${current_dir}.vel_filt.geo.tif
#LiCSBAS_flt2geotiff.py -i TS_GEOCml2mask/results/vel.mskd -p GEOCml2mask/EQA.dem_par -o ${parent_dir}_${current_dir}.vel.mskd.geo.tif
#LiCSBAS_flt2geotiff.py -i TS_GEOCml2mask/results/vel -p GEOCml2mask/EQA.dem_par -o ${parent_dir}_${current_dir}.vel.geo.tif
#LiCSBAS_flt2geotiff.py -i TS_GEOCml2mask/results/vstd -p GEOCml2mask/EQA.dem_par -o ${parent_dir}_${current_dir}.vstd.geo.tif
#cp TS_GEOCml2mask/network/network13.png ${parent_dir}_${current_dir}'_network.png'
#cp TS_GEOCml2mask/mask_ts.png ${parent_dir}_${current_dir}'_mask_ts.png'
#LiCSBAS_out2nc.py -i TS_GEOCml2mask/cum.h5 -o ${parent_dir}_${current_dir}.nc
LiCSBAS_disp_img.py -i TS_GEOCml2mask/results/vel.filt.mskd -p GEOCml2mask/EQA.dem_par -c SCM.roma_r --cmin -20 --cmax 20 --kmz ${parent_dir}_${current_dir}.vel.mskd.kmz
scp -r GEOCml2mask/baselines TS_GEOCml2mask/
#LiCSBAS_disp_img.py -i TS_GEOCml2mask/results/vel.filt.mskd -p GEOCml2mask/EQA.dem_par -c SCM.roma_r --cmin -20 --cmax 20 --title ${parent_dir}_${current_dir}_vel_filt_mskd --png ${parent_dir}_${current_dir}.vel.mskd.png
