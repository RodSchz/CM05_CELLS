* =====================================================================
* FFD_tb.sp - Diagnostico Funcional Exhaustivo para FFD (CMOS 5 V)
* Simulador objetivo: ngspice
* =====================================================================

* ---------------- 1) Archivos del usuario (EDITAR ruta si es necesario)
.include ..\..\..\..\pdk\tech\models\CM05_models.lib
.include ..\layout\FFD_pex.spice             $ .subckt FFD_M VDD GND Q CB C PRB QB CLK Data CLB
* ---------------- 2) Opciones de Simulacion para Extracciones PEX ----
* Se utiliza method=gear para evitar oscilaciones irreales y fallos de 
* convergencia ("time step too small") comunes en nodos parásitos RC.
.options method=gear

* ---------------- 3) Niveles CMOS 5 V y Fuentes PWL ------------------
.param VDDV = 5.0
.param VILV = 1.5               $ PEOR CASO "0" a la entrada
.param VIHV = 3.5               $ PEOR CASO "1" a la entrada

VDD  vdd 0 DC {VDDV}

* Secuencia temporal diseñada para evaluar TODAS las fases del FFD:
* Fase 1: 0ns-10ns   -> Init Asincrono (CLB=0, Q debe ser 0)
* Fase 2: 15ns-25ns  -> Captura de '0' (CLK pulso, D=0)
* Fase 3: 28ns-38ns  -> Hold de '0' (D cambia a 1, CLK=0)
* Fase 4: 40ns-50ns  -> Captura de '1' (CLK pulso, D=1)
* Fase 5: 53ns-63ns  -> Hold de '1' (D cambia a 0, CLK=0)
* Fase 6: 68ns-80ns  -> Preset Asincrono (PRB=0, Q debe forzarse a 1)
* Fase 7: 83ns-95ns  -> Clear Asincrono (CLB=0, Q debe forzarse a 0)

VDAT data 0 PWL(0 {VILV} 28n {VILV} 29n {VIHV} 53n {VIHV} 54n {VILV})
VCLK clk  0 PWL(0 {VILV} 15n {VILV} 16n {VIHV} 20n {VIHV} 21n {VILV} 40n {VILV} 41n {VIHV} 45n {VIHV} 46n {VILV})
VPRB prb  0 PWL(0 {VDDV} 68n {VDDV} 69n 0 74n 0 75n {VDDV})
VCLB clb  0 PWL(0 0       6n 0      7n {VDDV} 83n {VDDV} 84n 0 89n 0 90n {VDDV})

* ---------------- 4) Cargas estabilizadoras (Previene nodos flotantes)
* Fundamental para netlists extraidos (PEX) para ayudar a la convergencia
CL_q   q   0 20f               $ Carga capacitiva real de prueba
CL_qb  qb  0 1f                $ Carga parasita minima para salida negada
CL_c   c   0 1f                $ Carga parasita minima para reloj interno
CL_cb  cb  0 1f                $ Carga parasita minima para reloj negado

* ---------------- 5) Instancia del DUT -------------------------------
* Mapeo EXACTO segun tu FFD_pex.spice: VDD GND Q CB C PRB QB CLK Data CLB
XDUT vdd 0 q cb c prb qb clk data clb FFD_M

* Directiva de analisis transitorio
.tran 0.1n 100n

.control
  run

  * ------------- Parametros del diagnostico --------------------------
  let vil     = 1.5
  let vih     = 3.5
  let voh_min = 4.44                 $ Salida "1" valida si V >= VOH_min
  let vol_max = 0.5                  $ Salida "0" valida si V <= VOL_max

  * Muestreo de voltajes en los 7 instantes estrategicos
  meas tran vq1 FIND v(q) AT=10n   $ 1. Init Asincrono
  meas tran vq2 FIND v(q) AT=25n   $ 2. Captura '0'
  meas tran vq3 FIND v(q) AT=35n   $ 3. Hold '0'
  meas tran vq4 FIND v(q) AT=50n   $ 4. Captura '1'
  meas tran vq5 FIND v(q) AT=60n   $ 5. Hold '1'
  meas tran vq6 FIND v(q) AT=80n   $ 6. Preset Asincrono
  meas tran vq7 FIND v(q) AT=95n   $ 7. Clear Asincrono

  * Creacion de vectores de resultados
  let vq  = vector(7)
  let bit = vector(7)
  let esp = vector(7)

  * Vector de valores logicamente esperados en las 7 fases
  compose esp values 0 0 0 1 1 1 0

  let vq[0] = vq1
  let vq[1] = vq2
  let vq[2] = vq3
  let vq[3] = vq4
  let vq[4] = vq5
  let vq[5] = vq6
  let vq[6] = vq7

  let k = 0
  let nx = 0
  let nerr = 0

  while k < 7
    let vt = vq[k]
    * Clasificacion de niveles de salida
    if vt >= voh_min
      let bit[k] = 1
    else
      if vt <= vol_max
        let bit[k] = 0
      else
        let bit[k] = -1
        let nx = nx + 1
      end
    end
    
    * Comparacion de fallos lógicos
    if bit[k] <> esp[k] and bit[k] >= 0
      let nerr = nerr + 1
    end
    let k = k + 1
  end

  * Imprimir tabla formateada
  echo ""
  echo "=================== EVALUACION SECUENCIAL (FFD_PEX) ==================="
  echo " Fase  Accion / Estado    CLK   D   PRB  CLB | VQ_med[V]   Q_logico"
  echo "-----------------------------------------------------------------------"
  
  let b0 = bit[0]
  let b1 = bit[1]
  let b2 = bit[2]
  let b3 = bit[3]
  let b4 = bit[4]
  let b5 = bit[5]
  let b6 = bit[6]

  let v0 = vq[0]
  let v1 = vq[1]
  let v2 = vq[2]
  let v3 = vq[3]
  let v4 = vq[4]
  let v5 = vq[5]
  let v6 = vq[6]

  echo "  1    Init Asincrono      0    0    1    0  |   $&v0        $&b0"
  echo "  2    Captura '0'         ^    0    1    1  |   $&v1        $&b1"
  echo "  3    Hold '0' (Retiene)  0    1    1    1  |   $&v2        $&b2"
  echo "  4    Captura '1'         ^    1    1    1  |   $&v3        $&b3"
  echo "  5    Hold '1' (Retiene)  0    0    1    1  |   $&v4        $&b4"
  echo "  6    Preset Asincrono    0    0    0    1  |   $&v5        $&b5"
  echo "  7    Clear Asincrono     0    0    1    0  |   $&v6        $&b6"

  * ------------- Margenes de ruido dinamicos -------------------------
  let voh_r = 1e9
  let vol_r = -1e9
  let nh = 0
  let nl = 0
  let k = 0

  while k < 7
    if bit[k] = 1
      let nh = nh + 1
      if vq[k] < voh_r
        let voh_r = vq[k]
      end
    end
    if bit[k] = 0
      let nl = nl + 1
      if vq[k] > vol_r
        let vol_r = vq[k]
      end
    end
    let k = k + 1
  end

  let nmh = voh_r - vih
  let nml = vil - vol_r

  echo ""
  echo "=============== NIVELES Y MARGENES (DINAMICOS) ======================="
  echo " Especificacion: VIL=$&vil  VIH=$&vih  VOL<=$&vol_max  VOH>=$&voh_min"
  echo " Carga capacitiva de prueba: C_load = 20 fF"
  if nh > 0
    echo " VOH medido (peor) = $&voh_r V    NMH = VOH - VIH = $&nmh V"
  else
    echo " VOH medido: ninguna salida alta valida (Fallo de captura/Preset)"
  end
  if nl > 0
    echo " VOL medido (peor) = $&vol_r V    NML = VIL - VOL = $&nml V"
  else
    echo " VOL medido: ninguna salida baja valida (Fallo de captura/Clear)"
  end

  * ------------- Diagnostico y Veredicto -----------------------------
  echo ""
  echo "=============== DIAGNOSTICO ========================================="
  let pasa = 1

  if nx > 0
    let pasa = 0
    echo " [FALLA] $&nx estado(s) fuera de niveles de salida CMOS (entre VOL y VOH)"
  end
  if nerr > 0
    let pasa = 0
    echo " [FALLA] Error logico: La celda fallo en $&nerr transicion(es) esperada(s)"
  end
  if nh > 0 and nl > 0
    if nmh < 0 or nml < 0
      let pasa = 0
      echo " [FALLA] Margenes de ruido negativos bajo condiciones dinamicas"
    end
  end

  if bit[5] <> 1
    echo " [ALERTA] Falla en el Preset (PRB)"
  end
  if bit[6] <> 0
    echo " [ALERTA] Falla en el Clear (CLB)"
  end

  echo ""
  if pasa = 1
    echo " >>> VEREDICTO: COMPATIBLE y FUNCIONAL en entorno CMOS 5 V"
  else
    echo " >>> VEREDICTO: NO COMPATIBLE / FALLA EN CELDA (Revisar PEX)"
  end
  echo "====================================================================="
.endc
.end