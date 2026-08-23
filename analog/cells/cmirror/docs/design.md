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

## Testbench

`sim/cmirror_sim.asc` instancia en paralelo la versión de esquemático (`X1`) y
la extraída del layout (`U1`), las excita con fuentes de corriente controladas
(`G1`, `G2`, ganancia 1) manejadas por `V2`, y hace un barrido DC de 0 a 5 mV
en pasos de 0.1 mV, con `V1 = 5 V` de alimentación.

### Problema de portabilidad

El testbench incluye rutas absolutas del equipo del autor:

```
.inc C:\Users\Lenovo\KLayout\salt\CIDESI_CM05\tech\CIDESI_CM05\models\CM05_models.lib
.inc C:\Users\Lenovo\OneDrive\Documentos\Espejo_corriente\cmirror_lay.cir
```

En cuanto otro diseñador clone el repositorio, la simulación falla. Hay que
sustituirlas por rutas relativas y traer los modelos a `pdk/tech/models/`:

```
.inc ../../../../pdk/tech/models/CM05_models.lib
.inc cmirror_lay.cir
```

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
