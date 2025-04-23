#!/bin/bash

# Intenta obtener la región por defecto
REGION=$(aws configure get region)

# Si la región no está definida, se asigna una por defecto
if [ -z "$REGION" ]; then
  REGION="us-east-1"
fi

# Archivos de salida
OUTPUT_FILE="reporte_costos_aws_$(date +'%Y%m%d_%H%M%S').json"

# Cabecera del reporte
{
echo "{\"Reporte de Costos de AWS\": {"
echo "  \"Fecha\": \"$(date)\","
echo "  \"Región\": \"$REGION\","
echo "  \"Costos\": {"
} > "$OUTPUT_FILE"

# Costos de Backups
BACKUP_PLANS=$(aws backup list-backup-plans --region "$REGION" --query 'BackupPlansList' --output json 2>/dev/null | jq length)
if [ $? -eq 0 ]; then
  echo "    \"AWS Backups\": {\"Numero de Planes de Respaldo\": $BACKUP_PLANS}," >> "$OUTPUT_FILE"
else
  echo "    \"AWS Backups\": {\"Numero de Planes de Respaldo\": 0}," >> "$OUTPUT_FILE"
fi

# Costos de otros servicios
SERVICES=("S3" "DynamoDB" "EC2")
for SERVICE in "${SERVICES[@]}"; do
  COSTO=$(aws ce get-cost-and-usage \
    --region "$REGION" \
    --time-period Start=$(date -u +'%Y-%m-%d'),End=$(date -u +'%Y-%m-%d') \
    --granularity DAILY \
    --metrics AmortizedCost \
    --filter "{\"Dimensions\":{\"Key\":\"SERVICE\",\"Values\":[\"$SERVICE\"]}}" \
    --output json 2>/dev/null | jq -r '.ResultsByTime[0].Total.AmortizedCost.Amount')

  if [[ "$COSTO" == "null" || -z "$COSTO" ]]; then
    COSTO="0"
  fi

  echo "    \"$SERVICE\": {\"Costo\": \"$COSTO\"}," >> "$OUTPUT_FILE"
done

# Eliminar la última coma correctamente
# Extrae todas las líneas menos la última, luego modifica la penúltima
TMP_FILE="${OUTPUT_FILE}.tmp"
head -n -1 "$OUTPUT_FILE" > "$TMP_FILE"
sed '$ s/,$//' "$TMP_FILE" > "$OUTPUT_FILE"
rm "$TMP_FILE"

# Cierre del JSON
{
echo "  }"
echo "}}"
} >> "$OUTPUT_FILE"

echo "Reporte generado: $OUTPUT_FILE"
