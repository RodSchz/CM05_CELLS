* =====================================================================
* Unidad_N.sp - Netlist de REFERENCIA (diseno de contrato)
* Proceso: CIDESI_CM05        Dispositivo unitario tipo n
* Solicitado en el issue de base analogica (Linea B, Entregable 1)
*
* LA GEOMETRIA NO CAMBIA. La celda ya existe en
* analog/cells/Unidad_N/ y es correcta: W = 100 um, L = 10 um, un
* dispositivo activo y dos dummies. Este archivo existe para fijar su
* HOJA DE DATOS en el punto de operacion de la biblioteca, que es lo que
* faltaba: la caracterizacion anterior se hizo en V_GS = V_DS = 5 V
* (1.455 mA, 145 veces la polarizacion acordada) y con una revision de
* modelos ya reemplazada.
*
* PUNTO DE OPERACION DE LA BIBLIOTECA
*   I = 10 uA   VDD = 5 V   T = 27 C   Vout de referencia = 2.5 V
*
* HOJA DE DATOS OBJETIVO (ngspice, CM05_models.lib rev. preliminar 3)
*   |VGS|    =   1.106 V
*   V_DSsat  =   0.152 V     (Unidad_P: 0.157 V -> apareados a 5 mV)
*   gm       = 124.8 uS      (Unidad_P: 118.3 uS -> apareados al 5 %)
*   r_o      =   2.5 Mohm    a Vout = 2.5 V
*   gm * r_o =   313
*   C_gs     = 778 fF
*   area del dispositivo activo = 1000 um2
*
* POR QUE L = 10 um Y NO 5
*   Un NMOS a L = 5 um NO PUEDE ESPEJEAR: +19.6 % de error a
*   Vout = 2.5 V con r_o = 0.6 Mohm. Con el sustrato a 1.6e15 la zona de
*   agotamiento del drenaje se come ~1.4 um de un canal de 5 um. El PMOS
*   no sufre lo mismo porque su cuerpo es el pozo n a 1.25e17, 80 veces
*   mas dopado: ahi L = 5 um espejea con +0.2 %.
*   La eleccion de L = 10 um que ya trae la celda es correcta; lo que hay
*   que corregir es la cifra de L_min del documento de diseno, que dice
*   4 um cuando el DRC la fija en 5 um (R3_1 = 2*lambda).
*
* ORDEN DE PUERTOS
*   G D COM, tal como lo extrae KLayout hoy. No cambiarlo: Unidad_P usa
*   el mismo.
* =====================================================================
.SUBCKT Unidad_N G D COM
* --- dispositivo activo
MN1 D G COM COM CIDNMOS L=10u W=100u
* --- dummies, apagados, uno a cada lado
MD1 COM COM COM COM CIDNMOS L=10u W=100u
MD2 COM COM COM COM CIDNMOS L=10u W=100u
.ENDS Unidad_N
