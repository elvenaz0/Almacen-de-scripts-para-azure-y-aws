
#!/bin/bash

# Requiere AWS CLI v2 configurado con permisos para Transfer Family, S3 y Route 53

# === CONFIGURACIÓN CON DATOS REALES ===
TRANSFER_SERVER_ID="s-fd823b16f01246698"
BUCKET_NAME="s3-transfer-cloudjadelrio-prod"
HOSTED_ZONE_NAME="cloudjadelrio.com"

OUTPUT_FILE="verificacion_sftp_output.json"
echo "{" > $OUTPUT_FILE

echo "\"server_info\":" >> $OUTPUT_FILE
aws transfer describe-server --server-id "$TRANSFER_SERVER_ID" --output json >> $OUTPUT_FILE
echo "," >> $OUTPUT_FILE

echo "\"users\":" >> $OUTPUT_FILE
aws transfer list-users --server-id "$TRANSFER_SERVER_ID" --output json >> $OUTPUT_FILE
echo "," >> $OUTPUT_FILE

echo "\"s3_contents\":" >> $OUTPUT_FILE
aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --output json >> $OUTPUT_FILE
echo "," >> $OUTPUT_FILE

ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$HOSTED_ZONE_NAME" --query 'HostedZones[0].Id' --output text)

if [[ "$ZONE_ID" != "None" ]]; then
  echo "\"dns_zone_records\":" >> $OUTPUT_FILE
  aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --output json >> $OUTPUT_FILE
else
  echo "\"dns_zone_records\": { \"error\": \"Zone not found\" }" >> $OUTPUT_FILE
fi

echo "}" >> $OUTPUT_FILE

echo ""
echo "==== Archivo JSON generado: $OUTPUT_FILE ===="
