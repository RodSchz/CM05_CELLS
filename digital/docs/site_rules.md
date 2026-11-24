# Contrato geométrico de la biblioteca digital CM05

Toda celda estándar debe cumplir estas reglas. Una celda que no las cumpla no
puede colocarse en fila ni abutar con sus vecinas, aunque su DRC y su LVS estén
limpios.

Los valores viven en **`digital/site.yaml`**, que es la fuente única de verdad:
este documento los explica, y `scripts/drc/check_site.py` los verifica. Cambiar
un número allí obliga a revalidar toda la biblioteca.

## Rev. 2 — abutment horizontal

La rev. 1 declaraba los rieles retranqueados 7.5 µm por lado, de modo que al
abutar dos celdas quedaban **15 µm de hueco entre rieles** y la alimentación no
se conectaba por abutment: había que rutear VDD y GND a mano en cada fila.

La rev. 2 pone `rail_x_inset: 0.0`. El riel llega exacto a los dos bordes,
abuta con el de la vecina y se fusiona. Es la convención de la biblioteca
osu05, verificada por medición sobre un diseño real hecho con celdas osu05
escaladas a CM05.

### Por qué toque exacto y no sobresalto

osu05 hace que el riel **sobresalga 5 µm por lado**, así que al abutar los
rieles se traslapan 10 µm. Aquí el retranqueo es 0.0 (toque exacto) a
propósito: la holgura de Metal1 de señal al borde es de 7.5 µm = 3λ en las 16
celdas, así que un sobresalto de 5 µm dejaría el riel de la vecina a 2.5 µm de
una señal y violaría el espaciado mínimo de Metal1.

### Qué NO se adopta de osu05

En osu05 el **eje** del riel coincide con el límite de fila, de forma que dos
filas espejeadas comparten el mismo riel físico. Aquí no, y es deliberado: 15
de las 17 celdas llevan stubs de pin en Metal2 asomando por los bordes
superior e inferior (15 × 10 µm), que es la convención correcta para un proceso
de **dos metales con ruteo por canal**. Las filas no se pegan verticalmente:
entre ellas va el canal de ruteo, los stubs son los puntos de acceso del
router, y los rieles de cada fila se alimentan de una espina vertical.
Compartir riel entre filas espejeadas haría chocar esos stubs.

Si algún día hay un tercer metal, esa parte de la convención se puede
reconsiderar; ahorraría 30 µm por fila.

## La fila

| Parámetro | Valor | Cómo se determinó |
|---|---|---|
| Altura de fila | **222.5 µm** | 14 de 16 celdas de fila coinciden |
| Pitch (ancho unitario) | **2.5 µm** | MCD de los 16 anchos; los 16 son múltiplos exactos |
| Origen | **(0.0, 0.0)** | Esquina inferior izquierda de la capa de boundary |

Todo ancho debe ser múltiplo entero del pitch. Ejemplos que ya cumplen:
`FILLER` = 14 × 2.5, `Inverter` = 35 × 2.5, `NAND2X1` = 40 × 2.5,
`FFD` = 233 × 2.5.

### El límite lógico lo da la capa de boundary, no el bounding box

El contrato se verifica contra la capa **`100/0`**, presente en las 17 celdas.
El bounding box no sirve como referencia: se infla con cualquier etiqueta o
figura mal puesta y el contrato dejaría de detectarlo. `Inverter` y `TAP` son
justamente ese caso — su capa de boundary mide 85.0 µm mientras su geometría
llega a 87.5, y 87.5 es el valor correcto porque es el que deja el riel
centrado.

Nada puede quedar fuera de ese rectángulo (`overhang_x`, `overhang_y_bottom`,
`overhang_y_top`, los tres en 0.0). Un sobresalto lateral choca con la vecina;
uno vertical se mete en el canal de ruteo.

## Rieles de alimentación

En Metal1 (capa `49/0`). Medidos sobre `FILLER`, que no tiene más geometría que
los rieles:

| Riel | Extensión vertical | Ancho | Centro |
|---|---|---|---|
| GND | y 5.0 .. 15.0 | 10.0 µm | y = 10.0 |
| VDD | y 197.5 .. 207.5 | 10.0 µm | y = 202.5 |

El riel debe cubrir la **banda completa de borde a borde, sin muescas**.
`check_site.py` lo verifica por sustracción (`banda − metal1`), no por bounding
box: así detecta a la vez un riel corto, uno angosto y uno con una muesca en
medio.

## Holgura al borde lateral

Toda figura de Metal1 o Metal2 que **no** sea el riel debe quedar a
`edge_clearance` = 7.5 µm (3λ, el espaciado mínimo de Metal1) de los bordes
izquierdo y derecho. Sin esta regla, una señal pegada al borde queda a 0 µm del
riel o de la señal de la celda vecina en cuanto las dos se abutan.

## Pozo n

En capa `42/0`. Debe llegar al borde superior de la celda (y = 222.5) y,
en X, a los dos bordes laterales; además alguna figura del pozo tiene que
cruzar la celda de lado a lado, para formar banda continua al abutar.

Este era el defecto de `FILLER` en la rev. 1: su pozo estaba metido 2.5 µm por
lado y partía la banda en cada filler de la fila. El contrato anterior no lo
detectaba porque solo miraba el borde superior.

El borde inferior varía entre 110.0 y 125.0 µm según la celda. La configuración
acepta ese rango, pero conviene revisar si esa variación causa muescas de pozo
en DRC cuando dos celdas con bordes distintos quedan adyacentes.

## Pines

Etiquetas de texto en Metal1 (`49/1`) para alimentación y en Metal2 (`51/1`)
para señal, con el nombre exacto del netlist. Toda celda de fila debe declarar
al menos `VDD` y `GND`.

## Celdas exentas

Pads (`PADVDD`, `PADGND`, `PADIGI`, `CORNER`), padframes y `Outbuffer` no se
colocan en filas y están exentas. La lista está en `site.yaml`.

## Migración de la rev. 1 a la rev. 2

`scripts/layout/migrate_site_rev2.py` hace la parte mecánica, sin tocar
geometría interna: normaliza el origen en X, extiende los dos rieles hasta los
bordes, extiende el pozo n hasta los bordes y redibuja la capa de boundary como
el rectángulo lógico.

```bash
# 1. migrar a un directorio aparte y verificar
python scripts/layout/migrate_site_rev2.py --out /tmp/rev2 \
    digital/cells/*/layout/*.gds
python scripts/drc/check_site.py --fila /tmp/rev2/*.gds

# 2. si el resultado convence, en una rama y revisando el diff en KLayout
python scripts/layout/migrate_site_rev2.py --in-place \
    digital/cells/*/layout/*.gds
```

Resultado de esa migración sobre la biblioteca actual: **16 de 17 celdas
cumplen** y la fila de prueba de 3057.5 µm queda con el riel GND, el riel VDD y
el pozo n en **un solo polígono cada uno** — es decir, la alimentación ya se
conecta por abutment.

Cambios que aplicó: los rieles de 16 celdas, el pozo n de `FILLER` (+2.5 µm por
lado) y la capa de boundary de `Inverter` y `TAP`.

**`NAND3X1` es la única que hay que redibujar a mano:** su Metal1 y su Metal2
llegan hasta x = 0 y x = 105, con holgura 0 al borde en vez de 7.5 µm. Hay que
replegar ese ruteo interno antes de que la celda pueda abutar.

## Cómo verificar

```bash
pip install klayout

# Una celda suelta
python scripts/drc/check_site.py digital/cells/Inverter/layout/Inverter.gds

# Toda la biblioteca
python scripts/drc/check_site.py --quiet digital/cells/*/layout/*.gds

# Además, abutar todas las celdas y revisar continuidad de rieles y pozo n
python scripts/drc/check_site.py --quiet --fila digital/cells/*/layout/*.gds

# Solo una celda de un archivo con varias
python scripts/drc/check_site.py --cell AND2X1 CM05_celdas.gds
```

Sale con código 1 si hay violaciones, que es lo que hace fallar el check en el
pull request.
