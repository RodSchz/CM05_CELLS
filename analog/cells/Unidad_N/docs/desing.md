# Documentación de Diseño: `unidad_n`

Este documento consolida las decisiones de diseño, la justificación de las dimensiones geométricas ($W$ y $L$), los criterios de layout manual y los resultados de caracterización eléctrica para la celda unitaria activa unidad_n (NMOS) en el proceso CIDESI CM05 (esquina TT, sin simulación Monte Carlo).

### 1. Justificación del Dimensionamiento Geométrico ($W/L$)

La celda unidad_n está concebida como un bloque unitario estándar e indivisible para instanciarse $N$ veces en arreglos acoplados (espejos de corriente y pares diferenciales), garantizando un error de escalabilidad del $0.0\%$.

¿Por qué se eligió $L = 10\,\mu\text{m}$?
1.  Mitigación de la modulación de longitud de canal ($\lambda$):
 Aunque el proceso permite una longitud mínima de $L_{min} = 4\,\mu\text{m}$, se fijó $L = 10\,\mu\text{m}$ ($2.5\times$ la mínima) para elevar sustancialmente el voltaje de Early ($V_A$). Esto aplana la pendiente de $I_D \text{ vs } V_{DS}$ en la región de saturación, entregando una resistencia de salida $r_{out} \approx 431.86\,\text{k}\Omega$ que estabiliza la corriente ante variaciones de voltaje en los nodos.

2.  Reducción del despareamiento estocástico (Matching por Pelgrom)     :Según la ley de Pelgrom, la varianza del voltaje de umbral es inversamente proporcional a la raíz cuadrada del área del canal ($\sigma_{\Delta Vth} \propto \frac{1}{\sqrt{W \cdot L}}$). Un canal amplio minimiza las desviaciones de fabricación entre dispositivos vecinos dentro del chip.

 ¿Por qué se eligió W = 100 µm?
1. Punto de operación analógico cómodo:
Proporciona un nivel de corriente de saturación nominal de $+1.455\,\text{mA}$ a $5\,\text{V}$, evitando operar en regiones de sub-microamperios vulnerables al ruido térmico.

2. Relación de aspecto idónea (W/L = 10):
Ofrece un excelente compromiso entre transconductancia (g_m), ganancia intrínseca y área de silicio.

### 2. Decisiones de Layout y Trazado Físico
-Trazado manual desde cero: El layout de unidad_n se realizó totalmente a mano desde cero (sin uso de PCells o generadores automáticos) para mantener un control estricto sobre las dimensiones de difusiones, contactos y reducción de parasitarios.

-Rieles comunes (COM): Las líneas de referencia de la celda y la polarización del sustrato están conectadas a un nodo/riel común denominado COM.

-Orientación espacial única: Si la celda se instancia en un arreglo, debe conservar exactamente la misma alineación geográfica (sin rotaciones de $90^\circ$ ni espejeado) para evitar asimetrías por el grabado químico e implantación iónica.

-Estructuras Dummy y Anillos de Guarda:

-Dummies:Transistores laterales de borde con compuertas y difusiones atadas a COM para proteger la celda de variaciones litográficas.

-Anillos de guarda (BulkTap):Contactos de sustrato $p^+$ conectados continuamente a COM para fijar el potencial, aislar ruido y prevenir latch-up.

### 3. Matriz Consolidada de Caracterización Eléctrica

| Parámetro / Métrica | unidad_n (NMOS) | Justificación / Método de Medición |
| :--- | :---: | :--- |
| **Geometría (W / L)** | 100 µm / 10 µm | Trazado manual desde cero (W/L = 10) para alto r_out y bajo mismatch. |
| **Referencia de Riel** | COM | Rieles y polarización conectados a nodo común COM. |
| **Voltaje de Umbral (V_th)** | +0.730 V | Extracción DC mediante simulación (I_D vs V_GS). |
| **Corriente de Saturación (I_D,sat)** | +1.455 mA | Medido en el punto V_GS = V_DS = 5 V. |
| **Impedancia de Salida (r_out)** | ~431.86 kΩ | Inverso de la pendiente en la región plana de saturación. |
| **Tensión de Saturación (V_DS,sat)** | ≥ 4.270 V | Punto de transición donde V_DS ≥ V_GS - V_th. |
| **Error PEX vs. Esquemático** | 0.0% | Coincidencia total entre trazado extraído y esquemático. |
| **Error de Escalabilidad (N=2)** | 0.0% (2.910 mA) | Cumple holgadamente el criterio de aceptación (< 1.0%). |