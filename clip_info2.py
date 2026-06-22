#!/usr/bin/env python
import matplotlib.pyplot as plt
import os
import glob
from pathlib import Path
from pyproj import Geod
import rasterio
from rasterio.windows import from_bounds
import sys
import subprocess

# Archivos de entrada
volcanoes_file = "Volcanes_Chiles.txt"
name_file = "NameVolcano.txt"
geod = Geod(ellps="WGS84")

def get_full_valid_bounds(dem_file):
    """
    Devuelve la extensión completa real del DEM.
    No fuerza cuadrado ni recorte.
    """
    with rasterio.open(dem_file) as src:
        return (
            src.bounds.left,
            src.bounds.right,
            src.bounds.bottom,
            src.bounds.top,
        )

def get_square_bounds_full_raster(lon, lat, dem_file):
    with rasterio.open(dem_file) as src:
        data = src.read(1)
        nodata = src.nodata
        mask_valid = data != nodata

        rows, cols = mask_valid.nonzero()

        row_min, row_max = rows.min(), rows.max()
        col_min, col_max = cols.min(), cols.max()

        height = row_max - row_min
        width  = col_max - col_min

        side = min(height, width)

        # centrado en el DEM válido
        row_center = (row_min + row_max) // 2
        col_center = (col_min + col_max) // 2

        half = side // 2

        rmin = row_center - half
        rmax = row_center + half
        cmin = col_center - half
        cmax = col_center + half

        min_lon, min_lat = src.xy(rmax, cmin)
        max_lon, max_lat = src.xy(rmin, cmax)

        return min_lon, max_lon, min_lat, max_lat


def run_licsbass_script(resultsdir: str):
    """
    Runs the LiCSBAS_flt2geotiff.py script with paths based on the results directory.

    Args:
        resultsdir (str): The base directory for the results.

    Returns:
        str: The stdef run_licsbass_script(resultsdir: str):
    """
    out_path = f"{resultsdir}/results/hgt.geo.tif"
    if not os.path.isfile(out_path):
        # Construct the input and parameter file paths
        input_path = f"{resultsdir}/results/hgt"
        parameter_file = f"{resultsdir}/info/EQA.dem_par"

        # Define the command
        command = [
            "LiCSBAS_flt2geotiff.py",  # The script to execute
            "-i", input_path,  # Input path
            "-p", parameter_file  # Parameter file path
        ]

        try:
            # Run the command
            result = subprocess.run(command, check=True, text=True, capture_output=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            # Raise an error if the script fails
            raise RuntimeError(f"Script execution failed: {e.stderr}") from e
    else:
        return f"Output file {out_path} already exists, skipping execution."


def get_volcano_name_from_file(filename):
    try:
        with open(filename, "r", encoding="utf-8") as f:
            content = f.read().strip()
            if not content:
                return None
            if any(c in content for c in [' ', '.', '-']):
                return f'"{content}"'
            return content
    except FileNotFoundError:
        return None

def get_volcano_info(volcano_name, volcanoes_file):
    try:
        with open(volcanoes_file, "r", encoding="utf-8") as vf:
            next(vf)  # saltar header
            for line in vf:
                line = line.strip()
                if not line:
                    continue
                if line.startswith('"'):
                    parts = line.split()
                    name_tokens = []
                    for token in parts:
                        name_tokens.append(token)
                        if token.endswith('"'):
                            break
                    nombre_volcan = " ".join(name_tokens).strip('"')
                    rest = parts[len(name_tokens):]
                    if len(rest) != 3:
                        continue
                    lon = float(rest[0].rstrip(','))
                    lat = float(rest[1].rstrip(','))
                    distancia = float(rest[2].rstrip(','))
                else:
                    parts = line.split()
                    nombre_volcan = parts[0]
                    lon = float(parts[1].rstrip(','))
                    lat = float(parts[2].rstrip(','))
                    distancia = float(parts[3].rstrip(','))
                if nombre_volcan.lower() == volcano_name.strip('"').lower():
                    return nombre_volcan, lon, lat, distancia
    except Exception as e:
        print(f"Error leyendo archivo de volcanes: {e}")
    return None

def get_square_bounds(lon, lat, km_size=50):
    """Retorna un cuadrado km_size x km_size en grados centrado en lon/lat."""
    deg_side = km_size / 111  # 1° ≈ 111 km
    min_lon_cut = lon - deg_side/2
    max_lon_cut = lon + deg_side/2
    min_lat_cut = lat - deg_side/2
    max_lat_cut = lat + deg_side/2
    return min_lon_cut, max_lon_cut, min_lat_cut, max_lat_cut


# ... código anterior ...

import rasterio
import numpy as np

def get_square_bounds_full_dem(lon, lat, dem_file):
    """
    Calcula el mayor cuadrado centrado en (lon, lat) que esté completamente dentro de datos válidos.
    Incluye verificación de esquinas.
    """
    with rasterio.open(dem_file) as src:
        data = src.read(1)
        nodata = src.nodata
        mask_valid = data != nodata

        row_c, col_c = src.index(lon, lat)
        nrows, ncols = data.shape

        # Crecer en las cuatro direcciones
        up = down = left = right = 0

        while row_c - (up + 1) >= 0 and mask_valid[row_c - (up + 1), col_c]:
            up += 1
        while row_c + (down + 1) < nrows and mask_valid[row_c + (down + 1), col_c]:
            down += 1
        while col_c - (left + 1) >= 0 and mask_valid[row_c, col_c - (left + 1)]:
            left += 1
        while col_c + (right + 1) < ncols and mask_valid[row_c, col_c + (right + 1)]:
            right += 1

        # Tamaño inicial del cuadrado
        half_size = min(up, down, left, right)

        while half_size > 0:
            rmin = row_c - half_size
            rmax = row_c + half_size
            cmin = col_c - half_size
            cmax = col_c + half_size

            corners = [
                mask_valid[rmin, cmin],
                mask_valid[rmin, cmax],
                mask_valid[rmax, cmin],
                mask_valid[rmax, cmax],
            ]

            if all(corners):
                break  # cuadrado válido

            half_size -= 1  # reducir hasta que sea válido

        if half_size == 0:
            raise ValueError("No se pudo construir un cuadrado válido sin tocar NoData")

        # Convertir a coordenadas geográficas
        min_lon, min_lat = src.xy(rmax, cmin)
        max_lon, max_lat = src.xy(rmin, cmax)

        return min_lon, max_lon, min_lat, max_lat

from matplotlib_scalebar.scalebar import ScaleBar
import numpy as np

def add_scalebar(ax, lat, length_fraction=0.25, position="upper left"):
    # Conversión grados → km en dirección Este-Oeste
    deg_to_km = 111.32 * np.cos(np.deg2rad(lat))

    scalebar = ScaleBar(
        dx=deg_to_km * 1000,  # metros por grado
        units="m",
        dimension="si-length",
        scale_loc="bottom",
        length_fraction=length_fraction,
        location=position,
        box_alpha=1,
        color="black",
        fixed_units="km",
        font_properties={'size': 8},
    )
    ax.add_artist(scalebar)

def main():
    current_dir = os.getcwd()
    default_volcano_name = os.path.basename(os.path.dirname(current_dir))
    clean_args = []

    # Detectar flags
    use_square_nan = "--cuadrado" in sys.argv
    use_full_raster = "--full" in sys.argv
    use_clip = "--clip" in sys.argv


    area_km = 25  # valor por defecto
    if "--area" in sys.argv:
     try:
        idx = sys.argv.index("--area")
        area_km = float(sys.argv[idx + 1])
     except (IndexError, ValueError):
        print("Error: --area debe ir seguido de un número (ej: --area 50)")
        return

# Limpiar argumentos
     skip_next = False

     for i, arg in enumerate(sys.argv[1:]):
         if skip_next:
             skip_next = False
             continue
         if arg == "--area":
             skip_next = True
             continue
         if arg not in ["--cuadrado", "--full", "--clip"]:
             clean_args.append(arg)

    # Determinar nombre del volcán
    if len(clean_args) == 0:
        volcano_name = get_volcano_name_from_file(name_file)
        if not volcano_name:
            print(f"No se encontró {name_file}. Usando valor por defecto: {default_volcano_name}")
            volcano_name = default_volcano_name
    else:
        volcano_name = clean_args[0]

    print(f"Volcán: {volcano_name}")

    volcano_info = get_volcano_info(volcano_name, volcanoes_file)
    if not volcano_info:
        print(f"Volcán '{volcano_name}' no encontrado.")
        return

    nombre_volcan, lon, lat, _ = volcano_info
    print(f"Coordenadas volcán: {lon}, {lat}")



    # Buscar archivo DEM
#    dem_files = glob.glob("GEOC/*.geo.hgt.tif") + glob.glob("GEOC/geo/*.geo.hgt.tif") + glob.glob("TS*/results/hgt.geo.tif")
#    if not dem_files:
#        print("No se encontró archivo DEM.")
#        return
#    dem_file = dem_files[0]

    patterns = [
        "GEOC/*.geo.hgt.tif",
        "GEOC/geo/*.geo.hgt.tif",
        "TS*/results/hgt.geo.tif"
    ]
    
    dem_file = None
    
    for p in patterns:
        files = glob.glob(p)
        if files:
            dem_file = files[0]
            break
    
    if dem_file is None:
        print("No se encontró archivo DEM, using TS* for create the hgt.geo.tif")


        dirs = glob.glob("TS*")
        for d in dirs:
#         run_licsbass_script(d)
#         try:


         print(f"→ Procesando {d}")

         try:
            # Intentar correr el script
            output = run_licsbass_script(d)
            print(f"OK: {output}")

         except Exception as e:
            # Si hay error → parar todo
            print(f"Error procesando {d}: {e}")
            raise   # Esto detiene completamente la ejecución

        print("Todos los TS* procesados sin errores.")


        for p in patterns:
         files = glob.glob(p)
         if files:
            dem_file = files[0]
            break

        if dem_file is None:
          print("No se pudo generar ningún hgt.geo.tif. Abortando.")
          return



    #    return


    #    return


    #if use_full_dem:
    #    # Usar todo el DEM pero cuadrado centrado en volcán
    #    min_lon_cut, max_lon_cut, min_lat_cut, max_lat_cut = get_square_bounds_full_dem(lon, lat, dem_file)
    #else:
    #    # Usar recorte de 25km x 25km
    #    min_lon_cut, max_lon_cut, min_lat_cut, max_lat_cut = get_square_bounds(lon, lat, km_size=25)

    if use_clip:
        print("Modo CLIP extensión completa del DEM activado")
        min_lon_cut, max_lon_cut, min_lat_cut, max_lat_cut = \
            get_full_valid_bounds(dem_file)

    elif use_full_raster:
        print("Modo FULL cuadrado máximo activado")
        min_lon_cut, max_lon_cut, min_lat_cut, max_lat_cut = \
            get_square_bounds_full_raster(lon, lat, dem_file)

    elif use_square_nan:
        print("Modo cuadrado máximo centrado sin NaN activado")
        min_lon_cut, max_lon_cut, min_lat_cut, max_lat_cut = \
            get_square_bounds_full_dem(lon, lat, dem_file)

    else:
        print(f"Modo área fija activado: {area_km} km")
        min_lon_cut, max_lon_cut, min_lat_cut, max_lat_cut = \
            get_square_bounds(lon, lat, km_size=area_km)

    # Crear archivo de salida
    parts = current_dir.strip("/").split("/")
    erta = parts[-2] if len(parts) > 1 else "ERTA"
    code = parts[-1] if len(parts) > 0 else "CODE"
    output_file = f"clip_file_{erta}_{code}.txt"

    with open(output_file, "w") as f:
        f.write(f"{min_lon_cut:.4f}/{max_lon_cut:.4f}/{min_lat_cut:.4f}/{max_lat_cut:.4f}\n")

    print(f"Archivo generado: {output_file}")
    print(f"Bounds: {min_lon_cut:.4f}/{max_lon_cut:.4f}/{min_lat_cut:.4f}/{max_lat_cut:.4f}")



    # Obtener nombres como en bash
    parent_dir = os.path.basename(os.path.dirname(os.getcwd()))
    current_dir = os.path.basename(os.getcwd())

    # Construir nombre del archivo
    filename = f"Area_clip_{parent_dir}_{current_dir}.jpg"

    # Mostrar DEM y recorte
    with rasterio.open(dem_file) as src:
        dem_data = src.read(1)
        dem_data = dem_data.astype(float)
        dem_data[dem_data == src.nodata] = float('nan')
        extent = [src.bounds.left, src.bounds.right, src.bounds.bottom, src.bounds.top]

        plt.figure(figsize=(10, 8))
        plt.imshow(dem_data, extent=extent, cmap='terrain', origin='upper')
        plt.colorbar(label='Elevación (m)')
        plt.title(f"DEM y recorte cuadrado - {nombre_volcan}")

        # Dibujar el cuadrado
        plt.plot([min_lon_cut, max_lon_cut, max_lon_cut, min_lon_cut, min_lon_cut],
                 [min_lat_cut, min_lat_cut, max_lat_cut, max_lat_cut, min_lat_cut],
                 color='red', linewidth=2, label='Recorte cuadrado')
        plt.scatter(lon, lat, color='blue', marker='x', s=100, label='Cima volcán')

        lat_centro = (src.bounds.top + src.bounds.bottom) / 2

        ax = plt.gca()
        add_scalebar(ax, lat=lat_centro)
        plt.xlabel("Longitud")
        plt.ylabel("Latitud")
        plt.legend()
        # Guardar figura
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"Figura guardada como: {filename}")

        plt.show()


if __name__ == "__main__":
    main()
