* =====================================================================
* RUNIT.sp - Netlist de REFERENCIA (diseno de contrato)
* Proceso: CIDESI_CM05        Resistor unitario de polisilicio
*
* VALOR NOMINAL: 10 kohm
*   RHO del poly = 2500 ohm/cuadro (CM05_process.lym)
*   Geometria    = W 10 um x L 40 um = 4 cuadros
*   10 um de ancho es 4*lambda, el doble del minimo de poly (R3_1 = 2*lambda
*   = 5 um): se escoge ancho para apareamiento, no minimo.
*
* CAPAS OBLIGATORIAS (si falta una, el LVS no ve un resistor)
*   46/0  Poly            cuerpo
*   34/0  HiRes           marca el poly como resistor intencional
*   70/0  ResBody         cuerpo del dispositivo
*   70/1  ResTerm         los dos terminales
*   70/2  Res.text        nombre de terminal (opcional)
*   47/0  ContactPoly + 49/0 Metal1 en cada terminal
*
*   El deck extrae el cuerpo como  body_poly = ResBody & HiRes,
*   y los terminales como  term_poly = ResTerm + Metal1.
*
* EXACTAMENTE DOS CONTACTOS
*   El extractor de KLayout exige DOS poligonos de contacto por cuerpo de
*   resistor. Con tres o mas DESCARTA el dispositivo entero y avisa
*   "Expected two polygons on contacts... resistor shape ignored".
*   Un contacto de mas no es una violacion de DRC: es un resistor que
*   desaparece del netlist. Revisa el log de extraccion, no solo el LVS.
*
* CONEXION EN SERIE Y PARALELO
*   El valor se construye multiplicando unidades, igual que los MOS:
*   N en serie = 10*N kohm, N en paralelo = 10/N kohm. No se cambia la
*   geometria del cuerpo para obtener otro valor.
*
* COEFICIENTE TERMICO
*   R_POLY declara TC1 = 1.5e-3 /C (preliminar, ajustar tras medir).
*   A 85 C eso son +8.7 % sobre el valor de 27 C.
*
* HUECO CONOCIDO DEL PEX
*   La capacitancia del cuerpo al sustrato NO se extrae: poly_campo usa
*   46/0 y no incluye HiRes (34/0). Para este cuerpo de 400 um2 son
*   ~20.9 fF (a 52.32 aF/um2) que el PEX no reporta. Si el resistor va en
*   un nodo sensible, agregalo a mano al testbench.
* =====================================================================
.SUBCKT RUNIT A B
R1 A B 10k
.ENDS RUNIT
