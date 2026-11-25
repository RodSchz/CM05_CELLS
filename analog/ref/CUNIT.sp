* =====================================================================
* CUNIT.sp - Netlist de REFERENCIA (diseno de contrato)
* Proceso: CIDESI_CM05        Capacitor unitario Metal1-poly (C_MIP)
*
* VALOR NOMINAL: 99.6 fF  (~100 fF)
*   Densidad  = 66.41 aF/um2  (oxido de tapa 0.32 + PMD 0.20 = 0.52 um)
*   Geometria = 40 x 37.5 um = 1500 um2
*   Las dos medidas son multiplos de 2.5 um (lambda), asi que cae en grilla.
*
* ===== EL CAPACITOR TIENE QUE QUEDAR FUERA DE PSELECT =====
*   El oxido de tapa se graba a 0.32 um en campo y a 0.22 um sobre
*   Pselect (44/0). Con el PMD encima son 0.52 um contra 0.42 um, o sea
*   66.41 aF/um2 contra 82.22: un capacitor colocado sobre Pselect vale
*   un 23.8 % MAS de lo que dice su hoja de datos.
*
*   Y no hay nada que lo detecte: el deck de extraccion usa
*   CM05.cap(:m1_poly), que esta fijo en 66.41 aF/um2. El PEX reportaria
*   66.41 aF/um2 sobre un dispositivo que fisicamente da 82.22. El error
*   NO lo atrapa el DRC, NO lo atrapa el LVS y NO lo atrapa el PEX: solo
*   aparece al medir el silicio.
*
*   Regla: el area de placas no toca Pselect (44/0). Mantener 7.5 um de
*   separacion a cualquier figura de Pselect.
* ==========================================================
*
* CAPAS OBLIGATORIAS
*   46/0  Poly     placa inferior
*   49/0  Metal1   placa superior
*   71/0  CapBody  cuerpo del dispositivo
*   71/1  CapTermA terminal A
*   71/2  CapTermB terminal B
*   71/3  Cap.text nombre de terminal (opcional)
*
*   El deck extrae
*     mip_body = (CapBody & Metal1_limpio & Poly_limpio) & (chip - Active)
*   donde "limpio" significa SIN contactos ni vias encima:
*     m1_limpio   = Metal1 - ContactActive - ContactPoly - Via
*     poly_limpio = Poly   - ContactPoly
*
* FUERA DE ACTIVE, TAMBIEN
*   El cuerpo se intersecta con (chip - Active): cualquier traslape con
*   Active (43/0) se resta del area del capacitor. Las placas van sobre
*   campo.
*
* LOS CONTACTOS VAN FUERA DE LAS PLACAS
*   Un contacto dentro del area de placas resta esa area del capacitor,
*   porque entra por m1_limpio y poly_limpio. Contacta por los bordes.
*
* CONEXION EN SERIE Y PARALELO
*   N en paralelo = 99.6*N fF, N en serie = 99.6/N fF. El valor se
*   construye multiplicando unidades, no reescalando la geometria.
*
* COEFICIENTE TERMICO
*   C_MIP declara TC1 = 5e-4 /C (preliminar, ajustar tras medir).
*
* ADVERTENCIA SOBRE EL ESPESOR
*   Los 0.52 um salen del stack del .xs, no de medicion. El traveler del
*   TCAD termina en Metal 1, asi que todo lo de arriba es estimacion. El
*   valor absoluto de este capacitor esta sin validar; lo que si es
*   confiable es la RELACION entre dos capacitores iguales.
* =====================================================================
.SUBCKT CUNIT A B
C1 A B 99.6f
.ENDS CUNIT
