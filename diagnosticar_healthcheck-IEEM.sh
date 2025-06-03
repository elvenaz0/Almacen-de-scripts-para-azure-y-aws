#!/bin/bash

# Reemplaza este ID con tu Health Check real
HEALTH_CHECK_ID=$1
REGION="us-east-1"

if [ -z "$HEALTH_CHECK_ID" ]; then
  echo "❌ Debes proporcionar el Health Check ID. Ejemplo:"
  echo "./diagnosticar_healthcheck.sh <health-check-id>"
  exit 1
fi

echo "🔍 Consultando configuración del Health Check..."
aws route53 get-health-check --health-check-id $HEALTH_CHECK_ID --region $REGION > healthcheck_config_$HEALTH_CHECK_ID.json

echo "✅ Configuración guardada en: healthcheck_config_$HEALTH_CHECK_ID.json"

echo "🔍 Consultando estado detallado del Health Check..."
aws route53 get-health-check-status --health-check-id $HEALTH_CHECK_ID --region $REGION > healthcheck_status_$HEALTH_CHECK_ID.json

echo "✅ Estado guardado en: healthcheck_status_$HEALTH_CHECK_ID.json"

echo "🔍 Consultando historial de eventos del Health Check (CloudWatch, si configurado)..."
# Aquí se podría agregar integración con CloudWatch Logs si tienes alarmas configuradas
# Ejemplo: aws cloudwatch describe-alarms --query 'MetricAlarms[?Dimensions[?Name==`HealthCheckId` && Value==`$HEALTH_CHECK_ID`]]'

echo "ℹ️ Revisa los archivos generados para identificar detalles de la causa del mal estado."
