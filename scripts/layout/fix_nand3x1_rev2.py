#!/usr/bin/env python3
"""
fix_nand3x1_rev2.py — Ensancha NAND3X1 de 105.0 a 120.0 um para que cumpla la
holgura al borde del contrato rev. 2.

NAND3X1 lleva sus cuatro pines como tiras verticales de Metal2 de altura
completa, y dos de ellas quedan pegadas a los bordes:

    A    x   0.0 ..  10.0   (via en x 2.5..7.5, pad de Metal1 en x 0..10)
    B    x  42.5 ..  57.5
    C    x  65.0 ..  80.0
    Out  x  95.0 .. 105.0   (via en x 97.5..102.5)

Al abutar dos celdas, la tira A de una toca la tira Out de la otra: es un
cortocircuito entre la entrada de una compuerta y la salida de la vecina, no
solo una violación del contrato.

No se puede arreglar moviendo las tiras hacia adentro sin redibujar el ruteo:
el pad de Metal1 de A (x 0..10) ya está a 7.5 um del bloque grande de Metal1
que empieza en x = 17.5, así que correrlo 7.5 um lo pondría en corto con ese
bloque. La solución mecánica y sin riesgo es ensanchar la celda: se recorre
todo el contenido +7.5 um y la celda pasa de 105.0 a 120.0 um (42 -> 48
sitios). Todas las distancias internas quedan intactas y ambos bordes
terminan con exactamente 7.5 um = 3*lambda de holgura.

Correr una sola vez, DESPUES de migrate_site_rev2.py. Es idempotente: si la
celda ya mide 120.0 um no hace nada.

Uso:
    python scripts/layout/fix_nand3x1_rev2.py \
        digital/cells/NAND3X1/layout/NAND3X1.gds
"""

import argparse
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

ANCHO_VIEJO = 105.0
ANCHO_NUEVO = 120.0
CORRIMIENTO = 7.5


def box_um(u, x0, y0, x1, y1):
    return db.Box(int(round(x0 / u)), int(round(y0 / u)),
                  int(round(x1 / u)), int(round(y1 / u)))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("gds", help="ruta de NAND3X1.gds")
    ap.add_argument("--config", default=DEFAULT_CONFIG)
    ap.add_argument("--out", help="escribir aqui en vez de sobrescribir")
    args = ap.parse_args(argv)

    cfg = load_config(args.config)
    layout = db.Layout()
    layout.read(args.gds)
    u = layout.dbu
    cell = layout.top_cell()
    ancho = cell.bbox().to_dtype(u).width()

    if abs(ancho - ANCHO_NUEVO) < 1e-9:
        print(f"  {cell.name}: ya mide {ANCHO_NUEVO:.1f} um, no hago nada")
        return 0
    if abs(ancho - ANCHO_VIEJO) > 1e-9:
        sys.exit(f"ERROR: {cell.name} mide {ancho:.1f} um; esperaba "
                 f"{ANCHO_VIEJO:.1f}. Corre antes migrate_site_rev2.py y "
                 f"revisa que sea la celda correcta.")

    # 1. recorrer todo el contenido hacia la derecha
    cell.transform(db.Trans(int(round(CORRIMIENTO / u)), 0))

    # 2. rieles de borde a borde en el ancho nuevo
    ril = layer_index(layout, cfg["rail_layer"])
    for _, y0, y1 in rail_bands(cfg):
        cell.shapes(ril).insert(box_um(u, 0.0, y0, ANCHO_NUEVO, y1))

    # 3. pozo n de borde a borde
    nwi = layer_index(layout, cfg["nwell_layer"])
    nw = db.Region(cell.begin_shapes_rec(nwi)).merged()
    if not nw.is_empty():
        nb = nw.bbox().to_dtype(u)
        for x0, x1, sonda in ((0.0, nb.left, (nb.left, nb.left + cfg["site_width"])),
                              (nb.right, ANCHO_NUEVO,
                               (nb.right - cfg["site_width"], nb.right))):
            if x1 - x0 <= 1e-9:
                continue
            tira = (nw & db.Region(box_um(u, sonda[0], nb.bottom,
                                          sonda[1], nb.top))).merged()
            tb = tira.bbox().to_dtype(u)
            cell.shapes(nwi).insert(box_um(u, x0, tb.bottom, x1, tb.top))

    # 4. boundary al ancho nuevo
    bndi = layer_index(layout, cfg["boundary_layer"])
    cell.shapes(bndi).clear()
    cell.shapes(bndi).insert(box_um(u, 0.0, 0.0, ANCHO_NUEVO, cfg["row_height"]))

    destino = args.out or args.gds
    layout.write(destino)
    print(f"  {cell.name}: {ANCHO_VIEJO:.1f} -> {ANCHO_NUEVO:.1f} um "
          f"(contenido +{CORRIMIENTO:.1f} um) -> {destino}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
