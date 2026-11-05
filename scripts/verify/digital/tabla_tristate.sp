* =====================================================================
* tabla_tristate.sp - Diagnostico y Tabla de Verdad para Celdas
*                      de 3 Estados / Tri-State (CMOS 5 V)
* Simulador objetivo: ngspice
* =====================================================================

* ---------------- 1) Archivos del usuario (EDITAR) -------------------
.include ..\..\..\..\pdk\tech\models\CM05_models.lib
.include ..\layout\MI_CELDA.spice        $ .subckt MI_CELDA_M VDD GND Data Out OEB

* ---------------- 2) Niveles CMOS 5 V (editables) --------------------
.param VDDV    = 5
.param VILV    = 1.5               $ PEOR CASO "0"
.param VIHV    = 3.5               $ PEOR CASO "1"

VDD  vdd 0 DC {VDDV}
VA   a   0 DC 0
VEN  en  0 DC 0
ILD  y   0 DC 0                    $ Carga de prueba de salida

* ---------------- 3) Instancia del DUT (EDITAR orden de pines) --------
* Ajustar orden de pines segun la celda (ejemplo para Buffer3S: VDD GND Data Out OEB)
XDUT vdd 0 a y en MI_CELDA_M

.control
  * ------------- Parametros del diagnostico (editables) --------------
  let vdd_n   = 5.0
  let vil     = 1.5                   $ Deben coincidir con los .param
  let vih     = 3.5
  let voh_min = 4.44                 $ Salida "1" valida si V >= VOH_min
  let vol_max = 0.5                  $ Salida "0" valida si V <= VOL_max
  let iload   = 20e-6              $ Carga de prueba en estado activo [A]

  * Configurations:
  * 0 = INVERTER3S | 1 = BUFFER3S
  let es_buffer3s    = 1           $ 1 para Buffer3S, 0 para Inverter3S
  let en_activo_alto = 0           $ 1 si EN=1 habilita, 0 si OEB/ENB=0 habilita
  let usar_esperado  = 1           $ 0 = solo identificar la funcion

  * Definicion de la tabla esperada (Codigos: 0=Low, 1=High, 2=Hi-Z)
  * Orden de combinaciones A EN: 00, 01, 10, 11
  if es_buffer3s = 1
    if en_activo_alto = 1
      compose esperado values 2 0 2 1
    else
      compose esperado values 0 2 1 2
    end
  else
    if en_activo_alto = 1
      compose esperado values 2 1 2 0
    else
      compose esperado values 1 2 0 2
    end
  end

  * ------------- Vectores de resultados ------------------------------
  let vy0   = vector(4)            $ Salida sin carga
  let vyl   = vector(4)            $ Salida con carga IOH/IOL
  let v_hi  = vector(4)            $ Muestreo Hi-Z con pull-up
  let v_lo  = vector(4)            $ Muestreo Hi-Z con pull-down
  let bit   = vector(4)            $ 1 (Alto), 0 (Bajo), 2 (Hi-Z / Z), -1 (X)
  let idd   = vector(4)            $ Corriente estatica de VDD
  let k = 0
  let nx = 0
  let nerr = 0

  echo ""
  echo "=============== TABLA DE VERDAD (entradas a VIL / VIH) ==============="
  echo " A  EN   VA[V]  VEN[V]   Y sin carga[V]   Y con carga[V]   IDD[A]   Y"
  echo "----------------------------------------------------------------------"

  foreach a_en 00 01 10 11
    * --- Niveles de entrada de peor caso
    if $a_en eq 00
      let va  = vil
      let ven = vil
      let la  = 0
      let len = 0
    end
    if $a_en eq 01
      let va  = vil
      let ven = vih
      let la  = 0
      let len = 1
    end
    if $a_en eq 10
      let va  = vih
      let ven = vil
      let la  = 1
      let len = 0
    end
    if $a_en eq 11
      let va  = vih
      let ven = vih
      let la  = 1
      let len = 1
    end

    alter VA  dc = $&va
    alter VEN dc = $&ven

    * Determinar si la celda debe estar activa segun polaridad de EN
    let activo = 0
    if en_activo_alto = 1
      if len = 1
        let activo = 1
      end
    else
      if len = 0
        let activo = 1
      end
    end

    * --- Evolucion en estado ACTIVO (Driver habilitado)
    if activo = 1
      * (a) Sin carga
      alter ILD dc = 0
      op
      let vy0[k] = v(y)
      let idd[k] = -i(vdd)

      * (b) Con carga (direccion segun estado)
      if vy0[k] > vdd_n/2
        let il = iload
      else
        let il = -iload
      end
      alter ILD dc = $&il
      op
      let vyl[k] = v(y)

      * Clasificacion logica
      let vt = vyl[k]
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

    * --- Evolucion en estado DESHABILITADO (Alta Impedancia Hi-Z / Z)
    else
      * Se valida que la salida flote libremente bajo pull-up y pull-down debil (10 uA)
      alter ILD dc = 10e-6
      op
      let v_hi[k] = v(y)
      let idd[k] = -i(vdd)

      alter ILD dc = -10e-6
      op
      let v_lo[k] = v(y)

      let vy0[k] = (v_hi[k] + v_lo[k])/2
      let vyl[k] = v_hi[k]

      * Si responde al estiramiento sin oponer resistencia, esta en Alta Impedancia (Z)
      if v_hi[k] >= 4.5 and v_lo[k] <= 0.5
        let bit[k] = 2             $ 2 representa 'Z'
      else
        let bit[k] = -1            $ No quedo flotando adecuadamente
        let nx = nx + 1
      end
    end

    * Impresion de renglon
    let vu = vy0[k]
    let vl = vyl[k]
    let ii = idd[k]
    let bb = bit[k]

    if bb = 2
      echo " $&la   $&len    $&va    $&ven    $&vu   $&vl (Hi-Z) $&ii   Z"
    else
      if bb < 0
        echo " $&la   $&len    $&va    $&ven    $&vu   $&vl   $&ii   X"
      else
        echo " $&la   $&len    $&va    $&ven    $&vu   $&vl   $&ii   $&bb"
      end
    end

    let k = k + 1
  end

  * ------------- Margenes de ruido (para estados activos) --------------
  let voh_r = 1e9
  let vol_r = -1e9
  let nh = 0
  let nl = 0
  let k = 0
  while k < 4
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
    echo " FUNCION: no identificable ($&nx salida(s) invalida(s) X o falla en Hi-Z)"
  else
    let cod = 27*bit[0] + 9*bit[1] + 3*bit[2] + bit[3]
    let ok_f = 0
    
    * Codigos en base 3 (0=0, 1=1, 2=Z):
    * Buffer3S con OEB   (EN activo bajo, Y = 0 Z 1 Z)  -> cod = 23
    * Buffer3S con EN    (EN activo alto, Y = Z 0 Z 1)  -> cod = 61
    * Inverter3S con OEB (EN activo bajo, Y = 1 Z 0 Z)  -> cod = 47
    * Inverter3S con EN  (EN activo alto, Y = Z 1 Z 0)  -> cod = 69
    if cod = 23 or cod = 61
      echo " FUNCION identificada: BUFFER3S"
      let ok_f = 1
    end
    if cod = 47 or cod = 69
      echo " FUNCION identificada: INVERTER3S"
      let ok_f = 1
    end

    if ok_f = 0
      echo " FUNCION identificada: otra celda de 3 estados (codigo = $&cod)"
    end
  end

  * ------------- Comparacion con la funcion esperada -----------------
  if usar_esperado = 1
    let k = 0
    while k < 4
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
    echo " [FALLA] $&nx salida(s) invalida(s) o falla en estado de Alta Impedancia (Hi-Z)"
  end
  if nerr > 0
    let pasa = 0
    echo " [FALLA] La funcion logica / habilitacion no es la esperada"
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