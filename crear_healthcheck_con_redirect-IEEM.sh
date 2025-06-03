#!/bin/bash

DOMAIN="intranet.ieem.org.mx"
IP="34.196.211.135"
PORT=443
TYPE="HTTPS"
REGION="us-east-1"

echo "🚀 Creando Health Check para $DOMAIN con seguimiento de redirecciones..."

CREATE_OUTPUT=$(aws route53 create-health-check --caller-reference "$(date +%s)"   --health-check-config '{
    "IPAddress": "'$IP'",
    "Port": '$PORT',
    "Type": "'$TYPE'",
    "ResourcePath": "/",
    "RequestInterval": 30,
    "FailureThreshold": 3,
    "EnableSNI": true,
    "MeasureLatency": true,
    "Regions": ["sa-east-1", "us-east-1", "us-west-1"],
    "Inverted": false,
    "Disabled": false,
    "FullyQualifiedDomainName": "'$DOMAIN'",
    "SearchString": "",
    "EnableFollowRedirects": true
  }' --region $REGION)

HEALTH_CHECK_ID=$(echo $CREATE_OUTPUT | jq -r '.HealthCheck.Id')
echo "✅ Health Check creado con ID: $HEALTH_CHECK_ID"
