# Regla de dimensionamiento (ancho de canal) — familia X1

**Rev. 2, noviembre 2026.** Reemplaza la regla anterior (`W_p` base = 25 µm),
que se decidió con los modelos SPICE preliminares. Aquellos modelos daban una
razón de fuerza `KP_n/KP_p = 1.09`, físicamente imposible con un solo óxido de
compuerta, y por eso sus simulaciones mostraban `t_f > t_r` — justo al revés
de lo que hace el silicio.

## 1. La regla

- **Inversor de referencia:** `W_n = 10 µm`, `W_p = 50 µm` (razón 5), `L = 5 µm`.
- **NMOS en serie:** `W_n = 10·k`, con `k` = número de dispositivos en serie.
- **PMOS en serie:** **no** se multiplica por `k` a ciegas. Se sube hasta donde
  quepa en la banda de difusión (máximo ≈ 65 µm) y se acepta que la compuerta
  NOR es la lenta de la familia. La razón está en el punto 3.
- **Paralelo:** no se compensa; cada dispositivo lleva su ancho base.

| Celda | NMOS | `W_n` | PMOS | `W_p` |
|---|---|---|---|---|
| Inverter / Buffer | 1 | **10** | 1 | **50** |
| NAND2X1 | serie de 2 | **20** | paralelo | **50** |
| NAND3X1 | serie de 3 | **30** | paralelo | **50** |
| NOR2X1 | paralelo | **10** | serie de 2 | **50 – 65** |
| NOR3X1 | paralelo | **10** | serie de 3 | **65**, plegado si hace falta |

## 2. De dónde sale el inversor de referencia

Simulado con los modelos ajustados a TCAD (rev. preliminar 3), `V_DD = 5 V`,
`C_L = 100 fF`, `W_n = 10 µm`, barriendo `W_p`:

| `W_p` [µm] | `V_M` [V] | `t_r` [ns] | `t_f` [ns] | `t_r/t_f` |
|---|---|---|---|---|
| 25 | 1.755 | 2.611 | 0.740 | 3.53 |
| 40 | 1.888 | 1.894 | 0.773 | 2.45 |
| **50** | **1.953** | **1.668** | **0.789** | **2.11** |
| 65 | 2.030 | 1.448 | 0.814 | 1.78 |
| 80 | 2.091 | 1.332 | 0.841 | 1.58 |
| 100 | 2.156 | 1.238 | 0.868 | 1.43 |

Tres cosas fijan el valor en 50:

- **Coincide con el Manual de referencia CIDESI_CM05 v1**, que da como inversor
  de referencia `W_n = 10 / W_p = 50` con `V_M = 1.95 V` y márgenes de ruido de
  1.36 V (bajo) y 2.49 V (alto). La simulación de arriba da `V_M = 1.953 V`,
  así que las dos fuentes coinciden de forma independiente.
- **Rendimientos decrecientes.** De 25 a 50 el tiempo de subida mejora 36 %; de
  50 a 100 mejora otro 26 % a cambio de duplicar el ancho, y el de bajada
  empeora porque el drenaje del PMOS carga la salida.
- **`t_r = t_f` no está al alcance ni hace falta.** Extrapolando haría falta
  `W_p ≈ 150 µm`, y el manual señala que `V_M = 2.5 V` pediría `W_p ≈ 370 µm`,
  "que no es necesario para lógica". Un inversor con el flanco de subida al
  doble del de bajada es perfectamente utilizable a 5 V.

## 3. Por qué el PMOS en serie no se multiplica por k

La regla clásica `W_p = 50·k` sale de igualar la resistencia de encendido de la
pila. Es correcta a primer orden, pero ignora que el dispositivo más ancho
también carga más la salida con su propio drenaje. A 5 µm, con dispositivos de
decenas de micras, ese término ya no es despreciable.

Medido sobre NOR2 (`W_n = 10`, `C_L = 100 fF`, conmuta A con B en 0):

| `W_p` de cada PMOS | `t_r` [ns] | `t_f` [ns] | `t_r/t_f` |
|---|---|---|---|
| 50 | 3.981 | 1.390 | 2.86 |
| 65 | 3.630 | 1.576 | 2.30 |
| 100 | 3.355 | 2.001 | 1.68 |

Pasar de 50 a 100 —que es lo que pediría la regla `×k`— mejora la subida solo
**16 %** y empeora la bajada **44 %**. No vale la pena, y además 100 µm no cabe
en la banda de difusión PMOS, que admite ≈ 65 µm.

**Consecuencia de diseño:** la NOR es la compuerta lenta de la familia. Su
flanco de subida es ~2.4 veces el de un inversor del mismo `W_p`, y eso no se
arregla ensanchando. Donde importe la velocidad, **preferir lógica basada en
NAND** (la serie va del lado NMOS, que es el fuerte) y dejar la NOR para donde
la función la pida.

## 4. Restricción física

La banda de difusión PMOS utilizable, con la altura de fila de 222.5 µm del
contrato rev. 2, admite un ancho máximo de ≈ **65 µm**; el lado NMOS tiene más
holgura. Un `W_p` mayor obliga a plegar el transistor en dedos paralelos, que
es trabajo de layout a mano y hay que justificarlo celda por celda.

## 5. Estado de la biblioteca frente a la regla

| Celda | `W_n` / `W_p` actuales | Según la regla | Diferencia |
|---|---|---|---|
| Inverter | 10 / 25 | 10 / 50 | PMOS a la mitad |
| Buffer, Buffer3S, Buffer_4X, Buffer_8X | 10 / 25 | 10 / 50 | PMOS a la mitad |
| FFD, Latch, Inverter3S | 10 / 25 | 10 / 50 | PMOS a la mitad |
| NAND2X1 | 15 / 50 | 20 / 50 | NMOS 25 % corto |
| NAND3X1 | 30 / 50 | 30 / 50 | **cumple** |
| NOR2X1 | 10 / 50 | 10 / 50–65 | **cumple** |
| AND2X1 | 15 / 50 | 20 / 50 | NMOS 25 % corto |
| OR2X1 | 10 / 50 | 10 / 50 | **cumple** |
| XOR2X1 | 10, 15 / 50 | revisar por rama | — |
| XNOR2X1 | 10, 20 / 50 | revisar por rama | — |

**Esto no es una emergencia.** Las 11 celdas combinacionales **pasan hoy** los
testbenches de niveles lógicos con `VIL = 1.2` y `VIH = 3.3`, incluso las que
llevan el PMOS a la mitad:

| Celda | función | VOH [V] | VOL [V] | NMH [V] | NML [V] |
|---|---|---|---|---|---|
| Inverter | INVERTER | 4.763 | 0.061 | 1.463 | 1.139 |
| Buffer | BUFFER | 4.905 | 0.040 | 1.605 | 1.160 |
| Buffer_4X | BUFFER | 4.977 | 0.010 | 1.677 | 1.190 |
| Buffer_8X | BUFFER | 4.988 | 0.005 | 1.688 | 1.195 |
| NAND2X1 | NAND | 4.869 | 0.084 | 1.569 | 1.116 |
| NOR2X1 | NOR | 4.643 | 0.054 | 1.343 | 1.146 |
| AND2X1 | AND | 4.949 | 0.028 | 1.649 | 1.172 |
| OR2X1 | OR | 4.949 | 0.041 | 1.649 | 1.159 |
| XOR2X1 | XOR | 4.774 | 0.084 | 1.474 | 1.116 |
| XNOR2X1 | XNOR | 4.680 | 0.095 | 1.380 | 1.105 |
| NAND3X1 | NAND3 | 4.828 | 0.068 | 1.528 | 1.132 |

El dimensionamiento no es lo que decide si una celda pasa el criterio DC: eso
lo decide la relación entre los umbrales y los niveles de entrada. Lo que el
ancho gobierna es **el umbral de conmutación y la simetría de los flancos**.

Por eso el `W_p` de 25 µm de la familia de inversores no la invalida, pero sí
la deja con `V_M = 1.755 V` en vez de 1.953 y con la subida 3.5 veces más
lenta que la bajada. Subirla a 50 es una mejora de margen y de velocidad, no
una corrección de un defecto, y se puede hacer celda por celda.

## 6. Registro: por qué cambió la regla

La rev. 1 eligió `W_p` base = 25 µm con esta tabla, simulada en LTspice con los
modelos preliminares:

| Celda | `W_p` | `t_r` | `t_f` | Conclusión de entonces |
|---|---|---|---|---|
| Inverter | 25 | 2.66 ns | 4.17 ns | "mejor balance" |
| Inverter | 50 | 2.47 ns | 7.18 ns | "muy desbalanceado" |
| NOR2X1 | 50 | 3.81 ns | 7.56 ns | "mejor balance posible" |
| NOR2X1 | 100 | 2.97 ns | 10.96 ns | "muy desbalanceado" |

Nótese que en esa tabla **el flanco de bajada es el lento**, y empeora al
ensanchar el PMOS. Eso solo puede pasar si el PMOS es comparable o más fuerte
que el NMOS, que es exactamente lo que decían los modelos de entonces:
`TOX = 50.2 nm` en el NMOS contra `25 nm` en el PMOS, con un solo óxido de
compuerta real. Con los modelos de TCAD, que comparten `TOX = 29.4 nm`, el
PMOS resulta unas **8 veces más débil por micra** y el orden se invierte.

El detalle del diagnóstico está en el documento de auditoría de modelos del
proyecto.
