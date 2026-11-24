# Niveles lógicos de la biblioteca digital CM05

**FUENTE ÚNICA DE VERDAD.** Los seis testbenches de `scripts/verify/digital/`
toman estos valores. Cambiarlos obliga a revalidar toda la biblioteca.

| Parámetro | Valor | De dónde sale |
|---|---|---|
| `VDD` | 5.0 V | — |
| `VIL` | **1.2 V** | Máximo "0" que la peor celda tolera, con margen |
| `VIH` | **3.3 V** | Por encima de `VDD − \|VTO_p\|` = 3.22 V: el PMOS queda apagado |
| `VOH_min` | 4.44 V | Convención CMOS 5 V |
| `VOL_max` | 0.5 V | Convención CMOS 5 V |
| Carga de prueba | 20 µA | Convención de hoja de datos (80 µA en 4X, 160 µA en 8X) |

## Por qué no son 1.5 / 3.5

El valor anterior venía de la convención JEDEC de 0.3 y 0.7 de VDD, que supone
umbrales simétricos. **CM05 no los tiene.** Con los modelos ajustados a TCAD
(rev. 3, 2026-11-23):

- `VTO_n` = 0.955 V — bajo, el NMOS enciende temprano
- `|VTO_p|` = 1.781 V — alto, el PMOS apaga temprano

Un reparto simétrico tiene la forma equivocada para un proceso asimétrico.
Medido con ngspice sobre cada topología (carga de 20 µA):

| Estructura | VIL máx. tolerado | VIH mín. necesario |
|---|---|---|
| NAND3 50/30 (3 en serie) | 2.24 V | ≤ 2.6 V |
| NAND2 50/15 (2 en serie) | 2.16 V | ≤ 2.6 V |
| Inverter 25/10 | 1.49 V | ≤ 2.5 V |
| **NOR2 50/10 (2 en paralelo)** | **1.31 V** | ≤ 2.5 V |

El lado bajo ataba y el alto sobraba: la especificación pedía tolerar 1.5 V
cuando la peor celda aguanta 1.31, y exigía 3.5 V cuando basta con 2.6.

Con 1.5 / 3.5 fallaban `Inverter` (VOH = 4.421 V) y `NOR2X1` (la salida se
desplomaba de 3.99 a 0.477 V al aplicar la carga).

## Verificación con 1.2 / 3.3

| Celda | Netlist | VOH | VOL | NMH | NML |
|---|---|---|---|---|---|
| AND2X1 | extraído | 4.949 | 0.028 | 1.65 | 1.17 |
| NAND3X1 | extraído | 4.828 | 0.068 | 1.53 | 1.13 |
| Inverter | reconstruido | 4.763 | 0.061 | 1.46 | 1.14 |
| Buffer | reconstruido | 4.905 | 0.040 | 1.60 | 1.16 |
| Buffer_4X | reconstruido | 4.879 | 0.051 | 1.58 | 1.15 |
| Buffer_8X | reconstruido | 4.845 | 0.065 | 1.55 | 1.13 |
| NAND2X1 | reconstruido | 4.869 | 0.084 | 1.57 | 1.12 |
| NOR2X1 | reconstruido | 4.643 | 0.054 | 1.34 | 1.15 |
| OR2X1 | reconstruido | 4.949 | 0.041 | 1.65 | 1.16 |

*Reconstruido* = topología estándar con los anchos medidos sobre el GDS, no
extracción real. Solo `AND2X1` y `NAND3X1` tienen netlist extraído hoy.

## Compatibilidad externa

**No se pierde interoperabilidad con 74HC en ninguna dirección.**

| Sentido | Lo que entrega | Lo que exige | |
|---|---|---|---|
| 74HC → CM05 | ≤ 0.33 V / ≥ 4.4 V | ≤ 1.2 V / ≥ 3.3 V | ✅ |
| CM05 → 74HC | ≤ 0.084 V / ≥ 4.64 V | ≤ 1.35 V / ≥ 3.15 V | ✅ |

El 1.5 / 3.5 es la especificación de **entrada** del 74HC, no lo que entrega a
la salida. Exigírselo a las celdas internas era pedirles tolerar algo que
ningún dispositivo real les manda.

## Advertencias

- **A `VIL` = 1.2 V cada compuerta fuga ~11 µA**, porque 1.2 V está por encima
  de `VTO_n` = 0.955 V. Es una condición de especificación, no de operación: en
  uso real las entradas están en los rieles y la fuga es de picoamperes. Si se
  quisiera corriente estática despreciable también en el peor caso, `VIL`
  tendría que bajar de 0.955 V, y ahí cae a 0.65 µA.
- **`NOR2X1` sigue siendo la celda más débil**, con solo 0.11 V entre el `VIL`
  fijado y su límite de 1.31 V. Su PMOS en serie da 25 µm efectivos contra
  20 µm de NMOS en paralelo, una razón de 1.25 cuando el proceso pide ~5.
  Ensanchar el PMOS a 100 µm la llevaría a tolerar 1.5 V, pero excede los
  ~65 µm de banda de difusión y obligaría a plegar en dedos.
- **`docs/regla_de_dimensionamiento.md` se derivó con los modelos anteriores**,
  cuya razón `KP_n/KP_p` era 1.09 en vez de 5.19. Sus tiempos de subida y
  bajada hay que recalcularlos.
- **`NAND2X1` está dibujada con `W_n` = 15 µm y la regla pide 20 µm.** Ninguna
  de las dos versiones falla los niveles, pero la discrepancia debe resolverse.

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-24 | 1.5 / 3.5 → **1.2 / 3.3**, con los modelos rev. 3 ajustados a TCAD |
