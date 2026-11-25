"""
check_hilachas.py - Riesgo de corto por residuo de aluminio en los escalones.

NO ES UN CHEQUEO ACTIVO. Hoy el aluminio de CM05 se graba en HUMEDO, que es
isotropico: el ataque lateral se lleva el metal que trepa los escalones, asi
que no quedan filamentos. Este script existe para el dia que eso cambie.

CUANDO CORRERLO
---------------
Si el grabado del aluminio pasa a ATAQUE SECO (plasma, anisotropico). Ese es
el unico disparador. En el PDK esta declarado en
tech/CIDESI_CM05/xsection/CIDESI_CM05.xs como:

    m1_etch = "humedo"      # "humedo" (isotropico) o "seco" (anisotropico)

Si alguien lo cambia a "seco", corre esto sobre toda la biblioteca antes de
liberar nada.

QUE BUSCA
---------
Con grabado seco, el Al que trepa un escalon mas alto que la profundidad de
grabado queda como filamento pegado al flanco, corriendo a lo largo de TODO
el borde de la figura. El escalon critico es la compuerta con su oxido de
tapa: 0.60 um contra 0.52 de grabado.

Consecuencia: toda pista de Metal1 que cruce una figura de poly queda unida
al filamento de ese borde. Si dos redes distintas cruzan la MISMA figura de
poly, el filamento las cortocircuita. Con la seccion que da el corte
(0.28 x 0.33 um) son unos 29 ohm por cada 100 um: un corto franco.

ESTADO CONOCIDO DE LA BIBLIOTECA (nov-2026)
-------------------------------------------
Con grabado seco, 14 de las 17 celdas de fila fallarian. Solo pasan FILLER
(no tiene poly), Inverter y TAP. Los peores son FFD, con una figura de poly
cruzada por 10 redes, y Latch con 8.

Eso NO es un defecto de las celdas: en un proceso de dos metales es
inevitable pasar M1 sobre poly. Si se pasa a seco, la mitigacion tiene que
ser de proceso (perfil del escalon, sobregrabado), no de layout.

Uso:
    python scripts/drc/check_hilachas.py digital/cells/*/layout/*.gds

Requiere el modulo de KLayout: pip install klayout
"""
import sys, glob
import klayout.db as db

CAPAS = dict(nwell=(42,0), active=(43,0), pplus=(44,0), nplus=(45,0),
             poly=(46,0), ctp=(47,0), cta=(48,0), m1=(49,0),
             via1=(50,0), m2=(51,0), m1txt=(49,1), m2txt=(51,1))

def revisa(gds):
    ly = db.Layout(); ly.read(gds); top = ly.top_cell(); u = ly.dbu
    idx = {k: ly.layer(*v) for k, v in CAPAS.items()}
    l2n = db.LayoutToNetlist(db.RecursiveShapeIterator(ly, top, []))
    L = {}
    for k in ("nwell","active","poly","ctp","cta","m1","via1","m2"):
        L[k] = l2n.make_polygon_layer(idx[k], k)
    for k in ("m1txt","m2txt"):
        L[k] = l2n.make_text_layer(idx[k], k)
    nplus = l2n.make_polygon_layer(idx["nplus"], "nplus")
    pplus = l2n.make_polygon_layer(idx["pplus"], "pplus")
    sd = L["active"] - L["poly"]
    l2n.register(sd, "sd")
    # El pozo se conecta SOLO por su tap (activo n+ dentro del pozo), no por
    # la fuente/drenaje p+ del PMOS: conectarlo a todo el activo cortocircuita
    # la salida con VDD.
    tap_nwell = (L["active"] & L["nwell"]) & nplus
    tap_psub  = (L["active"] - L["nwell"]) & pplus
    l2n.register(tap_nwell, "tap_nwell"); l2n.register(tap_psub, "tap_psub")
    l2n.connect(sd, L["cta"]); l2n.connect(L["poly"], L["ctp"])
    l2n.connect(L["cta"], L["m1"]); l2n.connect(L["ctp"], L["m1"])
    l2n.connect(L["m1"], L["via1"]); l2n.connect(L["via1"], L["m2"])
    l2n.connect(L["nwell"], tap_nwell)
    l2n.connect(L["m1"], L["m1txt"]); l2n.connect(L["m2"], L["m2txt"])
    l2n.extract_netlist()

    circuito = l2n.netlist().circuit_by_name(top.name)
    if circuito is None:
        return top.name, ["no se pudo extraer el netlist"]
    # region de Metal1 de cada red
    redes = []
    for net in circuito.each_net():
        r = l2n.shapes_of_net(net, L["m1"], True)
        if r is None or r.is_empty():
            continue
        redes.append((net.expanded_name(), r.merged()))

    poly = db.Region(top.begin_shapes_rec(idx["poly"])).merged()
    hallazgos = []
    for p in poly.each():
        pr = db.Region(p)
        tocan = [n for n, r in redes if not (r & pr).is_empty()]
        if len(tocan) > 1:
            b = p.bbox().to_dtype(u)
            hallazgos.append(
                f"poly en x {b.left:.1f}..{b.right:.1f} y {b.bottom:.1f}..{b.top:.1f} "
                f"lo cruzan {len(tocan)} redes de Metal1: {', '.join(sorted(tocan))}")
    return top.name, hallazgos

def main(argv):
    archivos = []
    for pat in argv:
        archivos.extend(glob.glob(pat) or [pat])
    malas = 0
    for f in sorted(archivos):
        nombre, h = revisa(f)
        if h:
            malas += 1
            print(f"  X  {nombre:<14} {len(h)} figura(s) de poly en riesgo")
            for x in h: print(f"       - {x}")
        else:
            print(f"  OK {nombre:<14} ninguna figura de poly cruzada por dos redes")
    print()
    print(f"Resumen: {len(archivos)-malas}/{len(archivos)} celdas sin riesgo de corto por residuo.")
    return 1 if malas else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
