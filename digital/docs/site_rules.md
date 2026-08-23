# Contrato geométrico de la biblioteca digital CM05

Toda celda estándar debe cumplir estas reglas. Una celda que no las cumpla no
puede colocarse en fila ni abutar con sus vecinas, aunque su DRC y su LVS estén
limpios.

Los valores viven en **`digital/site.yaml`**, que es la fuente única de verdad:
este documento los explica, y `scripts/drc/check_site.py` los verifica. Cambiar
un número allí obliga a revalidar toda la biblioteca.

## De dónde salen estos valores

No se inventaron: se midieron sobre `CM05_celdas.gds` del PDK (`CIDESI_CM05`
v0.8), que ya contiene 19 celdas dibujadas. Se tomó como referencia el
subconjunto de 11 celdas mutuamente consistentes.

## La fila

| Parámetro | Valor | Cómo se determinó |
|---|---|---|
| Altura de fila | **222.5 µm** | 14 de 16 celdas de fila coinciden |
| Pitch (ancho unitario) | **2.5 µm** | MCD de los 16 anchos; los 16 son múltiplos exactos |
| Origen | **(0.0, 0.0)** | Esquina inferior izquierda del bounding box |

Todo ancho debe ser múltiplo entero del pitch. Ejemplos que ya cumplen:
`FILLER` = 14 × 2.5, `Inverter` = 35 × 2.5, `NAND2X1` = 40 × 2.5,
`FFD` = 233 × 2.5.

## Rieles de alimentación

En Metal1 (capa `49/0`). Medidos sobre `FILLER`, que no tiene más geometría que
los rieles:

| Riel | Extensión vertical | Ancho | Centro |
|---|---|---|---|
| GND | y 5.0 .. 15.0 | 10.0 µm | y = 10.0 |
| VDD | y 197.5 .. 207.5 | 10.0 µm | y = 202.5 |

Los centros coinciden con la posición de las etiquetas `GND` y `VDD` en todas
las celdas, así que el criterio es sólido.

### Retranqueo horizontal: 7.5 µm — decisión pendiente

Los rieles **no llegan a los bordes**: están metidos exactamente 7.5 µm por
cada lado, de forma consistente en las 16 celdas de fila. Es una convención
deliberada, no un error aislado.

La consecuencia hay que tenerla presente: al abutar dos celdas queda un hueco
de **15 µm entre rieles**, así que la alimentación *no se conecta por
abutment*. Hay que rutearla explícitamente en cada fila.

Es una decisión legítima para un proceso de 5 µm con diseños pequeños. Pero si
en algún momento quieres colocación y ruteo automáticos, tendrás que redibujar
las 16 celdas con `rail_x_inset: 0.0`. Cuanto antes se decida, más barato sale.

## Pozo n

En capa `42/0`. Debe llegar al borde superior de la celda (y = 222.5) para
formar una banda continua al abutar.

El borde inferior varía entre 110.0 y 125.0 µm según la celda. La configuración
acepta ese rango, pero conviene revisar si esa variación causa muescas de pozo
en DRC cuando dos celdas con bordes distintos quedan adyacentes.

## Pines

Etiquetas de texto en Metal1 (`49/1`), con el nombre exacto del netlist. Toda
celda de fila debe declarar al menos `VDD` y `GND`.

## Celdas exentas

Pads (`PADVDD`, `PADGND`, `PADIGI`, `CORNER`), padframes y `Outbuffer` no se
colocan en filas y están exentas. La lista está en `site.yaml`.

## Estado actual de la biblioteca

Resultado de `check_site.py` sobre `CM05_celdas.gds` v0.8:

**11 de 16 celdas cumplen** — `XNOR2X1`, `NOR2X1`, `Latch`, `Buffer3S`,
`Buffer_4X`, `Buffer`, `NAND2X1`, `FFD`, `TAP`, `OR2X1`, `Inverter`.

**5 con violaciones:**

| Celda | Problema | Gravedad |
|---|---|---|
| `AND2X1` | Origen en y = −2.5 (cuelga por debajo) y altura 225.0 | Alta — desalinea la fila |
| `XOR2X1` | Origen en y = +2.5 (desplazada hacia arriba); pozo n hasta 225.0 | Alta — desalinea la fila |
| `Inverter3S` | Altura 215.0 (−7.5); pozo n hasta 215.0 | Alta — deja hueco vertical |
| `Buffer_8X` | Riel GND de x 5.0 a 235.0 en vez de 7.5 a 237.5 | Media — asimétrico |
| `FILLER` | Origen en x = 7.5; sin etiquetas `VDD`/`GND` | Media — ver nota |

**Nota sobre `FILLER`:** sus rieles sí llegan a los bordes de su propio
bounding box. Si la intención es que el filler sea justamente lo que puentea
los huecos de 15 µm entre rieles, entonces su regla es distinta a la del resto
y hay que declararla como excepción explícita en `site.yaml`. Vale la pena
decidirlo antes de corregir su origen.

`AND2X1`, `XOR2X1` e `Inverter3S` son defectos claros: hay que corregirlos.

## Cómo verificar

```bash
pip install klayout

# Una celda suelta
python scripts/drc/check_site.py digital/cells/inv_x1/layout/inv_x1.gds

# Toda la biblioteca
python scripts/drc/check_site.py --quiet CM05_celdas.gds

# Solo una celda de un archivo con varias
python scripts/drc/check_site.py --cell AND2X1 CM05_celdas.gds
```

Sale con código 1 si hay violaciones, que es lo que hace fallar el check en el
pull request.
