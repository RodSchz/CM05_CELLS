# Definición de Regla de Ancho de Canal (W) para Familia X1

## 1. Regla Elegida

Tras evaluar el comportamiento eléctrico y las restricciones físicas del layout, se ha adoptado la **Opción B** como la regla estándar para el dimensionamiento de transistores en la biblioteca de celdas:

* **Unidad Base NMOS:** $W_n = 10 \, \mu m$
* **Unidad Base PMOS:** $W_p = 25 \, \mu m$
* **Compensación en serie:** El ancho se multiplica por la profundidad de la pila ($k$).
  * NMOS en serie: $W_n = 10 \cdot k$
  * PMOS en serie: $W_p = 25 \cdot k$

## 2. Justificación y Simulaciones

La decisión se tomó a partir de una caracterización transitoria simulada en LTspice con las siguientes condiciones:
* Tecnología y modelos: `CM05_models.lib`
* Alimentación: $V_{DD} = 5V$
* Carga: Fan-out de 1 (1 Inversor de carga a la salida).
* Tiempos medidos del 10% al 90% de $V_{DD}$.

### Resultados de la Simulación

| Celda Evaluada | $W_p$ simulado | $t_r$ (Subida) | $t_f$ (Bajada) | Observaciones de Balance |
|---|---|---|---|---|
| **Inverter** | 25 | 2.66 ns | 4.17 ns | **Mejor balance** ($t_r \approx t_f$). |
| **Inverter** | 50 | 2.47 ns | 7.18 ns | Muy desbalanceado ($t_f$ es el triple de $t_r$). |
| **NOR2X1** | 50 | 3.81 ns | 7.56 ns | **Mejor balance posible** para esta topología. |
| **NOR2X1** | 100 | 2.97 ns | 10.96 ns | Muy desbalanceado ($t_f$ es casi 4 veces mayor). |

### Restricciones Físicas (Layout)

Además del balance eléctrico, la regla elegida respeta los límites del GDS actual. La banda PMOS de difusión utilizable admite un ancho máximo de $\sim 65 \, \mu m$.

* Elegir la Opción C ($W_p = 50$ base) habría obligado a usar $W_p = 100$ en la NOR2, violando la regla física o exigiendo un plegado prematuro.
* Con la **Opción B**, la NOR2 queda en $W_p = 50 \, \mu m$, ajustándose perfectamente a la altura del riel sin necesidad de rediseño especial en dedos. (El plegado quedará reservado estrictamente para topologías de serie 3 como la NOR3, donde $25 \cdot 3 = 75 \, \mu m$).

## 3. Tabla de Anchos por Topología (Familia X1)

A partir de la regla establecida, los esquemáticos y layouts deben ajustarse a los siguientes valores:

| Celda Lógica | Condición NMOS | $W_n$ objetivo | Condición PMOS | $W_p$ objetivo |
|---|---|---|---|---|
| **Inverter** | 1 dispositivo | **10** | 1 dispositivo | **25** |
| **NAND2X1** | Serie de 2 ($k=2$) | **20** | Paralelo de 2 | **25** |
| **NAND3X1** | Serie de 3 ($k=3$) | **30** | Paralelo de 3 | **25** |
| **NOR2X1** | Paralelo de 2 | **10** | Serie de 2 ($k=2$) | **50** |
| **NOR3X1** | Paralelo de 3 | **10** | Serie de 3 ($k=3$) | **75*** |

*( \* ) El PMOS de la NOR3X1 supera los 65 µm de banda, por lo que requiere obligatoriamente dibujarse plegado en dedos en el layout.*