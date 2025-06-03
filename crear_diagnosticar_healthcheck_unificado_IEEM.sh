#!/bin/bash

# Parámetros
DOMAIN="intranet.ieem.org.mx"
IP="34.196.211.135"
PORT=443  # HTTPS
TYPE="HTTPS"
REGION="us-east-1"

echo "🚀 Creando Health Check para $DOMAIN solo en regiones específicas..."

# Crear Health Check con MeasureLatency habilitado y mínimo 3 regiones
CREATE_OUTPUT=$(aws route53 create-health-check --caller-reference "$(date +%s)"   --health-check-config '{
    "IPAddress": "'$IP'",
    "Port": '$PORT',
    "Type": "'$TYPE'",
    "ResourcePath": "/",
    "RequestInterval": 30,
    "FailureThreshold": 3,
    "MeasureLatency": true,
    "Regions": ["sa-east-1", "us-east-1", "us-west-1"]
  }' --region $REGION)

HEALTH_CHECK_ID=$(echo $CREATE_OUTPUT | jq -r '.HealthCheck.Id')

if [ -z "$HEALTH_CHECK_ID" ]; then
  echo "❌ Error: No se pudo obtener el ID del Health Check."
  exit 1
fi

echo "✅ Health Check creado con ID: $HEALTH_CHECK_ID"

# Esperar para que el Health Check esté disponible
echo "⏳ Esperando 15 segundos para inicialización..."
sleep 15

# Consultar estado del Health Check
echo "🔍 Consultando estado..."
STATE_JSON=$(aws route53 get-health-check-status --health-check-id $HEALTH_CHECK_ID --region $REGION)

# Consultar métricas en CloudWatch
echo "📊 Obteniendo métricas de CloudWatch..."
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_TIME=$(date -u -d '-1 hour' +"%Y-%m-%dT%H:%M:%SZ")

METRICS_JSON=$(aws cloudwatch get-metric-statistics --namespace AWS/Route53 --metric-name HealthCheckStatus   --dimensions Name=HealthCheckId,Value=$HEALTH_CHECK_ID   --start-time $START_TIME --end-time $END_TIME --period 300   --statistics Average --region $REGION)

# Unificar todo en un solo archivo JSON
echo "{" > healthcheck_full_report_$HEALTH_CHECK_ID.json
echo "  \"HealthCheckId\": \"$HEALTH_CHECK_ID\"," >> healthcheck_full_report_$HEALTH_CHECK_ID.json
echo "  \"HealthCheckStatus\": $STATE_JSON," >> healthcheck_full_report_$HEALTH_CHECK_ID.json
echo "  \"CloudWatchMetrics\": $METRICS_JSON" >> healthcheck_full_report_$HEALTH_CHECK_ID.json
echo "}" >> healthcheck_full_report_$HEALTH_CHECK_ID.json

echo "✅ Reporte completo guardado en: healthcheck_full_report_$HEALTH_CHECK_ID.json"
