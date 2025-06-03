#!/bin/bash

HEALTH_CHECK_ID=$1
ALARM_NAME="Alarm-HealthCheck-$HEALTH_CHECK_ID"
SNS_TOPIC_ARN="arn:aws:sns:us-east-1:123456789012:MyAlerts"  # Reemplaza con tu SNS real
REGION="us-east-1"

if [ -z "$HEALTH_CHECK_ID" ]; then
  echo "❌ Debes proporcionar el Health Check ID. Ejemplo:"
  echo "./crear_alarma_cloudwatch.sh <health-check-id>"
  exit 1
fi

echo "🚨 Creando alarma en CloudWatch para $HEALTH_CHECK_ID..."

aws cloudwatch put-metric-alarm --alarm-name "$ALARM_NAME"   --metric-name HealthCheckStatus --namespace AWS/Route53   --statistic Minimum --period 60 --threshold 1   --comparison-operator LessThanThreshold   --dimensions Name=HealthCheckId,Value=$HEALTH_CHECK_ID   --evaluation-periods 1 --alarm-actions $SNS_TOPIC_ARN   --region $REGION

echo "✅ Alarma creada: $ALARM_NAME"
