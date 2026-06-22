#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Script to detect interferograms without loops and suggest missing interferograms
# Final version: a maximum of one loop per interferogram

import os
import glob
import numpy as np
from datetime import datetime

def get_ifgdates_from_folders(geoc_dir="GEOC"):
    """Obtiene interferogramas desde las carpetas GEOC/2* y devuelve lista única ordenada."""
    ifgdates = []
    for folder in sorted(glob.glob(os.path.join(geoc_dir, "2*"))):
        if os.path.isdir(folder):
            ifgd = os.path.basename(folder)
            if len(ifgd) == 17 and ifgd[8] == "_":
                ifgdates.append(ifgd)
    return sorted(set(ifgdates))

def ifgdates2imdates(ifgdates):
    """Convierte lista de interferogramas a lista de fechas únicas."""
    primarylist = [ifgd[:8] for ifgd in ifgdates]
    secondarylist = [ifgd[-8:] for ifgd in ifgdates]
    return sorted(set(primarylist + secondarylist))

def make_loop_matrix(ifgdates):
    """Construye la loop matrix (1, -1, 0) a partir de ifgdates."""
    n_ifg = len(ifgdates)
    Aloop = []
    for ix_ifg12, ifgd12 in enumerate(ifgdates):
        f1 = ifgd12[:8]
        f2 = ifgd12[9:17]
        ifgdates23 = [ifgd for ifgd in ifgdates if ifgd.startswith(f2)]
        for ifgd23 in ifgdates23:
            f3 = ifgd23[9:17]
            candidate_ifg13 = f1 + "_" + f3
            if candidate_ifg13 in ifgdates:
                ix_ifg23 = ifgdates.index(ifgd23)
                ix_ifg13 = ifgdates.index(candidate_ifg13)
                Aline = [0]*n_ifg
                Aline[ix_ifg12] = 1
                Aline[ix_ifg23] = 1
                Aline[ix_ifg13] = -1
                Aloop.append(Aline)
    return np.array(Aloop)

def suggest_missing_ifgs(ifgdates):
    """Sugiere interferogramas faltantes que cerrarían loops."""
    missing_ifgs = set()
    for ifgd12 in ifgdates:
        f1 = ifgd12[:8]
        f2 = ifgd12[9:17]
        ifgdates23 = [ifgd for ifgd in ifgdates if ifgd.startswith(f2)]
        for ifgd23 in ifgdates23:
            f3 = ifgd23[9:17]
            candidate_ifg13 = f1 + "_" + f3
            if candidate_ifg13 not in ifgdates:
                missing_ifgs.add(candidate_ifg13)
    return sorted(missing_ifgs)

def minimal_loops_for_no_loop_ifgs(ifgdates, no_loop_ifg):
    """
    Genera loops mínimos:
    - máximo un loop por interferograma
    - selecciona f3 como la fecha futura más cercana
    - evita ternas duplicadas
    """
    imdates = sorted(ifgdates2imdates(ifgdates))
    results = {}
    existing = set(ifgdates)
    used_ternas = set()

    for ifgd in no_loop_ifg:
        f1 = ifgd[:8]
        f2 = ifgd[9:17]

        # Buscar f3 como la fecha futura más cercana a f2
        future_dates = [d for d in imdates if d > f2]
        loop_found = False

        for f3 in future_dates:
            cand12 = f1 + "_" + f2
            cand23 = f2 + "_" + f3
            cand13 = f1 + "_" + f3

            if sum([cand in existing for cand in (cand12, cand23, cand13)]) == 2:
                terna = tuple(sorted([cand12, cand23, cand13]))
                if terna not in used_ternas:
                    results[ifgd] = [cand12, cand23, cand13]
                    used_ternas.add(terna)
                    loop_found = True
                    break

        if not loop_found:
            results[ifgd] = []

    return results

if __name__ == "__main__":

    ifgdates = get_ifgdates_from_folders("GEOC")

    Aloop = make_loop_matrix(ifgdates)
    if Aloop.size == 0:
        no_loop_ifg = ifgdates
    else:
        ns_loop4ifg = np.abs(Aloop).sum(axis=0)
        ixs_ifg_no_loop = np.where(ns_loop4ifg == 0)[0]
        no_loop_ifg = [ifgdates[ix] for ix in ixs_ifg_no_loop]

    with open("no_loop_ifg_GEOC.txt", "w") as f:
        f.write("\n".join(no_loop_ifg))

    missing_ifgs = suggest_missing_ifgs(ifgdates)
    with open("missing_ifgs_GEOC.txt", "w") as f:
        f.write("\n".join(missing_ifgs))

    minimal_loops = minimal_loops_for_no_loop_ifgs(ifgdates, no_loop_ifg)
    with open("minimal_loops_GEOC.txt", "w") as f:
        for loop in minimal_loops.values():
            if loop:
                f.write("\n".join(loop) + "\n")
