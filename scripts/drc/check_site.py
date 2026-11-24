#!/usr/bin/env python3
"""
check_site.py — Valida el contrato geométrico de las celdas digitales CM05.

Comprueba que cada celda pueda colocarse en una fila y abutar con sus vecinas:
límite lógico, altura de fila, ancho múltiplo del pitch, envolvente, rieles de
alimentación, pozo n y etiquetas de pines de alimentación.

El límite lógico de la celda lo da la capa de boundary (site.yaml:
boundary_layer), NO el bounding box: en la convención de abutment el riel y el
pozo n sobresalen deliberadamente de la celda.

Uso:
    python check_site.py <archivo.gds> [más archivos...]
    python check_site.py --cell Inverter CM05_celdas.gds
    python check_site.py --config ruta/site.yaml digital/cells/*/layout/*.gds
    python check_site.py --fila digital/cells/*/layout/*.gds

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
                cfg[key] = [v.strip().strip('"').strip("'")
                            for v in inner.split(",")] if inner else []
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


def rail_bands(cfg):
    """[(nombre, y_inferior, y_superior)] de los dos rieles."""
    return [
        ("GND", cfg["gnd_rail_bottom"], cfg["gnd_rail_top"]),
        ("VDD", cfg["vdd_rail_bottom"], cfg["vdd_rail_top"]),
    ]


# --------------------------------------------------------------------------
# Comprobaciones
# --------------------------------------------------------------------------

TOL = 1e-6          # tolerancia en micras para comparar coordenadas
GEO = 0.001         # tolerancia para coordenadas geométricas (1 nm)


def near(a, b, tol=TOL):
    return abs(a - b) <= tol


def region(layout, cell, spec):
    return db.Region(cell.begin_shapes_rec(layer_index(layout, spec))).merged()


def logical_box(layout, cell, cfg):
    """Caja lógica de la celda según la capa de boundary. None si no la hay."""
    bnd = region(layout, cell, cfg["boundary_layer"])
    if bnd.is_empty():
        return None, None
    return bnd.bbox().to_dtype(layout.dbu), bnd.count()


def check_cell(layout, cell, cfg):
    """Devuelve la lista de violaciones de una celda. Vacía = cumple."""
    u = layout.dbu
    bad = []
    if cell.bbox().empty():
        return ["celda vacia (sin geometria)"]

    # 1. Límite lógico: lo define la capa de boundary, no el bounding box.
    #    En esta convención el riel y el pozo n sobresalen a propósito.
    caja, nfig = logical_box(layout, cell, cfg)
    if caja is None:
        return [f"sin capa de boundary {cfg['boundary_layer']}: no se puede "
                f"determinar el limite logico de la celda"]
    if nfig != 1:
        bad.append(f"la capa de boundary tiene {nfig} figuras, se esperaba 1")

    left, bottom = caja.left, caja.bottom
    width, height = caja.width(), caja.height()

    # 2. Origen del límite lógico
    if not near(left, cfg["origin_x"], GEO) or not near(bottom, cfg["origin_y"], GEO):
        bad.append(
            f"origen del boundary en ({left:.1f}, {bottom:.1f}), se esperaba "
            f"({cfg['origin_x']:.1f}, {cfg['origin_y']:.1f})"
        )

    # 3. Altura de fila exacta (paso de fila, de eje de riel a eje de riel)
    if not near(height, cfg["row_height"], GEO):
        delta = height - cfg["row_height"]
        bad.append(f"altura {height:.1f} um, se esperaba {cfg['row_height']:.1f} ({delta:+.1f})")

    # 4. Ancho múltiplo del pitch
    pitch = cfg["site_width"]
    sites = width / pitch
    if not near(sites, round(sites)):
        bad.append(f"ancho {width:.1f} um no es multiplo de {pitch:.1f}")

    # 5. Envolvente: solo riel y pozo n pueden salir del límite, y solo en Y.
    #    Cualquier sobresalto lateral choca con la celda vecina.
    ox = cfg.get("overhang_x", 0.0)
    oyb = cfg.get("overhang_y_bottom", 0.0)
    oyt = cfg.get("overhang_y_top", 0.0)
    bb = cell.bbox().to_dtype(u)
    for etiqueta, exceso, limite in (
        ("izquierda", left - bb.left, ox),
        ("derecha", bb.right - (left + width), ox),
        ("inferior", bottom - bb.bottom, oyb),
        ("superior", bb.top - (bottom + height), oyt),
    ):
        if exceso > limite + GEO:
            bad.append(
                f"geometria sobresale {exceso:.1f} um por la {etiqueta} del boundary "
                f"(maximo permitido {limite:.1f})"
            )

    # 6. Rieles de alimentación: banda completa y de borde a borde
    m1 = region(layout, cell, cfg["rail_layer"])
    inset = cfg.get("rail_x_inset", 0.0)
    x_ini, x_fin = left + inset, left + width - inset
    for nombre, y0, y1 in rail_bands(cfg):
        banda = db.Box(int(round(x_ini / u)), int(round(y0 / u)),
                       int(round(x_fin / u)), int(round(y1 / u)))
        riel = (m1 & db.Region(banda)).merged()
        if riel.is_empty():
            bad.append(f"sin riel {nombre} en y {y0:.1f}..{y1:.1f}")
            continue
        # La banda esperada debe quedar completamente cubierta por Metal1:
        # esto detecta a la vez un riel corto, uno angosto y uno con muescas.
        falta = (db.Region(banda) - riel).merged()
        if not falta.is_empty():
            trozos = sorted((p.bbox().to_dtype(u) for p in falta.each()),
                            key=lambda b: b.left)
            det = "; ".join(f"x {b.left:.1f}..{b.right:.1f} y {b.bottom:.1f}..{b.top:.1f}"
                            for b in trozos[:3])
            if len(trozos) > 3:
                det += f"; ... ({len(trozos)} trozos)"
            bad.append(
                f"riel {nombre} no cubre la banda y {y0:.1f}..{y1:.1f} de x {x_ini:.1f} "
                f"a {x_fin:.1f}: falta Metal1 en {det}"
            )
        # ...y no debe pasarse del borde: un riel que sobresale corta con el vecino
        rb = riel.bbox().to_dtype(u)
        if rb.left < x_ini - GEO or rb.right > x_fin + GEO:
            bad.append(
                f"riel {nombre} va de x {rb.left:.1f} a {rb.right:.1f}, "
                f"se esperaba {x_ini:.1f}..{x_fin:.1f} (retranqueo {inset:.1f} um)"
            )

    # 6b. Holgura al borde lateral de todo lo que no sea el riel. Sin esto, una
    #     señal pegada al borde queda a 0 um del riel o de la señal de la
    #     vecina en cuanto se abutan las dos celdas.
    hol = cfg.get("edge_clearance", 0.0)
    if hol > 0.0:
        bandas = db.Region()
        for _, y0, y1 in rail_bands(cfg):
            bandas.insert(db.Box(int(round((left - 1.0) / u)), int(round(y0 / u)),
                                 int(round((left + width + 1.0) / u)), int(round(y1 / u))))
        franjas = db.Region()
        franjas.insert(db.Box(int(round((left - 1.0) / u)), int(round((bottom - 1.0) / u)),
                              int(round((left + hol) / u)), int(round((bottom + height + 1.0) / u))))
        franjas.insert(db.Box(int(round((left + width - hol) / u)), int(round((bottom - 1.0) / u)),
                              int(round((left + width + 1.0) / u)),
                              int(round((bottom + height + 1.0) / u))))
        for spec in cfg.get("edge_clearance_layers", []):
            intrusa = ((region(layout, cell, spec) - bandas.merged()) & franjas.merged()).merged()
            if not intrusa.is_empty():
                ib = intrusa.bbox().to_dtype(u)
                bad.append(
                    f"capa {spec} sin riel invade la franja de {hol:.1f} um junto al borde "
                    f"(x {ib.left:.1f}..{ib.right:.1f}, y {ib.bottom:.1f}..{ib.top:.1f}): "
                    f"cortocircuita con la celda vecina al abutar"
                )

    # 7. Pozo n: de borde a borde en X, y hasta pasar el límite superior
    nwell = region(layout, cell, cfg["nwell_layer"])
    if nwell.is_empty():
        bad.append("sin pozo n")
    else:
        nb = nwell.bbox().to_dtype(u)
        n_inset = cfg.get("nwell_x_inset", 0.0)
        nx_ini, nx_fin = left + n_inset, left + width - n_inset
        if not near(nb.left, nx_ini, GEO) or not near(nb.right, nx_fin, GEO):
            bad.append(
                f"pozo n va de x {nb.left:.1f} a {nb.right:.1f}, se esperaba "
                f"{nx_ini:.1f}..{nx_fin:.1f}: no forma banda continua al abutar"
            )
        # Continuidad lateral real: alguna figura del pozo debe cruzar la celda
        # de borde a borde. Un pozo partido en dos islas pasa el test del bbox.
        cruza = any(
            near(p.bbox().to_dtype(u).left, nx_ini, GEO)
            and near(p.bbox().to_dtype(u).right, nx_fin, GEO)
            for p in nwell.each()
        )
        if not cruza:
            bad.append("ninguna figura del pozo n cruza la celda de borde a borde "
                       "(pozo partido): se rompe la banda al abutar")
        hi = cfg.get("nwell_top", bottom + height)
        if not near(nb.top, hi, GEO):
            bad.append(f"pozo n llega a y {nb.top:.1f}, se esperaba {hi:.1f}")
        lo = nb.bottom
        if not (cfg["nwell_bottom_min"] - GEO <= lo <= cfg["nwell_bottom_max"] + GEO):
            bad.append(
                f"borde inferior del pozo n en y {lo:.1f}, fuera del rango "
                f"{cfg['nwell_bottom_min']:.1f}..{cfg['nwell_bottom_max']:.1f}"
            )

    # 8. Etiquetas de los pines de alimentación
    pin_idx = layer_index(layout, cfg["power_pin_layer"])
    etiquetas = {
        s.text.string for s in cell.shapes(pin_idx).each() if s.is_text()
    }
    for pin in cfg["power_pins"]:
        if pin not in etiquetas:
            bad.append(f"falta la etiqueta del pin {pin} en la capa {cfg['power_pin_layer']}")

    return bad


# --------------------------------------------------------------------------
# Prueba de fila: abutar todas las celdas y verificar continuidad
# --------------------------------------------------------------------------

def huecos(reg, u, x0, x1):
    """Intervalos de x no cubiertos por reg entre x0 y x1 (en micras)."""
    tramos = sorted(
        (p.bbox().to_dtype(u).left, p.bbox().to_dtype(u).right) for p in reg.each()
    )
    fuera, cursor = [], x0
    for a, b in tramos:
        if a > cursor + GEO:
            fuera.append((cursor, a))
        cursor = max(cursor, b)
    if cursor < x1 - GEO:
        fuera.append((cursor, x1))
    return fuera


def check_fila(celdas, cfg):
    """celdas = [(layout, cell)]. Las abuta en una fila y revisa continuidad.

    Es la prueba que el chequeo celda por celda no puede hacer: un retranqueo
    o un pozo n metido se ve solo cuando dos celdas quedan pegadas.
    Devuelve (lista_de_problemas, informe).
    """
    if not celdas:
        return ["no hay celdas para la prueba de fila"], []
    u0 = celdas[0][0].dbu
    for lay, _ in celdas:
        if not near(lay.dbu, u0, 1e-12):
            return [f"dbu distinto entre archivos ({lay.dbu} vs {u0}): "
                    f"no puedo abutar las celdas"], []

    acum = {"riel GND": db.Region(), "riel VDD": db.Region(), "pozo n": db.Region()}
    x, orden = 0.0, []
    for lay, cell in celdas:
        caja, _ = logical_box(lay, cell, cfg)
        if caja is None:
            continue
        dx = int(round((x - caja.left) / u0))
        t = db.Trans(dx, 0)
        bandas = dict(((n, (y0, y1)) for n, y0, y1 in rail_bands(cfg)))
        m1 = region(lay, cell, cfg["rail_layer"])
        for n, (y0, y1) in bandas.items():
            franja = db.Region(db.Box(int(-1e9), int(round(y0 / u0)),
                                      int(1e9), int(round(y1 / u0))))
            acum["riel " + n] += (m1 & franja).transformed(t)
        acum["pozo n"] += region(lay, cell, cfg["nwell_layer"]).transformed(t)
        orden.append((cell.name, x, x + caja.width()))
        x += caja.width()

    problemas, informe = [], []
    informe.append(f"fila de prueba: {len(orden)} celdas, ancho total {x:.1f} um")
    informe.append("  orden: " + " | ".join(n for n, _, _ in orden))
    for nombre, reg in acum.items():
        reg = reg.merged()
        faltan = huecos(reg, u0, 0.0, x)
        estado = "OK" if not faltan and reg.count() == 1 else "FALLA"
        informe.append(f"  {nombre:<9} {reg.count():>3} poligono(s)   {estado}")
        for a, b in faltan:
            vecinas = [n for n, xi, xf in orden if xi <= b + GEO and xf >= a - GEO]
            informe.append(f"      hueco en x {a:.1f}..{b:.1f} ({b-a:.1f} um) "
                           f"entre {' y '.join(vecinas) if vecinas else '?'}")
        if faltan:
            problemas.append(
                f"{nombre} discontinuo al abutar: {len(faltan)} hueco(s), "
                f"el mayor de {max(b-a for a, b in faltan):.1f} um"
            )
    return problemas, informe


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
    ap.add_argument("--fila", action="store_true",
                    help="además, abutar todas las celdas y verificar la "
                         "continuidad de rieles y pozo n")
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
    para_fila = []

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
            para_fila.append((layout, cell))
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

    problemas_fila = []
    if args.fila:
        print()
        problemas_fila, informe = check_fila(para_fila, cfg)
        for linea in informe:
            print(linea)
        if problemas_fila:
            print()
            print("Prueba de fila FALLIDA:")
            for p in problemas_fila:
                print(f"  - {p}")

    if fallos or problemas_fila:
        if fallos:
            print(f"{len(fallos)} celda(s) con violaciones:")
            for _, nombre, problemas in fallos:
                print(f"  - {nombre} ({len(problemas)})")
        return 1
    print("Todas las celdas cumplen.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
