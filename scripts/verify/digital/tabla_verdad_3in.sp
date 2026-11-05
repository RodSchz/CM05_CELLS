* =====================================================================
* tabla_verdad_2in.sp - Tabla de verdad y diagnostico de compatibilidad
*                       CMOS 5 V para una compuerta de 2 entradas
* Simulador objetivo: ngspice
*
* Que hace:
*   1) Aplica las 4 combinaciones de entrada usando niveles de PEOR CASO:
*      "0" logico = VIL  y  "1" logico = VIH  (no 0 V / 5 V ideales).
*   2) Mide la salida en DC (.op) sin carga y con una carga de corriente
*      IOH / IOL en la direccion que corresponda al estado de salida.
*   3) Clasifica cada salida: 1 si V >= VOH_min, 0 si V <= VOL_max,
*      X (invalida) en otro caso.
*   4) Identifica la funcion logica, la compara con la esperada (opcional),
*      calcula margenes de ruido y emite el veredicto de compatibilidad.
* =====================================================================

* ---------------- 1) Archivos del usuario (EDITAR) -------------------
.include ..\..\..\..\pdk\tech\models\CM05_models.lib
.include ..\layout\MI_CELDA          $ .subckt MI_CELDA VDD GND OUT C A B

* ---------------- 2) Niveles CMOS 5 V (editables) --------------------
* Referencia: niveles JEDEC/CMOS 5 V usuales (VIL = 0.3 VDD, VIH = 0.7 VDD)
.param VDDV    = 5
.param VILV    = 1.5               $ max. voltaje aceptado como "0" a la entrada
.param VIHV    = 3.5               $ min. voltaje aceptado como "1" a la entrada

VDD  vdd 0 DC {VDDV}
VA   a   0 DC 0
VB   b   0 DC 0
VC   c   0 DC 0
ILD  y   0 DC 0                    $ carga de salida (se ajusta en .control)

* ---------------- 3) Instancia del DUT (EDITAR orden de pines) --------
XDUT a b c vdd 0 MI_CELDA

.control
  * ------------- Parametros del diagnostico (editables) --------------
  let vdd_n  = 5.0
  let vil    = 1.5                   $ deben coincidir con los .param
  let vih    = 3.5
  let voh_min = 4.44                 $ salida "1" valida si V >= VOH_min
  let vol_max = 0.5                  $ salida "0" valida si V <= VOL_max
  let iload  = 20e-6                 $ |IOH| = |IOL| de prueba [A] (0 = sin carga)

  * Funcion esperada (opcional): Y para AB = 000 a 111
  * NAND: 1 1 1 1 1 1 1 0 | NOR: 1 0 0 0 0 0 0 0 | AND: 0 0 0 0 0 0 0 1 | OR: 0 1 1 1 1 1 1 1
  * XOR : 0 1 1 0 1 0 0 1 | XNOR: 1 0 0 1 0 1 1 0
  let usar_esperado = 1              $ 0 = solo identificar la funcion
  compose esperado values 1 0 0 0 0 0 0 0  $<-- MI_CELDA

  * ------------- Vectores de resultados ------------------------------
  let vy0  = vector(8)               $ salida sin carga
  let vyl  = vector(8)               $ salida con carga IOH/IOL
  let bit  = vector(8)               $ 1, 0 o -1 (X)
  let idd  = vector(8)               $ corriente estatica de VDD
  let k = 0
  let nx = 0
  let nerr = 0

  echo ""
  echo "=============== TABLA DE VERDAD (entradas a VIL / VIH) ==============="
  echo " A  B C  VA[V]  VB[V]  VC[V]   Y sin carga[V]   Y con carga[V]   IDD[A]   Y"
  echo "----------------------------------------------------------------------"

  foreach abc 000 001 010 011 100 101 110 111
    * --- niveles de entrada de peor caso
    if $abc eq 000
      let va = vil
      let vb = vil
      let vc = vil
      let la = 0
      let lb = 0
      let lc = 0
    end
    if $abc eq 001
      let va = vil
      let vb = vil
      let vc = vih
      let la = 0
      let lb = 0
      let lc = 1
    end
    if $abc eq 010
      let va = vil
      let vb = vih
      let vc = vil
      let la = 0
      let lb = 1
      let lc = 0
    end
    if $abc eq 011
      let va = vil
      let vb = vih
      let vc = vih
      let la = 0
      let lb = 1
      let lc = 1
    end
    if $abc eq 100
      let va = vih
      let vb = vil
      let vc = vil
      let la = 1
      let lb = 0
      let lc = 0
    end
    if $abc eq 101
      let va = vih
      let vb = vil
      let vc = vih
      let la = 1
      let lb = 0
      let lc = 1
    end
    if $abc eq 110
      let va = vih
      let vb = vih
      let vc = vil
      let la = 1
      let lb = 1
      let lc = 0
    end
    if $abc eq 111
      let va = vih
      let vb = vih
      let vc = vih
      let la = 1
      let lb = 1
      let lc = 1
    end
    alter VA dc = $&va
    alter VB dc = $&vb
    alter VC dc = $&vc    $ <--- Aplicar voltaje a la fuente C

    * --- (a) salida sin carga
    alter ILD dc = 0
    op
    let vy0[k] = v(y)
    let idd[k] = -i(vdd)

    * --- (b) con carga en la direccion del estado detectado:
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

    * --- clasificacion con la salida cargada (peor caso)
    *     (si la carga invierte el estado detectado sin carga -> X)
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
      echo " $&la  $&lb  $&lc   $&va    $&vb    $&vc    $&vu   $&vl   $&ii   X"
    else
      echo " $&la  $&lb  $&lc   $&va    $&vb    $&vc    $&vu   $&vl   $&ii   $&bb"
    end
    let k = k + 1
  end

  * ------------- Margenes de ruido (con los niveles reales medidos) ----
  * VOH real = minimo de las salidas altas, VOL real = maximo de las bajas
  let voh_r = 1e9
  let vol_r = -1e9
  let nh = 0
  let nl = 0
  let k = 0
  while k < 8
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
    let cod = 128*bit[0] + 64*bit[1] + 32*bit[2] + 16*bit[3] + 8*bit[4] + 4*bit[5] + 2*bit[6] + bit[7]
    let ok_f = 0
    if cod = 128
      echo " FUNCION identificada: NOR3  (Y = 1 0 0 0 0 0 0 0)"
      let ok_f = 1
    end
    if cod = 254
      echo " FUNCION identificada: NAND3 (Y = 1 1 1 1 1 1 1 0)"
      let ok_f = 1
    end
    if cod = 1
      echo " FUNCION identificada: AND3  (Y = 0 0 0 0 0 0 0 1)"
      let ok_f = 1
    end
    if cod = 127
      echo " FUNCION identificada: OR3   (Y = 0 1 1 1 1 1 1 1)"
      let ok_f = 1
    end
    if cod = 105
      echo " FUNCION identificada: XOR3  (Y = 0 1 1 0 1 0 0 1)"
      let ok_f = 1
    end
    if cod = 150
      echo " FUNCION identificada: XNOR3 (Y = 1 0 0 1 0 1 1 0)"
      let ok_f = 1
    end
    if ok_f = 0
      echo " FUNCION identificada: otra (codigo Y000..Y111 = $&cod en decimal)"
    end
  end

  * ------------- Comparacion con la funcion esperada -----------------
  if usar_esperado = 1
    let k = 0
    while k < 8
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

* =====================================================================
* NOTAS
* 1) Ejecutar en lote:  ngspice -b tabla_verdad_2in.sp
* 2) Si tu .subckt tiene otro orden de pines o nombre, solo cambia la
*    linea XDUT; si los nodos de alimentacion son VDD/VSS globales, quita
*    "vdd 0" de la instancia.
* 3) La salida se clasifica con carga (peor caso). Si quieres el criterio
*    sin carga, pon iload = 0.
* 4) Con iload = 20 uA el criterio corresponde a la condicion de VOH/VOL
*    "CMOS" de las hojas de datos; para fan-out real usa la corriente
*    que demanden las compuertas que va a manejar (en DC es casi cero en
*    CMOS, por eso la condicion de 20 uA es la convencion habitual).
* =====================================================================
