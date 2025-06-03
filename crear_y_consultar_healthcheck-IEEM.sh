#!/bin/bash

# Datos
DOMAIN="intranet.ieem.org.mx"
IP="34.196.211.135"
PORT=443  # Usa 80 si es HTTP, 443 si es HTTPS
TYPE="HTTPS"
REGION="us-east-1"

echo "🚀 Creando Health Check para $DOMAIN..."

# Crear Health Check
CREATE_OUTPUT=$(aws route53 create-health-check --caller-reference "$(date +%s)"   --health-check-config '{
    "IPAddress": "'$IP'",
    "Port": '$PORT',
    "Type": "'$TYPE'",
    "ResourcePath": "/",
    "RequestInterval": 30,
    "FailureThreshold": 3
  }' --region $REGION)

HEALTH_CHECK_ID=$(echo $CREATE_OUTPUT | jq -r '.HealthCheck.Id')

echo "✅ Health Check creado con ID: $HEALTH_CHECK_ID"

# Consultar estado del Health Check
echo "🔍 Consultando estado del Health Check..."
aws route53 get-health-check-status --health-check-id $HEALTH_CHECK_ID --region $REGION > healthcheck_status_$HEALTH_CHECK_ID.json

echo "✅ Resultado guardado en: healthcheck_status_$HEALTH_CHECK_ID.json"
