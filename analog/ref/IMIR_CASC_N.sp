* =====================================================================
* IMIR_CASC_N.sp - Netlist de REFERENCIA (diseno de contrato)
* Proceso: CIDESI_CM05    Espejo de corriente cascodo n, relacion 1:1
*
* CUATRO UNIDADES de Unidad_N (100/10 um), mas dummies.
*
* PARA QUE SIRVE
*   El espejo simple (cmirror) tiene r_o = 2.50 Mohm, y a 10 uA eso se
*   traduce en +5.42 % de error a Vout = 2.5 V: la rama de referencia
*   tiene su drenaje en 1.106 V y la de salida en 2.5 V, y esos 1.394 V
*   de diferencia sobre 2.50 Mohm dan 0.56 uA. Este bloque es la
*   correccion de ese error, que es el error dominante del catalogo.
*
* PUNTO DE OPERACION: Iin = 10 uA, VDD = 5 V, T = 27 C, Vcas = 1.6 V
*
* HOJA DE DATOS OBJETIVO (ngspice, CM05_models.lib rev. preliminar 3)
*   Iout a Vout = 2.5 V : 10.002 uA   (+0.02 %)
*   r_o                 :    913 Mohm (ajuste lineal de 2 a 4.5 V)
*   r_o a Vout = 1.0 V  :    913 Mohm (plano desde 1 V, ver abajo)
*   V_min               :  0.215 V    (desviacion del 1 % de la recta)
*
*   Contra el espejo simple: 365 veces mas r_o por 80 mV de V_min.
*   Esa es la "penalizacion de tension minima" que pide documentar la
*   propuesta de estancia, y resulta ser mucho menor de lo que la regla
*   de bolsillo (2 x V_DSsat = 0.30 V) haria esperar.
*
* VCAS NO ES LIBRE
*   Vcas fija la tension del nodo interno: V(n1) = Vcas - 1.106 V. El
*   dispositivo de abajo necesita V_DS >= V_DSsat = 0.152 V.
*
*     Vcas = 1.4 V -> V(n1) = 0.294 V, margen 142 mV, V_min = 0.190 V
*     Vcas = 1.6 V -> V(n1) = 0.494 V, margen 342 mV, V_min = 0.215 V  <-- usar
*     Vcas = 2.0 V -> r_o a Vout = 1.0 V cae a 33 Mohm
*     Vcas = 2.2 V -> r_o a Vout = 1.0 V cae a 3.8 Mohm
*
*   Se usa 1.6 V: conserva la r_o plana hasta Vout = 1.0 V y deja 342 mV
*   de margen de umbral. Con 1.4 V el V_min es 25 mV mejor, pero un
*   corrimiento de VTO de +150 mV degradaria el cascodo, y el PDK no
*   tiene esquinas para comprobarlo.
*
*   Subir Vcas por encima de 2 V mete el dispositivo de abajo hacia
*   triodo y el cascodo deja de funcionar a Vout bajo, aunque la
*   corriente a 2.5 V siga pareciendo correcta. Es el modo de falla que
*   hay que vigilar: mide r_o a Vout = 1.0 V, no solo a 2.5 V.
*
* LAYOUT
*   Los cuatro dispositivos en centroide comun, misma orientacion,
*   dummies en los extremos y anillo de guarda continuo, igual que
*   Unidad_N. El par de abajo (M1, M2) y el par de cascodo (M3, M4) son
*   dos conjuntos apareados distintos: cada uno necesita su centroide.
*
* ADVERTENCIA SOBRE LA r_o
*   913 Mohm es lo que da el modelo. Por encima de ~1 Gohm ningun valor
*   es creible sin medicion: la fuga de union y el DIBL no estan
*   modelados. Reportalo como "limitado por el modelo".
* =====================================================================
.SUBCKT IMIR_CASC_N Iin Iout Vcas GND
* --- par de abajo
M1 n1   Iin  GND GND CIDNMOS L=10u W=100u
M2 n2   Iin  GND GND CIDNMOS L=10u W=100u
* --- par de cascodo
M3 Iin  Vcas n1  GND CIDNMOS L=10u W=100u
M4 Iout Vcas n2  GND CIDNMOS L=10u W=100u
* --- dummies, apagados
MD1 GND GND GND GND CIDNMOS L=10u W=100u
MD2 GND GND GND GND CIDNMOS L=10u W=100u
.ENDS IMIR_CASC_N
