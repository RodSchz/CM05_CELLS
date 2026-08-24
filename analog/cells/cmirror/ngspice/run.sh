#!/usr/bin/env bash
# Corre el banco de pruebas post-layout de cmirror y guarda el reporte.
# Funciona igual en WSL, en Linux y en el runner de GitHub.
set -euo pipefail
cd "$(dirname "$0")"

command -v ngspice >/dev/null || { echo "ERROR: ngspice no esta instalado."; exit 127; }

mkdir -p ../results
LOG=../results/cmirror_ngspice.log
ngspice -b cmirror_tb.spice 2>&1 | tee "$LOG"

echo
echo "--- Resumen ---"
grep -E "^(ratio_|io_|v_ref|i_sat|r_out|v_min)" "$LOG" || true
echo "Reporte completo: $LOG"
