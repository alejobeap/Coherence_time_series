#!/usr/bin/env python
#Pedro Espin-Bedon
#Check the GEOC folder to see if there are any gaps; if there are, create them and run the interferograms – you just need to unwrap them once they’ve finished.
import os
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt

# Carpeta GEOC
directorio = "GEOC"

# Filtrar solo carpetas válidas con formato YYYYMMDD_YYYYMMDD
valid_rows = []
for f in os.listdir(directorio):
    ruta = os.path.join(directorio, f)
    if os.path.isdir(ruta):
        partes = f.split("_")
        if len(partes) == 2 and partes[0].isdigit() and partes[1].isdigit():
            try:
                start = pd.to_datetime(partes[0], format="%Y%m%d")
                end = pd.to_datetime(partes[1], format="%Y%m%d")
                valid_rows.append((start, end))
            except Exception:
                pass

# Crear DataFrame
df = pd.DataFrame(valid_rows, columns=["start", "end"])

# Ordenar intervalos
intervalos = df.sort_values("start")[["start", "end"]].to_records(index=False)

coberturas, gaps = [], []
if len(intervalos) > 0:
    rango_ini = intervalos[0].start
    rango_fin = intervalos[0].end

    for i in range(1, len(intervalos)):
        inicio, fin = intervalos[i].start, intervalos[i].end
        if inicio <= rango_fin:
            rango_fin = max(rango_fin, fin)
        else:
            coberturas.append((rango_ini, rango_fin))
            gaps.append((rango_fin, inicio))
            rango_ini, rango_fin = inicio, fin

    coberturas.append((rango_ini, rango_fin))

    # Gap final solo si faltan más de 2 semanas hasta hoy
    today = pd.Timestamp(datetime.today().date())
    if rango_fin <= today - pd.Timedelta(weeks=2):
        gap_start = rango_fin - pd.DateOffset(months=1)
        gap_end = today + pd.DateOffset(months=1)
        gaps.append((gap_start, gap_end))

# Guardar gaps en archivo
with open("gaps_dates.txt", "w") as f:
    for gap_start, gap_end in gaps:
        gap_start = pd.to_datetime(gap_start)
        gap_end = pd.to_datetime(gap_end)
        f.write(f"{gap_start.strftime('%Y-%m-%d')} {gap_end.strftime('%Y-%m-%d')}\n")

# =====================
if coberturas or gaps:
    fig, ax = plt.subplots(figsize=(12, 2))

    for start, end in coberturas:
        ax.plot([start, end], [1, 1], color="green", linewidth=6, solid_capstyle="butt")

    for start, end in gaps:
        ax.plot([start, end], [1, 1], color="red", linewidth=6, solid_capstyle="butt")

    today = pd.Timestamp(datetime.today().date())
    ax.axvline(today, color="blue", linestyle="--", linewidth=1)

    ax.set_yticks([])
    ax.set_ylim(0.5, 1.5)
    ax.set_title("Coberturas y Gaps en GEOC", fontsize=12)
    ax.grid(axis="x", linestyle="--", alpha=0.5)

    plt.tight_layout()
    plt.savefig("timeline.png", dpi=150)
    plt.close()
