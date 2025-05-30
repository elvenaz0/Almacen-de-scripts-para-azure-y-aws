#!/bin/sh
# Script para verificar una conexion VPN en AWS y exportar sus detalles.
# Requiere AWS CLI y jq instalados.

set -e

REGION="${1:-us-east-1}"
CONNECTION="${2:-vpn-00000000000000000}"  # ID o nombre (tag Name) de la VPN
OUTPUT_FILE="${3:-vpn-diagnostic.json}"

PROGRESS_BAR_WIDTH=40
TOTAL_STEPS=3
CURRENT_STEP=0

# Verificar dependencias
command -v aws >/dev/null 2>&1 || { echo "aws CLI no encontrado." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq no encontrado." >&2; exit 1; }

# Verificar credenciales
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "No hay sesion activa de AWS CLI. Configura las credenciales e intenta de nuevo." >&2
    exit 1
fi

progress() {
    message=$1
    progress=$((CURRENT_STEP * PROGRESS_BAR_WIDTH / TOTAL_STEPS))
    remaining=$((PROGRESS_BAR_WIDTH - progress))
    bar=$(printf '%*s' "$progress" | tr ' ' '#')
    space=$(printf '%*s' "$remaining" | tr ' ' '-')
    printf "\r[%s%s] %d%% - %s" "$bar" "$space" $((CURRENT_STEP * 100 / TOTAL_STEPS)) "$message"
}

step_done() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
}

verify_region() {
    progress "Verificando region $REGION"
    if ! aws ec2 describe-regions --query 'Regions[].RegionName' --output text | grep -qw "$REGION"; then
        echo "\nRegion no valida: $REGION" >&2
        exit 1
    fi
    step_done
}

fetch_vpn() {
    progress "Obteniendo informacion de la VPN"
    if echo "$CONNECTION" | grep -q '^vpn-'; then
        FILTER="--vpn-connection-ids $CONNECTION"
    else
        FILTER="--filters Name=tag:Name,Values=$CONNECTION"
    fi
    CONNECTION_JSON=$(aws ec2 describe-vpn-connections --region "$REGION" $FILTER)
    if [ "$(echo "$CONNECTION_JSON" | jq '.VpnConnections | length')" -eq 0 ]; then
        echo "\nVPN '$CONNECTION' no encontrada en la region '$REGION'." >&2
        exit 1
    fi
    step_done
}

export_details() {
    progress "Exportando detalles"
    echo "$CONNECTION_JSON" > "$OUTPUT_FILE"
    step_done
}

verify_region
fetch_vpn
export_details
progress "Completado"
printf "\nDetalles guardados en '%s'.\n" "$OUTPUT_FILE"
