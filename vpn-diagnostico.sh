#!/bin/bash
# Diagnostico de conexiones VPN de Azure
# Busca la suscripcion que contiene el grupo de recursos,
# verifica la conexion VPN especificada y exporta los detalles a un archivo JSON.

set -euo pipefail
IFS=$'\n\t'

usage() {
    echo "Uso: $0 [GRUPO_RECURSOS] [NOMBRE_CONEXION] [ARCHIVO_SALIDA]"
    echo "Valores por defecto:"
    echo "  GRUPO_RECURSOS  -> AmbienteDesarrollo"
    echo "  NOMBRE_CONEXION -> Site_Miguel_Aleman_Fortinet_FTR_Desarrollo"
    echo "  ARCHIVO_SALIDA  -> vpn_diagnostico_resultado.json"
}

RESOURCE_GROUP="${1:-AmbienteDesarrollo}"
CONNECTION_NAME="${2:-Site_Miguel_Aleman_Fortinet_FTR_Desarrollo}"
OUTPUT_FILE="${3:-vpn_diagnostico_resultado.json}"

PROGRESS_BAR_WIDTH=40
TOTAL_STEPS=4
CURRENT_STEP=0

trap 'echo "\n❌ Error en la linea $LINENO" >&2; exit 1' ERR

# Comprobar dependencias
command -v az >/dev/null 2>&1 || { echo "❌ Azure CLI no encontrado." >&2; exit 1; }

# Comprobar autenticacion
if ! az account show >/dev/null 2>&1; then
    echo "❌ No hay sesion activa de Azure CLI. Ejecuta 'az login' e intenta de nuevo." >&2
    exit 1
fi

progress() {
    local msg="$1"
    local progress=$((CURRENT_STEP * PROGRESS_BAR_WIDTH / TOTAL_STEPS))
    local remaining=$((PROGRESS_BAR_WIDTH - progress))
    printf -v bar '%0.s#' $(seq 1 $progress)
    printf -v space '%0.s-' $(seq 1 $remaining)
    printf "\r[%s%s] %d%% - %s" "$bar" "$space" $((CURRENT_STEP * 100 / TOTAL_STEPS)) "$msg"
}

step_done() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
}

find_subscription() {
    progress "Buscando suscripcion para el grupo '$RESOURCE_GROUP'"
    az account list --query '[].id' -o tsv | while read -r sub_id; do
        az account set --subscription "$sub_id" >/dev/null 2>&1
        if az group exists --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
            echo "$sub_id"
            break
        fi
    done
    step_done
}

verify_connection() {
    progress "Verificando conexion VPN"
    az network vpn-connection show \
        --name "$CONNECTION_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --only-show-errors \
        --output none
    step_done
}

export_details() {
    progress "Exportando informacion"
    az network vpn-connection show \
        --name "$CONNECTION_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --output json > "$OUTPUT_FILE"
    step_done
}

SUBSCRIPTION_ID=$(find_subscription)

if [[ -z "$SUBSCRIPTION_ID" ]]; then
    echo "\n❌ No se encontro la suscripcion que contiene el grupo '$RESOURCE_GROUP'." >&2
    exit 1
fi

az account set --subscription "$SUBSCRIPTION_ID" >/dev/null
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
step_done

progress "Suscripcion '$SUBSCRIPTION_NAME' establecida"

verify_connection
export_details

progress "Completado"

printf "\n✅ Diagnostico completado. Archivo guardado en '%s'.\n" "$OUTPUT_FILE"
