#!/usr/bin/env python 
# -*- coding: utf-8 -*-
# Code using the reunwrap developed by Milan

import os
import sys

#sys.path.append("/gws/smf/j04/nceo_geohazards/software/licsar_extra/python")

from lics_unwrap import process_ifg_pair

# Captura el argumento de línea de comandos
if len(sys.argv) < 2:
    print("Uso: python unwrap_milan.py <carpeta>")
    sys.exit(1)

folder = sys.argv[1]  # esto reemplaza el $1 de Bash

# Construye los nombres de archivo dinámicamente
wrapinput = f"GEOC/{folder}/{folder}.geo.diff_unfiltered_pha.tif"
ccinput = f"GEOC/{folder}/{folder}.geo.cc.tif"
outtif = f"GEOC/{folder}/{folder}.geo.unw.tif"

# Llamada a la función
process_ifg_pair(
    wrapinput,
    ccinput,
    procpairdir='GEOC/{folder}', #os.getcwd(),
    landmask_tif=None,
    magtif=None,
    ml=1,
    fillby='none',  # 'none' 'gauss'
    thres=0.2, #check
    cascade=True,
    smooth=False,
    lowpass=False,
    goldstein=True,
    specmag=False,
    spatialmask_km=2.0,
    defomax=0.6,
    frame='',
    hgtcorr=False,
    gacoscorr=True,
    pre_detrend=False,
    cliparea_geo=None,
    outtif=outtif,
    prevest=None,
    prev_ramp=None,
    coh2var=False,
    add_resid=True,
    rampit=False,
    subtract_gacos=False,
    extweights=None,
    keep_coh_debug=True,
    keep_coh_px=0.25,
    use_gamma=False,
    filtcoh_thres=0.4,
)

import subprocess

folder = "mi_carpeta"
subprocess.run(["rm", "-rf", f"GEOC/{folder}/tmp_unwrap"], check=True)

