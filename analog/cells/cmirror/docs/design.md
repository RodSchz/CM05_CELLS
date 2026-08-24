# cmirror — Notas de diseño

> Documento reconstruido a partir de los archivos entregados (`Espejo_corriente.rar`,
> agosto 2026). Las secciones marcadas **PENDIENTE** requieren información del
> diseñador.

## Propósito

Espejo de corriente NMOS 1:1. Primera celda usada para validar la estructura
del repositorio y el flujo LTspice → KLayout → extracción → comparación.

## Topología

Dos transistores CIDNMOS idénticos, `L = 10 µm`, `W = 100 µm`:

- **M1** en conexión de diodo (compuerta unida al drenaje, nodo `P1`). Fija la
  tensión de compuerta a partir de la corriente de referencia inyectada en `P1`.
- **M2** comparte compuerta y fuente con M1, y entrega la corriente espejada
  en `P2`.

Fuente común en `COM`. Relación nominal 1:1 por igualdad de W/L.

## Orden de puertos

Un detalle que hay que respetar al instanciar la celda, porque **no es el mismo
en el esquemático que en el layout**:

| Fuente | Orden |
|---|---|
| `cmirror.asy` (SpiceOrder) | `COM, P1, P2` |
| Netlist extraído por KLayout | `P1, P2, COM` |
| `cmirror_lay.asy` (símbolo del layout) | `P1, P2, COM` |

Los dos símbolos son consistentes con sus respectivos netlists, así que el
testbench funciona. Pero si alguien mezcla símbolo y netlist cruzados, la celda
se conecta mal sin dar error. **Conviene unificar el orden a `P1, P2, COM`** en
ambos símbolos y regenerar.

## Verificación realizada

**DRC: limpio.** El reporte `results/CIDESI_CMOS_DRC.lyrdb` se generó con el
runset `CIDESI_CM05/tech/CIDESI_CM05/drc/drc.lydrc` sobre la celda `cmirror` y
no contiene ninguna violación.

**LVS: coincidencia verificada manualmente, no formal.** El netlist extraído
del layout coincide topológicamente con el esquemático:

| | Esquemático (`cmirror_sch.cir`) | Extraído (`layout/cmirror.cir`) |
|---|---|---|
| M1 | `P1 P1 COM COM` (D G S B) | `COM P1 P1 COM` |
| M2 | `P2 P1 COM COM` | `P2 P1 COM COM` |
| Dimensiones | `l=10u w=100u` | `L=10U W=100U` |

La permuta drenaje/fuente en M1 es normal: el MOS es simétrico y la extracción
no distingue. **PENDIENTE:** correr LVS formal en KLayout para dejar constancia.

## Hallazgo: discrepancia en `cmirror_lay`

`sim/cmirror_lay.cir` — extraído de la celda `cmirror_lay` del GDS original, la
que el testbench usa como referencia de layout — declara:

```
M$1 P2  P1 COM COM CIDNMOS L=10U W=100U
M$2 COM P1 P1  COM CIDNMOS L=8U  W=100U    <-- L = 8 µm
```

**Los dos transistores no están apareados: uno tiene L = 10 µm y el otro
L = 8 µm.** En un espejo de corriente eso rompe la relación 1:1 — la corriente
de salida quedaría desviada aproximadamente un 25 % respecto a la referencia,
sin contar efectos de canal corto.

Hay que determinar si es un error de dibujo en esa celda de prueba o una
variante intencional. La celda `cmirror` que se conserva aquí **sí** tiene los
dos transistores a `L = 10 µm`, así que el problema está acotado a
`cmirror_lay`.

## Dos entornos de simulación

La celda se verifica en dos etapas distintas, no dos veces lo mismo:

| Carpeta | Parte de | Qué representa |
|---|---|---|
| `ltspice/` | El esquemático dibujado | El circuito ideal, pre-layout |
| `ngspice/` | El netlist extraído por KLayout | El circuito real, tal como quedó dibujado |

El testbench de ngspice no lee el `.asc`, así que no puede quedar
desincronizado con él. La diferencia entre ambos resultados es el dato de
interés: cuánto se aparta el dibujo del ideal.

## Resultados medidos (ngspice, netlist extraído)

Corner `tt`, 27 °C, sobre `layout/cmirror.cir`:

| Medición | Valor |
|---|---|
| Relación @ 10 µA | 1.0101 |
| Relación @ 50 µA | 1.0032 |
| Relación @ 100 µA | 1.0016 |
| Relación @ 190 µA | 1.0006 |
| V_GS @ 100 µA | 1.6685 V |
| r_out @ V_out = 4 V | 5.12 MΩ |
| V_min de salida | 0.836 V |

**El espejo funciona**, con un error por exceso de entre 0.06 % y 1 % según la
corriente. La relación baja al subir la corriente, y eso tiene una explicación
física clara: modulación de longitud de canal. M1, en conexión de diodo,
mantiene su drenaje en V_GS = 1.67 V; M2 lo tiene en 2.5 V. Esa diferencia de
V_DS hace que M2 conduzca un poco más, y el efecto pesa proporcionalmente más
cuando la corriente es baja.

Para reducirlo, el camino conocido es un espejo cascodo — a costa de subir la
tensión mínima de salida, que hoy es 0.836 V y define el límite inferior del
rango útil.

**Nota importante:** estos números son del netlist de LVS, sin parásitos. Con
`W = 100 µm` en un proceso de 5 µm, extraer con `PEX.lylvs` probablemente los
mueva. Falta hacerlo.

## Testbench de LTspice

`ltspice/cmirror_sim.asc` instancia en paralelo la versión de esquemático (`X1`) y
la extraída del layout (`U1`), las excita con fuentes de corriente controladas
(`G1`, `G2`, ganancia 1) manejadas por `V2`, y hace un barrido DC de 0 a 5 mV
en pasos de 0.1 mV, con `V1 = 5 V` de alimentación.

### Portabilidad: corregido

El testbench traía rutas absolutas al equipo del autor (`C:\Users\Lenovo\...`),
que rompían la simulación en cuanto otra persona clonara el repositorio. Ya
están sustituidas por rutas relativas:

```
.inc ../../../../pdk/tech/models/CM05_models.lib
.inc cmirror_lay.cir
```

Y todos los archivos de LTspice de la celda viven en una sola carpeta
(`ltspice/`), porque LTspice resuelve los símbolos jerárquicos relativos al
esquemático que los instancia y no se lleva bien con jerarquías de carpetas
profundas. Separar `schematic/` de `sim/` rompía el símbolo de `cmirror`.

### Limitación del testbench

Las salidas de X1 (esquemático) y U1 (layout) están conectadas al mismo nodo
`OUT`, que va a `V1 = 5 V`. Así que `I(V1)` es la suma de ambas corrientes y no
permite compararlas directamente. Se puede rescatar con las corrientes de
puerto de subcircuito (`Ix(x1:P2)`, `Ix(u1:P2)`), o simplemente usar el
testbench de ngspice, que ya mide la rama extraída por separado.

## Consideraciones de layout

**PENDIENTE.** No hay evidencia en los archivos de:

- Centroide común entre M1 y M2 — recomendable en un espejo, es el factor
  dominante del error de apareamiento.
- Dummies en los extremos del arreglo.
- Guard ring alrededor de la celda.

Con `W = 100 µm` y `L = 10 µm` los dispositivos son grandes, lo que ya ayuda al
apareamiento, pero la disposición relativa sigue importando.

## Limitaciones conocidas

- Simulado solo en un punto: `tt`, 27 °C. Faltan `ff` y `ss`, y variación de
  temperatura.
- Sin Monte Carlo, así que no hay estimación del error de apareamiento.
- Sin caracterización de resistencia de salida ni de tensión mínima de salida
  (`V_min_out`), que son las dos métricas que definen el rango útil del espejo.
- Sin objetivos numéricos declarados: no existe criterio de aceptación.
