# Verificación post-layout con ngspice

Esta carpeta **no** es una traducción del testbench de LTspice. Verifica algo
distinto.

| | `ltspice/` | `ngspice/` |
|---|---|---|
| Entrada | El esquemático que dibujó el diseñador | El netlist que KLayout **extrajo del layout** |
| Qué mide | El circuito ideal, pre-layout | El circuito real, tal como quedó dibujado |
| Entorno | Windows, con interfaz gráfica | Línea de comandos: WSL, Linux o el CI |
| Quién lo usa | Todos los diseñadores | Verificación y proyectos avanzados |

Por eso no pueden desincronizarse entre sí: el testbench de ngspice **no lee el
`.asc` para nada**. Si alguien cambia el esquemático y no el layout, la
diferencia entre ambos resultados es justamente lo que hay que notar.

## Cómo correrlo

```bash
./run.sh
```

O directamente:

```bash
ngspice -b cmirror_tb.spice
```

Requiere `ngspice` en el PATH. En Ubuntu o WSL:

```bash
sudo apt install ngspice
```

Los resultados quedan en `../results/`:

- `cmirror_ngspice.log` — reporte completo
- `cmirror_vout_sweep.csv` — barrido de la característica de salida, para graficar

## Qué mide

**1. Relación del espejo** — barrido de la corriente de referencia de 1 µA a
200 µA, midiendo `I_out / I_ref` en cuatro puntos.

**2. Resistencia de salida y tensión mínima de salida** — barrido de la tensión
de salida de 0 a 5 V con `I_ref = 100 µA`. `r_out` sale de la pendiente en la
región de saturación; `v_min` es la tensión a la que la corriente de salida
alcanza el 99.5 % de su valor nominal, o sea el límite inferior del rango útil.

## Resultados de referencia

Corridos sobre `layout/cmirror.cir`, corner `tt`, 27 °C:

| Medición | Valor |
|---|---|
| Relación @ 10 µA | 1.0101 |
| Relación @ 50 µA | 1.0032 |
| Relación @ 100 µA | 1.0016 |
| Relación @ 190 µA | 1.0006 |
| V_GS @ 100 µA | 1.6685 V |
| I_out @ V_out = 4 V | 100.45 µA |
| r_out @ V_out = 4 V | 5.12 MΩ |
| V_min de salida | 0.836 V |

### Cómo leer la relación

Está por encima de 1 y **baja conforme sube la corriente**. No es un error de
dibujo: es modulación de longitud de canal.

M1 está en conexión de diodo, así que su drenaje se queda en V_GS = 1.67 V.
M2 tiene el drenaje en 2.5 V. Esa diferencia de V_DS hace que M2 conduzca un
poco más que M1. El efecto es proporcionalmente mayor a corriente baja, que es
justo lo que muestran los números.

Si quisieras reducirlo, el camino conocido es un espejo cascodo — a costa de
subir `V_min` de salida, que hoy es 0.836 V.

## Limitaciones

- **Un solo corner.** `CM05_models.lib` solo define el caso típico. Sin `ff` ni
  `ss` no hay análisis de esquinas, y por eso esta celda no puede pasar de
  `drc_clean` a `verified`.
- **Sin Monte Carlo.** Los modelos no traen dispersión de parámetros, así que no
  hay estimación del error de apareamiento entre M1 y M2 — que en un espejo de
  corriente suele dominar sobre todo lo demás.
- **Sin parásitos.** Se usa el netlist de LVS, no el de PEX. Extraer con
  `PEX.lylvs` daría capacitancias y resistencias del dibujo. Con W = 100 µm en
  un proceso de 5 µm, no son despreciables.
- **Un solo punto de temperatura**, 27 °C.

Las cuatro son limitaciones del PDK o del alcance, no del banco de pruebas.
