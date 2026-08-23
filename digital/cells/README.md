# Biblioteca digital CM05

16 celdas de fila migradas desde `CM05_celdas.gds` del PDK `CIDESI_CM05` v0.8.

Contrato de fila: altura 222.5 µm, pitch 2.5 µm. Ver `../docs/site_rules.md`.

| Celda | Función | Ancho (µm) | Sites | Pines | Contrato | Estado |
|---|---|---:|---:|---:|---|---|
| [`AND2X1`](AND2X1/cell.yaml) | AND de 2 entradas | 167.5 | 67 | 5 | ❌ 2 | migrated |
| [`Buffer`](Buffer/cell.yaml) | Buffer no inversor | 100.0 | 40 | 4 | ✅ | migrated |
| [`Buffer3S`](Buffer3S/cell.yaml) | Buffer con salida de tres estados | 185.0 | 74 | 5 | ✅ | migrated |
| [`Buffer_4X`](Buffer_4X/cell.yaml) | Buffer no inversor, fuerza 4X | 167.5 | 67 | 4 | ✅ | migrated |
| [`Buffer_8X`](Buffer_8X/cell.yaml) | Buffer no inversor, fuerza 8X | 245.0 | 98 | 4 | ❌ 1 | migrated |
| [`FFD`](FFD/cell.yaml) | Flip-flop tipo D | 582.5 | 233 | 12 | ✅ | migrated |
| [`FILLER`](FILLER/cell.yaml) | Celda de relleno | 35.0 | 14 | 0 | ❌ 5 | migrated |
| [`Inverter`](Inverter/cell.yaml) | Inversor | 87.5 | 35 | 4 | ✅ | migrated |
| [`Inverter3S`](Inverter3S/cell.yaml) | Inversor con salida de tres estados | 160.0 | 64 | 5 | ❌ 2 | migrated |
| [`Latch`](Latch/cell.yaml) | Cerrojo transparente | 362.5 | 145 | 10 | ✅ | migrated |
| [`NAND2X1`](NAND2X1/cell.yaml) | NAND de 2 entradas | 100.0 | 40 | 5 | ✅ | migrated |
| [`NOR2X1`](NOR2X1/cell.yaml) | NOR de 2 entradas | 100.0 | 40 | 5 | ✅ | migrated |
| [`OR2X1`](OR2X1/cell.yaml) | OR de 2 entradas | 140.0 | 56 | 5 | ✅ | migrated |
| [`TAP`](TAP/cell.yaml) | Celda de contactos de sustrato y pozo | 87.5 | 35 | 2 | ✅ | migrated |
| [`XNOR2X1`](XNOR2X1/cell.yaml) | XNOR de 2 entradas | 237.5 | 95 | 5 | ✅ | migrated |
| [`XOR2X1`](XOR2X1/cell.yaml) | XOR de 2 entradas | 195.0 | 78 | 5 | ❌ 2 | migrated |

**11 de 16 cumplen el contrato de fila.**

## Pendientes comunes a todas

- **Netlists**: el netlist heredado solo declaraba `VDD` y `GND` como puertos.
  Hay que re-extraer desde KLayout con el etiquetado de pines corregido.
- **Direcciones de pines**: están inferidas del nombre (`Out*` → salida, resto →
  entrada). Hay que confirmarlas celda por celda.
- **Modelos de comportamiento** (`.v`) y caracterización (`.lib`): no existen.

## Convención de pines

| Capa | Uso |
|---|---|
| `49/1` Metal1.text | `VDD` y `GND` |
| `51/1` Metal2.text | señales |

`FFD` y `Latch` tienen además etiquetas en `46/1` (Poly.text) y señales en
`49/1` que parecen nodos internos. Revisar antes de correr LVS: un nodo interno
etiquetado se confunde con un puerto.

## Nomenclatura

Se conservaron los nombres originales (`Inverter`, `NAND2X1`, …) en vez de
aplicar la convención `<función>_<drive>` de `CONTRIBUTING.md`. El nombre viaja
del layout al netlist y al LVS, y hay diseños que ya instancian estas celdas:
renombrarlas es un cambio coordinado que conviene decidir aparte.
