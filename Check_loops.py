#!/usr/bin/env python
# Check if there are IFS witouth loops and create a list possible candidates (Based in LiCSBAS12...py)

import glob
import numpy as np
import os
import pandas as pd
import networkx as nx



def get_ifgdates_from_files(pattern="IFSforLiCSBAS_*.txt"):
    """Lee interferogramas desde todos los archivos que cumplan el patrón."""
    ifgdates = []
    for filename in glob.glob(pattern):
        with open(filename, "r") as f:
            for line in f:
                ifgd = line.strip()
                if len(ifgd) == 17 and ifgd[8] == "_":  # formato YYYYMMDD_YYYYMMDD
                    ifgdates.append(ifgd)
    return sorted(set(ifgdates))


def ifgdates2imdates(ifgdates):
    """Convierte lista de interferogramas a lista de imágenes únicas."""
    primarylist = [ifgd[:8] for ifgd in ifgdates]
    secondarylist = [ifgd[-8:] for ifgd in ifgdates]
    return sorted(set(primarylist + secondarylist))


def make_loop_matrix(ifgdates):
    """Construye la loop matrix (contiene 1, -1, 0) a partir de ifgdates."""
    n_ifg = len(ifgdates)
    Aloop = []

    for ix_ifg12, ifgd12 in enumerate(ifgdates):
        f1 = ifgd12[0:8]
        f2 = ifgd12[9:17]

        # Buscar candidatos ifg23
        ifgdates23 = [ifgd for ifgd in ifgdates if ifgd.startswith(f2)]
        for ifgd23 in ifgdates23:
            f3 = ifgd23[9:17]
            candidate_ifg13 = f1 + "_" + f3

            if candidate_ifg13 in ifgdates:
                ix_ifg23 = ifgdates.index(ifgd23)
                ix_ifg13 = ifgdates.index(candidate_ifg13)

                Aline = [0] * n_ifg
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

        # Buscar ifg23
        ifgdates23 = [ifgd for ifgd in ifgdates if ifgd.startswith(f2)]
        for ifgd23 in ifgdates23:
            f3 = ifgd23[9:17]
            candidate_ifg13 = f1 + "_" + f3
            if candidate_ifg13 not in ifgdates:
                missing_ifgs.add(candidate_ifg13)

    return sorted(missing_ifgs)


def minimal_loops_for_no_loop_ifgs(ifgdates, no_loop_ifg):
    """Para cada interferograma sin loop, devuelve una sola terna (3 IFGs)."""
    imdates = ifgdates2imdates(ifgdates)
    results = {}

    for ifgd in no_loop_ifg:
        f1 = ifgd[:8]
        f2 = ifgd[9:17]
        loop_found = False

        for f3 in imdates:
            if f3 in (f1, f2):
                continue

            cand12 = f1 + "_" + f2
            cand23 = f2 + "_" + f3
            cand13 = f1 + "_" + f3
            existing = set(ifgdates)

            existing_count = sum([cand in existing for cand in (cand12, cand23, cand13)])
            if existing_count >= 2:
                results[ifgd] = [cand12, cand23, cand13]
                loop_found = True
                break
        if not loop_found:
            results[ifgd] = []
    return results


if __name__ == "__main__":

    #  Leer interferogramas
    ifgdates = get_ifgdates_from_files("IFSforLiCSBAS_*.txt")

    #  Construir loop matrix
    Aloop = make_loop_matrix(ifgdates)
    if Aloop.size == 0:
        no_loop_ifg = ifgdates
    else:
        ns_loop4ifg = np.abs(Aloop).sum(axis=0)
        ixs_ifg_no_loop = np.where(ns_loop4ifg == 0)[0]
        no_loop_ifg = [ifgdates[ix] for ix in ixs_ifg_no_loop]

    #  Guardar interferogramas sin loops
    with open("no_loop_ifg.txt", "w") as f:
        f.write("\n".join(no_loop_ifg))

    #  Sugerir interferogramas faltantes
    missing_ifgs = suggest_missing_ifgs(ifgdates)
    with open("missing_ifgs.txt", "w") as f:
        f.write("\n".join(missing_ifgs))

    #  Loops mínimos (solo las ternas, sin texto adicional)
    minimal_loops = minimal_loops_for_no_loop_ifgs(ifgdates, no_loop_ifg)
    with open("minimal_loops.txt", "w") as f:
        for loop in minimal_loops.values():
            if loop:
                f.write("\n".join(loop) + "\n")


