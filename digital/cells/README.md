# Biblioteca digital CM05

16 celdas de fila. Contrato: altura 222.5 µm, pitch 2.5 µm — ver `../docs/site_rules.md`.

| Celda | Función | Ancho | Sites | Pines | LTspice | Contrato | Bloqueos | Estado |
|---|---|---:|---:|---:|:---:|---|---:|---|
| [`AND2X1`](AND2X1/cell.yaml) | AND de 2 entradas | 167.5 | 67 | 5 | sí | ❌ | 3 | wip |
| [`Buffer`](Buffer/cell.yaml) | Buffer no inversor | 100.0 | 40 | 4 | sí | ✅ | 2 | wip |
| [`Buffer3S`](Buffer3S/cell.yaml) | Buffer con salida de tres estados | 185.0 | 74 | 5 | — | ✅ | — | migrated |
| [`Buffer_4X`](Buffer_4X/cell.yaml) | Buffer no inversor, fuerza 4X | 167.5 | 67 | 4 | — | ✅ | — | migrated |
| [`Buffer_8X`](Buffer_8X/cell.yaml) | Buffer no inversor, fuerza 8X | 245.0 | 98 | 4 | — | ❌ | — | migrated |
| [`FFD`](FFD/cell.yaml) | Flip-flop tipo D | 582.5 | 233 | 12 | — | ✅ | — | migrated |
| [`FILLER`](FILLER/cell.yaml) | Celda de relleno | 35.0 | 14 | 0 | — | ❌ | — | migrated |
| [`Inverter`](Inverter/cell.yaml) | Inversor | 87.5 | 35 | 4 | sí | ✅ | 3 | wip |
| [`Inverter3S`](Inverter3S/cell.yaml) | Inversor con salida de tres estados | 160.0 | 64 | 5 | — | ❌ | — | migrated |
| [`Latch`](Latch/cell.yaml) | Cerrojo transparente | 362.5 | 145 | 10 | — | ✅ | — | migrated |
| [`NAND2X1`](NAND2X1/cell.yaml) | NAND de 2 entradas | 100.0 | 40 | 5 | sí | ✅ | 2 | wip |
| [`NOR2X1`](NOR2X1/cell.yaml) | NOR de 2 entradas | 100.0 | 40 | 5 | sí | ✅ | 2 | wip |
| [`OR2X1`](OR2X1/cell.yaml) | OR de 2 entradas | 140.0 | 56 | 5 | sí | ✅ | 2 | wip |
| [`TAP`](TAP/cell.yaml) | Celda de contactos de sustrato y pozo | 87.5 | 35 | 2 | — | ✅ | — | migrated |
| [`XNOR2X1`](XNOR2X1/cell.yaml) | XNOR de 2 entradas | 237.5 | 95 | 5 | sí | ✅ | 3 | wip |
| [`XOR2X1`](XOR2X1/cell.yaml) | XOR de 2 entradas | 195.0 | 78 | 5 | sí | ❌ | 2 | wip |

**11 de 16** cumplen el contrato de fila · **8 de 16** tienen esquemático · **19 bloqueos abiertos**.

## Cómo leer el estado

| Estado | Significa |
|---|---|
| `wip` | En trabajo. Tiene bloqueos abiertos que impiden avanzar. |
| `migrated` | Traída del material previo, sin verificar. |
| `drc_clean` | DRC limpio. |
| `lvs_clean` | LVS sin discrepancias. |
| `characterized` | Caracterizada, con `.lib` generado. |
| `released` | Liberada. **Requiere cero bloqueos abiertos.** |

Los bloqueos viven en el campo `blockers:` de cada `cell.yaml`, con `id`,
`severity`, `summary`, `owner` e `issue`. El campo `issue` apunta al número de
issue de GitHub donde se está resolviendo.

## Bloqueos comunes a todas las celdas con esquemático

- **`pines-alimentacion`** — el esquemático nombra `V+` / `V-`, el layout `VDD` / `GND`.
- **`netlist-sin-puertos`** — el netlist heredado solo declaraba `VDD` y `GND`; falta re-extraer.

## Bloqueos específicos

| Celda | Bloqueo |
|---|---|
| `AND2X1` | Esquemático PMOS 25u/NMOS 10u contra layout 50u/15u. **La buena es la del layout.** |
| `Inverter` | El esquemático se llama `NOT`, la celda del layout `Inverter`. |
| `XNOR2X1` | El archivo es `XNOR2x1` (x minúscula); en Linux es otro nombre. |

## Sin esquemático todavía

`Inverter3S`, `Buffer_4X`, `Buffer_8X`, `Buffer3S`, `Latch`, `FFD`, `TAP`, `FILLER`.

## Convención de pines

| Capa | Uso |
|---|---|
| `49/1` Metal1.text | `VDD` y `GND` |
| `51/1` Metal2.text | señales |

`FFD` y `Latch` tienen además etiquetas en `46/1` (Poly.text) y señales en
`49/1` que parecen nodos internos. Revisar antes de correr LVS.

## Nomenclatura

Se conservaron los nombres originales del layout (`Inverter`, `NAND2X1`, …) en
vez de la convención `<función>_<drive>` de `CONTRIBUTING.md`. El nombre viaja
del layout al netlist y al LVS, y hay diseños que ya instancian estas celdas:
renombrarlas es un cambio coordinado que conviene decidir aparte.
