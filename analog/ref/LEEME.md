# Netlists de referencia — bloques analógicos

Mismo patrón que `digital/ref/`: aquí viven los **netlists de contrato** de los
bloques analógicos pedidos por un issue abierto.

## Qué son

CIDESI aporta el diseño eléctrico y el punto de operación; lo que se solicita en
el issue es el **diseño físico**. El LVS del layout entregado tiene que empatar
contra el netlist de aquí, y la hoja de datos tiene que reproducir los valores
de su cabecera.

La diferencia con el caso digital: en analógico el contrato no es solo la
topología, es **la geometría y el punto de operación**. Un espejo con la
topología correcta y el ancho equivocado no sirve, porque todo el catálogo se
construye multiplicando el dispositivo unitario.

Los anchos no se negocian en el PR. Si crees que una geometría está mal, dilo en
el issue antes de dibujar.

## Punto de operación de la biblioteca

Todo el catálogo analógico se diseña y se caracteriza aquí:

| Parámetro | Valor |
|---|---|
| Corriente del dispositivo unitario | **10 µA** |
| Tensión de alimentación | **5 V** |
| Temperatura | **27 °C** (único punto; el PDK no tiene esquinas) |
| Tensión de salida de referencia | **2.5 V** |
| Geometría de los bloques | celdas independientes, sin altura común |

## El par unitario

| | W/L | `V_DSsat` | `gm` | `r_o` | Estado |
|---|---|---|---|---|---|
| `Unidad_N` | 100/10 | 0.152 V | 124.8 µS | 2.5 MΩ | existe, geometría correcta |
| `Unidad_P` | **640/10** | 0.157 V | 118.3 µS | 84.1 MΩ | **a redibujar** (hoy 100/10) |

Están apareados a propósito: `V_DSsat` a 5 mV y `gm` al 5 %. Es lo que permite
construir bloques n-p simétricos sin compensar con relaciones de espejeo.

`Unidad_P` necesita 6.4 veces el ancho del `Unidad_N` para el mismo `gm` porque
el PMOS de CM05 es ~8 veces más débil por micra: 5.2× por movilidad y el resto
por penalización de umbral, con un solo óxido de compuerta.

## Ciclo de vida

Un netlist sale de esta carpeta cuando el bloque está entregado y verificado: el
netlist extraído queda en `analog/cells/<BLOQUE>/layout/<BLOQUE>.cir` y este
archivo se borra. Si sigue aquí, el bloque está pendiente.

`Unidad_N.sp` es el caso especial: la celda ya existe y su geometría no cambia.
El archivo está aquí solo para fijar su hoja de datos en el punto de operación
correcto, y se borra cuando esa hoja de datos esté en su `cell.yaml`.

## Contenido actual

| Archivo | Bloque | Qué se pide |
|---|---|---|
| `Unidad_N.sp` | Dispositivo unitario n | Solo re-caracterizar y corregir documentación |
| `Unidad_P.sp` | Dispositivo unitario p | Redibujar a 640/10, plegada en 8 dedos de 80 µm |

## Cómo simularlos

No son testbenches: son subcircuitos. Se instancian desde un testbench propio en
`analog/cells/<BLOQUE>/ngspice/`. El procedimiento está en `docs/guia-celdas.md`
sección 5.

Definición de `V_min` que usa toda la biblioteca: la tensión de salida donde la
corriente se desvía **1 % de la recta ajustada a la región de saturación**
(ajuste de 2 a 4.5 V para bloques n). No se usa "el 99 % del valor a 2.5 V":
con modulación de longitud de canal eso mide la pendiente en vez de la rodilla,
y da números que no significan nada.

## Documentos relacionados

- `docs/guia-celdas.md` sección 5 — ruta de una celda analógica
- `analog/cells/cmirror/cell.yaml` — el `cell.yaml` más completo del repo
- `analog/_template/` — plantilla de metadatos y de notas de diseño
- `pdk/tech/models/LEEME.md` — modelos y sus limitaciones
- `digital/ref/LEEME.md` — el mismo patrón, lado digital
