
#!/bin/bash

# Requiere AWS CLI v2 configurado con permisos para Transfer Family, S3 y Route 53

# === CONFIGURACIÓN CON DATOS REALES ===
TRANSFER_SERVER_ID="s-fd823b16f01246698"
BUCKET_NAME="s3-transfer-cloudjadelrio-prod"  # Asumido a partir del patrón de uso
HOSTED_ZONE_NAME="cloudjadelrio.com"

echo "==== 1. Información del servidor SFTP ($TRANSFER_SERVER_ID) ===="
aws transfer describe-server --server-id "$TRANSFER_SERVER_ID"

echo ""
echo "==== 2. Lista de usuarios asociados al servidor SFTP ===="
aws transfer list-users --server-id "$TRANSFER_SERVER_ID"

echo ""
echo "==== 3. Contenido del bucket S3 asociado ($BUCKET_NAME) ===="
aws s3 ls "s3://$BUCKET_NAME/" --recursive

echo ""
echo "==== 4. Búsqueda de registros DNS en Route 53 ($HOSTED_ZONE_NAME) ===="
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$HOSTED_ZONE_NAME" --query 'HostedZones[0].Id' --output text)

if [[ "$ZONE_ID" != "None" ]]; then
  echo "Zona encontrada: $ZONE_ID"
  echo "Registros en $HOSTED_ZONE_NAME:"
  aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --output table
else
  echo "No se encontró la zona DNS en Route 53 para $HOSTED_ZONE_NAME"
fi

echo ""
echo "==== Validación completada. Asegúrate de respaldar todo antes de eliminar el servidor. ===="
