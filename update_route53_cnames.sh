#!/bin/bash

set -e

# --- Dominio base ---
DOMAIN="ieem.org.mx"

# --- Nuevos CNAMEs y destinos de CloudFront ---
declare -A CNAMES
CNAMES["eleccionjudicial2025.ieem.org.mx"]="d3lbgwd7xjihjbb.cloudfront.net"
CNAMES["judicial2025.ieem.org.mx"]="d3hu6begid9v2n.cloudfront.net"

# --- Obtener Hosted Zone ID ---
echo "🔎 Buscando Hosted Zone ID para $DOMAIN..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "$DOMAIN" \
  --query "HostedZones[0].Id" \
  --output text | cut -d'/' -f3)

if [ -z "$HOSTED_ZONE_ID" ]; then
  echo "❌ No se pudo encontrar la zona hospedada para $DOMAIN"
  exit 1
fi

echo "✅ Hosted Zone ID encontrada: $HOSTED_ZONE_ID"

# --- Crear archivo JSON para cambios ---
JSON_FILE="route53-cnames-update.json"
echo "🛠️ Generando archivo $JSON_FILE..."

{
  echo '{'
  echo '  "Comment": "Actualizar CNAMEs para CloudFront IEEM 2025",'
  echo '  "Changes": ['

  FIRST=true
  for NAME in "${!CNAMES[@]}"; do
    if [ "$FIRST" = true ]; then
      FIRST=false
    else
      echo '    ,'
    fi

    cat <<EOF
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$NAME.",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "${CNAMES[$NAME]}"
          }
        ]
      }
    }
EOF
  done

  echo '  ]'
  echo '}'
} > "$JSON_FILE"

echo "📤 Aplicando cambios en Route 53..."
aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file://"$JSON_FILE"

# --- Validación con dig ---
echo "🔍 Validando CNAMEs creados..."
RESULTS=()
for NAME in "${!CNAMES[@]}"; do
  TARGET=$(dig +short "$NAME")
  STATUS="❌ NO APUNTA"
  if [[ "$TARGET" == "${CNAMES[$NAME]}"* ]]; then
    STATUS="✅ OK"
  fi
  RESULTS+=("{\"name\":\"$NAME\",\"expected\":\"${CNAMES[$NAME]}\",\"actual\":\"$TARGET\",\"status\":\"$STATUS\"}")
done

# --- Guardar resultado en JSON ---
VALIDATION_FILE="route53_validation_$(date +%Y%m%d_%H%M%S).json"
jq -n --arg domain "$DOMAIN" \
  --arg zone_id "$HOSTED_ZONE_ID" \
  --argjson results "[${RESULTS[*]}]" \
  '{domain: $domain, hosted_zone_id: $zone_id, validation: $results}' \
  > "$VALIDATION_FILE"

echo "📝 Resultado de validación guardado en $VALIDATION_FILE"
