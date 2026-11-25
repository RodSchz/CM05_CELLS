# Netlists de referencia — celdas digitales solicitadas

Aquí viven los **netlists de contrato** de las celdas que están pedidas por un
issue pero todavía no existen en `digital/cells/`.

## Qué son

CIDESI aporta el diseño eléctrico; lo que se solicita en el issue es el **diseño
físico**. Estos archivos son ese diseño eléctrico, ya dimensionado y verificado
en ngspice contra los modelos del PDK. **El LVS del layout entregado tiene que
empatar contra el netlist de aquí**: mismo número de dispositivos, mismos `W` y
`L`, misma conectividad, mismos puertos en el mismo orden.

Los anchos no se negocian en el PR. Si crees que un ancho está mal, dilo en el
issue antes de dibujar.

La cabecera de cada archivo trae la función, el issue que lo pide, el criterio de
dimensionamiento, los márgenes medidos y el vector `esperado` del testbench que
corresponde.

## Ciclo de vida

Un netlist sale de esta carpeta cuando la celda ya existe: al mergear el layout,
el netlist extraído por KLayout queda en
`digital/cells/<CELDA>/layout/<CELDA>.cir` y **este archivo se borra**. Si sigue
aquí, la celda está pendiente.

## Contenido actual

| Archivo | Función | Issue | Entradas |
|---|---|---|---|
| `NOR3X1.sp` | `Out = NOT(A + B + C)` | #40 | 3 |
| `AOI21X1.sp` | `Out = NOT(A·B + C)` | #40 | 3 |
| `OAI21X1.sp` | `Out = NOT((A + B)·C)` | #40 | 3 |
| `AOI22X1.sp` | `Out = NOT(A·B + C·D)` | #40 | 4 |
| `OAI22X1.sp` | `Out = NOT((A + B)·(C + D))` | #40 | 4 |

## Cómo simularlos

No son testbenches: son subcircuitos. Se verifican con los testbenches de
`scripts/verify/digital/`, copiados a la carpeta `sim/` de la celda. El
procedimiento está en `docs/guia-celdas.md`.

Las cinco celdas de arriba se corrieron en CIDESI y las cinco dan `COINCIDE` y
veredicto `COMPATIBLE` con niveles CMOS 5 V.

## Documentos relacionados

- `docs/regla_de_dimensionamiento.md` — de dónde salen los anchos
- `docs/niveles_logicos.md` — `VIL`, `VIH`, `VOH`, `VOL` y márgenes de ruido
- `digital/docs/site_rules.md` — el contrato de fila que debe cumplir el layout
- `digital/_template/README.md` — cómo arrancar una celda nueva
