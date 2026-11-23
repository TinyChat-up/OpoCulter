#!/bin/zsh
# Genera capturas en el simulador "iPhone 16".
# Uso: scripts/capturas.sh <ruta a Educulter.app (Debug, simulador)> <carpeta de salida> [05a|05a1|lote01]
#   05a    → capturas de la Fase 05A (por defecto)
#   05a1   → pantallas que cambian en la Fase 05A.1
#   lote01 → los 38 ítems del lote 01 (LEN.ORT) antes de responder, para revisar el contenido
#   05b    → piloto premium (v2): claro, oscuro y AX5
set -euo pipefail
APP="$1"; SALIDA="$2"; CONJUNTO="${3:-05a}"
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
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" -enMemoria -semilla 42 -avatar 0 -captura "$2" > /dev/null
  sleep 7
  xcrun simctl io "$UDID" screenshot --type=png "$SALIDA/$1.png" > /dev/null 2>&1
  echo "  $1"
}

if [[ "$CONJUNTO" == "lote01" ]]; then
  xcrun simctl ui "$UDID" content_size large
  xcrun simctl ui "$UDID" appearance light
  for id in $(python3 -c "import json,sys; print(' '.join(i['id'] for i in json.load(open(sys.argv[1]))))" "${0:A:h}/../Educulter/Content/items/LEN.ORT.json"); do
    captura "${id}" "item:${id}:antes"
  done
  xcrun simctl status_bar "$UDID" clear
  exit 0
fi

if [[ "$CONJUNTO" == "05b" ]]; then
  xcrun simctl ui "$UDID" content_size large
  xcrun simctl ui "$UDID" appearance light
  echo "Modo claro"
  captura 00_bienvenida bienvenida
  captura 01_hoy hoy
  captura 02_hoy_matematicas "hoy:mates"
  captura 03_hoy_final "hoy:final"
  captura 04_globo_racha "hoy:globo"
  captura 05_perfil perfil
  captura 06_tilde_antes "item:LEN.ORT.AGU.0010:antes"
  captura 07_tilde_relleno "item:LEN.ORT.AGU.0017:relleno"
  captura 08_tilde_fallo "item:LEN.ORT.AGU.0010:despues"
  captura 09_tilde_sin_tilde_correcto "item:LEN.ORT.AGU.0012:correcto"
  captura 10_barras_antes "item:MAT.NUM.FRAREP.0002:antes"
  captura 11_barras_equivalente_relleno "item:MAT.NUM.FRAEQ.0003:relleno"
  captura 12_barras_equivalente_fallo "item:MAT.NUM.FRAEQ.0003:despues"
  captura 13_barras_dividir_antes "item:MAT.NUM.FRAREP.0003:antes"
  captura 14_barras_dividir_correcto "item:MAT.NUM.FRAEQ.0004:correcto"
  captura 15_eleccion "item:LEN.ORT.AGU.0001:antes"
  captura 16_feedback_fallo_lengua "item:LEN.ORT.AGU.0005:despues"
  captura 17_segmentar "item:LEN.SIN.COMPL.0001:relleno"
  captura 18_construir "item:MAT.NUM.FRAEQ.0005:antes"
  captura 19_numerico "item:MAT.OPE.FRACSUM.0001:antes"
  captura 20_resumen resumen
  captura 21_teoria_matematicas "teoria:MAT.NUM.FRAEQ.T01"
  captura 22_revision revision
  captura 23_camino_llega_pronto mapa
  captura 24_personajes personajes
  captura 25_avatares avatares
  echo "Modo oscuro"
  xcrun simctl ui "$UDID" appearance dark
  captura 30_oscuro_hoy hoy
  captura 31_oscuro_tilde_fallo "item:LEN.ORT.AGU.0010:despues"
  captura 32_oscuro_barras_fallo "item:MAT.NUM.FRAEQ.0003:despues"
  captura 33_oscuro_resumen resumen
  captura 34_oscuro_personajes personajes
  captura 35_oscuro_bienvenida bienvenida
  echo "Texto de accesibilidad máximo"
  xcrun simctl ui "$UDID" appearance light
  xcrun simctl ui "$UDID" content_size accessibility-extra-extra-extra-large
  captura 40_ax_hoy hoy
  captura 41_ax_tilde "item:LEN.ORT.AGU.0017:antes"
  captura 42_ax_barras_dividir "item:MAT.NUM.FRAREP.0003:relleno"
  captura 43_ax_feedback "item:MAT.NUM.FRAEQ.0003:despues"
  captura 44_ax_perfil perfil
  xcrun simctl ui "$UDID" content_size large
  xcrun simctl status_bar "$UDID" clear
  exit 0
fi

if [[ "$CONJUNTO" == "05a1" ]]; then
  xcrun simctl ui "$UDID" content_size large
  xcrun simctl ui "$UDID" appearance light
  echo "Modo claro"
  captura 00_hoy hoy
  captura 01_hoy_final "hoy:final"
  captura 02_globo_racha "hoy:globo"
  captura 03_eleccion_cabecera "item:LEN.ORT.AGU.0001:antes"
  captura 04_feedback_no_es_correcto_lengua "item:LEN.ORT.AGU.0005:despues"
  captura 05_feedback_no_es_correcto_mates "item:MAT.OPE.FRACSUM.0001:despues"
  captura 06_feedback_correcto_xp "item:LEN.ORT.HOM.0001:correcto"
  captura 07_segmentar_antes "item:LEN.SIN.COMPL.0001:antes"
  captura 08_segmentar_relleno "item:LEN.SIN.COMPL.0001:relleno"
  captura 09_segmentar_despues "item:LEN.SIN.COMPL.0001:despues"
  captura 10_construir_largo "item:LEN.ORT.AGU.0008:antes"
  captura 11_construir_largo_relleno "item:LEN.ORT.AGU.0008:relleno"
  captura 12_construir_mi "item:LEN.ORT.DIA.0008:antes"
  captura 13_construir_pq "item:LEN.ORT.PQ.0006:despues"
  captura 14_marcar_coma "item:LEN.ORT.DIA.0005:antes"
  captura 15_marcar_coma_despues "item:LEN.ORT.DIA.0005:despues"
  captura 16_marcar_silabas "item:LEN.ORT.AGU.0003:antes"
  captura 17_clasificar_tres "item:LEN.ORT.AGU.0002:antes"
  captura 18_emparejar_seis "item:LEN.ORT.DIA.0003:antes"
  captura 19_verdadero_falso "item:LEN.ORT.AGU.0004:antes"
  captura 20_numerico "item:MAT.OPE.FRACSUM.0001:antes"
  captura 21_resumen resumen
  captura 22_teoria_agudas "teoria:LEN.ORT.AGU.T01"
  captura 23_teoria_diacritica "teoria:LEN.ORT.DIA.T01"
  captura 24_teoria_hiato "teoria:LEN.ORT.HIA.T01"
  captura 25_teoria_porque "teoria:LEN.ORT.PQ.T01"
  captura 26_teoria_homofonos "teoria:LEN.ORT.HOM.T01"
  captura 27_revision revision
  echo "Modo oscuro"
  xcrun simctl ui "$UDID" appearance dark
  captura 30_oscuro_hoy hoy
  captura 31_oscuro_segmentar "item:LEN.SIN.COMPL.0001:relleno"
  captura 32_oscuro_feedback "item:LEN.ORT.AGU.0005:despues"
  captura 33_oscuro_resumen resumen
  captura 34_oscuro_globo "hoy:globo"
  echo "Texto de accesibilidad máximo"
  xcrun simctl ui "$UDID" appearance light
  xcrun simctl ui "$UDID" content_size accessibility-extra-extra-extra-large
  captura 40_ax_hoy hoy
  captura 41_ax_cabecera "item:LEN.ORT.AGU.0001:antes"
  captura 42_ax_segmentar "item:LEN.SIN.COMPL.0001:antes"
  captura 43_ax_construir "item:LEN.ORT.AGU.0008:antes"
  captura 44_ax_feedback "item:LEN.ORT.AGU.0005:despues"
  xcrun simctl ui "$UDID" content_size large
  xcrun simctl status_bar "$UDID" clear
  exit 0
fi

# Ítems de demostración (uno por mecánica).
typeset -A ITEMS
ITEMS=(01_eleccion LEN.REC.FIGURAS.0001 02_verdaderoFalso LEN.CLA.SUSTADJ.0002 03_clasificar LEN.CLA.SUSTADJ.0001
       04_ordenar LEN.LIT.CRONO.0001 05_emparejar LEN.LEX.SINON.0001 06_marcarTexto LEN.CLA.VERBO.0001
       07_segmentar LEN.SIN.COMPL.0001 08_ruedas LEN.VER.ANALISIS.0001 09_construir LEN.ORT.AGU.0008 10_numerico MAT.OPE.FRACSUM.0001)

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
captura 13_teoria_esquema "teoria:LEN.ORT.AGU.T01"
captura 14_llega_pronto mapa
captura 15_revision revision

echo "Modo oscuro"
xcrun simctl ui "$UDID" appearance dark
captura 20_oscuro_hoy hoy
captura 21_oscuro_segmentar "item:LEN.SIN.COMPL.0001:despues"
captura 22_oscuro_numerico "item:MAT.OPE.FRACSUM.0001:antes"
captura 23_oscuro_feedback "item:LEN.REC.FIGURAS.0001:despues"
captura 24_oscuro_resumen resumen
captura 25_oscuro_teoria "teoria:LEN.ORT.AGU.T01"

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
