#!/bin/bash

# =========================
# CONFIGURACIÓN
# =========================
REGIONES=("us-east-1" "us-west-2" "us-east-2" "us-west-1")
FECHA=$(date +'%Y%m%d_%H%M%S')
COSTO_GB=0.05
CARPETA_S3="s3://elvenazshitnottouch/carpeta de pruebas para scripts"

# Validación de jq
if ! command -v jq &> /dev/null; then
  echo "jq no está instalado. Instálalo para continuar."
  exit 1
fi

barra_progreso() {
  local mensaje=$1
  echo -n "🔄 $mensaje..."
  for i in {1..3}; do echo -n "."; sleep 0.4; done
  echo " ✅"
}

formato_bytes_a_gb() {
  local bytes=$1
  awk "BEGIN { printf \"%.2f\", $bytes/1073741824 }"
}

# =========================
# INICIO DEL LOOP POR REGIÓN
# =========================
for REGION in "${REGIONES[@]}"; do
  OUTPUT="reporte_aws_backup_${REGION}_${FECHA}.json"
  OUTPUT_MD="reporte_aws_backup_${REGION}_${FECHA}.md"
  TMP="tmp_$OUTPUT"

  echo "{" > "$TMP"
  echo "  \"Fecha\": \"$(date)\"," >> "$TMP"
  echo "  \"Región\": \"$REGION\"," >> "$TMP"

  # ========= Planes de Backup =========
  barra_progreso "Obteniendo planes de backup en $REGION"
  echo "  \"PlanesDeBackup\": [" >> "$TMP"
  PLANES=$(aws backup list-backup-plans --region "$REGION" --output json | jq -c '.BackupPlansList[]')
  PLAN_TOTAL=$(echo "$PLANES" | wc -l)
  i=0
  echo "$PLANES" | while read -r PLAN; do
    PLAN_ID=$(echo "$PLAN" | jq -r '.BackupPlanId')
    DETALLE=$(aws backup get-backup-plan --backup-plan-id "$PLAN_ID" --region "$REGION" --output json)
    SELECCIONES=$(aws backup list-backup-selections --backup-plan-id "$PLAN_ID" --region "$REGION" --output json | jq -c '.BackupSelectionsList[]?' | while read -r SEL; do
      SEL_ID=$(echo "$SEL" | jq -r '.SelectionId')
      aws backup get-backup-selection --backup-plan-id "$PLAN_ID" --selection-id "$SEL_ID" --region "$REGION" --output json
    done | jq -s '.')

    echo "    {" >> "$TMP"
    echo "      \"BackupPlanId\": \"$PLAN_ID\"," >> "$TMP"
    echo "      \"Detalle\": $DETALLE," >> "$TMP"
    echo "      \"Selecciones\": $SELECCIONES" >> "$TMP"
    i=$((i + 1))
    [[ "$i" -lt "$PLAN_TOTAL" ]] && echo "    }," || echo "    }"
  done >> "$TMP"
  echo "  ]," >> "$TMP"

  # ========= Recursos y Vaults =========
  barra_progreso "Obteniendo recursos protegidos y vaults"
  RESOURCES=$(aws backup list-protected-resources --region "$REGION" --output json)
  VAULTS=$(aws backup list-backup-vaults --region "$REGION" --output json)
  echo "  \"RecursosProtegidos\": $RESOURCES," >> "$TMP"
  echo "  \"VaultsDeBackup\": $VAULTS," >> "$TMP"

  # ========= Recovery Points + Costos =========
  echo "  \"PuntosDeRecuperacion\": [" >> "$TMP"
  COSTO_TOTAL=0
  echo "$VAULTS" | jq -c '.BackupVaultList[]?' | while read -r VAULT; do
    VAULT_NAME=$(echo "$VAULT" | jq -r '.BackupVaultName')
    RP=$(aws backup list-recovery-points-by-backup-vault --backup-vault-name "$VAULT_NAME" --region "$REGION" --output json)
    BYTES=$(echo "$RP" | jq '[.RecoveryPoints[].BackupSizeInBytes] | add // 0')
    GB=$(formato_bytes_a_gb "$BYTES")
    COSTO=$(awk "BEGIN { printf \"%.2f\", $GB * $COSTO_GB }")
    COSTO_TOTAL=$(awk "BEGIN { printf \"%.2f\", $COSTO_TOTAL + $COSTO }")
    echo "    {\"Vault\": \"$VAULT_NAME\", \"CostoEstimadoUSD\": $COSTO, \"RecoveryPoints\": $RP}," >> "$TMP"
  done | sed '$ s/,$//' >> "$TMP"
  echo "  ]," >> "$TMP"
  echo "  \"CostoTotalEstimadoUSD\": $COSTO_TOTAL" >> "$TMP"
  echo "}" >> "$TMP"

  mv "$TMP" "$OUTPUT"
  echo "✅ JSON generado: $OUTPUT"

  # ========= Generar Markdown =========
  echo "# 📊 Reporte AWS Backup – Región $REGION" > "$OUTPUT_MD"
  echo "**Fecha:** $(date)" >> "$OUTPUT_MD"
  echo -e "\n## 🔐 Total estimado en USD: **\$${COSTO_TOTAL}**\n" >> "$OUTPUT_MD"

  if [[ "$REGION" == "us-east-1" ]]; then
    echo "La región **$REGION** tiene múltiples planes activos, respaldos recientes y recursos protegidos (EC2)." >> "$OUTPUT_MD"
  else
    echo "La región **$REGION** tiene planes definidos pero **no hay recursos asociados ni respaldos ejecutados aún**." >> "$OUTPUT_MD"
  fi

  echo -e "\nLos detalles completos están disponibles en el archivo JSON generado.\n" >> "$OUTPUT_MD"
  echo "✅ Markdown generado: $OUTPUT_MD"

  # ========= Subida a S3 =========
  echo "📤 Subiendo archivos a S3..."
  aws s3 cp "$OUTPUT" "$CARPETA_S3/$OUTPUT"
  aws s3 cp "$OUTPUT_MD" "$CARPETA_S3/$OUTPUT_MD"

  if [ $? -eq 0 ]; then
    echo "✅ Archivos subidos a: $CARPETA_S3"
  else
    echo "❌ Error al subir archivos a S3."
  fi

done
