# Bloques

Ensambles que instancian celdas de las bibliotecas. A diferencia de una celda,
un bloque **cruza carpetas por naturaleza**: su valor está en componer.

| Bloque | Función | Instancia | Estado | Bloqueos |
|---|---|---|---|---:|
| [`HA`](HA/cell.yaml) | Medio sumador | `AND2X1`, `XOR2X1` | wip | 1 |
| [`Full_adder`](Full_adder/cell.yaml) | Sumador completo | `HA`, `OR2X1` | wip | 1 |
| [`NOT_CHAIN`](NOT_CHAIN/cell.yaml) | Cadena de inversores — retardo de propagación | `NOT`, `Buffer` | wip | 1 |
| [`MUX2X1`](MUX2X1/cell.yaml) | Multiplexor 2 a 1 | — | wip | 1 |
| [`Padframe2x2`](Padframe2x2/cell.yaml) | Padframe 2×2 | pads | migrated | — |
| [`Padframe4x4`](Padframe4x4/cell.yaml) | Padframe 4×4 | pads | migrated | — |

## Por qué los cuatro primeros están en `wip`

**`HA`, `Full_adder` y `NOT_CHAIN` no abren todavía en LTspice.** Instancian
símbolos de celdas que viven en `digital/cells/<nombre>/ltspice/`, y LTspice
busca los símbolos en la carpeta del esquemático que los coloca. No los va a
encontrar.

Esto es deliberado, no un descuido. La regla del repositorio es:

> **Jerarquía dentro de una unidad de trabajo; netlist en las fronteras de
> liberación.**

Una celda en diseño usa símbolo jerárquico dentro de su propia carpeta: es una
unidad, nadie más la toca, y no hay copia derivada que envejezca. Un bloque
consume celdas **liberadas**, y las consume por `.subckt` exportado con `.inc`.

Exportar el netlist de una celda que se edita a diario es frágil. Exportarlo
cuando la celda se libera — un evento raro y deliberado, ya modelado en
`status: released` — es simplemente parte de liberar.

Así que estos bloques quedan desbloqueados cuando las celdas que usan lleguen a
`released` y se exporten sus netlists. Igual que `CM05_celdas.gds` es el
producto liberado del layout.

**`MUX2X1`** es distinto: su esquemático tiene cables y etiquetas (`A`, `B`,
`S`, `Y`) pero ningún componente colocado. Se conserva a propósito como versión
en trabajo.

## Valor didáctico

`HA` → `Full_adder` muestra la jerarquía completa: compuerta, medio sumador,
sumador completo. `NOT_CHAIN` mide retardo de propagación en cadena — una
medición que no sale de un testbench de celda aislada.
