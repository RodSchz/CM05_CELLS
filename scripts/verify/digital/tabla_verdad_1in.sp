* =====================================================================
* tabla_verdad_1in.sp - Diagnostico y Tabla de Verdad para Celdas
*                       Combinacionales de 1 Entrada (CMOS 5 V)
* Simulador objetivo: ngspice
* =====================================================================

* ---------------- 1) Archivos del usuario (EDITAR) -------------------
.include ..\..\..\..\pdk\tech\models\CM05_models.lib
.include ..\layout\MI_CELDA_1IN.spice         $ a y vdd 0 MI_CELDA_1IN

* ---------------- 2) Niveles CMOS 5 V (editables) --------------------
.param VDDV    = 5
.param VILV    = 1.5               $ PEOR CASO "0"
.param VIHV    = 3.5               $ PEOR CASO "1"

VDD  vdd 0 DC {VDDV}
VA   a   0 DC 0
ILD  y   0 DC 0                    $ Carga de prueba de salida

* ---------------- 3) Instancia del DUT (EDITAR orden de pines) --------
XDUT a y vdd 0 MI_CELDA_1IN

.control
  * ------------- Parametros del diagnostico (editables) --------------
  let vdd_n   = 5.0
  let vil     = 1.5                   $ Deben coincidir con los .param
  let vih     = 3.5
  let voh_min = 4.44                 $ Salida "1" valida si V >= VOH_min
  let vol_max = 0.5                  $ Salida "0" valida si V <= VOL_max
  let iload   = 20e-6              $ Para Buffer_4X usar 80e-6, Buffer_8X usar 160e-6

  * 0 = INVERTER (Y = 1 0) | 1 = BUFFER (Y = 0 1)
  let es_buffer     = 1            $ Cambiar a 1 para Buffer / Buffer_4X / Buffer_8X
  let usar_esperado = 1            $ 0 = solo identificar la funcion
  
  if es_buffer = 1
    compose esperado values 0 1
  else
    compose esperado values 1 0
  end

  * ------------- Vectores de resultados ------------------------------
  let vy0 = vector(2)              $ Salida sin carga
  let vyl = vector(2)              $ Salida con carga IOH/IOL
  let bit = vector(2)              $ 1, 0 o -1 (X)
  let idd = vector(2)              $ Corriente estatica de VDD
  let k = 0
  let nx = 0
  let nerr = 0

  echo ""
  echo "=============== TABLA DE VERDAD (entradas a VIL / VIH) ==============="
  echo " A   VA[V]   Y sin carga[V]   Y con carga[V]   IDD[A]   Y"
  echo "-----------------------------------------------------------"

  foreach a_val 0 1
    if $a_val eq 0
      let va = vil
      let la = 0
    else
      let va = vih
      let la = 1
    end
    alter VA dc = $&va

    * --- (a) Salida sin carga
    alter ILD dc = 0
    op
    let vy0[k] = v(y)
    let idd[k] = -i(vdd)

    * --- (b) Con carga en la direccion del estado detectado:
    *     salida alta -> se extrae IOH (fuente de y a 0, positiva)
    *     salida baja -> se inyecta IOL (negativa)
    if vy0[k] > vdd_n/2
      let il = iload
    else
      let il = -iload
    end
    alter ILD dc = $&il
    op
    let vyl[k] = v(y)

    * --- Clasificacion con la salida cargada (peor caso)
    let vt = vyl[k]
    let s0 = 0
    if vy0[k] > vdd_n/2
      let s0 = 1
    end
    if vt >= voh_min
      let bit[k] = 1
    else
      if vt <= vol_max
        let bit[k] = 0
      else
        let bit[k] = -1
      end
    end
    if bit[k] >= 0
      if bit[k] <> s0
        let bit[k] = -1
      end
    end
    if bit[k] < 0
      let nx = nx + 1
    end

    let vu = vy0[k]
    let vl = vyl[k]
    let ii = idd[k]
    let bb = bit[k]
    if bb < 0
      echo " $&la   $&va    $&vu   $&vl   $&ii   X"
    else
      echo " $&la   $&va    $&vu   $&vl   $&ii   $&bb"
    end
    let k = k + 1
  end

  * ------------- Margenes de ruido (con los niveles reales medidos) ----
  let voh_r = 1e9
  let vol_r = -1e9
  let nh = 0
  let nl = 0
  let k = 0
  while k < 2
    if bit[k] = 1
      let nh = nh + 1
      if vyl[k] < voh_r
        let voh_r = vyl[k]
      end
    end
    if bit[k] = 0
      let nl = nl + 1
      if vyl[k] > vol_r
        let vol_r = vyl[k]
      end
    end
    let k = k + 1
  end
  let nmh = voh_r - vih
  let nml = vil - vol_r

  echo ""
  echo "=============== NIVELES Y MARGENES ==================================="
  echo " Especificacion: VIL=$&vil  VIH=$&vih  VOL<=$&vol_max  VOH>=$&voh_min"
  echo " Carga de prueba |IOH|=|IOL| = $&iload A"
  if nh > 0
    echo " VOH medido (peor) = $&voh_r V    NMH = VOH - VIH = $&nmh V"
  else
    echo " VOH medido: ninguna salida alta valida"
  end
  if nl > 0
    echo " VOL medido (peor) = $&vol_r V    NML = VIL - VOL = $&nml V"
  else
    echo " VOL medido: ninguna salida baja valida"
  end

  * ------------- Identificacion de la funcion ------------------------
  echo ""
  echo "=============== DIAGNOSTICO ========================================="
  if nx > 0
    echo " FUNCION: no identificable ($&nx salida(s) invalida(s) X)"
  else
    let cod = 2*bit[0] + bit[1]
    let ok_f = 0
    if cod = 2
      echo " FUNCION identificada: INVERTER (Y = 1 0)"
      let ok_f = 1
    end
    if cod = 1
      echo " FUNCION identificada: BUFFER   (Y = 0 1)"
      let ok_f = 1
    end
    if ok_f = 0
      echo " FUNCION identificada: otra (codigo Y0..Y1 = $&cod en decimal)"
    end
  end

  * ------------- Comparacion con la funcion esperada -----------------
  if usar_esperado = 1
    let k = 0
    while k < 2
      if bit[k] <> esperado[k]
        let nerr = nerr + 1
      end
      let k = k + 1
    end
    if nerr = 0
      echo " Tabla de verdad vs. esperada: COINCIDE"
    else
      echo " Tabla de verdad vs. esperada: $&nerr combinacion(es) NO coinciden"
    end
  end

  * ------------- Veredicto -------------------------------------------
  let pasa = 1
  if nx > 0
    let pasa = 0
    echo " [FALLA] $&nx salida(s) invalida(s): entre VOL_max y VOH_min o volteada(s) por la carga"
  end
  if nerr > 0
    let pasa = 0
    echo " [FALLA] La funcion logica no es la esperada"
  end
  if nh > 0
    if nmh < 0
      let pasa = 0
      echo " [FALLA] NMH negativo"
    end
  end
  if nl > 0
    if nml < 0
      let pasa = 0
      echo " [FALLA] NML negativo"
    end
  end

  echo ""
  if pasa = 1
    echo " >>> VEREDICTO: COMPATIBLE con niveles CMOS 5 V"
  else
    echo " >>> VEREDICTO: NO COMPATIBLE con niveles CMOS 5 V"
  end
  echo "======================================================================"
.endc

.end