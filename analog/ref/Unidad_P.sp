* =====================================================================
* Unidad_P.sp - Netlist de REFERENCIA (diseno de contrato)
* Proceso: CIDESI_CM05        Dispositivo unitario tipo p
* Solicitado en el issue de base analogica (Linea B, Entregable 1)
*
* ESTE ARCHIVO ES EL CONTRATO DEL LVS. La geometria no se negocia en el
* pull request: W = 640 um, L = 10 um, mas dos dedos dummy.
*
* POR QUE 640 um
*   La version actual de Unidad_P es 100/10, la misma geometria que
*   Unidad_N. A 10 uA eso da gm = 45.8 uS contra 124.8 uS del NMOS (2.7
*   veces menos) y V_DSsat = 0.418 V contra 0.152 V. Con el PMOS de CM05
*   ~8 veces mas debil por micra, igualar al NMOS pide ancho.
*
* PUNTO DE OPERACION DE LA BIBLIOTECA
*   I = 10 uA   VDD = 5 V   T = 27 C   Vout de referencia = 2.5 V
*
* HOJA DE DATOS OBJETIVO (ngspice, CM05_models.lib rev. preliminar 3)
*   |VGS|    = 1.934 V     (1.938 V en la forma de un solo dispositivo; los
*                           4 mV salen de los terminos por dispositivo de
*                           LEVEL 3 y no son fisicos)
*   V_DSsat  = 0.157 V     (Unidad_N: 0.152 V  -> apareados a 5 mV)
*   gm       = 118.3 uS    (Unidad_N: 124.8 uS -> apareados al 5 %)
*   r_o      =  84.1 Mohm  a Vout = 2.5 V
*   gm * r_o =  9951
*   C_gs     = 4990 fF
*   area del dispositivo activo = 6400 um2
*
* PLEGADO
*   640 um no se dibuja de un trazo: van 8 dedos de 80 um compartiendo
*   islas de drenaje y fuente, con la compuerta en comun. Los 8 dedos son
*   UN dispositivo de W = 640 um. Si la extraccion de KLayout reporta 8
*   dispositivos de W = 80 um en paralelo es equivalente y tambien se
*   acepta, pero hay que declararlo en el cell.yaml. Cualquier otra cosa
*   (anchos distintos entre dedos, dedos en serie, un dedo suelto)
*   significa que el plegado esta mal conectado.
*
* DUMMIES
*   Dos dedos dummy de 80/10, uno en cada extremo del arreglo, con
*   compuerta y difusiones atadas a COM para que queden apagados. No son
*   dos dispositivos de 640: el dummy protege al dedo de borde, no al
*   dispositivo completo. Con ellos la celda ocupa 10 dedos = 8000 um2.
*
* ORDEN DE PUERTOS
*   G D COM, el mismo que ya usa Unidad_N. No cambiarlo.
* =====================================================================
.SUBCKT Unidad_P G D COM
* --- dispositivo activo: 8 dedos de 80 um = W total de 640 um
MP1 D G COM COM CIDPMOS L=10u W=80u
MP2 D G COM COM CIDPMOS L=10u W=80u
MP3 D G COM COM CIDPMOS L=10u W=80u
MP4 D G COM COM CIDPMOS L=10u W=80u
MP5 D G COM COM CIDPMOS L=10u W=80u
MP6 D G COM COM CIDPMOS L=10u W=80u
MP7 D G COM COM CIDPMOS L=10u W=80u
MP8 D G COM COM CIDPMOS L=10u W=80u
* --- dedos dummy, apagados, uno en cada extremo del arreglo
MD1 COM COM COM COM CIDPMOS L=10u W=80u
MD2 COM COM COM COM CIDPMOS L=10u W=80u
.ENDS Unidad_P

* ---------------------------------------------------------------------
* Forma equivalente, si el extractor fusiona los dedos en un dispositivo:
*
*   .SUBCKT Unidad_P G D COM
*   MP1 D   G   COM COM CIDPMOS L=10u W=640u
*   MD1 COM COM COM COM CIDPMOS L=10u W=80u
*   MD2 COM COM COM COM CIDPMOS L=10u W=80u
*   .ENDS Unidad_P
*
* Las dos formas dan el mismo punto de operacion. La de arriba es la que
* corresponde a la geometria dibujada.
* ---------------------------------------------------------------------
