#!/bin/bash

WORKSPACE_ID=ws-b554csl05
REGION="us-east-1"

if [ -z "$WORKSPACE_ID" ]; then
  echo "❌ Debes proporcionar el Workspace ID. Ejemplo:"
  echo "./validar_workspace.sh ws-xxxxxxxxxx"
  exit 1
fi

echo "🔍 Obteniendo estado general del Workspace..."
aws workspaces describe-workspaces --workspace-ids $WORKSPACE_ID --region $REGION > ${WORKSPACE_ID}_describe.json

echo "✅ Guardado: ${WORKSPACE_ID}_describe.json"

echo "🔍 Verificando estado del directorio asociado..."
DIR_ID=$(jq -r '.Workspaces[0].DirectoryId' ${WORKSPACE_ID}_describe.json)
aws ds describe-directories --directory-ids $DIR_ID --region $REGION > ${DIR_ID}_directory.json

echo "✅ Guardado: ${DIR_ID}_directory.json"

echo "🔍 Verificando subred y recursos de red..."
SUBNET_ID=$(jq -r '.Workspaces[0].SubnetId' ${WORKSPACE_ID}_describe.json)
aws ec2 describe-subnets --subnet-ids $SUBNET_ID --region $REGION > ${SUBNET_ID}_subnet.json

echo "✅ Guardado: ${SUBNET_ID}_subnet.json"

echo "🔍 Verificando límites de WorkSpaces en la cuenta..."
aws service-quotas list-service-quotas --service-code workspaces --region $REGION > workspaces_limits.json

echo "✅ Guardado: workspaces_limits.json"

echo "🔍 Verificando capacidad de la zona de disponibilidad..."
AZ=$(jq -r '.Subnets[0].AvailabilityZone' ${SUBNET_ID}_subnet.json)
echo "⚠ Esto debe validarse manualmente para disponibilidad puntual en la AZ: $AZ"

echo "✅ Revisión inicial completada. Archivos generados:"
echo "- ${WORKSPACE_ID}_describe.json"
echo "- ${DIR_ID}_directory.json"
echo "- ${SUBNET_ID}_subnet.json"
echo "- workspaces_limits.json"
