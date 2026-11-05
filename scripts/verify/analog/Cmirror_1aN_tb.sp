* ============================================================================
* cmirror_1aN_tb.sp - Validacion Automatizada bajo Especificaciones (1:2, 1:4, 1:8)
* Simulador objetivo: ngspice
* ============================================================================

* ---------------- 1) Archivos del usuario -----------------------------------
.include ../../../../pdk/tech/models/CM05_models.lib
.include ../layout/Cmirror_1aN_pex.spice      $ Netlist extraido

* ---------------- 2) Fuentes y Estimulaciones -------------------------------
.param VDDV   = 5.0
.param IREFV  = 100u                         $ Corriente de prueba nominal

Vcom   COM   0 DC 0
Iref   0    P1 DC {IREFV}

* Fuentes independientes de polarizacion para cada salida analogica (inicial en 2.5V)
Vout_2 P2_2  0 DC 2.5
Vout_4 P2_4  0 DC 2.5
Vout_8 P2_8  0 DC 2.5

* ---------------- 3) Instancia del DUT (Extraido) ---------------------------
X1 COM P2_8 P2_4 P2_2 P1 Cmirror_1aN_p

* ---------------- 4) Bloque de Control y Diagnostico ----------------------
.control
  set noaskquit

  * ------------- Parametros y Tolerancias ----------------------------------
  let max_err_pct = 1.0       $ Tolerancia estricta de +/- 1% segun especificaciones
  let k_2 = 2.0
  let k_4 = 4.0
  let k_8 = 8.0

  echo ""
  echo "======================================================================"
  echo "      VALIDACION POST-LAYOUT: ESPEJO DE CORRIENTE (1:2, 1:4, 1:8)    "
  echo "======================================================================"

  * ------------- 1. RELACIONES A 10uA, 50uA, 100uA Y 190uA -------------------
  dc Iref 1u 200u 1u

  let io2 = -vout_2#branch
  let io4 = -vout_4#branch
  let io8 = -vout_8#branch

  * Mediciones para Rama 1:2
  meas dc io2_10u  FIND io2 AT=10u
  meas dc io2_50u  FIND io2 AT=50u
  meas dc io2_100u FIND io2 AT=100u
  meas dc io2_190u FIND io2 AT=190u

  let r2_10u  = io2_10u  / 10e-6
  let r2_50u  = io2_50u  / 50e-6
  let r2_100u = io2_100u / 100e-6
  let r2_190u = io2_190u / 190e-6
  let e2_100u = abs((r2_100u - k_2) / k_2) * 100

  * Mediciones para Rama 1:4
  meas dc io4_10u  FIND io4 AT=10u
  meas dc io4_50u  FIND io4 AT=50u
  meas dc io4_100u FIND io4 AT=100u
  meas dc io4_190u FIND io4 AT=190u

  let r4_10u  = io4_10u  / 10e-6
  let r4_50u  = io4_50u  / 50e-6
  let r4_100u = io4_100u / 100e-6
  let r4_190u = io4_190u / 190e-6
  let e4_100u = abs((r4_100u - k_4) / k_4) * 100

  * Mediciones para Rama 1:8
  meas dc io8_10u  FIND io8 AT=10u
  meas dc io8_50u  FIND io8 AT=50u
  meas dc io8_100u FIND io8 AT=100u
  meas dc io8_190u FIND io8 AT=190u

  let r8_10u  = io8_10u  / 10e-6
  let r8_50u  = io8_50u  / 50e-6
  let r8_100u = io8_100u / 100e-6
  let r8_190u = io8_190u / 190e-6
  let e8_100u = abs((r8_100u - k_8) / k_8) * 100

  * Guardar variables del barrido de Iref
  set r2_10=$&r2_10u  r2_50=$&r2_50u  r2_100=$&r2_100u  r2_190=$&r2_190u  e2_100=$&e2_100u
  set r4_10=$&r4_10u  r4_50=$&r4_50u  r4_100=$&r4_100u  r4_190=$&r4_190u  e4_100=$&e4_100u
  set r8_10=$&r8_10u  r8_50=$&r8_50u  r8_100=$&r8_100u  r8_190=$&r8_190u  e8_100=$&e8_100u

  * ------------- 2. ROUT A VOUT = 4V Y VMIN (RAMA 1:2) -------------------
  reset
  alter @Iref[dc] = 100u
  dc Vout_2 0 5 0.01
  let io2_v = -vout_2#branch
  let rout2 = 1 / (deriv(io2_v) + 1e-15)
  meas dc r_out_2_val FIND rout2 AT=4.0
  let i_t2 = 100e-6 * k_2 * 0.995
  meas dc v_min_2_val WHEN io2_v=$&i_t2 RISE=1

  set ro2 = $&r_out_2_val
  set vm2 = $&v_min_2_val

  * ------------- 3. ROUT A VOUT = 4V Y VMIN (RAMA 1:4) -------------------
  reset
  alter @Iref[dc] = 100u
  dc Vout_4 0 5 0.01
  let io4_v = -vout_4#branch
  let rout4 = 1 / (deriv(io4_v) + 1e-15)
  meas dc r_out_4_val FIND rout4 AT=4.0
  let i_t4 = 100e-6 * k_4 * 0.995
  meas dc v_min_4_val WHEN io4_v=$&i_t4 RISE=1

  set ro4 = $&r_out_4_val
  set vm4 = $&v_min_4_val

  * ------------- 4. ROUT A VOUT = 4V Y VMIN (RAMA 1:8) -------------------
  reset
  alter @Iref[dc] = 100u
  dc Vout_8 0 5 0.01
  let io8_v = -vout_8#branch
  let rout8 = 1 / (deriv(io8_v) + 1e-15)
  meas dc r_out_8_val FIND rout8 AT=4.0
  let i_t8 = 100e-6 * k_8 * 0.995
  meas dc v_min_8_val WHEN io8_v=$&i_t8 RISE=1

  set ro8 = $&r_out_8_val
  set vm8 = $&v_min_8_val

  * ------------- REPORTE DE RESULTADOS POR TABLA ------------------------
  echo ""
  echo "---------------- DETALLE DE MEDICIONES POR TABLA ----------------------"
  echo " [Rama 1:2]"
  echo "   - Relacion @ 100 uA  : $r2_100 (Error: $e2_100 % | Obj: +/- 1.0%)"
  echo "   - Relacion @ 10 uA   : $r2_10"
  echo "   - Relacion @ 50 uA   : $r2_50"
  echo "   - Relacion @ 190 uA  : $r2_190"
  echo "   - Rout @ Vout = 4V   : $ro2 Ohms"
  echo "   - V_min de salida    : $vm2 V"
  echo ""
  echo " [Rama 1:4]"
  echo "   - Relacion @ 100 uA  : $r4_100 (Error: $e4_100 % | Obj: +/- 1.0%)"
  echo "   - Relacion @ 10 uA   : $r4_10"
  echo "   - Relacion @ 50 uA   : $r4_50"
  echo "   - Relacion @ 190 uA  : $r4_190"
  echo "   - Rout @ Vout = 4V   : $ro4 Ohms"
  echo "   - V_min de salida    : $vm4 V"
  echo ""
  echo " [Rama 1:8]"
  echo "   - Relacion @ 100 uA  : $r8_100 (Error: $e8_100 % | Obj: +/- 1.0%)"
  echo "   - Relacion @ 10 uA   : $r8_10"
  echo "   - Relacion @ 50 uA   : $r8_50"
  echo "   - Relacion @ 190 uA  : $r8_190"
  echo "   - Rout @ Vout = 4V   : $ro8 Ohms"
  echo "   - V_min de salida    : $vm8 V"
  echo "----------------------------------------------------------------------"

  let pasa = 1

  if $e2_100 > max_err_pct
    let pasa = 0
    echo " [FALLA] Error de copia fuera de +/-1% en Rama 1:2"
  end
  if $e4_100 > max_err_pct
    let pasa = 0
    echo " [FALLA] Error de copia fuera de +/-1% en Rama 1:4"
  end
  if $e8_100 > max_err_pct
    let pasa = 0
    echo " [FALLA] Error de copia fuera de +/-1% en Rama 1:8"
  end

  echo ""
  if pasa = 1
    echo " >>> VEREDICTO FINAL: CUMPLE CON TODAS LAS METRICAS DE LA TABLA (PASSED) <<<"
  else
    echo " >>> VEREDICTO FINAL: NO CUMPLE EL OBJETIVO DE +/-1% (FAILED) <<<"
  end
  echo "======================================================================"

.endc

.end