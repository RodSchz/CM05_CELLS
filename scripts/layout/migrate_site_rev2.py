#!/usr/bin/env python3
"""
migrate_site_rev2.py — Migra las celdas de fila al contrato de site.yaml rev. 2.

La migración es mecánica y NO toca la geometría interna de ninguna celda:

  1. lleva el borde izquierdo del contenido a x = 0;
  2. extiende los dos rieles de Metal1 hasta los dos bordes laterales, para
     que abuten y se fusionen con los de la celda vecina (rail_x_inset: 0.0);
  3. extiende el pozo n hasta los dos bordes laterales si no llegaba
     (esto es lo que le falta a FILLER);
  4. redibuja la capa de boundary como el rectángulo lógico de la celda,
     (0, 0) .. (ancho, row_height).

El ancho lógico se toma del bounding box de la celda ORIGINAL, no de su capa
de boundary: en Inverter y TAP la capa de boundary está 2.5 um corta y es el
bbox el que coincide con el riel centrado.

Lo que esta migración NO puede resolver sola: una celda cuyo Metal1 o Metal2
de señal se acerque al borde más de edge_clearance. Eso hay que redibujarlo a
mano porque implica mover ruteo interno. check_site.py lo reporta por nombre.

Uso:
    python scripts/layout/migrate_site_rev2.py --out /tmp/rev2 \
        digital/cells/*/layout/*.gds
    python scripts/drc/check_site.py --fila /tmp/rev2/*.gds

Con --in-place sobrescribe los GDS del repo. Hazlo en una rama y revisa el
diff visual en KLayout antes de hacer commit.
"""

import argparse
import glob
import os
import sys

try:
    import klayout.db as db
except ImportError:
    try:
        import pya as db
    except ImportError:
        sys.exit("ERROR: falta el modulo de KLayout. Instala con: pip install klayout")

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "drc"))
from check_site import DEFAULT_CONFIG, load_config, layer_index, rail_bands  # noqa: E402


def box_um(u, x0, y0, x1, y1):
    return db.Box(int(round(x0 / u)), int(round(y0 / u)),
                  int(round(x1 / u)), int(round(y1 / u)))


def migrate_cell(layout, cell, cfg):
    u = layout.dbu
    bb = cell.bbox().to_dtype(u)
    ancho = bb.width()
    cambios = []

    # 1. normalizar el origen en X
    if abs(bb.left) > 1e-9:
        cell.transform(db.Trans(int(round(-bb.left / u)), 0))
        cambios.append(f"dx {-bb.left:+.1f}")

    # 2. rieles de borde a borde
    ril = layer_index(layout, cfg["rail_layer"])
    m1 = db.Region(cell.begin_shapes_rec(ril)).merged()
    for nombre, y0, y1 in rail_bands(cfg):
        pedido = db.Region(box_um(u, 0.0, y0, ancho, y1))
        if not (pedido - m1).merged().is_empty():
            cell.shapes(ril).insert(box_um(u, 0.0, y0, ancho, y1))
            cambios.append(f"riel {nombre} a 0..{ancho:.1f}")

    # 3. pozo n de borde a borde
    nwi = layer_index(layout, cfg["nwell_layer"])
    nw = db.Region(cell.begin_shapes_rec(nwi)).merged()
    if not nw.is_empty():
        nb = nw.bbox().to_dtype(u)
        for lado, falta in (("izq", nb.left), ("der", ancho - nb.right)):
            if falta <= 1e-9:
                continue
            # franja del pozo pegada a ese borde, para extenderla sin rellenar
            # zonas donde el pozo no existe
            sonda = ((nb.left, nb.left + cfg["site_width"]) if lado == "izq"
                     else (nb.right - cfg["site_width"], nb.right))
            tira = (nw & db.Region(box_um(u, sonda[0], nb.bottom,
                                          sonda[1], nb.top))).merged()
            tb = tira.bbox().to_dtype(u)
            x0, x1 = (0.0, nb.left) if lado == "izq" else (nb.right, ancho)
            cell.shapes(nwi).insert(box_um(u, x0, tb.bottom, x1, tb.top))
            cambios.append(f"pozo n {lado} +{falta:.1f}")

    # 4. boundary = rectángulo lógico
    bndi = layer_index(layout, cfg["boundary_layer"])
    previo = db.Region(cell.begin_shapes_rec(bndi)).merged()
    esperado = db.Region(box_um(u, 0.0, 0.0, ancho, cfg["row_height"]))
    if not (previo ^ esperado).merged().is_empty():
        cell.shapes(bndi).clear()
        cell.shapes(bndi).insert(box_um(u, 0.0, 0.0, ancho, cfg["row_height"]))
        cambios.append(f"boundary 0..{ancho:.1f} x 0..{cfg['row_height']:.1f}")

    return ancho, cambios


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("gds", nargs="+")
    ap.add_argument("--config", default=DEFAULT_CONFIG)
    ap.add_argument("--out", help="directorio de salida")
    ap.add_argument("--in-place", action="store_true",
                    help="sobrescribe los GDS originales")
    args = ap.parse_args(argv)

    if not args.out and not args.in_place:
        ap.error("indica --out <dir> o --in-place")

    cfg = load_config(args.config)
    exentas = set(cfg.get("exempt", []))

    archivos = []
    for patron in args.gds:
        encontrados = glob.glob(patron)
        archivos.extend(encontrados if encontrados else [patron])

    if args.out:
        os.makedirs(args.out, exist_ok=True)

    for archivo in archivos:
        layout = db.Layout()
        layout.read(archivo)
        hechas = []
        for cell in list(layout.each_cell()):
            if cell.name.startswith("$$$") or cell.name in exentas:
                continue
            if not cell.is_top():
                continue
            hechas.append((cell.name,) + migrate_cell(layout, cell, cfg))
        if not hechas:
            continue
        destino = (archivo if args.in_place
                   else os.path.join(args.out, os.path.basename(archivo)))
        layout.write(destino)
        for nombre, ancho, cambios in hechas:
            detalle = "; ".join(cambios) if cambios else "sin cambios"
            print(f"  {nombre:<14} ancho {ancho:7.1f}   {detalle}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
