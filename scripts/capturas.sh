#!/bin/zsh
# Genera las capturas de la Fase 05A en el simulador "iPhone 16".
# Uso: scripts/capturas.sh <ruta a Educulter.app (Debug, simulador)> <carpeta de salida>
set -euo pipefail
APP="$1"; SALIDA="$2"
UDID=$(xcrun simctl list devices available | grep -E "^ +iPhone 16 \(" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
BUNDLE=com.educulter.dev
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b > /dev/null
xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
mkdir -p "$SALIDA"
# Arranque en frío para que las primeras capturas no salgan en blanco.
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" -enMemoria > /dev/null; sleep 12

captura() { # nombre escena
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" -enMemoria -semilla 42 -captura "$2" > /dev/null
  sleep 7
  xcrun simctl io "$UDID" screenshot --type=png "$SALIDA/$1.png" > /dev/null 2>&1
  echo "  $1"
}

# Ítems de demostración (el primero de cada mecánica).
typeset -A ITEMS
ITEMS=(01_eleccion LEN.REC.FIGURAS.0001 02_verdaderoFalso LEN.CLA.SUSTADJ.0002 03_clasificar LEN.CLA.SUSTADJ.0001
       04_ordenar LEN.LIT.CRONO.0001 05_emparejar LEN.LEX.SINON.0001 06_marcarTexto LEN.CLA.VERBO.0001
       07_segmentar LEN.SIN.COMPL.0001 08_ruedas LEN.VER.ANALISIS.0001 09_construir LEN.ORT.TILDES.0002 10_numerico MAT.NUM.FRACSUM.0001)

xcrun simctl ui "$UDID" content_size large
xcrun simctl ui "$UDID" appearance light
echo "Modo claro"
captura 00_hoy hoy
for clave in ${(ok)ITEMS}; do
  captura "${clave}_a_antes" "item:${ITEMS[$clave]}:antes"
  captura "${clave}_b_despues" "item:${ITEMS[$clave]}:despues"
done
captura 11_feedback_correcto "item:MAT.POR.PORCENT.0001:correcto"
captura 12_resumen resumen
captura 13_teoria_esquema "teoria:LEN.ORT.TILDES.T01"
captura 14_llega_pronto mapa
captura 15_revision revision

echo "Modo oscuro"
xcrun simctl ui "$UDID" appearance dark
captura 20_oscuro_hoy hoy
captura 21_oscuro_segmentar "item:LEN.SIN.COMPL.0001:despues"
captura 22_oscuro_numerico "item:MAT.NUM.FRACSUM.0001:antes"
captura 23_oscuro_feedback "item:LEN.REC.FIGURAS.0001:despues"
captura 24_oscuro_resumen resumen
captura 25_oscuro_teoria "teoria:LEN.ORT.TILDES.T01"

echo "Texto de accesibilidad máximo"
xcrun simctl ui "$UDID" appearance light
xcrun simctl ui "$UDID" content_size accessibility-extra-extra-extra-large
captura 30_ax_hoy hoy
captura 31_ax_segmentar "item:LEN.SIN.COMPL.0001:antes"
captura 32_ax_emparejar "item:LEN.LEX.SINON.0001:antes"
captura 33_ax_feedback "item:LEN.REC.FIGURAS.0001:despues"
xcrun simctl ui "$UDID" appearance dark
captura 34_ax_oscuro_resumen resumen

xcrun simctl ui "$UDID" content_size large
xcrun simctl ui "$UDID" appearance light
xcrun simctl status_bar "$UDID" clear
