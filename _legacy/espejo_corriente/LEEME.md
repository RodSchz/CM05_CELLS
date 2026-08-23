# Espejo_corriente — material no clasificado

Contenido del archivo `Espejo_corriente.rar` que **no** se incorporó a
`analog/cells/cmirror/`. Nada se descartó; esto es lo que quedó fuera y por qué.

| Archivo | Qué es | Por qué está aquí |
|---|---|---|
| `cmirror_multicelda.gds` | GDS original completo | Contiene 5 celdas: `cmirror`, `cmirror_lay`, `prueba`, `Inverter`, `AND2X1`. Se extrajo solo `cmirror` hacia la celda. |
| `cmirror2.cir` | Netlist idéntico a `cmirror.cir` | Solo cambia el nombre del subcircuito (`cmirror2`). Duplicado. |
| `prueba.cir` | Netlist extraído de la celda `prueba` | Contiene los subcircuitos **`Inverter`** y **`AND2X1`** — material de biblioteca digital, ver abajo. |
| `prueba_lvs.asc` | Esquemático LTspice vacío | 28 bytes, sin contenido. |
| `prueba_lvs.cir` | Netlist con la instancia comentada | `*XX1 ... cmirror`. Sin uso. |
| `cmirror_sim.log` | Bitácora de LTspice | Salida regenerable; excluida por `.gitignore`. |
| `cmirror_sim.raw` | Resultados crudos de simulación | Salida regenerable; excluida por `.gitignore`. |

## Material digital recuperable

`cmirror_multicelda.gds` y `prueba.cir` contienen dos celdas digitales ya
dibujadas y extraídas:

| Celda | Tamaño (µm) | Formas | Netlist |
|---|---|---|---|
| `Inverter` | 87.5 × 222.5 | 56 | `prueba.cir` → `.SUBCKT Inverter VDD GND` |
| `AND2X1` | 167.5 × 225.0 | 105 | `prueba.cir` → `.SUBCKT AND2X1 VDD GND` |

Son candidatas directas para `digital/cells/`. Dos observaciones antes de
migrarlas:

1. **Las alturas no coinciden**: 222.5 µm contra 225.0 µm. Una biblioteca
   estándar exige altura de fila idéntica en todas las celdas. Hay que decidir
   la altura definitiva y rehacer la que no cumpla.
2. **Los puertos de los subcircuitos solo declaran `VDD` y `GND`** — faltan las
   entradas y la salida (`A`, `B`, `Out` aparecen como nodos internos). Habrá
   que revisar el etiquetado de pines en el layout antes de extraer de nuevo.
