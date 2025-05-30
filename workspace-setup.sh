#!/bin/sh
# Script para crear un AD Connector y un WorkSpace en AWS.
# Requiere AWS CLI y jq instalados.

set -e

# === CONFIGURACION ===
DIRECTORY_NAME="multiva-ws"
DOMAIN_NAME="multivaloresgf.local"
CONNECTOR_USER="aws.cloud"
CONNECTOR_PASSWORD="multiva2025"
VPC_ID="vpc-0813782c20119079a"
SUBNET_1="subnet-0b1010b0f001706d5"
SUBNET_2="subnet-0daf1490687914fb8"
DNS1="10.160.14.3"
DNS2="10.160.14.156"
REGION="us-east-1"

# Parametros del WorkSpace
USER_NAME="eduardo.mazariego.ex"
BUNDLE_ID="wsb-6gkrxc3bt"
WORKSPACE_NAME="Workspace-Eduardo"
OUTPUT_FILE="workspace_created.json"

# Verificar dependencias
command -v aws >/dev/null 2>&1 || { echo "aws CLI no encontrado" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq no encontrado" >&2; exit 1; }

# Crear archivo de configuracion JSON para el AD Connector
cat > connect-settings.json <<CONF
{
  "VpcId": "$VPC_ID",
  "SubnetIds": ["$SUBNET_1", "$SUBNET_2"],
  "CustomerDnsIps": ["$DNS1", "$DNS2"],
  "CustomerUserName": "$CONNECTOR_USER"
}
CONF

echo "Creando AD Connector '$DIRECTORY_NAME' en $REGION..."
CREATE_OUTPUT=$(aws ds create-directory \
    --name "$DOMAIN_NAME" \
    --short-name "$DIRECTORY_NAME" \
    --password "$CONNECTOR_PASSWORD" \
    --size Small \
    --type ADConnector \
    --connect-settings file://connect-settings.json \
    --region "$REGION")

NEW_DIRECTORY_ID=$(echo "$CREATE_OUTPUT" | jq -r '.DirectoryId')

if [ -z "$NEW_DIRECTORY_ID" ]; then
    echo "No se pudo obtener el ID del directorio" >&2
    exit 1
fi

echo "Directorio creado: $NEW_DIRECTORY_ID"
echo "Esperando a que el directorio este 'Active'..."

while :; do
    STATE=$(aws ds describe-directories \
        --directory-ids "$NEW_DIRECTORY_ID" \
        --query "DirectoryDescriptions[0].Stage" \
        --output text \
        --region "$REGION")

    echo "Estado actual: $STATE"
    if [ "$STATE" = "Active" ]; then
        break
    elif [ "$STATE" = "Failed" ]; then
        echo "Error: el AD Connector fallo en su creacion" >&2
        exit 1
    fi
    sleep 15
done

echo "AD Connector listo. Creando WorkSpace..."

cat > workspace-config.json <<WS
[
  {
    "DirectoryId": "$NEW_DIRECTORY_ID",
    "UserName": "$USER_NAME",
    "BundleId": "$BUNDLE_ID",
    "WorkspaceProperties": {
      "RunningMode": "AUTO_STOP",
      "RunningModeAutoStopTimeoutInMinutes": 60,
      "RootVolumeSizeGib": 80,
      "UserVolumeSizeGib": 100,
      "ComputeTypeName": "POWER"
    },
    "Tags": [
      { "Key": "Name", "Value": "$WORKSPACE_NAME" }
    ]
  }
]
WS

aws workspaces create-workspaces \
    --region "$REGION" \
    --workspaces file://workspace-config.json >/dev/null

echo "Esperando a que el WorkSpace este 'AVAILABLE'..."

while :; do
    STATE=$(aws workspaces describe-workspaces \
        --directory-id "$NEW_DIRECTORY_ID" \
        --user-name "$USER_NAME" \
        --query "Workspaces[0].State" \
        --output text \
        --region "$REGION")

    echo "Estado actual: $STATE"
    if [ "$STATE" = "AVAILABLE" ]; then
        break
    elif [ "$STATE" = "ERROR" ] || [ "$STATE" = "SUSPENDED" ]; then
        echo "Error: el WorkSpace no pudo crearse correctamente (estado: $STATE)" >&2
        exit 1
    fi
    sleep 15
done

aws workspaces describe-workspaces \
    --directory-id "$NEW_DIRECTORY_ID" \
    --user-name "$USER_NAME" \
    --output json \
    --region "$REGION" > "$OUTPUT_FILE"

IP=$(jq -r '.Workspaces[0].IpAddress' < "$OUTPUT_FILE")
SUBNET=$(jq -r '.Workspaces[0].SubnetId' < "$OUTPUT_FILE")
STATE=$(jq -r '.Workspaces[0].State' < "$OUTPUT_FILE")

echo ""
echo "WorkSpace creado correctamente" 
echo "IP: $IP" 
echo "Subred: $SUBNET" 
echo "Estado final: $STATE" 
echo "Detalles guardados en: $OUTPUT_FILE"

# Limpieza de archivos temporales
rm -f connect-settings.json workspace-config.json

