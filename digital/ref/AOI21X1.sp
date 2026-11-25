* =====================================================================
* AOI21X1.sp - Netlist de REFERENCIA (diseno de contrato)
* Proceso: CIDESI_CM05        Funcion: Out = NOT(A*B + C)
* Solicitado en el issue #40 (Linea A, Entregable 1)
*
* ESTE ARCHIVO ES EL CONTRATO DEL LVS. El layout que se entregue debe
* empatar contra el: mismo numero de dispositivos, mismos W y L, misma
* conectividad y los puertos en este orden. No se cambian los anchos.
*
* Dimensionamiento: docs/regla_de_dimensionamiento.md rev. 2
*   W_n = 10 um x (numero de NMOS en serie)
*   W_p = 50 um base; 65 um si hay PMOS en serie (tope de la banda p)
*   L   = 5 um en todos los dispositivos
*
* Verificado en ngspice con pdk/tech/models/CM05_models.lib
* (rev. preliminar 3, ajustada a TCAD), VDD = 5 V, VIL = 1.2 V,
* VIH = 3.3 V, carga de 20 uA, criterio VOH >= 4.44 V y VOL <= 0.5 V.
* Peor caso de la tabla de verdad completa:
*   VOH = 4.670 V   VOL = 0.0572 V   NMH = 1.370 V   NML = 1.143 V
*
* Testbench: scripts/verify/digital/tabla_verdad_3in.sp
*   compose esperado values 1 0 1 0 1 0 0 0
* =====================================================================
.SUBCKT AOI21X1 A B C Out VDD GND
MP1 p1 A VDD VDD CIDPMOS L=5u W=65u
MP2 p1 B VDD VDD CIDPMOS L=5u W=65u
MP3 Out C p1 VDD CIDPMOS L=5u W=65u
MN1 Out A n1 GND CIDNMOS L=5u W=20u
MN2 n1 B GND GND CIDNMOS L=5u W=20u
MN3 Out C GND GND CIDNMOS L=5u W=10u
.ENDS AOI21X1
