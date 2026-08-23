#!/usr/bin/env python3
"""
check_site.py — Valida el contrato geométrico de las celdas digitales CM05.

Comprueba que cada celda pueda colocarse en una fila y abutar con sus vecinas:
origen, altura, ancho múltiplo del pitch, rieles de alimentación, pozo n y
etiquetas de pines de alimentación.

Uso:
    python check_site.py <archivo.gds> [más archivos...]
    python check_site.py --cell Inverter CM05_celdas.gds
    python check_site.py --config ruta/site.yaml digital/cells/*/layout/*.gds

Requiere el módulo de KLayout:
    pip install klayout

También corre dentro de KLayout en modo batch:
    klayout -b -r check_site.py -rd input=archivo.gds

Código de salida: 0 si todo cumple, 1 si hay al menos una violación.
"""

import argparse
import glob
import os
import sys

try:
    import klayout.db as db
except ImportError:                                    # dentro de KLayout
    try:
        import pya as db
    except ImportError:
        sys.exit("ERROR: falta el modulo de KLayout. Instala con: pip install klayout")


# --------------------------------------------------------------------------
# Configuración
# --------------------------------------------------------------------------

DEFAULT_CONFIG = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "..", "digital", "site.yaml"
)


def load_config(path):
    """Lector mínimo de YAML plano: clave: valor y listas con guion.

    Evita la dependencia de PyYAML, que no siempre está en el runner de CI.
    Solo soporta el subconjunto que usa site.yaml.
    """
    cfg, current_list = {}, None
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            if line.lstrip().startswith("- "):
                if current_list is not None:
                    cfg[current_list].append(line.lstrip()[2:].strip())
                continue
            if ":" not in line:
                continue
            key, val = line.split(":", 1)
            key, val = key.strip(), val.strip()
            if not val:                                # inicio de lista
                cfg[key], current_list = [], key
                continue
            current_list = None
            if val.startswith("[") and val.endswith("]"):
                inner = val[1:-1].strip()
                cfg[key] = [v.strip() for v in inner.split(",")] if inner else []
            elif val.startswith('"') and val.endswith('"'):
                cfg[key] = val[1:-1]
            elif val in ("true", "false"):
                cfg[key] = val == "true"
            else:
                try:
                    cfg[key] = float(val)
                except ValueError:
                    cfg[key] = val
    return cfg


def layer_index(layout, spec):
    """'49/0' -> índice de capa en el layout."""
    lay, dt = spec.split("/")
    return layout.layer(int(lay), int(dt))


# --------------------------------------------------------------------------
# Comprobaciones
# --------------------------------------------------------------------------

TOL = 1e-6          # tolerancia en micras para comparar coordenadas


def near(a, b, tol=TOL):
    return abs(a - b) <= tol


def check_cell(layout, cell, cfg):
    """Devuelve la lista de violaciones de una celda. Vacía = cumple."""
    u = layout.dbu
    bad = []
    bbox = cell.bbox()
    if bbox.empty():
        return ["celda vacia (sin geometria)"]

    left, bottom = bbox.left * u, bbox.bottom * u
    width, height = bbox.width() * u, bbox.height() * u

    # 1. Origen en la esquina inferior izquierda
    if not near(left, cfg["origin_x"]) or not near(bottom, cfg["origin_y"]):
        bad.append(
            f"origen en ({left:.1f}, {bottom:.1f}), se esperaba "
            f"({cfg['origin_x']:.1f}, {cfg['origin_y']:.1f})"
        )

    # 2. Altura de fila exacta
    if not near(height, cfg["row_height"]):
        delta = height - cfg["row_height"]
        bad.append(f"altura {height:.1f} um, se esperaba {cfg['row_height']:.1f} ({delta:+.1f})")

    # 3. Ancho múltiplo del pitch
    pitch = cfg["site_width"]
    sites = width / pitch
    if not near(sites, round(sites), 1e-6):
        bad.append(f"ancho {width:.1f} um no es multiplo de {pitch:.1f}")

    # 4. Rieles de alimentación presentes y a lo ancho de la celda
    m1 = db.Region(cell.begin_shapes_rec(layer_index(layout, cfg["rail_layer"])))
    for nombre, y0, y1 in (
        ("GND", cfg["gnd_rail_bottom"], cfg["gnd_rail_top"]),
        ("VDD", cfg["vdd_rail_bottom"], cfg["vdd_rail_top"]),
    ):
        banda = db.Box(bbox.left, int(round(y0 / u)), bbox.right, int(round(y1 / u)))
        riel = (m1 & db.Region(banda)).merged()
        if riel.is_empty():
            bad.append(f"sin riel {nombre} en y {y0:.1f}..{y1:.1f}")
            continue
        rb = riel.bbox()
        # El riel debe cubrir la banda completa en vertical
        if not (near(rb.bottom * u, y0, 0.001) and near(rb.top * u, y1, 0.001)):
            bad.append(
                f"riel {nombre} ocupa y {rb.bottom*u:.1f}..{rb.top*u:.1f}, "
                f"se esperaba {y0:.1f}..{y1:.1f}"
            )
        # Extensión horizontal: debe respetar el retranqueo declarado
        inset = cfg.get("rail_x_inset", 0.0)
        x_ini, x_fin = left + inset, left + width - inset
        if not near(rb.left * u, x_ini, 0.001) or not near(rb.right * u, x_fin, 0.001):
            detalle = "debe llegar a los bordes" if inset == 0 else f"retranqueo {inset:.1f} um"
            bad.append(
                f"riel {nombre} va de x {rb.left*u:.1f} a {rb.right*u:.1f}, "
                f"se esperaba {x_ini:.1f}..{x_fin:.1f} ({detalle})"
            )

    # 5. Pozo n hasta el borde superior
    nwell = db.Region(cell.begin_shapes_rec(layer_index(layout, cfg["nwell_layer"]))).merged()
    if nwell.is_empty():
        bad.append("sin pozo n")
    else:
        nb = nwell.bbox()
        if not near(nb.top * u, cfg["nwell_top"], 0.001):
            bad.append(
                f"pozo n llega a y {nb.top*u:.1f}, se esperaba {cfg['nwell_top']:.1f}"
            )
        lo = nb.bottom * u
        if not (cfg["nwell_bottom_min"] - TOL <= lo <= cfg["nwell_bottom_max"] + TOL):
            bad.append(
                f"borde inferior del pozo n en y {lo:.1f}, fuera del rango "
                f"{cfg['nwell_bottom_min']:.1f}..{cfg['nwell_bottom_max']:.1f}"
            )

    # 6. Etiquetas de los pines de alimentación
    pin_idx = layer_index(layout, cfg["power_pin_layer"])
    etiquetas = {
        s.text.string for s in cell.shapes(pin_idx).each() if s.is_text()
    }
    for pin in cfg["power_pins"]:
        if pin not in etiquetas:
            bad.append(f"falta la etiqueta del pin {pin} en la capa {cfg['power_pin_layer']}")

    return bad


# --------------------------------------------------------------------------
# Programa principal
# --------------------------------------------------------------------------

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("gds", nargs="*", help="archivos GDS/OASIS a revisar")
    ap.add_argument("--config", default=DEFAULT_CONFIG, help="ruta de site.yaml")
    ap.add_argument("--cell", action="append", default=[],
                    help="revisar solo esta celda (repetible)")
    ap.add_argument("--quiet", action="store_true", help="solo mostrar violaciones")
    args = ap.parse_args(argv)

    # KLayout batch pasa los argumentos por -rd, no por argv
    entradas = args.gds or ([globals()["input"]] if isinstance(globals().get("input"), str) else [])
    archivos = []
    for patron in entradas:
        encontrados = glob.glob(patron)
        archivos.extend(encontrados if encontrados else [patron])
    if not archivos:
        ap.error("no se indico ningun archivo GDS")

    if not os.path.exists(args.config):
        sys.exit(f"ERROR: no encuentro la configuracion en {args.config}")
    cfg = load_config(args.config)
    exentas = set(cfg.get("exempt", []))

    total = ok = 0
    fallos = []

    for archivo in archivos:
        if not os.path.exists(archivo):
            sys.exit(f"ERROR: no existe {archivo}")
        layout = db.Layout()
        layout.read(archivo)

        for cell in layout.each_cell():
            nombre = cell.name
            if nombre.startswith("$$$"):
                continue
            if args.cell and nombre not in args.cell:
                continue
            if nombre in exentas:
                if not args.quiet:
                    print(f"  ~  {nombre:<16} exenta del contrato de fila")
                continue

            total += 1
            problemas = check_cell(layout, cell, cfg)
            if problemas:
                fallos.append((archivo, nombre, problemas))
                print(f"  X  {nombre:<16} {len(problemas)} violacion(es)")
                for p in problemas:
                    print(f"       - {p}")
            else:
                ok += 1
                if not args.quiet:
                    print(f"  OK {nombre:<16} cumple")

    print()
    print(f"Resumen: {ok}/{total} celdas cumplen el contrato de fila.")
    if fallos:
        print(f"{len(fallos)} celda(s) con violaciones:")
        for _, nombre, problemas in fallos:
            print(f"  - {nombre} ({len(problemas)})")
        return 1
    print("Todas las celdas cumplen.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
