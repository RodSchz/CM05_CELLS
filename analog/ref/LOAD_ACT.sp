* =====================================================================
* LOAD_ACT.sp - Netlist de REFERENCIA (diseno de contrato)
* Proceso: CIDESI_CM05    Cargas activas n y p (una unidad en diodo)
*
* UNA UNIDAD conectada en diodo (compuerta unida al drenaje), mas
* dummies. Es el bloque mas simple del catalogo y buena primera celda.
*
* PUNTO DE OPERACION: I = 10 uA, VDD = 5 V, T = 27 C
*
* HOJA DE DATOS OBJETIVO (ngspice, CM05_models.lib rev. preliminar 3)
*
*   LOAD_ACT_N (Unidad_N, 100/10)
*     caida de tension     = 1.106 V
*     R equivalente (1/gm) = 8.11 kohm
*
*   LOAD_ACT_P (Unidad_P, 640/10 en 8 dedos)
*     caida de tension     = 1.934 V
*     R equivalente (1/gm) = 8.53 kohm
*
*   Las dos R equivalentes quedan apareadas al 5 %. Eso NO pasaba con el
*   Unidad_P anterior de 100/10, que daba 21.8 kohm: es el beneficio
*   directo de haber apareado el par unitario, y conviene que la hoja de
*   datos lo diga.
*
* QUE ES "R EQUIVALENTE"
*   Es la resistencia incremental dV/dI alrededor de 10 uA, medida con un
*   barrido de la fuente de corriente de 8 a 12 uA, no 1/gm calculado
*   aparte. Coincide con 1/gm porque el dispositivo esta en diodo, pero
*   la medicion es la que va en la hoja de datos.
*
* CUIDADO AL USARLA
*   Una carga activa NO es un resistor de 8 kohm: su resistencia cambia
*   con la corriente (va como 1/sqrt(I) en inversion fuerte). A 1 uA la
*   N sube a ~25 kohm. La hoja de datos debe declarar la corriente.
*
* LAYOUT
*   Un dispositivo unitario, misma orientacion, dummies y anillo de
*   guarda. No hay par apareado, asi que no aplica centroide comun; lo
*   que si aplica es que la geometria sea EXACTAMENTE la del unitario,
*   porque el valor depende de ella.
* =====================================================================
.SUBCKT LOAD_ACT_N A GND
M1 A A GND GND CIDNMOS L=10u W=100u
MD1 GND GND GND GND CIDNMOS L=10u W=100u
MD2 GND GND GND GND CIDNMOS L=10u W=100u
.ENDS LOAD_ACT_N

.SUBCKT LOAD_ACT_P A VDD
* 8 dedos de 80 um = un dispositivo de W = 640 um
MP1 A A VDD VDD CIDPMOS L=10u W=80u
MP2 A A VDD VDD CIDPMOS L=10u W=80u
MP3 A A VDD VDD CIDPMOS L=10u W=80u
MP4 A A VDD VDD CIDPMOS L=10u W=80u
MP5 A A VDD VDD CIDPMOS L=10u W=80u
MP6 A A VDD VDD CIDPMOS L=10u W=80u
MP7 A A VDD VDD CIDPMOS L=10u W=80u
MP8 A A VDD VDD CIDPMOS L=10u W=80u
MD1 VDD VDD VDD VDD CIDPMOS L=10u W=80u
MD2 VDD VDD VDD VDD CIDPMOS L=10u W=80u
.ENDS LOAD_ACT_P
