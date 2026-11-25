* =====================================================================
* DIFFPAIR_N.sp - Netlist de REFERENCIA (diseno de contrato)
* Proceso: CIDESI_CM05    Par diferencial n con fuente de cola
*
* CINCO UNIDADES de Unidad_N (100/10 um), mas dummies:
*   M1, M2  el par de entrada                         (10 uA cada uno)
*   M3      diodo de referencia de la cola            (Iref = 10 uA)
*   M4, M5  la cola, dos unidades espejeadas de M3    (20 uA)
*
* La cola es un espejo 1:2 por multiplicacion, no un dispositivo del
* doble de ancho. Es el mismo criterio de todo el catalogo.
*
* PUNTO DE OPERACION
*   Iref = 10 uA   VDD = 5 V   T = 27 C
*   Salidas polarizadas a 2.5 V (el rango de modo comun depende de esto)
*
* HOJA DE DATOS OBJETIVO (ngspice, CM05_models.lib rev. preliminar 3)
*   corriente de cola            = 19.78 uA (9.89 uA por rama)
*     Nominal son 2 x 10 uA. Los 0.22 uA que faltan son el mismo efecto
*     de V_DS del espejo simple: el diodo de referencia tiene su drenaje
*     en 1.106 V y el nodo de cola queda mas abajo, asi que la cola
*     conduce un poco menos que la referencia. No es un error de diseno.
*   gm diferencial a VCM = 2.0 V = 123.9 uS
*   rango de modo comun          = 1.4 a 3.6 V (gm dentro del 5 %)
*
*   El gm diferencial coincide con el gm de UNA unidad (124.8 uS), que es
*   lo que debe pasar: en un par diferencial balanceado la
*   transconductancia de la etapa es la de un dispositivo, no la suma.
*   Si tu medicion da el doble, estas midiendo corriente de una sola
*   rama en vez de la diferencia.
*
* DE DONDE SALEN LOS LIMITES DEL MODO COMUN
*   Limite inferior (1.4 V): la cola necesita V_DS >= 0.152 V, y el nodo
*   de cola esta en VCM - 1.106 V. Por debajo de ~1.3 V la cola entra en
*   triodo y el gm cae.
*   Limite superior (3.6 V): con las salidas en 2.5 V, los dispositivos
*   de entrada tienen V_DS = 2.5 - (VCM - 1.106). A VCM = 3.8 V eso son
*   0.22 V, por debajo de V_DSsat, y el gm se desploma a 48.9 uS.
*
*   El limite superior DEPENDE de la polarizacion de salida. Si las
*   salidas van a otra tension, cambia. Declaralo en la hoja de datos.
*
* COMO MEDIR EL gm DIFERENCIAL
*   Fija las dos salidas con fuentes de tension a 2.5 V, aplica Vid de
*   -5 mV y +5 mV, y toma la diferencia de corriente de salida dividida
*   entre los 10 mV. No uses una carga resistiva: entonces mides la
*   ganancia de la etapa, no el gm del par.
*
* LAYOUT
*   M1 y M2 en centroide comun, que es el apareamiento critico del
*   bloque: un desbalance aqui es offset de entrada directo.
*   M3, M4 y M5 son otro conjunto apareado y necesitan su propio
*   centroide; interdigitar la referencia con las dos unidades de cola.
*   Misma orientacion en los cinco, dummies en los extremos de cada
*   arreglo, anillo de guarda continuo.
*
* LO QUE NO SE PUEDE VERIFICAR
*   El offset de entrada es, por construccion, cero en simulacion: los
*   modelos no traen dispersion de VTO y no hay Monte Carlo. El offset
*   real lo fija el apareamiento del layout, que es justamente lo que
*   este bloque ejercita y lo que no se puede simular. La hoja de datos
*   declara offset = 0 V con la nota de que es un limite del modelo, no
*   un resultado.
* =====================================================================
.SUBCKT DIFFPAIR_N Inp Inn Outp Outn Iref GND
* --- par de entrada
M1 Outp Inp  tail GND CIDNMOS L=10u W=100u
M2 Outn Inn  tail GND CIDNMOS L=10u W=100u
* --- referencia de la cola
M3 Iref Iref GND  GND CIDNMOS L=10u W=100u
* --- cola: dos unidades espejeadas de M3
M4 tail Iref GND  GND CIDNMOS L=10u W=100u
M5 tail Iref GND  GND CIDNMOS L=10u W=100u
* --- dummies, apagados
MD1 GND GND GND GND CIDNMOS L=10u W=100u
MD2 GND GND GND GND CIDNMOS L=10u W=100u
.ENDS DIFFPAIR_N
