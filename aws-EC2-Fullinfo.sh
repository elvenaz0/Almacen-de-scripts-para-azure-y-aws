#!/bin/bash

REGIONES=("us-east-1")
FECHA=$(date +'%Y%m%d_%H%M%S')
CARPETA_S3="s3://elvenazshitnottouch/carpeta de pruebas para scripts"
COSTO_ESTIMADO_POR_INSTANCIA_HORA=0.10  # Aproximado si no se desea usar Pricing API

# Validación de jq
if ! command -v jq &> /dev/null; then
  echo "⚠️  jq no está instalado. Instálalo antes de continuar."
  exit 1
fi

barra_progreso() {
  local mensaje=$1
  echo -n "🔄 $mensaje..."
  for i in {1..3}; do echo -n "."; sleep 0.4; done
  echo " ✅"
}

for REGION in "${REGIONES[@]}"; do
  OUTPUT="reporte_ec2_${REGION}_${FECHA}.json"
  OUTPUT_MD="reporte_ec2_${REGION}_${FECHA}.md"
  TMP="tmp_$OUTPUT"

  echo "{" > "$TMP"
  echo "  \"Fecha\": \"$(date)\"," >> "$TMP"
  echo "  \"Región\": \"$REGION\"," >> "$TMP"

  barra_progreso "Obteniendo información de instancias EC2 en $REGION"
  INSTANCIAS=$(aws ec2 describe-instances --region "$REGION" --output json)

  INST_COUNT=$(echo "$INSTANCIAS" | jq '[.Reservations[].Instances[]] | length')
  echo "  \"NumeroDeInstancias\": $INST_COUNT," >> "$TMP"

  # Obtener detalles de instancias
  echo "  \"Instancias\": [" >> "$TMP"
  echo "$INSTANCIAS" | jq -c '.Reservations[].Instances[]' | while read -r INST; do
    INSTANCE_ID=$(echo "$INST" | jq -r '.InstanceId')
    INSTANCE_TYPE=$(echo "$INST" | jq -r '.InstanceType')
    STATE=$(echo "$INST" | jq -r '.State.Name')
    ZONE=$(echo "$INST" | jq -r '.Placement.AvailabilityZone')
    PUBLIC_IP=$(echo "$INST" | jq -r '.PublicIpAddress // "N/A"')
    PRIVATE_IP=$(echo "$INST" | jq -r '.PrivateIpAddress')
    LAUNCH_TIME=$(echo "$INST" | jq -r '.LaunchTime')
    AMI_ID=$(echo "$INST" | jq -r '.ImageId')
    TAGS=$(echo "$INST" | jq -c '.Tags // []')
    VOLUMENES=$(aws ec2 describe-volumes --region "$REGION" --filters Name=attachment.instance-id,Values="$INSTANCE_ID" --output json | jq -c '.Volumes')

    COSTO_HORA=$COSTO_ESTIMADO_POR_INSTANCIA_HORA
    COSTO_MES=$(awk "BEGIN { printf \"%.2f\", $COSTO_HORA * 24 * 30 }")

    echo "    {" >> "$TMP"
    echo "      \"InstanceId\": \"$INSTANCE_ID\"," >> "$TMP"
    echo "      \"Estado\": \"$STATE\"," >> "$TMP"
    echo "      \"Tipo\": \"$INSTANCE_TYPE\"," >> "$TMP"
    echo "      \"Zona\": \"$ZONE\"," >> "$TMP"
    echo "      \"IP_Publica\": \"$PUBLIC_IP\"," >> "$TMP"
    echo "      \"IP_Privada\": \"$PRIVATE_IP\"," >> "$TMP"
    echo "      \"AMI\": \"$AMI_ID\"," >> "$TMP"
    echo "      \"Etiquetas\": $TAGS," >> "$TMP"
    echo "      \"VolumenesEBS\": $VOLUMENES," >> "$TMP"
    echo "      \"CostoEstimadoMensualUSD\": \"$COSTO_MES\"" >> "$TMP"
    echo "    }," >> "$TMP"
  done | sed '$ s/,$//' >> "$TMP"
  echo "  ]" >> "$TMP"
  echo "}" >> "$TMP"
  mv "$TMP" "$OUTPUT"
  echo "✅ JSON generado: $OUTPUT"

  # =========================
  # Markdown explicativo
  # =========================
  echo "# 📄 Reporte de EC2 – Región $REGION" > "$OUTPUT_MD"
  echo "**Fecha:** $(date)" >> "$OUTPUT_MD"
  echo -e "\n## 📊 Resumen de instancias" >> "$OUTPUT_MD"
  echo "- Total de instancias: $INST_COUNT" >> "$OUTPUT_MD"

  if [ "$INST_COUNT" -eq 0 ]; then
    echo "- ⚠️ No se encontraron instancias EC2 en esta región." >> "$OUTPUT_MD"
  else
    echo -e "\n### Detalle por instancia:" >> "$OUTPUT_MD"
    echo "$INSTANCIAS" | jq -r '.Reservations[].Instances[] | "- ID: \(.InstanceId) | Tipo: \(.InstanceType) | Estado: \(.State.Name) | IP Privada: \(.PrivateIpAddress) | AMI: \(.ImageId)"' >> "$OUTPUT_MD"
  fi

  echo -e "\n✅ Reporte generado correctamente.\n" >> "$OUTPUT_MD"

  # =========================
  # Subida a S3
  # =========================
  echo "📤 Subiendo archivos a S3..."
  aws s3 cp "$OUTPUT" "$CARPETA_S3/$OUTPUT"
  aws s3 cp "$OUTPUT_MD" "$CARPETA_S3/$OUTPUT_MD"

  if [ $? -eq 0 ]; then
    echo "✅ Archivos subidos a: $CARPETA_S3"
  else
    echo "❌ Error al subir archivos a S3."
  fi

done
